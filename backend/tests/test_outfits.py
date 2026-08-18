from datetime import datetime, timezone

from fastapi import HTTPException, status

from app.models.outfit import Outfit
from app.services import outfit_service as outfit_module

TEST_USER_ID = "00000000-0000-0000-0000-000000000001"


def _sample_outfit(**overrides):
    now = datetime.now(timezone.utc)
    base = dict(
        id="22222222-2222-2222-2222-222222222222",
        user_id=TEST_USER_ID,
        name="Everyday Edit",
        item_ids=["11111111-1111-1111-1111-111111111111"],
        occasion="casual",
        weather_context=None,
        score=0.75,
        explanation="A straightforward pairing for casual.",
        saved=False,
        favorited=False,
        created_at=now,
        updated_at=now,
    )
    base.update(overrides)
    return Outfit(**base)


def test_generate_outfit_returns_created_outfit(client, monkeypatch):
    async def fake_generate(user_id, occasion, use_weather=False, latitude=None, longitude=None):
        assert user_id == TEST_USER_ID
        assert occasion == "casual"
        assert use_weather is False
        return _sample_outfit()

    monkeypatch.setattr(outfit_module.outfit_service, "generate_outfit", fake_generate)

    response = client.post(
        "/api/v1/outfits/generate",
        json={"occasion": "casual"},
        headers={"Authorization": "Bearer test-token"},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["name"] == "Everyday Edit"
    assert body["item_ids"] == ["11111111-1111-1111-1111-111111111111"]
    assert body["saved"] is False


def test_generate_outfit_passes_weather_coordinates(client, monkeypatch):
    async def fake_generate(user_id, occasion, use_weather=False, latitude=None, longitude=None):
        assert use_weather is True
        assert latitude == 40.7
        assert longitude == -74.0
        return _sample_outfit(weather_context={"temperature": 18})

    monkeypatch.setattr(outfit_module.outfit_service, "generate_outfit", fake_generate)

    response = client.post(
        "/api/v1/outfits/generate",
        json={"occasion": "dinner", "use_weather": True, "latitude": 40.7, "longitude": -74.0},
        headers={"Authorization": "Bearer test-token"},
    )
    assert response.status_code == 200
    assert response.json()["weather_context"]["temperature"] == 18


def test_list_outfits_returns_outfits_and_total(client, monkeypatch):
    async def fake_list(user_id, saved_only=False):
        assert user_id == TEST_USER_ID
        assert saved_only is True
        return [_sample_outfit(saved=True)], 1

    monkeypatch.setattr(outfit_module.outfit_service, "list_outfits", fake_list)

    response = client.get(
        "/api/v1/outfits/?saved_only=true",
        headers={"Authorization": "Bearer test-token"},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["total"] == 1
    assert body["outfits"][0]["saved"] is True


def test_save_outfit_returns_saved_outfit(client, monkeypatch):
    async def fake_save(user_id, outfit_id):
        assert user_id == TEST_USER_ID
        assert outfit_id == "22222222-2222-2222-2222-222222222222"
        return _sample_outfit(saved=True)

    monkeypatch.setattr(outfit_module.outfit_service, "save_outfit", fake_save)

    response = client.post(
        "/api/v1/outfits/22222222-2222-2222-2222-222222222222/save",
        headers={"Authorization": "Bearer test-token"},
    )
    assert response.status_code == 200
    assert response.json()["saved"] is True


def test_favorite_outfit_returns_favorited_outfit(client, monkeypatch):
    async def fake_favorite(user_id, outfit_id):
        return _sample_outfit(favorited=True)

    monkeypatch.setattr(outfit_module.outfit_service, "favorite_outfit", fake_favorite)

    response = client.post(
        "/api/v1/outfits/22222222-2222-2222-2222-222222222222/favorite",
        headers={"Authorization": "Bearer test-token"},
    )
    assert response.status_code == 200
    assert response.json()["favorited"] is True


def test_feedback_outfit_returns_recorded_true(client, monkeypatch):
    async def fake_feedback(user_id, outfit_id, rating, reason=None):
        assert rating == 4
        assert reason is None
        return None

    monkeypatch.setattr(outfit_module.outfit_service, "record_feedback", fake_feedback)

    response = client.post(
        "/api/v1/outfits/22222222-2222-2222-2222-222222222222/feedback",
        json={"rating": 4},
        headers={"Authorization": "Bearer test-token"},
    )
    assert response.status_code == 200
    assert response.json() == {"recorded": True}


def test_save_outfit_not_found_returns_404(client, monkeypatch):
    async def fake_save(user_id, outfit_id):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Outfit not found")

    monkeypatch.setattr(outfit_module.outfit_service, "save_outfit", fake_save)

    response = client.post(
        "/api/v1/outfits/does-not-exist/save",
        headers={"Authorization": "Bearer test-token"},
    )
    assert response.status_code == 404
