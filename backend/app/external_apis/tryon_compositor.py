"""Free-tier virtual try-on: a deterministic image compositor.

This intentionally does not call out to third-party "AI virtual try-on"
services (Gradio Spaces / Inference API models like IDM-VTON are unreliable
and slow on free tiers, and often unavailable outright). Instead it resizes
each garment image and layers it over the person photo in the right body
zone. It's an honest preview compositor, not garment warping — the
confidence score reflects that.
"""

import io
from typing import Dict, List, Tuple

import aiohttp
from PIL import Image

CANVAS_SIZE = (512, 768)

# (width, height, anchor_x, anchor_y) as fractions of the canvas, per zone.
ZONES: Dict[str, Tuple[float, float, float, float]] = {
    "upper_body": (0.62, 0.42, 0.5, 0.30),
    "lower_body": (0.58, 0.46, 0.5, 0.66),
    "full_body": (0.72, 0.85, 0.5, 0.5),
    "accessory": (0.32, 0.22, 0.5, 0.14),
}

CATEGORY_ZONES = {
    "tops": "upper_body",
    "outerwear": "upper_body",
    "activewear": "upper_body",
    "bottoms": "lower_body",
    "footwear": "lower_body",
    "dresses": "full_body",
    "accessories": "accessory",
}


async def _download(url: str) -> bytes:
    async with aiohttp.ClientSession() as session:
        async with session.get(url) as response:
            response.raise_for_status()
            return await response.read()


def _paste_zone(canvas: Image.Image, garment: Image.Image, zone: str, opacity: float) -> None:
    frac_w, frac_h, anchor_x, anchor_y = ZONES[zone]
    canvas_w, canvas_h = canvas.size
    target_w, target_h = int(canvas_w * frac_w), int(canvas_h * frac_h)

    garment = garment.convert("RGBA")
    garment.thumbnail((target_w, target_h), Image.LANCZOS)

    if garment.mode == "RGBA":
        alpha = garment.split()[-1].point(lambda a: int(a * opacity))
        garment.putalpha(alpha)

    x = int(canvas_w * anchor_x - garment.width / 2)
    y = int(canvas_h * anchor_y - garment.height / 2)
    canvas.alpha_composite(garment, (x, y))


async def composite_tryon(person_image_bytes: bytes, garments: List[Dict]) -> Tuple[bytes, float]:
    """Layer each garment (dict with `image_url` and `category`) onto the
    person photo. Returns (jpeg_bytes, confidence_score)."""
    person = Image.open(io.BytesIO(person_image_bytes)).convert("RGBA")
    person = person.resize(CANVAS_SIZE, Image.LANCZOS)
    canvas = person.copy()

    placed = 0
    for garment in garments:
        url = garment.get("image_url")
        if not url:
            continue
        try:
            garment_bytes = await _download(url)
            garment_img = Image.open(io.BytesIO(garment_bytes))
        except Exception:
            continue

        zone = CATEGORY_ZONES.get(garment.get("category") or "", "full_body")
        _paste_zone(canvas, garment_img, zone, opacity=0.92)
        placed += 1

    output = io.BytesIO()
    canvas.convert("RGB").save(output, format="JPEG", quality=88)

    # Honest score: this is a layout preview, not garment-fitted AI —
    # reward having placed every requested item, cap well under "real" AI.
    confidence = 0.0 if not garments else round(0.35 + 0.15 * min(placed, 3), 2)
    return output.getvalue(), confidence
