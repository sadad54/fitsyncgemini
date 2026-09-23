"""Run separately: python -m app.tryon.worker (from backend/).

No inference runs inside request handlers. Supabase owns the durable queue.
Crashes leave a visible job; stale claims fail instead of silently rebilling.
"""
import asyncio
import time
from loguru import logger
from app.core.database import db
from app.core.config import settings
from app.tryon import storage
from app.tryon.providers import get_provider, TryOnOptions
from app.services.tryon_service import TABLE, execute, now, purge


async def process(row, provider):
    started = time.monotonic()
    result_path = f"{row['user_id']}/{row['id']}/result.jpg"
    uploaded = False
    try:
        async with asyncio.timeout(660):
            image = await storage.download(row["person_path"])
            for garment in row["garments"]:
                image = await provider.generate(image, await storage.download(garment["path"]),
                    TryOnOptions(category=garment["category"], **row["options"]))
            await storage.upload(result_path, image)
            uploaded = True
            result = await execute(db.get_client().table(TABLE).update({
                "status": "completed", "result_path": result_path,
                "inference_seconds": round(time.monotonic() - started, 3),
                "completed_at": now(), "updated_at": now(),
            }).eq("id", row["id"]).eq("status", "processing").is_("deleted_at", "null"))
            if not result.data:
                await storage.remove([result_path])
        logger.info("Try-on job {} completed in {:.1f}s", row["id"], time.monotonic() - started)
    except Exception as exc:
        logger.warning("Try-on job {} failed ({})", row["id"], type(exc).__name__)
        if uploaded:
            # Preserve a successfully committed result after response loss.
            saved = await execute(db.get_client().table(TABLE).select("status").eq("id", row["id"]))
            if saved.data and saved.data[0]["status"] == "completed":
                return
            await storage.remove([result_path])
        await execute(db.get_client().table(TABLE).update({
            "status": "failed", "updated_at": now(),
            "error_message": "Generation could not finish. Check your photo and try again when the prototype GPU is available.",
            "inference_seconds": round(time.monotonic() - started, 3),
        }).eq("id", row["id"]).eq("status", "processing"))


async def tick(provider):
    rows = await execute(db.get_client().rpc("claim_tryon", {
        "p_provider": settings.TRYON_PROVIDER, "p_model_version": settings.TRYON_MODEL_VERSION}))
    if rows.data:
        await process(rows.data[0], provider)
    expired = await execute(db.get_client().table(TABLE).select("*").is_("purged_at", "null")
        .neq("status", "processing").or_(f"expires_at.lt.{now()},deleted_at.not.is.null").limit(20))
    for row in expired.data:
        await purge(row)
    return bool(rows.data)


async def main():
    provider = get_provider()
    await db.connect()
    try:
        while True:
            try:
                busy = await tick(provider)
            except Exception as exc:
                logger.warning("Try-on queue unavailable ({})", type(exc).__name__)
                busy = False
            if not busy:
                await asyncio.sleep(3)
    finally:
        await db.disconnect()


if __name__ == "__main__":
    asyncio.run(main())
