"""One inference boundary. The durable backend queue owns submit/status.

Providers implement a single bounded generation; asynchronous vendor APIs can
submit and poll internally. No GPU libraries or provider secrets enter mobile.
"""
from dataclasses import dataclass, asdict
from typing import Protocol
from urllib.parse import urlparse
import asyncio
import base64
import os
import tempfile
import time
import httpx

from app.core.config import settings
from app.tryon.images import MAX_BYTES, normalize_image

REGIONS = {"tops": "upper", "outerwear": "upper", "bottoms": "lower", "dresses": "overall"}


@dataclass(frozen=True)
class TryOnOptions:
    category: str
    seed: int = 42
    num_inference_steps: int = 50
    guidance_scale: float = 2.5

    def payload(self):
        return asdict(self)


class TryOnProvider(Protocol):
    async def generate(self, person_image: bytes, garment_image: bytes,
                       options: TryOnOptions) -> bytes: ...


class RemoteProvider:
    def __init__(self, url: str, secret: str, timeout: float):
        parsed = urlparse(url)
        if parsed.scheme != "https" or not parsed.netloc or parsed.username or parsed.query:
            raise ValueError("TRYON_ENDPOINT must be an HTTPS base URL")
        if len(secret) < 32:
            raise ValueError("TRYON_SHARED_SECRET must contain at least 32 characters")
        self.url, self.secret, self.timeout = url.rstrip("/"), secret, timeout
        self.headers = {"X-Shared-Secret": secret}

    async def generate(self, person_image, garment_image, options):
        # Never retry uncertain GPU calls automatically: a timeout may still
        # have consumed compute. Redirects are disabled to avoid leaking secrets.
        async with httpx.AsyncClient(timeout=self.timeout, follow_redirects=False) as client:
            async with client.stream(
                "POST", f"{self.url}/generate",
                headers=self.headers,
                files={"person_image": ("person.jpg", person_image, "image/jpeg"),
                       "garment_image": ("garment.jpg", garment_image, "image/jpeg")},
                data={k: str(v) for k, v in options.payload().items()},
            ) as response:
                response.raise_for_status()
                data = bytearray()
                async for chunk in response.aiter_bytes():
                    data.extend(chunk)
                    if len(data) > MAX_BYTES:
                        raise ValueError("Provider result too large")
        return normalize_image(bytes(data))


class KaggleTunnelProvider(RemoteProvider):
    """Temporary HTTPS tunnel for supervised development only."""


class ModalProvider(RemoteProvider):
    """Authenticate at Modal's proxy before a GPU container is allocated."""
    def __init__(self, url, secret, timeout):
        super().__init__(url, secret, timeout)
        if not settings.TRYON_MODAL_KEY or not settings.TRYON_MODAL_SECRET:
            raise ValueError("Configure Modal proxy credentials on the backend")
        self.headers.update({"Modal-Key": settings.TRYON_MODAL_KEY,
                             "Modal-Secret": settings.TRYON_MODAL_SECRET})


class FashnProvider:
    """Commercially licensed hosted API: submit, then poll for a base64 result."""
    BASE_URL = "https://api.fashn.ai/v1"
    CATEGORIES = {"tops": "tops", "outerwear": "tops", "bottoms": "bottoms", "dresses": "one-pieces"}
    POLL_SECONDS = 2.0

    def __init__(self, api_key: str, timeout: float):
        if not api_key:
            raise ValueError("Configure FASHN_API_KEY on the backend")
        self.timeout = timeout
        self.headers = {"Authorization": f"Bearer {api_key}"}

    @staticmethod
    def _data_uri(image: bytes) -> str:
        return "data:image/jpeg;base64," + base64.b64encode(image).decode()

    async def generate(self, person_image, garment_image, options):
        if options.category not in self.CATEGORIES:
            raise ValueError(f"Unsupported try-on category: {options.category}")
        # return_base64 keeps outputs off FASHN's CDN (60 min retention, not 3 days).
        body = {"model_name": settings.FASHN_MODEL_NAME, "inputs": {
            "model_image": self._data_uri(person_image),
            "garment_image": self._data_uri(garment_image),
            "category": self.CATEGORIES[options.category],
            "mode": settings.FASHN_MODE, "seed": options.seed,
            "output_format": "jpeg", "return_base64": True}}
        deadline = time.monotonic() + self.timeout
        # Never resubmit automatically: each accepted run spends a credit.
        async with httpx.AsyncClient(base_url=self.BASE_URL, headers=self.headers,
                                     timeout=30, follow_redirects=False) as client:
            response = await client.post("/run", json=body)
            response.raise_for_status()
            submitted = response.json()
            if submitted.get("error") or not submitted.get("id"):
                raise RuntimeError(f"FASHN rejected the request: {submitted.get('error')}")
            while True:
                status = await client.get(f"/status/{submitted['id']}")
                status.raise_for_status()
                result = status.json()
                if result.get("status") == "completed":
                    break
                if result.get("status") in ("failed", "canceled"):
                    error = result.get("error") or {}
                    raise RuntimeError(f"FASHN {error.get('name', 'failure')}: {error.get('message', '')}".strip())
                if time.monotonic() >= deadline:
                    raise TimeoutError("FASHN did not finish in time")
                await asyncio.sleep(self.POLL_SECONDS)
        output = (result.get("output") or [None])[0]
        if not output or not output.startswith("data:"):
            raise RuntimeError("FASHN returned no base64 image")
        data = base64.b64decode(output.split(",", 1)[1])
        if len(data) > MAX_BYTES:
            raise ValueError("Provider result too large")
        return normalize_image(data)


class FashnSpaceProvider:
    """FASHN VTON v1.5 via its public Hugging Face Space. For live testing only:
    shared ZeroGPU quota, queueing and no uptime guarantee."""
    CATEGORIES = FashnProvider.CATEGORIES

    def __init__(self, space_id: str, timeout: float):
        self.space_id, self.timeout = space_id, timeout

    def _run(self, person_path: str, garment_path: str, options: TryOnOptions) -> bytes:
        from gradio_client import Client, handle_file  # imported lazily: optional dependency
        client = Client(self.space_id, token=settings.HF_TOKEN or None, verbose=False)
        result = client.predict(
            person_image=handle_file(person_path), garment_image=handle_file(garment_path),
            category=self.CATEGORIES[options.category],
            garment_photo_type=settings.FASHN_SPACE_GARMENT_PHOTO_TYPE,
            num_timesteps=options.num_inference_steps, guidance_scale=1.5,
            seed=options.seed, segmentation_free=True, api_name="/try_on")
        path = result.get("path") if isinstance(result, dict) else result
        with open(path, "rb") as f:
            return f.read()

    async def generate(self, person_image, garment_image, options):
        if options.category not in self.CATEGORIES:
            raise ValueError(f"Unsupported try-on category: {options.category}")
        with tempfile.TemporaryDirectory() as tmp:
            person_path, garment_path = os.path.join(tmp, "person.jpg"), os.path.join(tmp, "garment.jpg")
            for path, data in ((person_path, person_image), (garment_path, garment_image)):
                with open(path, "wb") as f:
                    f.write(data)
            data = await asyncio.wait_for(
                asyncio.to_thread(self._run, person_path, garment_path, options), self.timeout)
        if len(data) > MAX_BYTES:
            raise ValueError("Provider result too large")
        return normalize_image(data)


def get_provider(name: str | None = None) -> TryOnProvider:
    name = name or settings.TRYON_PROVIDER
    if name == "fashn":
        return FashnProvider(settings.FASHN_API_KEY, settings.TRYON_TIMEOUT_SECONDS)
    if name == "fashn_space":
        if settings.ENV == "production":
            raise ValueError("The public FASHN Space is for testing only")
        return FashnSpaceProvider(settings.FASHN_SPACE_ID, settings.TRYON_TIMEOUT_SECONDS)
    # Self-hosted CatVTON/IDM-VTON weights are CC BY-NC-SA: non-commercial only.
    if not settings.TRYON_NONCOMMERCIAL_ACK:
        raise ValueError("Enable TRYON_NONCOMMERCIAL_ACK only for permitted non-commercial testing")
    if name == "kaggle" and settings.ENV == "production":
        raise ValueError("Kaggle provider is development-only")
    providers = {"kaggle": KaggleTunnelProvider, "modal": ModalProvider}
    if name not in providers:
        raise ValueError("Try-on is disabled; configure a prototype provider first")
    return providers[name](settings.TRYON_ENDPOINT, settings.TRYON_SHARED_SECRET,
                           settings.TRYON_TIMEOUT_SECONDS)
