from datetime import datetime, timezone
from io import BytesIO

from fastapi import HTTPException, status

from app.models.tryon import TryOnResult
from app.services import tryon_service as tryon_module

TEST_USER_ID = "00000000-0000-0000-0000-000000000001"


def _sample_result(**overrides):
    now = datetime.now(timezone.utc)
    base = dict(
        id="33333333-3333-3333-3333-333333333333",
        user_id=TEST_USER_ID,
        item_ids=["11111111-1111-1111-1111-111111111111"],
        person_image_url="https://example.com/person.jpg",
        result_image_url="https://example.com/result.jpg",
        status="completed",
        confidence_score=0.65,
        error_message=None,
        created_at=now,
        updated_at=now,
    )
    base.update(overrides)
    return TryOnResult(**base)


def test_create_tryon_returns_result(client, monkeypatch):
    async def fake_create(user_id, person_image_bytes, item_ids):
        assert user_id == TEST_USER_ID
        assert item_ids == ["11111111-1111-1111-1111-111111111111"]
        return _sample_result()

    monkeypatch.setattr(tryon_module.tryon_service, "create_tryon", fake_create)

    response = client.post(
        "/api/v1/tryon/",
        data={"item_ids": '["11111111-1111-1111-1111-111111111111"]'},
        files={"person_image": ("person.jpg", BytesIO(b"fake-image-bytes"), "image/jpeg")},
        headers={"Authorization": "Bearer test-token"},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "completed"
    assert body["result_image_url"] == "https://example.com/result.jpg"


def test_create_tryon_without_items(client, monkeypatch):
    async def fake_create(user_id, person_image_bytes, item_ids):
        assert item_ids == []
        return _sample_result(item_ids=[])

    monkeypatch.setattr(tryon_module.tryon_service, "create_tryon", fake_create)

    response = client.post(
        "/api/v1/tryon/",
        files={"person_image": ("person.jpg", BytesIO(b"fake-image-bytes"), "image/jpeg")},
        headers={"Authorization": "Bearer test-token"},
    )
    assert response.status_code == 200
    assert response.json()["item_ids"] == []


def test_list_tryons_returns_results_and_total(client, monkeypatch):
    async def fake_list(user_id):
        assert user_id == TEST_USER_ID
        return [_sample_result()], 1

    monkeypatch.setattr(tryon_module.tryon_service, "list_tryons", fake_list)

    response = client.get("/api/v1/tryon/", headers={"Authorization": "Bearer test-token"})
    assert response.status_code == 200
    body = response.json()
    assert body["total"] == 1
    assert body["results"][0]["status"] == "completed"


def test_get_tryon_not_found_returns_404(client, monkeypatch):
    async def fake_get(user_id, tryon_id):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Try-on result not found")

    monkeypatch.setattr(tryon_module.tryon_service, "get_tryon", fake_get)

    response = client.get("/api/v1/tryon/does-not-exist", headers={"Authorization": "Bearer test-token"})
    assert response.status_code == 404


def test_delete_tryon_returns_deleted_true(client, monkeypatch):
    async def fake_delete(user_id, tryon_id):
        return None

    monkeypatch.setattr(tryon_module.tryon_service, "delete_tryon", fake_delete)

    response = client.delete(
        "/api/v1/tryon/33333333-3333-3333-3333-333333333333",
        headers={"Authorization": "Bearer test-token"},
    )
    assert response.status_code == 200
    assert response.json() == {"deleted": True}
