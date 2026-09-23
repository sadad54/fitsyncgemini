from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Tuple

from fastapi import HTTPException, status
from loguru import logger

from app.core.database import db
from app.external_apis.remote_tryon_client import generate_remote_tryon
from app.external_apis.tryon_compositor import composite_tryon, download_image_bytes
from app.models.tryon import TryOnResult
from app.utils.image_utils import process_and_upload_image_async

BUCKET = "try-on-results"

# Real diffusion output vs. the local compositor's honest "layout preview"
# scoring (see tryon_compositor.py) — reflects that this actually redraws
# the garment onto the body rather than pasting a flat cutout.
GPU_RESULT_CONFIDENCE = 0.9


def _to_tryon(row: Dict[str, Any]) -> TryOnResult:
    return TryOnResult(
        id=row["id"],
        user_id=row["user_id"],
        item_ids=row.get("item_ids") or [],
        person_image_url=row.get("person_image_url"),
        result_image_url=row.get("result_image_url"),
        status=row.get("status") or "failed",
        confidence_score=row.get("confidence_score"),
        error_message=row.get("error_message"),
        created_at=row["created_at"],
        updated_at=row["updated_at"],
    )


class TryOnService:
    async def create_tryon(self, user_id: str, person_image_bytes: bytes, item_ids: List[str]) -> TryOnResult:
        garments: List[Dict[str, Any]] = []
        if item_ids:
            result = (
                db.get_client()
                .table("clothing_items")
                .select("id, image_url, category")
                .eq("user_id", user_id)
                .in_("id", item_ids)
                .execute()
            )
            garments = result.data or []
            if not garments:
                raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="None of the selected items were found in your closet")

        person_url, _ = await process_and_upload_image_async(person_image_bytes, user_id, bucket=BUCKET, resize=False)

        now = datetime.now(timezone.utc).isoformat()
        row: Dict[str, Any] = {
            "user_id": user_id,
            "item_ids": [g["id"] for g in garments],
            "person_image_url": person_url,
            "status": "processing",
            "view_mode": "preview",
            "created_at": now,
            "updated_at": now,
        }

        try:
            gpu_result = await self._composite_via_gpu(person_image_bytes, garments)
            if gpu_result is not None:
                result_bytes, confidence = gpu_result
            else:
                result_bytes, confidence = await composite_tryon(person_image_bytes, garments)
            result_url, _ = await process_and_upload_image_async(result_bytes, user_id, bucket=BUCKET, resize=False)
            row["status"] = "completed"
            row["result_image_url"] = result_url
            row["confidence_score"] = confidence
            row["completed_at"] = datetime.now(timezone.utc).isoformat()
        except Exception as exc:
            row["status"] = "failed"
            row["error_message"] = str(exc)

        result = db.get_client().table("try_on_sessions").insert(row).execute()
        return _to_tryon(result.data[0])

    async def _composite_via_gpu(self, person_image_bytes: bytes, garments: List[Dict[str, Any]]) -> Optional[Tuple[bytes, float]]:
        """Tries the optional GPU worker (see gpu_worker/README.md), one
        garment at a time — CatVTON inpaints a single region per call, so
        multiple garments (e.g. top + bottom) chain through it sequentially,
        each call redrawing onto the previous result. Returns None (never
        raises) on any failure, unconfigured worker, or empty garment list,
        so the caller falls back to the local compositor."""
        if not garments:
            return None

        current = person_image_bytes
        placed = 0
        for garment in garments:
            url = garment.get("image_url")
            if not url:
                continue
            try:
                garment_bytes = await download_image_bytes(url)
            except Exception:
                return None
            result = await generate_remote_tryon(current, garment_bytes, garment.get("category") or "tops")
            if result is None:
                return None
            current = result
            placed += 1

        if placed == 0:
            return None
        logger.info(f"GPU try-on worker composited {placed} garment(s)")
        return current, GPU_RESULT_CONFIDENCE

    async def list_tryons(self, user_id: str) -> Tuple[List[TryOnResult], int]:
        result = (
            db.get_client()
            .table("try_on_sessions")
            .select("*")
            .eq("user_id", user_id)
            .order("created_at", desc=True)
            .execute()
        )
        results = [_to_tryon(row) for row in result.data]
        return results, len(results)

    async def get_tryon(self, user_id: str, tryon_id: str) -> TryOnResult:
        result = (
            db.get_client()
            .table("try_on_sessions")
            .select("*")
            .eq("id", tryon_id)
            .eq("user_id", user_id)
            .execute()
        )
        if not result.data:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Try-on result not found")
        return _to_tryon(result.data[0])

    async def delete_tryon(self, user_id: str, tryon_id: str) -> None:
        result = (
            db.get_client()
            .table("try_on_sessions")
            .delete()
            .eq("id", tryon_id)
            .eq("user_id", user_id)
            .execute()
        )
        if not result.data:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Try-on result not found")


tryon_service = TryOnService()
