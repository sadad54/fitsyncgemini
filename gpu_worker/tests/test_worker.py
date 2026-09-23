import io
import sys
from pathlib import Path
import pytest
from fastapi.testclient import TestClient
from PIL import Image
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
# Backend also uses the module name app; load this file under a distinct name.
import importlib.util
spec = importlib.util.spec_from_file_location("gpu_app", Path(__file__).resolve().parents[1] / "app.py")
worker = importlib.util.module_from_spec(spec); spec.loader.exec_module(worker)


def image():
    stream = io.BytesIO(); Image.new("RGB", (60, 80)).save(stream, "JPEG"); return stream.getvalue()


def test_auth_is_required_even_without_secret(monkeypatch):
    client = TestClient(worker.app)
    monkeypatch.delenv("GPU_TRYON_SHARED_SECRET", raising=False)
    assert client.get("/health").status_code == 503
    monkeypatch.setenv("GPU_TRYON_SHARED_SECRET", "s" * 32)
    assert client.get("/health").status_code == 401


def test_dress_request_contract(monkeypatch):
    monkeypatch.setenv("GPU_TRYON_SHARED_SECRET", "s" * 32)
    monkeypatch.setenv("TRYON_NONCOMMERCIAL_ACK", "true")
    calls = []
    monkeypatch.setattr(worker, "generate_image", lambda *args: calls.append(args) or image())
    client = TestClient(worker.app)
    payload = {"person_image": ("p.jpg", image()), "garment_image": ("g.jpg", image())}
    headers = {"X-Shared-Secret": "s" * 32}
    r = client.post("/generate", headers=headers, files=payload, data={"category": "dresses", "seed": 7})
    assert r.status_code == 200 and r.headers["content-type"] == "image/jpeg"
    assert calls[0][2:] == ("dresses", 50, 7, 2.5)
    assert client.post("/generate", headers=headers, files=payload, data={"category": "footwear"}).status_code == 422
    assert client.post("/generate", headers=headers, files=payload, data={"category": "dresses", "num_inference_steps": 999}).status_code == 422
