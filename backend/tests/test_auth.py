from datetime import datetime, timezone

from app.api.dependencies import get_current_user
from app.main import app
from app.models.user import User
from app.services import unified_auth_service as auth_module

TEST_USER_ID = "00000000-0000-0000-0000-000000000001"


def test_get_me_returns_current_user(client):
    response = client.get("/api/v1/auth/me", headers={"Authorization": "Bearer test-token"})
    assert response.status_code == 200
    body = response.json()
    assert body["user_id"] == TEST_USER_ID
    assert body["email"] == "stylist@example.com"
    assert body["onboarding_complete"] is False


def test_get_me_without_authorization_header_is_rejected(client):
    app.dependency_overrides.pop(get_current_user, None)
    response = client.get("/api/v1/auth/me")
    assert response.status_code in (401, 403)


def test_put_me_updates_and_returns_profile(client, monkeypatch):
    async def fake_update_profile(user_id, updates):
        assert user_id == TEST_USER_ID
        assert updates["display_name"] == "Nova"
        assert updates["style_preferences"] == ["minimal", "tailored"]
        now = datetime.now(timezone.utc)
        return User(
            user_id=user_id,
            email="stylist@example.com",
            display_name="Nova",
            style_preferences=["minimal", "tailored"],
            favorite_colors=[],
            sizes={},
            onboarding_complete=True,
            created_at=now,
            updated_at=now,
        )

    monkeypatch.setattr(auth_module.auth_service, "update_profile", fake_update_profile)

    response = client.put(
        "/api/v1/auth/me",
        json={"display_name": "Nova", "style_preferences": ["minimal", "tailored"], "onboarding_complete": True},
        headers={"Authorization": "Bearer test-token"},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["display_name"] == "Nova"
    assert body["onboarding_complete"] is True


def test_legacy_register_and_login_routes_are_gone(client):
    assert client.post("/api/v1/auth/register", json={}).status_code == 404
    assert client.post("/api/v1/auth/login", data={}).status_code == 404
