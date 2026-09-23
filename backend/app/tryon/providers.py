"""One inference boundary. The durable backend queue owns submit/status.

Providers implement a single bounded generation; asynchronous vendor APIs can
submit and poll internally. No GPU libraries or provider secrets enter mobile.
"""
from dataclasses import dataclass, asdict
from typing import Protocol
from urllib.parse import urlparse
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


def get_provider(name: str | None = None) -> TryOnProvider:
    name = name or settings.TRYON_PROVIDER
    if not settings.TRYON_NONCOMMERCIAL_ACK:
        raise ValueError("Enable TRYON_NONCOMMERCIAL_ACK only for permitted non-commercial testing")
    if name == "kaggle" and settings.ENV == "production":
        raise ValueError("Kaggle provider is development-only")
    providers = {"kaggle": KaggleTunnelProvider, "modal": ModalProvider}
    if name not in providers:
        raise ValueError("Try-on is disabled; configure a prototype provider first")
    return providers[name](settings.TRYON_ENDPOINT, settings.TRYON_SHARED_SECRET,
                           settings.TRYON_TIMEOUT_SECONDS)
