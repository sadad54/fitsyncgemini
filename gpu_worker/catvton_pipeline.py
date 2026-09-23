"""Loads and caches the CatVTON pipeline.

Requires the CatVTON repo (github.com/Zheng-Chong/CatVTON) cloned into
./CatVTON alongside this file — see README.md. CatVTON is not pip-
installable as a library; its code is imported directly from that checkout.

Model weights (downloaded automatically on first run, then cached by
huggingface_hub in the usual ~/.cache/huggingface):
  base_ckpt: runwayml/stable-diffusion-inpainting
  attn_ckpt: zhengchong/CatVTON
Both verified against the CatVTON README/INSTALL.md — do not change these
without re-checking the upstream project.
"""

import os
import sys
import threading

_CATVTON_DIR = os.path.join(os.path.dirname(__file__), "CatVTON")
if os.path.isdir(_CATVTON_DIR) and _CATVTON_DIR not in sys.path:
    sys.path.insert(0, _CATVTON_DIR)

_pipeline = None
_lock = threading.Lock()


def get_pipeline():
    """Lazily builds the CUDA-resident pipeline once per process. Not
    thread-safe to call concurrently before the first call completes —
    call once at startup (see app.py's startup hook) rather than relying on
    first-request warmup."""
    global _pipeline
    if _pipeline is not None:
        return _pipeline
    with _lock:
        if _pipeline is not None:
            return _pipeline

        if not os.path.isdir(_CATVTON_DIR):
            raise RuntimeError(
                f"CatVTON repo not found at {_CATVTON_DIR} — clone "
                "https://github.com/Zheng-Chong/CatVTON into gpu_worker/CatVTON "
                "first (see README.md)."
            )

        import torch
        from model.pipeline import CatVTONPipeline  # from the cloned CatVTON repo

        base_ckpt = os.getenv("CATVTON_BASE_MODEL", "runwayml/stable-diffusion-inpainting")
        attn_ckpt = os.getenv("CATVTON_ATTN_CKPT", "zhengchong/CatVTON")

        _pipeline = CatVTONPipeline(
            base_ckpt=base_ckpt,
            attn_ckpt=attn_ckpt,
            attn_ckpt_version="mix",
            weight_dtype=torch.bfloat16,
            use_tf32=True,
            device="cuda",
        )
        return _pipeline
