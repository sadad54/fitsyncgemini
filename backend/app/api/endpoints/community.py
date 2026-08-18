from typing import List, Optional

from fastapi import APIRouter, Depends
from pydantic import BaseModel

from app.api.dependencies import get_current_user, get_optional_user
from app.models.user import User
from app.services.community_service import community_service

router = APIRouter()


class PostCreate(BaseModel):
    content: str = ""
    image_url: Optional[str] = None
    tags: List[str] = []


class CommentCreate(BaseModel):
    content: str


@router.get("/posts")
async def get_posts(
    limit: int = 20,
    offset: int = 0,
    current_user: Optional[User] = Depends(get_optional_user),
):
    viewer_id = current_user.user_id if current_user else None
    return await community_service.list_posts(viewer_id, limit=limit, offset=offset)


@router.post("/posts")
async def create_post(body: PostCreate, current_user: User = Depends(get_current_user)):
    return await community_service.create_post(current_user.user_id, body.content, body.image_url, body.tags)


@router.delete("/posts/{post_id}")
async def delete_post(post_id: str, current_user: User = Depends(get_current_user)):
    await community_service.delete_post(current_user.user_id, post_id)
    return {"success": True}


@router.post("/posts/{post_id}/like")
async def like_post(post_id: str, current_user: User = Depends(get_current_user)):
    return await community_service.like_post(current_user.user_id, post_id)


@router.delete("/posts/{post_id}/like")
async def unlike_post(post_id: str, current_user: User = Depends(get_current_user)):
    return await community_service.unlike_post(current_user.user_id, post_id)


@router.get("/posts/{post_id}/comments")
async def get_comments(post_id: str):
    return await community_service.list_comments(post_id)


@router.post("/posts/{post_id}/comments")
async def create_comment(post_id: str, body: CommentCreate, current_user: User = Depends(get_current_user)):
    return await community_service.create_comment(current_user.user_id, post_id, body.content)


@router.post("/users/{user_id}/follow")
async def follow_user(user_id: str, current_user: User = Depends(get_current_user)):
    return await community_service.follow_user(current_user.user_id, user_id)


@router.delete("/users/{user_id}/follow")
async def unfollow_user(user_id: str, current_user: User = Depends(get_current_user)):
    return await community_service.unfollow_user(current_user.user_id, user_id)


@router.get("/challenges")
async def get_challenges(current_user: Optional[User] = Depends(get_optional_user)):
    viewer_id = current_user.user_id if current_user else None
    return await community_service.list_challenges(viewer_id)


@router.post("/challenges/{challenge_id}/join")
async def join_challenge(challenge_id: str, current_user: User = Depends(get_current_user)):
    return await community_service.join_challenge(current_user.user_id, challenge_id)
