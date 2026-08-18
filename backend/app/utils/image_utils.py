import uuid
from typing import Tuple

import cv2
import numpy as np

from app.core.database import db

BUCKET = "clothing-items"


def process_image(image_bytes: bytes, resize_dim: Tuple[int, int] = (512, 512)) -> bytes:
    """Resize an image and return the re-encoded JPEG bytes."""
    try:
        nparr = np.frombuffer(image_bytes, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        if image is None:
            raise ValueError("OpenCV failed to decode image. Invalid image format.")

        resized = cv2.resize(image, resize_dim)

        success, encoded_image = cv2.imencode(".jpg", resized)
        if not success:
            raise ValueError("Failed to encode image to JPEG.")

        return encoded_image.tobytes()

    except Exception as e:
        raise RuntimeError(f"Image processing error: {str(e)}")


def upload_to_supabase(image_bytes: bytes, user_id: str, bucket: str = BUCKET) -> Tuple[str, str]:
    """Upload processed image bytes to Supabase storage and return (public_url, image_path)."""
    try:
        file_id = uuid.uuid4().hex
        image_path = f"{user_id}/{file_id}.jpg"

        client = db.get_client()
        client.storage.from_(bucket).upload(
            path=image_path,
            file=image_bytes,
            file_options={"content-type": "image/jpeg"},
        )

        public_url = client.storage.from_(bucket).get_public_url(image_path)
        return public_url, image_path

    except Exception as e:
        raise RuntimeError(f"Supabase upload error: {str(e)}")


def process_and_upload_image(image_bytes: bytes, user_id: str, bucket: str = BUCKET, resize: bool = True) -> Tuple[str, str]:
    """Full pipeline: resize/process the image, then upload it. Returns (public_url, image_path)."""
    try:
        processed_image = process_image(image_bytes) if resize else image_bytes
        return upload_to_supabase(processed_image, user_id, bucket=bucket)
    except Exception as e:
        raise RuntimeError(f"process_and_upload_image failed: {str(e)}")
