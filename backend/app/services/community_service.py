import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from fastapi import HTTPException, status

from app.core.database import db


def _author_lookup(user_ids: List[str]) -> Dict[str, Dict[str, Any]]:
    if not user_ids:
        return {}
    result = (
        db.get_client()
        .table("user_profiles")
        .select("user_id, display_name")
        .in_("user_id", list(set(user_ids)))
        .execute()
    )
    return {row["user_id"]: row for row in (result.data or [])}


def _to_post(row: Dict[str, Any], authors: Dict[str, Dict[str, Any]], liked_ids: set) -> Dict[str, Any]:
    author = authors.get(row["user_id"], {})
    return {
        "id": row["id"],
        "user_id": row["user_id"],
        "author_name": author.get("display_name") or "FitSync member",
        "content": row.get("caption") or "",
        "image_url": row.get("image_url"),
        "tags": row.get("tags") or [],
        "likes_count": row.get("likes_count", 0),
        "comments_count": row.get("comments_count", 0),
        "liked": row["id"] in liked_ids,
        "created_at": row["created_at"],
    }


class CommunityService:
    async def list_posts(self, viewer_id: Optional[str], limit: int = 20, offset: int = 0) -> List[Dict[str, Any]]:
        result = (
            db.get_client()
            .table("community_posts")
            .select("*")
            .order("created_at", desc=True)
            .range(offset, offset + limit - 1)
            .execute()
        )
        posts = result.data or []
        authors = _author_lookup([p["user_id"] for p in posts])

        liked_ids: set = set()
        if viewer_id and posts:
            likes_result = (
                db.get_client()
                .table("post_likes")
                .select("post_id")
                .eq("user_id", viewer_id)
                .in_("post_id", [p["id"] for p in posts])
                .execute()
            )
            liked_ids = {row["post_id"] for row in (likes_result.data or [])}

        return [_to_post(p, authors, liked_ids) for p in posts]

    async def create_post(self, user_id: str, content: str, image_url: Optional[str], tags: List[str]) -> Dict[str, Any]:
        if not content.strip() and not image_url:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "Post needs a caption or an image")

        payload = {
            "id": str(uuid.uuid4()),
            "user_id": user_id,
            "caption": content.strip(),
            "image_url": image_url,
            "tags": tags or [],
            "likes_count": 0,
            "comments_count": 0,
            "created_at": datetime.now(timezone.utc).isoformat(),
        }
        result = db.get_client().table("community_posts").insert(payload).execute()
        if not result.data:
            raise HTTPException(status.HTTP_500_INTERNAL_SERVER_ERROR, "Failed to create post")

        authors = _author_lookup([user_id])
        return _to_post(result.data[0], authors, set())

    async def delete_post(self, user_id: str, post_id: str) -> None:
        existing = db.get_client().table("community_posts").select("user_id").eq("id", post_id).execute()
        if not existing.data:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "Post not found")
        if existing.data[0]["user_id"] != user_id:
            raise HTTPException(status.HTTP_403_FORBIDDEN, "You can only delete your own posts")
        db.get_client().table("community_posts").delete().eq("id", post_id).execute()

    async def like_post(self, user_id: str, post_id: str) -> Dict[str, Any]:
        existing = (
            db.get_client().table("post_likes").select("id").eq("post_id", post_id).eq("user_id", user_id).execute()
        )
        if existing.data:
            return {"liked": True}
        db.get_client().table("post_likes").insert(
            {"id": str(uuid.uuid4()), "post_id": post_id, "user_id": user_id}
        ).execute()
        return {"liked": True}

    async def unlike_post(self, user_id: str, post_id: str) -> Dict[str, Any]:
        db.get_client().table("post_likes").delete().eq("post_id", post_id).eq("user_id", user_id).execute()
        return {"liked": False}

    async def list_comments(self, post_id: str) -> List[Dict[str, Any]]:
        result = (
            db.get_client()
            .table("comments")
            .select("*")
            .eq("post_id", post_id)
            .order("created_at", desc=False)
            .execute()
        )
        comments = result.data or []
        authors = _author_lookup([c["user_id"] for c in comments])
        return [
            {
                "id": c["id"],
                "post_id": c["post_id"],
                "user_id": c["user_id"],
                "author_name": authors.get(c["user_id"], {}).get("display_name") or "FitSync member",
                "content": c.get("content") or "",
                "created_at": c["created_at"],
            }
            for c in comments
        ]

    async def create_comment(self, user_id: str, post_id: str, content: str) -> Dict[str, Any]:
        if not content.strip():
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "Comment cannot be empty")
        payload = {
            "id": str(uuid.uuid4()),
            "post_id": post_id,
            "user_id": user_id,
            "content": content.strip(),
            "created_at": datetime.now(timezone.utc).isoformat(),
        }
        result = db.get_client().table("comments").insert(payload).execute()
        if not result.data:
            raise HTTPException(status.HTTP_500_INTERNAL_SERVER_ERROR, "Failed to add comment")
        authors = _author_lookup([user_id])
        row = result.data[0]
        return {
            "id": row["id"],
            "post_id": row["post_id"],
            "user_id": row["user_id"],
            "author_name": authors.get(user_id, {}).get("display_name") or "FitSync member",
            "content": row["content"],
            "created_at": row["created_at"],
        }

    async def follow_user(self, follower_id: str, followed_id: str) -> Dict[str, Any]:
        if follower_id == followed_id:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "Cannot follow yourself")
        existing = (
            db.get_client()
            .table("user_follows")
            .select("id")
            .eq("follower_id", follower_id)
            .eq("followed_id", followed_id)
            .execute()
        )
        if not existing.data:
            db.get_client().table("user_follows").insert(
                {"id": str(uuid.uuid4()), "follower_id": follower_id, "followed_id": followed_id}
            ).execute()
        return {"following": True}

    async def unfollow_user(self, follower_id: str, followed_id: str) -> Dict[str, Any]:
        db.get_client().table("user_follows").delete().eq("follower_id", follower_id).eq(
            "followed_id", followed_id
        ).execute()
        return {"following": False}

    async def list_challenges(self, viewer_id: Optional[str]) -> List[Dict[str, Any]]:
        result = db.get_client().table("style_challenges").select("*").order("created_at", desc=True).execute()
        challenges = result.data or []

        joined_ids: set = set()
        if viewer_id and challenges:
            participation = (
                db.get_client()
                .table("challenge_participants")
                .select("challenge_id")
                .eq("user_id", viewer_id)
                .in_("challenge_id", [c["id"] for c in challenges])
                .execute()
            )
            joined_ids = {row["challenge_id"] for row in (participation.data or [])}

        for challenge in challenges:
            challenge["joined"] = challenge["id"] in joined_ids
        return challenges

    async def join_challenge(self, user_id: str, challenge_id: str) -> Dict[str, Any]:
        challenge = db.get_client().table("style_challenges").select("id").eq("id", challenge_id).execute()
        if not challenge.data:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "Challenge not found")

        existing = (
            db.get_client()
            .table("challenge_participants")
            .select("id")
            .eq("challenge_id", challenge_id)
            .eq("user_id", user_id)
            .execute()
        )
        if not existing.data:
            db.get_client().table("challenge_participants").insert(
                {"id": str(uuid.uuid4()), "challenge_id": challenge_id, "user_id": user_id}
            ).execute()
        return {"joined": True}


community_service = CommunityService()
