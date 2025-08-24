from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from app.models.community import Post, Comment, Like
from app.services.community_service import CommunityService
from app.api.dependencies import get_current_user, get_optional_user
from typing import List

router = APIRouter()

@router.post("/posts", response_model=Post)
async def create_post(
    content: str,
    image: UploadFile = File(None),
    current_user = Depends(get_current_user),
    community_service: CommunityService = Depends()
):
    return await community_service.create_post(content, current_user.id, image)

@router.get("/posts", response_model=List[Post])
async def get_posts(
    community_service: CommunityService = Depends(),
    current_user = Depends(get_optional_user)
):
    return await community_service.get_posts(current_user.id if current_user else None)

@router.post("/posts/{post_id}/comments", response_model=Comment)
async def create_comment(
    post_id: str,
    content: str,
    current_user = Depends(get_current_user),
    community_service: CommunityService = Depends()
):
    return await community_service.create_comment(post_id, content, current_user.id)

@router.post("/posts/{post_id}/like")
async def like_post(
    post_id: str,
    current_user = Depends(get_current_user),
    community_service: CommunityService = Depends()
):
    return await community_service.like_post(post_id, current_user.id)

@router.delete("/posts/{post_id}/like")
async def unlike_post(
    post_id: str,
    current_user = Depends(get_current_user),
    community_service: CommunityService = Depends()
):
    return await community_service.unlike_post(post_id, current_user.id)
```

