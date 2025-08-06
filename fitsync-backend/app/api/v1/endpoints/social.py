from fastapi import APIRouter, Depends, Query, HTTPException
from typing import List, Optional
import structlog

from app.services.social_service import SocialService, get_social_service
from app.schemas.social import NearbyUser, OutfitRating, FashionChallenge
from app.core.security import get_current_user
from app.schemas.user import User

router = APIRouter()
logger = structlog.get_logger()

@router.get("/nearby", response_model=List[NearbyUser])
async def get_nearby_users(
    latitude: float = Query(..., ge=-90, le=90),
    longitude: float = Query(..., ge=-180, le=180),
    radius_km: float = Query(5.0, ge=0.1, le=50.0),
    style_filter: Optional[str] = None,
    limit: int = Query(20, ge=1, le=100),
    user: User = Depends(get_current_user),
    social_service: SocialService = Depends(get_social_service)
):
    """Find nearby users with similar style preferences"""
    
    try:
        nearby_users = await social_service.find_nearby_users(
            user_id=user.id,
            latitude=latitude,
            longitude=longitude,
            radius_km=radius_km,
            style_filter=style_filter,
            limit=limit
        )
        
        return nearby_users
        
    except Exception as e:
        logger.error(f"Nearby users search failed: {str(e)}")
        raise HTTPException(status_code=500, detail="Nearby users search failed")

@router.post("/rate")
async def rate_outfit(
    outfit_id: str,
    rating: int = Query(..., ge=1, le=5),
    comment: Optional[str] = None,
    user: User = Depends(get_current_user),
    social_service: SocialService = Depends(get_social_service)
):
    """Rate and review an outfit"""
    
    try:
        result = await social_service.rate_outfit(
            user_id=user.id,
            outfit_id=outfit_id,
            rating=rating,
            comment=comment
        )
        
        return result
        
    except Exception as e:
        logger.error(f"Outfit rating failed: {str(e)}")
        raise HTTPException(status_code=500, detail="Rating submission failed")

@router.get("/challenges", response_model=List[FashionChallenge])
async def get_fashion_challenges(
    active_only: bool = True,
    category: Optional[str] = None,
    limit: int = Query(10, ge=1, le=50),
    social_service: SocialService = Depends(get_social_service)
):
    """Get available fashion challenges"""
    
    try:
        challenges = await social_service.get_fashion_challenges(
            active_only=active_only,
            category=category,
            limit=limit
        )
        
        return challenges
        
    except Exception as e:
        logger.error(f"Fashion challenges fetch failed: {str(e)}")
        raise HTTPException(status_code=500, detail="Challenges fetch failed")

@router.post("/challenges/{challenge_id}/participate")
async def participate_in_challenge(
    challenge_id: str,
    outfit_photo: UploadFile = File(...),
    description: Optional[str] = None,
    user: User = Depends(get_current_user),
    social_service: SocialService = Depends(get_social_service)
):
    """Participate in a fashion challenge"""
    
    try:
        result = await social_service.participate_in_challenge(
            user_id=user.id,
            challenge_id=challenge_id,
            outfit_photo=outfit_photo,
            description=description
        )
        
        return result
        
    except Exception as e:
        logger.error(f"Challenge participation failed: {str(e)}")
        raise HTTPException(status_code=500, detail="Challenge participation failed")
