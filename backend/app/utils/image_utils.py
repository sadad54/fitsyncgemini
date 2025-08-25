import os
import uuid
import numpy as np
import cv2
from typing import Tuple, Optional
from app.utils.supabase_client import supabase


def process_image(image_bytes: bytes, resize_dim: Tuple[int, int] = (512, 512)) -> bytes:
    """
    Process an image (resize, etc.) and return the encoded bytes.
    """
    try:
        # Convert bytes to OpenCV image
        nparr = np.frombuffer(image_bytes, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        if image is None:
            raise ValueError("❌ OpenCV failed to decode image. Invalid image format.")

        # Resize the image
        resized = cv2.resize(image, resize_dim)

        # Encode to JPEG
        success, encoded_image = cv2.imencode('.jpg', resized)
        if not success:
            raise ValueError("❌ Failed to encode image to JPEG.")

        return encoded_image.tobytes()

    except Exception as e:
        raise RuntimeError(f"⚠️ Image processing error: {str(e)}")


def upload_to_supabase(image_bytes: bytes, user_id: str) -> Tuple[str, str]:
    """
    Upload processed image to Supabase storage and return (public_url, image_path).
    """
    try:
        file_id = uuid.uuid4().hex
        image_path = f"uploads/{user_id}/{file_id}.jpg"

        # Upload to Supabase
        supabase.storage.from_("fitsync").upload(
            path=image_path,
            file=image_bytes,
            file_options={"content-type": "image/jpeg"}
        )

        # Generate public URL
        public_url = supabase.storage.from_("fitsync").get_public_url(image_path)
        return public_url, image_path

    except Exception as e:
        raise RuntimeError(f"❌ Supabase upload error: {str(e)}")


def process_and_upload_image(image_bytes: bytes, user_id: str) -> Tuple[str, str]:
    """
    Full pipeline: process image and upload to Supabase.
    Returns: (public_url, image_path)
    """
    try:
        # Step 1: Resize/process the image
        processed_image = process_image(image_bytes)

        # Step 2: Upload and get URLs
        return upload_to_supabase(processed_image, user_id)

    except Exception as e:
        raise RuntimeError(f"❌ process_and_upload_image failed: {str(e)}")
