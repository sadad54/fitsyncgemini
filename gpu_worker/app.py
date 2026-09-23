"""Authenticated, bounded GPU inference. The backend owns durable jobs."""
import asyncio
import io
import os
import secrets
from fastapi import FastAPI, File, Form, HTTPException, UploadFile, Request
from fastapi.responses import Response
from PIL import Image, UnidentifiedImageError
from catvton_pipeline import generate_image

app = FastAPI(title="FitSync prototype GPU worker", docs_url=None, redoc_url=None)
_gate = asyncio.Lock()
MAX_BYTES = 10 * 1024 * 1024


@app.middleware("http")
async def authenticate(request: Request, call_next):
    # Authenticate before parsing uploads; fail closed even in local tests.
    secret = os.getenv("GPU_TRYON_SHARED_SECRET", "")
    if len(secret) < 32:
        return Response(status_code=503, content="Worker secret not configured")
    if not secrets.compare_digest(request.headers.get("X-Shared-Secret", ""), secret):
        return Response(status_code=401, content="Unauthorized")
    length = request.headers.get("content-length")
    if length and (not length.isdigit() or int(length) > 2 * MAX_BYTES + 65536):
        return Response(status_code=413, content="Upload too large")
    return await call_next(request)


async def read_image(upload):
    data = await upload.read(MAX_BYTES + 1)
    if not data or len(data) > MAX_BYTES:
        raise HTTPException(413, "Image must be no larger than 10 MB")
    try:
        with Image.open(io.BytesIO(data)) as image:
            if image.width * image.height > 20_000_000:
                raise ValueError()
            image.verify()
    except (OSError, ValueError, UnidentifiedImageError, Image.DecompressionBombError):
        raise HTTPException(422, "Invalid image")
    return data


@app.get("/health")
async def health():
    return {"status": "ok", "model": "catvton", "prototype": True}


@app.post("/generate")
async def generate(
    person_image: UploadFile = File(...), garment_image: UploadFile = File(...),
    category: str = Form(..., pattern="^(tops|outerwear|bottoms|dresses)$"),
    num_inference_steps: int = Form(50, ge=10, le=60),
    seed: int = Form(42, ge=0, le=2147483647),
    guidance_scale: float = Form(2.5, ge=1, le=5),
):
    if os.getenv("TRYON_NONCOMMERCIAL_ACK", "").lower() != "true":
        raise HTTPException(503, "Non-commercial prototype acknowledgment required")
    if _gate.locked():
        raise HTTPException(429, "GPU is busy")
    person, garment = await read_image(person_image), await read_image(garment_image)
    async with _gate:
        try:
            result = await asyncio.to_thread(generate_image, person, garment, category,
                num_inference_steps, seed, guidance_scale)
        except ValueError:
            raise HTTPException(422, "Could not detect clothing. Use a clear full-body photo.")
        except Exception:
            raise HTTPException(503, "GPU inference unavailable")
    return Response(content=result, media_type="image/jpeg")
