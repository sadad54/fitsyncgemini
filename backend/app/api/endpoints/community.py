from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from app.models.community import Post, Comment, Like
from app.services.community_service import CommunityService
from app.api.dependencies import get_current_user, get_optional_user
from typing import List, Dict, Any
from datetime import datetime

router = APIRouter()

# Simple mock data endpoint for testing (no auth required)
@router.get("/posts", response_model=List[Dict[str, Any]])
async def get_posts():
    """Get community posts - returns mock data for now"""
    mock_posts = [
        {
            "id": 1,
            "username": "fashionista_jane",
            "avatar": "https://images.unsplash.com/photo-1494790108755-2616b332c8f2?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=150&q=80",
            "image_url": "https://images.unsplash.com/photo-1506629905607-bb5c07bef3ea?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=400&q=80",
            "content": "Perfect summer day calls for this flowy maxi dress! 🌞 The floral print gives me major vacation vibes ✨ #SummerStyle #FloralDress #OOTD",
            "likes": 42,
            "comments": 8,
            "created_at": "2025-11-05T10:30:00Z",
            "liked": False,
            "challenge": "Summer Vibes Challenge"
        },
        {
            "id": 2,
            "username": "style_guru_mike",
            "avatar": "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=150&q=80",
            "image_url": "https://images.unsplash.com/photo-1617137984095-74e4e5e3613f?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=400&q=80",
            "content": "Keeping it minimal today with this monochrome look. Sometimes less really is more 👌 #MinimalStyle #Monochrome #LessIsMore",
            "likes": 67,
            "comments": 12,
            "created_at": "2025-11-05T08:15:00Z",
            "liked": True,
            "challenge": "Monochrome Monday"
        },
        {
            "id": 3,
            "username": "chic_explorer",
            "avatar": "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=150&q=80",
            "image_url": "https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=400&q=80",
            "content": "Found this amazing vintage leather jacket at a thrift store! Paired it with modern pieces for the perfect blend 💎 #VintageFinds #ThriftStyle #SustainableFashion",
            "likes": 89,
            "comments": 15,
            "created_at": "2025-11-04T16:45:00Z",
            "liked": False,
            "challenge": "Vintage Revival Challenge"
        },
        {
            "id": 4,
            "username": "trendy_alex",
            "avatar": "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=150&q=80",
            "image_url": "https://images.unsplash.com/photo-1434389677669-e08b4cac3105?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=400&q=80",
            "content": "Street style captured in the heart of London! This oversized blazer is giving me boss vibes 💼✨ #StreetStyle #London #Blazer",
            "likes": 34,
            "comments": 6,
            "created_at": "2025-11-04T14:20:00Z",
            "liked": True,
            "challenge": None
        }
    ]
    return mock_posts

@router.post("/posts", response_model=Post)
async def create_post(
    content: str,
    image: UploadFile = File(None),
    current_user = Depends(get_current_user),
    community_service: CommunityService = Depends()
):
    return await community_service.create_post(content, current_user.id, image)

@router.get("/posts/authenticated", response_model=List[Post])
async def get_posts_authenticated(
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


