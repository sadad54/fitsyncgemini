"""Isolated router tests: no credentials, model loads or external services."""
import sys
from pathlib import Path
from unittest.mock import Mock
import supabase
import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
# Existing auth service constructs its client at import time.
_original = supabase.create_client
supabase.create_client = Mock()
from app.api.dependencies import get_current_user
from app.api.endpoints.v1.tryon import router
supabase.create_client = _original
from types import SimpleNamespace


@pytest.fixture
def client():
    app = FastAPI()
    app.include_router(router, prefix="/tryon")
    app.dependency_overrides[get_current_user] = lambda: SimpleNamespace(user_id="user-1")
    return TestClient(app)
