# pylint: disable=import-error
"""
Social posts endpoints
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import Any, List
from sqlalchemy.orm import Session

from app.core.security import get_current_user
from app.database import get_db
from app.models.user import User
from app.models.social import StylePost
from app.models.clothing import OutfitCombination
from app.schemas.social import StylePostCreate, StylePostResponse

router = APIRouter()


@router.get("/posts", response_model=List[StylePostResponse])
def list_style_posts(
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    _current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Any:
    try:
        posts = (
            db.query(StylePost)
            .order_by(StylePost.created_at.desc())
            .offset(offset)
            .limit(limit)
            .all()
        )

        response: List[StylePostResponse] = []
        for p in posts:
            response.append(
                StylePostResponse(
                    id=p.id,
                    userId=p.user_id,
                    userName=p.user.username if p.user else "",
                    userAvatarUrl=p.user.profile.profile_image_url if getattr(p.user, "profile", None) else None,
                    imageUrl=p.image_url or "",
                    caption=p.caption,
                    outfitId=p.outfit_id,
                    tags=p.hashtags or [],
                    likesCount=p.likes_count or 0,
                    commentsCount=p.comments_count or 0,
                    latitude=p.latitude,
                    longitude=p.longitude,
                    location=p.location,
                    createdAt=p.created_at,
                )
            )

        return response
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list posts: {str(e)}") from e


@router.post("/posts", response_model=StylePostResponse, status_code=status.HTTP_201_CREATED)
def create_style_post(
    payload: StylePostCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Any:
    try:
        outfit = db.query(OutfitCombination).filter(
            OutfitCombination.id == payload.outfit_id,
            OutfitCombination.user_id == current_user.id,
        ).first()
        if not outfit:
            raise HTTPException(status_code=400, detail="Invalid outfit_id for this user")

        post = StylePost(
            user_id=current_user.id,
            outfit_id=payload.outfit_id,
            title=None,
            caption=payload.caption,
            hashtags=payload.tags or [],
            location=payload.location,
            latitude=payload.latitude,
            longitude=payload.longitude,
            image_url=payload.image_url,
            is_public=True,
        )
        db.add(post)
        db.commit()
        db.refresh(post)

        return StylePostResponse(
            id=post.id,
            userId=post.user_id,
            userName=current_user.username,
            userAvatarUrl=current_user.profile.profile_image_url if getattr(current_user, "profile", None) else None,
            imageUrl=post.image_url or "",
            caption=post.caption,
            outfitId=post.outfit_id,
            tags=post.hashtags or [],
            likesCount=post.likes_count or 0,
            commentsCount=post.comments_count or 0,
            latitude=post.latitude,
            longitude=post.longitude,
            location=post.location,
            createdAt=post.created_at,
        )
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to create post: {str(e)}") from e


