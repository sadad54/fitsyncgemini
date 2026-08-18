import io

import pytest
from PIL import Image

from app.external_apis.tryon_compositor import composite_tryon


def _jpeg_bytes(size=(200, 200), color=(255, 0, 0)):
    buf = io.BytesIO()
    Image.new("RGB", size, color).save(buf, format="JPEG")
    return buf.getvalue()


@pytest.mark.asyncio
async def test_composite_tryon_with_no_garments_returns_low_confidence():
    person = _jpeg_bytes()
    result_bytes, confidence = await composite_tryon(person, [])
    assert confidence == 0.0
    img = Image.open(io.BytesIO(result_bytes))
    assert img.size == (512, 768)


@pytest.mark.asyncio
async def test_composite_tryon_skips_unreachable_garment_urls():
    person = _jpeg_bytes()
    garments = [{"category": "tops", "image_url": "http://127.0.0.1:1/does-not-exist.jpg"}]
    result_bytes, confidence = await composite_tryon(person, garments)
    # Download fails, so nothing gets placed -> base confidence for "requested but placed none".
    assert confidence == 0.35
    img = Image.open(io.BytesIO(result_bytes))
    assert img.size == (512, 768)
