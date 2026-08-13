import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from datetime import datetime, timezone

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.api.dependencies import get_current_user
from app.models.user import User

TEST_USER_ID = "00000000-0000-0000-0000-000000000001"


def _fake_user() -> User:
    now = datetime.now(timezone.utc)
    return User(
        user_id=TEST_USER_ID,
        email="stylist@example.com",
        display_name="Stylist",
        style_preferences=[],
        favorite_colors=[],
        sizes={},
        onboarding_complete=False,
        created_at=now,
        updated_at=now,
    )


@pytest.fixture
def client():
    app.dependency_overrides[get_current_user] = _fake_user
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()
