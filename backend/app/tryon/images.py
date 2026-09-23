"""Decode untrusted images, bound memory, remove EXIF, preserve aspect ratio."""
from io import BytesIO
import warnings
from PIL import Image, ImageOps, UnidentifiedImageError

MAX_BYTES = 10 * 1024 * 1024
MAX_PIXELS = 20_000_000


def normalize_image(data: bytes) -> bytes:
    if not data or len(data) > MAX_BYTES:
        raise ValueError("Image must be non-empty and no larger than 10 MB")
    try:
        with warnings.catch_warnings():
            warnings.simplefilter("error", Image.DecompressionBombWarning)
            with Image.open(BytesIO(data)) as image:
                if image.width * image.height > MAX_PIXELS:
                    raise ValueError("Image exceeds 20 megapixels")
                image = ImageOps.exif_transpose(image)
                image.thumbnail((1536, 2048), Image.Resampling.LANCZOS)
                if image.mode in ("RGBA", "LA") or "transparency" in image.info:
                    rgba = image.convert("RGBA")
                    canvas = Image.new("RGB", image.size, "white")
                    canvas.paste(rgba, mask=rgba.getchannel("A"))
                    image = canvas
                else:
                    image = image.convert("RGB")
                output = BytesIO()
                image.save(output, "JPEG", quality=95)
                return output.getvalue()
    except (UnidentifiedImageError, OSError, Image.DecompressionBombError,
            Image.DecompressionBombWarning) as exc:
        raise ValueError("Upload a valid JPEG, PNG or WebP image") from exc
