import asyncio
import hashlib
import json
from datetime import datetime, timezone
from typing import Any
from uuid import uuid4

from fastapi import HTTPException
from loguru import logger

from app.core.config import settings
from app.core.database import db
from app.models.tryon import TryOnResult
from app.tryon import storage
from app.tryon.images import normalize_image
from app.tryon.providers import REGIONS, get_provider

TABLE = "tryon_jobs"


def now():
    return datetime.now(timezone.utc).isoformat()


def validate_selection(items: list[dict]) -> list[dict]:
    if not 1 <= len(items) <= 2:
        raise ValueError("Choose one dress, one top/bottom, or one top and one bottom")
    regions = [REGIONS.get(g.get("category")) for g in items]
    if None in regions:
        raise ValueError("Try-on supports tops, outerwear, bottoms and dresses; remove shoes/accessories")
    if len(items) == 2 and set(regions) != {"upper", "lower"}:
        raise ValueError("Choose a dress by itself, or one top and one bottom")
    # Same order regardless of database row order: bottom first, then top.
    return sorted(items, key=lambda g: (REGIONS[g["category"]] != "lower", g["id"]))


def cache_key(person: bytes, garments: list[tuple[dict, bytes]], options: dict) -> str:
    identity = {
        "person": hashlib.sha256(person).hexdigest(),
        "garments": [{"id": g["id"], "category": g["category"],
                       "sha256": hashlib.sha256(data).hexdigest()} for g, data in garments],
        "options": options, "provider": settings.TRYON_PROVIDER,
        "model_version": settings.TRYON_MODEL_VERSION,
    }
    return hashlib.sha256(json.dumps(identity, sort_keys=True).encode()).hexdigest()


async def execute(query):
    return await asyncio.to_thread(query.execute)


async def to_result(row: dict[str, Any]) -> TryOnResult:
    data = dict(row)
    if "person_path" in data:
        data["person_image_url"] = await storage.signed_url(data["person_path"])
        data["result_image_url"] = await storage.signed_url(data.get("result_path"))
        data["render_kind"] = "diffusion"
    else:
        data["render_kind"] = "legacy_preview"
    return TryOnResult(**data)


class TryOnService:
    async def create_tryon(self, user_id, person_image_bytes, item_ids, seed=42):
        try:
            get_provider()  # Fail before uploading if disabled/misconfigured.
        except ValueError as exc:
            raise HTTPException(503, str(exc)) from exc
        result = await execute(db.get_client().table("clothing_items")
            .select("id, image_url, category").eq("user_id", user_id).in_("id", item_ids))
        items = result.data or []
        if {g["id"] for g in items} != set(item_ids):
            raise HTTPException(404, "One or more selected items were not found in your closet")
        try:
            items = validate_selection(items)
            person = await asyncio.to_thread(normalize_image, person_image_bytes)
            garments = [(g, await storage.garment_bytes(g.get("image_url") or "", user_id)) for g in items]
        except ValueError as exc:
            raise HTTPException(422, str(exc)) from exc
        except Exception as exc:
            raise HTTPException(503, "Could not read a selected garment image. Please try again.") from exc
        options = {"seed": seed, "num_inference_steps": 50, "guidance_scale": 2.5}
        job_id = str(uuid4())
        root = f"{user_id}/{job_id}"
        row = {"id": job_id, "user_id": user_id, "item_ids": [g["id"] for g in items],
               "provider": settings.TRYON_PROVIDER, "model_version": settings.TRYON_MODEL_VERSION,
               "cache_key": cache_key(person, garments, options), "options": options,
               "person_path": f"{root}/person.jpg", "garments": []}
        uploaded = []
        try:
            await storage.upload(row["person_path"], person)
            uploaded.append(row["person_path"])
            for index, (garment, data) in enumerate(garments):
                path = f"{root}/garment-{index}.jpg"
                await storage.upload(path, data)
                uploaded.append(path)
                row["garments"].append({"path": path, "category": garment["category"]})
            result = await execute(db.get_client().rpc("enqueue_tryon", {
                "p_job": row, "p_monthly_limit": settings.TRYON_MONTHLY_JOB_LIMIT,
                "p_daily_limit": settings.TRYON_DAILY_USER_LIMIT}))
            accepted = result.data[0]
        except Exception as exc:
            # RPC response loss is ambiguous: do not delete an admitted job's inputs.
            existing = await execute(db.get_client().table(TABLE).select("*").eq("id", job_id))
            if existing.data:
                return await to_result(existing.data[0])
            await storage.remove(uploaded)
            if "TRYON_QUOTA_EXCEEDED" in str(exc):
                raise HTTPException(429, "Prototype generation limit reached. Try again later.") from exc
            if "TRYON_ALREADY_ACTIVE" in str(exc):
                raise HTTPException(409, "You already have a try-on in progress. Open history to resume it.") from exc
            logger.warning("Try-on admission failed ({})", type(exc).__name__)
            raise HTTPException(503, "Try-on queue unavailable. Please try again later.") from exc
        if accepted["id"] != job_id:
            await storage.remove(uploaded)
        return await to_result(accepted)

    async def list_tryons(self, user_id):
        current = await execute(db.get_client().table(TABLE).select("*").eq("user_id", user_id)
            .is_("deleted_at", "null").gt("expires_at", now()).order("created_at", desc=True).limit(100))
        legacy = await execute(db.get_client().table("try_on_sessions").select("*")
            .eq("user_id", user_id).order("created_at", desc=True).limit(100))
        rows = sorted(current.data + legacy.data, key=lambda r: r["created_at"], reverse=True)[:100]
        return [await to_result(r) for r in rows], len(rows)

    async def get_tryon(self, user_id, tryon_id):
        result = await execute(db.get_client().table(TABLE).select("*").eq("id", tryon_id)
            .eq("user_id", user_id).is_("deleted_at", "null").gt("expires_at", now()))
        if not result.data:
            result = await execute(db.get_client().table("try_on_sessions").select("*")
                .eq("id", tryon_id).eq("user_id", user_id))
        if not result.data:
            raise HTTPException(404, "Try-on result not found or expired")
        return await to_result(result.data[0])

    async def delete_tryon(self, user_id, tryon_id):
        # Retain quota accounting, erase image objects. Worker purges again on
        # storage failure. Atomic status guard prevents a delete/claim race.
        result = await execute(db.get_client().table(TABLE).update({"deleted_at": now()})
            .eq("id", tryon_id).eq("user_id", user_id).neq("status", "processing").is_("deleted_at", "null"))
        if result.data:
            await purge(result.data[0])
            return
        active = await execute(db.get_client().table(TABLE).select("id").eq("id", tryon_id)
            .eq("user_id", user_id).eq("status", "processing"))
        if active.data:
            raise HTTPException(409, "Wait for the active generation to finish before deleting it")
        result = await execute(db.get_client().table("try_on_sessions").delete()
            .eq("id", tryon_id).eq("user_id", user_id))
        if not result.data:
            raise HTTPException(404, "Try-on result not found")


async def purge(row):
    paths = [row["person_path"], *[g["path"] for g in row["garments"]]]
    paths.append(row.get("result_path") or f"{row['user_id']}/{row['id']}/result.jpg")
    try:
        await storage.remove(paths)
        await execute(db.get_client().table(TABLE).update({"purged_at": now()}).eq("id", row["id"]))
    except Exception:
        logger.warning("Try-on image cleanup pending for job {}", row["id"])


tryon_service = TryOnService()
