"""CatVTON + official DensePose/SCHP automasking, loaded once per process."""
import io
import os
import sys
import threading
from pathlib import Path
from PIL import Image, ImageOps

_CATVTON_DIR = str(Path(os.getenv("CATVTON_DIR", Path(__file__).parent / "CatVTON")))
_pipeline = None
_masker = None
_load_lock = threading.Lock()
_inference_lock = threading.Lock()


def get_pipeline():
    global _pipeline, _masker
    with _load_lock:
        if _pipeline is not None:
            return _pipeline
        if not Path(_CATVTON_DIR).is_dir():
            raise RuntimeError("Clone the pinned CatVTON checkout first; see gpu_worker/README.md")
        if _CATVTON_DIR not in sys.path:
            sys.path.insert(0, _CATVTON_DIR)
        import torch
        from huggingface_hub import snapshot_download
        from model.pipeline import CatVTONPipeline
        from model.cloth_masker import AutoMasker
        if not torch.cuda.is_available():
            raise RuntimeError("CatVTON requires a CUDA GPU; run this worker on Kaggle or Modal")
        checkpoint = snapshot_download("zhengchong/CatVTON", revision=os.getenv("CATVTON_REVISION", "main"))
        pipeline = CatVTONPipeline(
            base_ckpt=os.getenv("CATVTON_BASE_MODEL", "booksforcharlie/stable-diffusion-inpainting"),
            attn_ckpt=checkpoint, attn_ckpt_version="mix", weight_dtype=torch.float16,
            use_tf32=False, device="cuda",
        )
        masker = AutoMasker(densepose_ckpt=os.path.join(checkpoint, "DensePose"),
                            schp_ckpt=os.path.join(checkpoint, "SCHP"), device="cuda")
        _pipeline, _masker = pipeline, masker
        return _pipeline


REGIONS = {"tops": "upper", "outerwear": "upper", "bottoms": "lower", "dresses": "overall"}


def generate_image(person_bytes, garment_bytes, category, num_inference_steps=50, seed=42, guidance_scale=2.5):
    if category not in REGIONS:
        raise ValueError("Unsupported garment category")
    pipeline = get_pipeline()
    import torch
    from diffusers.image_processor import VaeImageProcessor
    from utils import resize_and_padding
    with _inference_lock, torch.inference_mode():
        # Letterbox instead of cropping away the feet/hem in full-body photos.
        person = ImageOps.exif_transpose(Image.open(io.BytesIO(person_bytes))).convert("RGB")
        garment = ImageOps.exif_transpose(Image.open(io.BytesIO(garment_bytes))).convert("RGB")
        person = resize_and_padding(person, (768, 1024))
        garment = resize_and_padding(garment, (768, 1024))
        mask = _masker(person, REGIONS[category])["mask"]
        if mask.getbbox() is None:
            raise ValueError("No clothing region detected. Use a clear front-facing photo.")
        mask = VaeImageProcessor(vae_scale_factor=8, do_normalize=False,
            do_binarize=True, do_convert_grayscale=True).blur(mask, blur_factor=9)
        result = pipeline(image=person, condition_image=garment, mask=mask,
            num_inference_steps=num_inference_steps, guidance_scale=guidance_scale,
            generator=torch.Generator(device="cuda").manual_seed(seed), width=768, height=1024)[0]
        output = io.BytesIO()
        result.save(output, "JPEG", quality=95)
        return output.getvalue()
