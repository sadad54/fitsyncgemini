"""Optional deployment; never deploy until free-credit controls are checked."""
from pathlib import Path
import modal

ROOT = Path(__file__).parent
CATVTON_COMMIT = "999bdbe81e6008a3f5749af7c1e0b0fa3d21b48e"
image = (
    modal.Image.debian_slim(python_version="3.11")
    .apt_install("git", "libgl1", "libglib2.0-0")
    .pip_install_from_requirements(str(ROOT / "requirements.txt"))
    .run_commands("git clone https://github.com/Zheng-Chong/CatVTON.git /opt/CatVTON",
                  f"git -C /opt/CatVTON checkout {CATVTON_COMMIT}")
    .env({"CATVTON_DIR": "/opt/CatVTON", "HF_HOME": "/cache/huggingface"})
    .add_local_file(str(ROOT / "app.py"), "/worker/app.py")
    .add_local_file(str(ROOT / "catvton_pipeline.py"), "/worker/catvton_pipeline.py")
)
app = modal.App("fitsync-tryon-prototype")
cache = modal.Volume.from_name("fitsync-tryon-models", create_if_missing=True)


@app.function(image=image, gpu="T4", min_containers=0, max_containers=1,
              scaledown_window=30, timeout=300, volumes={"/cache": cache},
              secrets=[modal.Secret.from_name("fitsync-tryon")])
@modal.asgi_app(requires_proxy_auth=True)
def serve():
    import sys
    sys.path.insert(0, "/worker")
    from app import app as web_app
    return web_app
