from datetime import datetime, timedelta, timezone

import pytest

from app.api.dependencies import get_optional_user
from app.main import app
from app.services import community_service as community_module
from tests.conftest import TEST_USER_ID, _fake_user
from tests.fake_supabase import FakeDb, FakeSupabase

AUTH = {"Authorization": "Bearer test-token"}
RINA = "00000000-0000-0000-0000-0000000000aa"
THEO = "00000000-0000-0000-0000-0000000000bb"


def _ts(minutes_ago: int) -> str:
    return (datetime.now(timezone.utc) - timedelta(minutes=minutes_ago)).isoformat()


@pytest.fixture
def store(monkeypatch):
    fake = FakeSupabase(unique={"post_likes": [("post_id", "user_id")]})
    fake.tables = {
        "user_profiles": [
            {"user_id": RINA, "display_name": "Rina Ferrer", "style_preferences": ["Minimal", "Workwear"]},
            {"user_id": THEO, "display_name": "Theo Mbeki", "style_preferences": []},
            {"user_id": TEST_USER_ID, "display_name": "Stylist", "style_preferences": []},
        ],
        "community_posts": [
            {"id": "p-rina", "user_id": RINA, "caption": "Three pieces, one tone.", "tags": ["Monochrome week"],
             "challenge_id": "ch-mono", "likes_count": 0, "comments_count": 0, "created_at": _ts(60)},
            {"id": "p-theo", "user_id": THEO, "caption": "Linen dress, flat boot.", "tags": [],
             "challenge_id": None, "likes_count": 0, "comments_count": 0, "created_at": _ts(10)},
        ],
        "style_challenges": [
            {"id": "ch-mono", "title": "Monochrome week", "description": "One tone.", "reward": "Featured slot",
             "difficulty_level": "Medium", "participants_count": 0, "end_date": (datetime.now(timezone.utc) + timedelta(days=4, hours=1)).isoformat(),
             "active": True, "created_at": _ts(1000)},
            {"id": "ch-old", "title": "Retired", "active": False, "created_at": _ts(2000)},
        ],
        "user_follows": [{"id": "f1", "follower_id": TEST_USER_ID, "followed_id": RINA}],
        "post_likes": [],
        "comments": [],
        "challenge_participants": [],
    }
    monkeypatch.setattr(community_module, "db", FakeDb(fake))
    return fake


@pytest.fixture
def viewer():
    app.dependency_overrides[get_optional_user] = _fake_user
    yield
    app.dependency_overrides.pop(get_optional_user, None)


def test_discover_feed_is_newest_first_with_author_and_follow_flags(client, store, viewer):
    posts = client.get("/api/v1/community/posts", headers=AUTH).json()
    assert [p["id"] for p in posts] == ["p-theo", "p-rina"]
    assert posts[1]["author_name"] == "Rina Ferrer"
    assert posts[1]["following"] is True and posts[0]["following"] is False


def test_following_feed_only_has_followed_authors(client, store, viewer):
    posts = client.get("/api/v1/community/posts?feed=following", headers=AUTH).json()
    assert [p["id"] for p in posts] == ["p-rina"]


def test_following_feed_is_empty_for_anonymous_viewer(client, store):
    assert client.get("/api/v1/community/posts?feed=following").json() == []


def test_rejects_unknown_feed_and_huge_pages(client, store):
    assert client.get("/api/v1/community/posts?feed=everything").status_code == 422
    assert client.get("/api/v1/community/posts?limit=500").status_code == 422


def test_like_is_idempotent_and_counter_matches_rows(client, store, viewer):
    for _ in range(3):
        body = client.post("/api/v1/community/posts/p-rina/like", headers=AUTH).json()
    assert body == {"liked": True, "likes_count": 1}
    assert len(store.tables["post_likes"]) == 1
    post = client.get("/api/v1/community/posts/p-rina", headers=AUTH).json()
    assert post["liked"] is True and post["likes_count"] == 1

    body = client.delete("/api/v1/community/posts/p-rina/like", headers=AUTH).json()
    assert body == {"liked": False, "likes_count": 0}


def test_like_missing_post_is_404(client, store):
    assert client.post("/api/v1/community/posts/nope/like", headers=AUTH).status_code == 404


def test_comment_updates_count_and_lists_in_order(client, store):
    client.post("/api/v1/community/posts/p-theo/comments", json={"content": "  Great boots  "}, headers=AUTH)
    client.post("/api/v1/community/posts/p-theo/comments", json={"content": "Which linen?"}, headers=AUTH)
    comments = client.get("/api/v1/community/posts/p-theo/comments").json()
    assert [c["content"] for c in comments] == ["Great boots", "Which linen?"]
    assert comments[0]["author_name"] == "Stylist"
    assert next(p for p in store.tables["community_posts"] if p["id"] == "p-theo")["comments_count"] == 2


def test_empty_comment_rejected(client, store):
    assert client.post("/api/v1/community/posts/p-theo/comments", json={"content": "   "}, headers=AUTH).status_code == 400


def test_create_post_tagged_to_challenge(client, store):
    resp = client.post("/api/v1/community/posts", json={"content": "Day one", "tags": ["Monochrome week", " "], "challenge_id": "ch-mono"}, headers=AUTH)
    assert resp.status_code == 200
    body = resp.json()
    assert body["tags"] == ["Monochrome week"] and body["challenge_id"] == "ch-mono" and body["author_name"] == "Stylist"


def test_create_post_unknown_challenge_is_404(client, store):
    resp = client.post("/api/v1/community/posts", json={"content": "x", "challenge_id": "missing"}, headers=AUTH)
    assert resp.status_code == 404


def test_only_author_can_delete(client, store):
    assert client.delete("/api/v1/community/posts/p-rina", headers=AUTH).status_code == 403


def test_member_profile_counts_and_follow_toggle(client, store, viewer):
    member = client.get(f"/api/v1/community/users/{THEO}", headers=AUTH).json()
    assert member["name"] == "Theo Mbeki" and member["posts_count"] == 1
    assert member["following"] is False and member["followers_count"] == 0
    assert [p["id"] for p in member["posts"]] == ["p-theo"]

    assert client.post(f"/api/v1/community/users/{THEO}/follow", headers=AUTH).json() == {"following": True, "followers_count": 1}
    assert client.post(f"/api/v1/community/users/{THEO}/follow", headers=AUTH).json()["followers_count"] == 1
    assert client.delete(f"/api/v1/community/users/{THEO}/follow", headers=AUTH).json() == {"following": False, "followers_count": 0}


def test_cannot_follow_self(client, store):
    assert client.post(f"/api/v1/community/users/{TEST_USER_ID}/follow", headers=AUTH).status_code == 400


def test_unknown_member_is_404(client, store):
    assert client.get("/api/v1/community/users/ghost").status_code == 404


def test_challenges_hide_inactive_and_report_days_left(client, store, viewer):
    challenges = client.get("/api/v1/community/challenges", headers=AUTH).json()
    assert [c["id"] for c in challenges] == ["ch-mono"]
    assert challenges[0]["days_left"] == 5 and challenges[0]["difficulty"] == "medium" and challenges[0]["joined"] is False


def test_join_and_leave_challenge_keeps_count_in_sync(client, store, viewer):
    assert client.post("/api/v1/community/challenges/ch-mono/join", headers=AUTH).json() == {"joined": True, "participants_count": 1}
    assert client.post("/api/v1/community/challenges/ch-mono/join", headers=AUTH).json()["participants_count"] == 1
    detail = client.get("/api/v1/community/challenges/ch-mono", headers=AUTH).json()
    assert detail["joined"] is True and detail["recent_participants"] == ["Stylist"]
    assert [e["id"] for e in detail["entries"]] == ["p-rina"]
    assert client.delete("/api/v1/community/challenges/ch-mono/join", headers=AUTH).json() == {"joined": False, "participants_count": 0}


def test_join_unknown_challenge_is_404(client, store):
    assert client.post("/api/v1/community/challenges/nope/join", headers=AUTH).status_code == 404
