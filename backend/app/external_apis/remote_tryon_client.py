"""Client for the optional GPU try-on worker (see gpu_worker/README.md).

Returns None whenever the worker isn't configured, unreachable, or errors —
callers (tryon_service.py) fall back to the local PIL compositor rather than
failing the request. This mirrors the graceful-degradation pattern already
used for weather/locations (see weather_service.py, location_service.py).
"""

from typing import Optional

import httpx
from loguru import logger

from app.core.config import settings


async def generate_remote_tryon(person_image_bytes: bytes, garment_image_bytes: bytes, category: str) -> Optional[bytes]:
    if not settings.GPU_TRYON_URL:
        return None

    headers = {}
    if settings.GPU_TRYON_SHARED_SECRET:
        headers["X-Shared-Secret"] = settings.GPU_TRYON_SHARED_SECRET

    files = {
        "person_image": ("person.jpg", person_image_bytes, "image/jpeg"),
        "garment_image": ("garment.jpg", garment_image_bytes, "image/jpeg"),
    }
    data = {"category": category}

    try:
        async with httpx.AsyncClient(timeout=settings.GPU_TRYON_TIMEOUT_SECONDS) as client:
            response = await client.post(f"{settings.GPU_TRYON_URL.rstrip('/')}/generate", files=files, data=data, headers=headers)
        if response.status_code != 200:
            logger.warning(f"GPU try-on worker returned {response.status_code}: {response.text[:200]}")
            return None
        return response.content
    except Exception as exc:
        logger.warning(f"GPU try-on worker unreachable, falling back to local compositor: {exc}")
        return None
