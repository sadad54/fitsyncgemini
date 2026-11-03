import math
import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from fastapi import HTTPException, status

from app.core.database import db

MEMBER_NAME = "Flairwise member"


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _client():
    return db.get_client()


def _author_lookup(user_ids: List[str]) -> Dict[str, Dict[str, Any]]:
    if not user_ids:
        return {}
    result = (
        _client()
        .table("user_profiles")
        .select("user_id, display_name, style_preferences")
        .in_("user_id", list(set(user_ids)))
        .execute()
    )
    return {row["user_id"]: row for row in (result.data or [])}


def _followed_ids(viewer_id: Optional[str]) -> set:
    if not viewer_id:
        return set()
    rows = _client().table("user_follows").select("followed_id").eq("follower_id", viewer_id).execute().data or []
    return {row["followed_id"] for row in rows}


def _count(table: str, column: str, value: Any) -> int:
    result = _client().table(table).select("id", count="exact").eq(column, value).execute()
    return result.count if result.count is not None else len(result.data or [])


def _to_post(row: Dict[str, Any], authors: Dict[str, Dict[str, Any]], liked_ids: set, followed: set) -> Dict[str, Any]:
    author = authors.get(row["user_id"], {})
    return {
        "id": row["id"],
        "user_id": row["user_id"],
        "author_name": author.get("display_name") or MEMBER_NAME,
        "content": row.get("caption") or "",
        "image_url": row.get("image_url"),
        "tags": row.get("tags") or [],
        "challenge_id": row.get("challenge_id"),
        "likes_count": row.get("likes_count", 0),
        "comments_count": row.get("comments_count", 0),
        "liked": row["id"] in liked_ids,
        "following": row["user_id"] in followed,
        "created_at": row["created_at"],
    }


def _days_left(end_date: Optional[str]) -> Optional[int]:
    if not end_date:
        return None
    try:
        end = datetime.fromisoformat(str(end_date).replace("Z", "+00:00"))
    except ValueError:
        return None
    if end.tzinfo is None:
        end = end.replace(tzinfo=timezone.utc)
    return max(0, math.ceil((end - datetime.now(timezone.utc)).total_seconds() / 86400))


class CommunityService:
    # ---- posts -------------------------------------------------------------

    def _decorate(self, posts: List[Dict[str, Any]], viewer_id: Optional[str]) -> List[Dict[str, Any]]:
        authors = _author_lookup([p["user_id"] for p in posts])
        liked_ids: set = set()
        if viewer_id and posts:
            rows = (
                _client()
                .table("post_likes")
                .select("post_id")
                .eq("user_id", viewer_id)
                .in_("post_id", [p["id"] for p in posts])
                .execute()
                .data
                or []
            )
            liked_ids = {row["post_id"] for row in rows}
        followed = _followed_ids(viewer_id)
        return [_to_post(p, authors, liked_ids, followed) for p in posts]

    async def list_posts(
        self,
        viewer_id: Optional[str],
        limit: int = 20,
        offset: int = 0,
        feed: str = "discover",
        author_id: Optional[str] = None,
        challenge_id: Optional[str] = None,
    ) -> List[Dict[str, Any]]:
        query = _client().table("community_posts").select("*")
        if feed == "following":
            followed = _followed_ids(viewer_id)
            if not followed:
                return []
            query = query.in_("user_id", list(followed))
        if author_id:
            query = query.eq("user_id", author_id)
        if challenge_id:
            query = query.eq("challenge_id", challenge_id)
        posts = query.order("created_at", desc=True).range(offset, offset + limit - 1).execute().data or []
        return self._decorate(posts, viewer_id)

    async def get_post(self, viewer_id: Optional[str], post_id: str) -> Dict[str, Any]:
        rows = _client().table("community_posts").select("*").eq("id", post_id).execute().data or []
        if not rows:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "Post not found")
        return self._decorate(rows, viewer_id)[0]

    async def create_post(
        self, user_id: str, content: str, image_url: Optional[str], tags: List[str], challenge_id: Optional[str] = None
    ) -> Dict[str, Any]:
        if not content.strip() and not image_url:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "Post needs a caption or an image")
        if challenge_id and not _client().table("style_challenges").select("id").eq("id", challenge_id).execute().data:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "Challenge not found")

        payload = {
            "id": str(uuid.uuid4()),
            "user_id": user_id,
            "caption": content.strip(),
            "image_url": image_url,
            "tags": [t.strip() for t in tags if t.strip()][:5],
            "challenge_id": challenge_id,
            "likes_count": 0,
            "comments_count": 0,
            "created_at": _now(),
        }
        result = _client().table("community_posts").insert(payload).execute()
        if not result.data:
            raise HTTPException(status.HTTP_500_INTERNAL_SERVER_ERROR, "Failed to create post")
        return self._decorate(result.data, user_id)[0]

    async def delete_post(self, user_id: str, post_id: str) -> None:
        existing = _client().table("community_posts").select("user_id").eq("id", post_id).execute()
        if not existing.data:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "Post not found")
        if existing.data[0]["user_id"] != user_id:
            raise HTTPException(status.HTTP_403_FORBIDDEN, "You can only delete your own posts")
        _client().table("community_posts").delete().eq("id", post_id).execute()

    def _require_post(self, post_id: str) -> None:
        if not _client().table("community_posts").select("id").eq("id", post_id).execute().data:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "Post not found")

    def _sync_likes(self, post_id: str) -> int:
        # Recount instead of incrementing, so retries and double taps can never drift the total.
        likes = _count("post_likes", "post_id", post_id)
        _client().table("community_posts").update({"likes_count": likes}).eq("id", post_id).execute()
        return likes

    async def like_post(self, user_id: str, post_id: str) -> Dict[str, Any]:
        self._require_post(post_id)
        existing = _client().table("post_likes").select("id").eq("post_id", post_id).eq("user_id", user_id).execute()
        if not existing.data:
            try:
                _client().table("post_likes").insert(
                    {"id": str(uuid.uuid4()), "post_id": post_id, "user_id": user_id}
                ).execute()
            except Exception:
                pass  # a concurrent like won the unique (post_id, user_id) race; the recount below is still right
        return {"liked": True, "likes_count": self._sync_likes(post_id)}

    async def unlike_post(self, user_id: str, post_id: str) -> Dict[str, Any]:
        self._require_post(post_id)
        _client().table("post_likes").delete().eq("post_id", post_id).eq("user_id", user_id).execute()
        return {"liked": False, "likes_count": self._sync_likes(post_id)}

    # ---- comments ----------------------------------------------------------

    async def list_comments(self, post_id: str) -> List[Dict[str, Any]]:
        comments = (
            _client().table("comments").select("*").eq("post_id", post_id).order("created_at", desc=False).execute().data
            or []
        )
        authors = _author_lookup([c["user_id"] for c in comments])
        return [self._to_comment(c, authors) for c in comments]

    @staticmethod
    def _to_comment(row: Dict[str, Any], authors: Dict[str, Dict[str, Any]]) -> Dict[str, Any]:
        return {
            "id": row["id"],
            "post_id": row["post_id"],
            "user_id": row["user_id"],
            "author_name": authors.get(row["user_id"], {}).get("display_name") or MEMBER_NAME,
            "content": row.get("content") or "",
            "created_at": row["created_at"],
        }

    async def create_comment(self, user_id: str, post_id: str, content: str) -> Dict[str, Any]:
        if not content.strip():
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "Comment cannot be empty")
        self._require_post(post_id)
        payload = {
            "id": str(uuid.uuid4()),
            "post_id": post_id,
            "user_id": user_id,
            "content": content.strip()[:1000],
            "created_at": _now(),
        }
        result = _client().table("comments").insert(payload).execute()
        if not result.data:
            raise HTTPException(status.HTTP_500_INTERNAL_SERVER_ERROR, "Failed to add comment")
        comments = _count("comments", "post_id", post_id)
        _client().table("community_posts").update({"comments_count": comments}).eq("id", post_id).execute()
        return self._to_comment(result.data[0], _author_lookup([user_id]))

    # ---- members -----------------------------------------------------------

    async def get_member(self, viewer_id: Optional[str], user_id: str) -> Dict[str, Any]:
        profile = _author_lookup([user_id]).get(user_id)
        posts = await self.list_posts(viewer_id, limit=12, author_id=user_id)
        if not profile and not posts:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "Member not found")
        return {
            "user_id": user_id,
            "name": (profile or {}).get("display_name") or MEMBER_NAME,
            "style_tags": ((profile or {}).get("style_preferences") or [])[:4],
            "posts_count": _count("community_posts", "user_id", user_id),
            "followers_count": _count("user_follows", "followed_id", user_id),
            "challenges_count": _count("challenge_participants", "user_id", user_id),
            "following": user_id in _followed_ids(viewer_id),
            "is_self": viewer_id == user_id,
            "posts": posts,
        }

    async def follow_user(self, follower_id: str, followed_id: str) -> Dict[str, Any]:
        if follower_id == followed_id:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "Cannot follow yourself")
        existing = (
            _client()
            .table("user_follows")
            .select("id")
            .eq("follower_id", follower_id)
            .eq("followed_id", followed_id)
            .execute()
        )
        if not existing.data:
            _client().table("user_follows").insert(
                {"id": str(uuid.uuid4()), "follower_id": follower_id, "followed_id": followed_id}
            ).execute()
        return {"following": True, "followers_count": _count("user_follows", "followed_id", followed_id)}

    async def unfollow_user(self, follower_id: str, followed_id: str) -> Dict[str, Any]:
        _client().table("user_follows").delete().eq("follower_id", follower_id).eq("followed_id", followed_id).execute()
        return {"following": False, "followers_count": _count("user_follows", "followed_id", followed_id)}

    # ---- challenges --------------------------------------------------------

    def _to_challenge(self, row: Dict[str, Any], joined_ids: set) -> Dict[str, Any]:
        return {
            "id": row["id"],
            "title": row.get("title") or "Challenge",
            "description": row.get("description") or "",
            "reward": row.get("reward") or "",
            "difficulty": (row.get("difficulty_level") or "medium").lower(),
            "category": row.get("category"),
            "color": row.get("color"),
            "image_url": row.get("image_url"),
            "participants_count": row.get("participants_count") or 0,
            "days_left": _days_left(row.get("end_date")),
            "joined": row["id"] in joined_ids,
        }

    def _joined(self, viewer_id: Optional[str], ids: List[str]) -> set:
        if not viewer_id or not ids:
            return set()
        rows = (
            _client()
            .table("challenge_participants")
            .select("challenge_id")
            .eq("user_id", viewer_id)
            .in_("challenge_id", ids)
            .execute()
            .data
            or []
        )
        return {row["challenge_id"] for row in rows}

    async def list_challenges(self, viewer_id: Optional[str]) -> List[Dict[str, Any]]:
        challenges = _client().table("style_challenges").select("*").order("created_at", desc=True).execute().data or []
        challenges = [c for c in challenges if c.get("active", True)]
        joined = self._joined(viewer_id, [c["id"] for c in challenges])
        return [self._to_challenge(c, joined) for c in challenges]

    async def get_challenge(self, viewer_id: Optional[str], challenge_id: str) -> Dict[str, Any]:
        rows = _client().table("style_challenges").select("*").eq("id", challenge_id).execute().data or []
        if not rows:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "Challenge not found")
        challenge = self._to_challenge(rows[0], self._joined(viewer_id, [challenge_id]))
        challenge["entries"] = await self.list_posts(viewer_id, limit=20, challenge_id=challenge_id)
        participants = (
            _client().table("challenge_participants").select("user_id").eq("challenge_id", challenge_id).limit(5).execute().data
            or []
        )
        names = _author_lookup([p["user_id"] for p in participants])
        challenge["recent_participants"] = [
            (names.get(p["user_id"], {}).get("display_name") or MEMBER_NAME) for p in participants
        ]
        return challenge

    def _sync_participants(self, challenge_id: str) -> int:
        total = _count("challenge_participants", "challenge_id", challenge_id)
        _client().table("style_challenges").update({"participants_count": total}).eq("id", challenge_id).execute()
        return total

    async def join_challenge(self, user_id: str, challenge_id: str) -> Dict[str, Any]:
        if not _client().table("style_challenges").select("id").eq("id", challenge_id).execute().data:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "Challenge not found")
        existing = (
            _client()
            .table("challenge_participants")
            .select("id")
            .eq("challenge_id", challenge_id)
            .eq("user_id", user_id)
            .execute()
        )
        if not existing.data:
            _client().table("challenge_participants").insert(
                {"id": str(uuid.uuid4()), "challenge_id": challenge_id, "user_id": user_id}
            ).execute()
        return {"joined": True, "participants_count": self._sync_participants(challenge_id)}

    async def leave_challenge(self, user_id: str, challenge_id: str) -> Dict[str, Any]:
        _client().table("challenge_participants").delete().eq("challenge_id", challenge_id).eq("user_id", user_id).execute()
        return {"joined": False, "participants_count": self._sync_participants(challenge_id)}


community_service = CommunityService()
