# FitSync prototype GPU worker

Start with [the complete setup guide](../docs/VIRTUAL_TRYON.md).

This service runs **CatVTON on a remote CUDA GPU**, never on the phone or the
ordinary backend PC. It uses FP16, official DensePose/SCHP automasking and the
`overall` region for dresses. One warmed model is reused; inference is serialized.
The FastAPI backend owns durable queueing, private storage, polling, quotas and caching.

- [CatVTON Kaggle notebook](notebooks/01_catvton_kaggle.ipynb)
- [IDM-VTON comparison notebook](notebooks/02_idm_comparison_kaggle.ipynb)
- [Optional Modal configuration](modal_app.py)
- [Example benchmark manifest](benchmark_manifest.example.json)

Requirements: isolated Python 3.11 GPU environment and pinned CatVTON checkout
`999bdbe81e6008a3f5749af7c1e0b0fa3d21b48e` in `gpu_worker/CatVTON`.
Install `requirements.txt`, set `GPU_TRYON_SHARED_SECRET` (32+ characters) and
`TRYON_NONCOMMERCIAL_ACK=true`, then from this folder run:

```bash
uvicorn app:app --host 0.0.0.0 --port 8100
```

`GET /health` and `POST /generate` both require `X-Shared-Secret`. Generation
accepts multipart `person_image`, `garment_image`, `category`, `seed`,
`num_inference_steps`, `guidance_scale`; it returns JPEG bytes. Backend requests
are bounded and never automatically retried after an uncertain GPU timeout.
A missing secret fails closed. Inference errors remain errors; no PIL fallback.

Upstream CatVTON and IDM-VTON materials are **CC BY-NC-SA 4.0**; retain notices.
A free beta is not automatically non-commercial. Check permission before external
use or launch. Neither GPU inference nor the Modal build has been executed in
this development environment. Use the notebooks to validate quality and runtime.
