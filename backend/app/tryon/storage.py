"""Private snapshots and signed result links; no arbitrary URL fetching."""
import asyncio
from urllib.parse import urlparse, unquote
from app.core.config import settings
from app.core.database import db
from app.tryon.images import normalize_image

BUCKET = "try-on-private"


async def upload(path: str, data: bytes):
    await asyncio.to_thread(lambda: db.get_client().storage.from_(BUCKET).upload(
        path, data, {"content-type": "image/jpeg"}))


async def download(path: str) -> bytes:
    return await asyncio.to_thread(lambda: db.get_client().storage.from_(BUCKET).download(path))


async def remove(paths: list[str]):
    if paths:
        await asyncio.to_thread(lambda: db.get_client().storage.from_(BUCKET).remove(paths))


async def signed_url(path: str | None):
    if not path:
        return None
    result = await asyncio.to_thread(lambda: db.get_client().storage.from_(BUCKET).create_signed_url(path, 3600))
    return result.get("signedURL") or result.get("signedUrl")


async def garment_bytes(url: str, user_id: str) -> bytes:
    parsed, origin = urlparse(url), urlparse(settings.SUPABASE_URL)
    prefix = "/storage/v1/object/public/clothing-items/"
    if parsed.scheme != "https" or parsed.netloc != origin.netloc or not parsed.path.startswith(prefix):
        raise ValueError("Garment must be an image uploaded to your FitSync closet")
    path = unquote(parsed.path[len(prefix):])
    if not path.startswith(f"{user_id}/") or ".." in path.split("/"):
        raise ValueError("Garment image does not belong to your closet")
    data = await asyncio.to_thread(lambda: db.get_client().storage.from_("clothing-items").download(path))
    return await asyncio.to_thread(normalize_image, data)
