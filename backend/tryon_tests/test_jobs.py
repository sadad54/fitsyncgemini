import asyncio
from io import BytesIO
from types import SimpleNamespace
from unittest.mock import AsyncMock, Mock
import pytest
from PIL import Image
from app.tryon.images import normalize_image
from app.tryon.providers import get_provider, TryOnOptions, RemoteProvider, FashnProvider, FashnSpaceProvider
from app.core.config import settings
from app.services import tryon_service as service
from app.tryon import worker, storage

ITEM = "11111111-1111-1111-1111-111111111111"
JOB = "33333333-3333-3333-3333-333333333333"


def jpeg():
    b = BytesIO(); Image.new("RGB", (60, 80), "red").save(b, "JPEG"); return b.getvalue()


def row(**kwargs):
    return {"id": JOB, "user_id": "user-1", "item_ids": [ITEM], "status": "queued",
            "person_path": "user-1/job/person.jpg", "garments": [{"path": "garment.jpg", "category": "dresses"}],
            "options": {"seed": 42, "num_inference_steps": 50, "guidance_scale": 2.5},
            "created_at": "2026-09-23T00:00:00Z", "updated_at": "2026-09-23T00:00:00Z", **kwargs}


@pytest.mark.parametrize("ids", ['{}', 'null', '"bad"', '[]', '[1]', '["bad"]', f'["{ITEM}","{ITEM}"]'])
def test_bad_selection_rejected_before_service(client, monkeypatch, ids):
    create = AsyncMock(); monkeypatch.setattr(service.tryon_service, "create_tryon", create)
    r = client.post("/tryon/", data={"item_ids": ids}, files={"person_image": ("p.jpg", jpeg(), "image/jpeg")})
    assert r.status_code == 422
    create.assert_not_called()


def test_submit_returns_202_queued_without_inference(client, monkeypatch):
    create = AsyncMock(return_value=row()); monkeypatch.setattr(service.tryon_service, "create_tryon", create)
    r = client.post("/tryon/", data={"item_ids": f'["{ITEM}"]'}, files={"person_image": ("p.jpg", jpeg(), "image/jpeg")})
    assert r.status_code == 202 and r.json()["status"] == "queued"
    assert create.call_args.kwargs["seed"] == 42


def test_get_scopes_to_authenticated_owner(client, monkeypatch):
    fetch = AsyncMock(return_value=row()); monkeypatch.setattr(service.tryon_service, "get_tryon", fetch)
    assert client.get(f"/tryon/{JOB}").status_code == 200
    fetch.assert_awaited_once_with("user-1", JOB)


def test_provider_fail_closed(monkeypatch):
    monkeypatch.setattr(settings, "TRYON_NONCOMMERCIAL_ACK", True)
    monkeypatch.setattr(settings, "TRYON_PROVIDER", "disabled")
    with pytest.raises(ValueError): get_provider()
    monkeypatch.setattr(settings, "ENV", "production")
    with pytest.raises(ValueError, match="development-only"): get_provider("kaggle")
    with pytest.raises(ValueError): RemoteProvider("http://example.com", "s" * 32, 30)
    with pytest.raises(ValueError): RemoteProvider("https://example.com", "", 30)


def test_image_decode_and_aspect():
    assert Image.open(BytesIO(normalize_image(jpeg()))).size == (60, 80)
    with pytest.raises(ValueError): normalize_image(b"not an image")
    with pytest.raises(ValueError): normalize_image(b"x" * (10 * 1024 * 1024 + 1))


def test_garment_regions_and_order():
    assert service.validate_selection([{"id": "d", "category": "dresses"}])[0]["id"] == "d"
    result = service.validate_selection([{"id": "t", "category": "tops"}, {"id": "b", "category": "bottoms"}])
    assert [g["id"] for g in result] == ["b", "t"]
    for categories in [[], ["footwear"], ["dresses", "tops"], ["tops", "outerwear"]]:
        with pytest.raises(ValueError): service.validate_selection([{"id": str(i), "category": c} for i,c in enumerate(categories)])


def test_cache_changes_with_image_options_model(monkeypatch):
    garments = [({"id": ITEM, "category": "dresses"}, b"cloth")]
    a = service.cache_key(b"photo", garments, {"seed": 42})
    assert a == service.cache_key(b"photo", garments, {"seed": 42})
    assert a != service.cache_key(b"new photo", garments, {"seed": 42})
    assert a != service.cache_key(b"photo", garments, {"seed": 43})
    monkeypatch.setattr(settings, "TRYON_MODEL_VERSION", "another")
    assert a != service.cache_key(b"photo", garments, {"seed": 42})


@pytest.mark.asyncio
async def test_garment_download_rejects_ssrf_and_other_owner():
    for url in ["http://127.0.0.1/secret", "https://example.com/private", settings.SUPABASE_URL + "/storage/v1/object/public/clothing-items/other/x.jpg"]:
        with pytest.raises(ValueError): await storage.garment_bytes(url, "user-1")


@pytest.mark.asyncio
async def test_consumer_success_and_provider_failure(monkeypatch):
    query = Mock(); query.update.return_value = query; query.eq.return_value = query; query.is_.return_value = query
    db = Mock(); db.table.return_value = query
    monkeypatch.setattr(worker.db, "get_client", lambda: db)
    monkeypatch.setattr(storage, "download", AsyncMock(return_value=jpeg()))
    upload = AsyncMock(); monkeypatch.setattr(storage, "upload", upload)
    monkeypatch.setattr(worker, "execute", AsyncMock(return_value=SimpleNamespace(data=[row()])))
    provider = SimpleNamespace(generate=AsyncMock(return_value=jpeg()))
    await worker.process(row(), provider)
    assert query.update.call_args.args[0]["status"] == "completed"
    assert provider.generate.call_args.args[2].category == "dresses"
    upload.reset_mock()
    provider.generate.side_effect = TimeoutError()
    await worker.process(row(), provider)
    assert query.update.call_args.args[0]["status"] == "failed"
    upload.assert_not_called()  # No silent compositor fallback.


@pytest.mark.asyncio
async def test_partial_ownership_mismatch_prevents_upload(monkeypatch):
    query = Mock(); query.select.return_value = query; query.eq.return_value = query; query.in_.return_value = query
    db = Mock(); db.table.return_value = query
    monkeypatch.setattr(service.db, "get_client", lambda: db)
    monkeypatch.setattr(service, "get_provider", Mock())
    monkeypatch.setattr(service, "execute", AsyncMock(return_value=SimpleNamespace(data=[])))
    upload = AsyncMock(); monkeypatch.setattr(storage, "upload", upload)
    from fastapi import HTTPException
    with pytest.raises(HTTPException) as exc:
        await service.tryon_service.create_tryon("user-1", jpeg(), [ITEM])
    assert exc.value.status_code == 404
    upload.assert_not_called()


@pytest.mark.asyncio
async def test_admission_reuses_cached_job_and_erases_duplicate_uploads(monkeypatch):
    garment = {"id": ITEM, "category": "dresses", "image_url": "unused"}
    query = Mock(); query.select.return_value = query; query.eq.return_value = query; query.in_.return_value = query
    client = Mock(); client.table.return_value = query
    monkeypatch.setattr(service.db, "get_client", lambda: client)
    monkeypatch.setattr(service, "get_provider", Mock())
    monkeypatch.setattr(service, "execute", AsyncMock(side_effect=[SimpleNamespace(data=[garment]), SimpleNamespace(data=[row(status="completed")])]))
    monkeypatch.setattr(storage, "garment_bytes", AsyncMock(return_value=jpeg()))
    monkeypatch.setattr(storage, "upload", AsyncMock())
    monkeypatch.setattr(storage, "signed_url", AsyncMock(return_value="https://signed.example/photo"))
    remove = AsyncMock(); monkeypatch.setattr(storage, "remove", remove)
    result = await service.tryon_service.create_tryon("user-1", jpeg(), [ITEM])
    assert result.id == JOB and result.status == "completed"
    assert len(remove.call_args.args[0]) == 2
    assert client.rpc.call_args.args[0] == "enqueue_tryon"


@pytest.mark.asyncio
async def test_provider_multipart_contract(monkeypatch):
    import httpx
    original = httpx.AsyncClient
    def handle(request):
        assert request.url == "https://worker.example/generate"
        assert request.headers["X-Shared-Secret"] == "s" * 32
        assert b'name="category"' in request.content and b'dresses' in request.content
        assert b'name="seed"' in request.content
        return httpx.Response(200, content=jpeg(), headers={"content-type": "image/jpeg"})
    monkeypatch.setattr(httpx, "AsyncClient", lambda **kw: original(transport=httpx.MockTransport(handle), **kw))
    provider = RemoteProvider("https://worker.example", "s" * 32, 30)
    assert Image.open(BytesIO(await provider.generate(jpeg(), jpeg(), TryOnOptions("dresses")))).size == (60,80)


def test_fashn_needs_key_not_noncommercial_ack(monkeypatch):
    monkeypatch.setattr(settings, "TRYON_NONCOMMERCIAL_ACK", False)
    monkeypatch.setattr(settings, "FASHN_API_KEY", "")
    with pytest.raises(ValueError, match="FASHN_API_KEY"): get_provider("fashn")
    monkeypatch.setattr(settings, "FASHN_API_KEY", "key")
    assert isinstance(get_provider("fashn"), FashnProvider)


@pytest.mark.asyncio
async def test_fashn_submit_poll_contract(monkeypatch):
    import base64, json, httpx
    original = httpx.AsyncClient
    polls = []
    def handle(request):
        assert request.headers["Authorization"] == "Bearer key"
        if request.url.path == "/v1/run":
            body = json.loads(request.content)
            assert body["inputs"]["category"] == "one-pieces" and body["inputs"]["return_base64"] is True
            assert body["inputs"]["model_image"].startswith("data:image/jpeg;base64,")
            return httpx.Response(200, json={"id": "abc", "error": None})
        assert request.url.path == "/v1/status/abc"
        polls.append(1)
        if len(polls) == 1:
            return httpx.Response(200, json={"id": "abc", "status": "processing", "error": None})
        out = "data:image/jpeg;base64," + base64.b64encode(jpeg()).decode()
        return httpx.Response(200, json={"id": "abc", "status": "completed", "output": [out], "error": None})
    monkeypatch.setattr(httpx, "AsyncClient", lambda **kw: original(transport=httpx.MockTransport(handle), **kw))
    monkeypatch.setattr(FashnProvider, "POLL_SECONDS", 0)
    image = await FashnProvider("key", 30).generate(jpeg(), jpeg(), TryOnOptions("dresses"))
    assert Image.open(BytesIO(image)).size == (60, 80) and len(polls) == 2


@pytest.mark.asyncio
async def test_fashn_failure_surfaces_error(monkeypatch):
    import httpx
    original = httpx.AsyncClient
    def handle(request):
        if request.url.path == "/v1/run":
            return httpx.Response(200, json={"id": "abc", "error": None})
        return httpx.Response(200, json={"id": "abc", "status": "failed",
                                         "error": {"name": "PoseError", "message": "no pose"}})
    monkeypatch.setattr(httpx, "AsyncClient", lambda **kw: original(transport=httpx.MockTransport(handle), **kw))
    with pytest.raises(RuntimeError, match="PoseError"):
        await FashnProvider("key", 30).generate(jpeg(), jpeg(), TryOnOptions("tops"))


def test_fashn_space_is_dev_only(monkeypatch):
    monkeypatch.setattr(settings, "ENV", "development")
    assert isinstance(get_provider("fashn_space"), FashnSpaceProvider)
    monkeypatch.setattr(settings, "ENV", "production")
    with pytest.raises(ValueError, match="testing only"): get_provider("fashn_space")


@pytest.mark.asyncio
async def test_fashn_space_maps_category_and_normalizes(monkeypatch, tmp_path):
    out = tmp_path / "out.jpg"; out.write_bytes(jpeg())
    seen = {}
    def run(self, person_path, garment_path, options):
        seen["category"] = self.CATEGORIES[options.category]
        return out.read_bytes()
    monkeypatch.setattr(FashnSpaceProvider, "_run", run)
    image = await FashnSpaceProvider("x/y", 30).generate(jpeg(), jpeg(), TryOnOptions("dresses"))
    assert seen["category"] == "one-pieces" and Image.open(BytesIO(image)).size == (60, 80)
    with pytest.raises(ValueError):
        await FashnSpaceProvider("x/y", 30).generate(jpeg(), jpeg(), TryOnOptions("shoes"))
