"""GPU-side virtual try-on inference service (CatVTON).

Deployed separately from the main FitSync backend — runs on a CUDA machine
(e.g. a university GPU cluster reached via AnyDesk) and exposed to the main
backend over a private tunnel (Tailscale recommended: it reaches out from
this machine rather than needing an inbound port opened on the cluster's
firewall, which most university clusters won't allow). Never designed to be
reachable from the public internet; a shared-secret header is required
regardless as a second layer.

See README.md for setup. Run with:
    uvicorn app:app --host 0.0.0.0 --port 8100
"""

import io
import os
from typing import Optional

from fastapi import FastAPI, File, Form, Header, HTTPException, UploadFile
from fastapi.responses import Response
from PIL import Image

from catvton_pipeline import get_pipeline
from masking import CATEGORY_TO_REGION, build_mask

SHARED_SECRET = os.getenv("GPU_TRYON_SHARED_SECRET", "")

app = FastAPI(title="FitSync GPU Try-On Worker")


def _check_auth(shared_secret_header: Optional[str]) -> None:
    if not SHARED_SECRET:
        # Unconfigured = auth disabled. Fine for a quick local test over
        # Tailscale's own private network, but set GPU_TRYON_SHARED_SECRET
        # before treating this as a real deployment.
        return
    if shared_secret_header != SHARED_SECRET:
        raise HTTPException(status_code=401, detail="Invalid or missing shared secret")


@app.on_event("startup")
async def warmup() -> None:
    # Loads model weights once at process start (first run also downloads
    # them — see catvton_pipeline.py) so the first real request doesn't pay
    # that cost on top of tunnel latency.
    get_pipeline()


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.post("/generate")
async def generate(
    person_image: UploadFile = File(...),
    garment_image: UploadFile = File(...),
    category: str = Form("tops"),
    num_inference_steps: int = Form(35),
    x_shared_secret: Optional[str] = Header(default=None, alias="X-Shared-Secret"),
):
    _check_auth(x_shared_secret)

    person = Image.open(io.BytesIO(await person_image.read())).convert("RGB")
    garment = Image.open(io.BytesIO(await garment_image.read())).convert("RGB")

    region = CATEGORY_TO_REGION.get(category, "upper")
    try:
        mask = build_mask(person, region)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc))

    pipeline = get_pipeline()
    result = pipeline(
        image=person,
        condition_image=garment,
        mask=mask,
        num_inference_steps=num_inference_steps,
        guidance_scale=2.5,
    )[0]

    buf = io.BytesIO()
    result.save(buf, format="JPEG", quality=90)
    return Response(content=buf.getvalue(), media_type="image/jpeg")
