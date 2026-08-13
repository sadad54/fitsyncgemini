from datetime import datetime, timezone
from io import BytesIO

from fastapi import HTTPException, status

from app.models.clothing import ClothingItem
from app.services import clothing_service as clothing_module

TEST_USER_ID = "00000000-0000-0000-0000-000000000001"


def _sample_item(**overrides):
    now = datetime.now(timezone.utc)
    base = dict(
        id="11111111-1111-1111-1111-111111111111",
        user_id=TEST_USER_ID,
        name="Blue linen shirt",
        image_url="https://example.com/image.jpg",
        category="tops",
        subcategory="casual",
        colors=["blue"],
        tags=["linen"],
        seasons=[],
        occasions=[],
        brand=None,
        notes=None,
        analysis={},
        created_at=now,
        updated_at=now,
    )
    base.update(overrides)
    return ClothingItem(**base)


def test_create_clothing_item_returns_created_item(client, monkeypatch):
    async def fake_create(**kwargs):
        assert kwargs["user_id"] == TEST_USER_ID
        assert kwargs["name"] == "Blue linen shirt"
        return _sample_item()

    monkeypatch.setattr(clothing_module.clothing_service, "create_clothing_item", fake_create)

    response = client.post(
        "/api/v1/clothing/",
        data={"name": "Blue linen shirt"},
        files={"image": ("shirt.jpg", BytesIO(b"fake-image-bytes"), "image/jpeg")},
        headers={"Authorization": "Bearer test-token"},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["name"] == "Blue linen shirt"
    assert body["category"] == "tops"


def test_list_clothing_items_returns_items_and_total(client, monkeypatch):
    async def fake_list(user_id, category=None, search=None):
        assert user_id == TEST_USER_ID
        return [_sample_item()], 1

    monkeypatch.setattr(clothing_module.clothing_service, "list_clothing_items", fake_list)

    response = client.get("/api/v1/clothing/", headers={"Authorization": "Bearer test-token"})
    assert response.status_code == 200
    body = response.json()
    assert body["total"] == 1
    assert body["items"][0]["name"] == "Blue linen shirt"


def test_get_clothing_stats_is_not_shadowed_by_the_item_id_route(client, monkeypatch):
    async def fake_stats(user_id):
        assert user_id == TEST_USER_ID
        return {"total_items": 3, "by_category": {"tops": 2, "bottoms": 1}, "missing_essentials": ["footwear", "outerwear"]}

    async def poisoned_get_item(user_id, item_id):
        raise AssertionError(f"GET /stats was routed to get_clothing_item with item_id={item_id!r} instead")

    monkeypatch.setattr(clothing_module.clothing_service, "get_stats", fake_stats)
    monkeypatch.setattr(clothing_module.clothing_service, "get_clothing_item", poisoned_get_item)

    response = client.get("/api/v1/clothing/stats", headers={"Authorization": "Bearer test-token"})
    assert response.status_code == 200
    body = response.json()
    assert body["total_items"] == 3
    assert "footwear" in body["missing_essentials"]


def test_get_clothing_item_not_found_returns_404(client, monkeypatch):
    async def fake_get(user_id, item_id):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Clothing item not found")

    monkeypatch.setattr(clothing_module.clothing_service, "get_clothing_item", fake_get)

    response = client.get("/api/v1/clothing/does-not-exist", headers={"Authorization": "Bearer test-token"})
    assert response.status_code == 404


def test_update_clothing_item_returns_updated_item(client, monkeypatch):
    async def fake_update(user_id, item_id, updates):
        assert updates["name"] == "Updated name"
        return _sample_item(name="Updated name")

    monkeypatch.setattr(clothing_module.clothing_service, "update_clothing_item", fake_update)

    response = client.put(
        "/api/v1/clothing/11111111-1111-1111-1111-111111111111",
        json={"name": "Updated name"},
        headers={"Authorization": "Bearer test-token"},
    )
    assert response.status_code == 200
    assert response.json()["name"] == "Updated name"


def test_delete_clothing_item_returns_deleted_true(client, monkeypatch):
    async def fake_delete(user_id, item_id):
        return None

    monkeypatch.setattr(clothing_module.clothing_service, "delete_clothing_item", fake_delete)

    response = client.delete(
        "/api/v1/clothing/11111111-1111-1111-1111-111111111111",
        headers={"Authorization": "Bearer test-token"},
    )
    assert response.status_code == 200
    assert response.json() == {"deleted": True}


def test_legacy_analyze_and_recommendations_routes_are_gone(client):
    assert client.get("/api/v1/clothing/analyze/compatibility", headers={"Authorization": "Bearer test-token"}).status_code == 404
    assert client.get("/api/v1/clothing/recommendations/smart", headers={"Authorization": "Bearer test-token"}).status_code == 404
