from fastapi import APIRouter, Depends, Query, HTTPException
from typing import List, Optional
import structlog

from app.services.recommendation_service import RecommendationService, get_recommendation_service
from app.schemas.recommendation import OutfitRecommendation, SimilarStyleRecommendation
from app.core.security import get_current_user
from app.schemas.user import User

router = APIRouter()
logger = structlog.get_logger()

@router.post("/outfits", response_model=List[OutfitRecommendation])
async def recommend_outfits(
    wardrobe_items: List[str],
    occasion: Optional[str] = None,
    weather_condition: Optional[str] = None,
    style_preference: Optional[str] = None,
    color_preference: Optional[List[str]] = None,
    limit: int = Query(5, ge=1, le=20),
    user: User = Depends(get_current_user),
    rec_service: RecommendationService = Depends(get_recommendation_service)
):
    """Generate AI-powered outfit recommendations"""
    
    try:
        recommendations = await rec_service.generate_outfit_recommendations(
            user_id=user.id,
            wardrobe_items=wardrobe_items,
            occasion=occasion,
            weather_condition=weather_condition,
            style_preference=style_preference,
            color_preference=color_preference,
            limit=limit
        )
        
        logger.info(f"Generated {len(recommendations)} outfit recommendations for user {user.id}")
        return recommendations
        
    except Exception as e:
        logger.error(f"Outfit recommendation failed: {str(e)}")
        raise HTTPException(status_code=500, detail="Recommendation generation failed")

@router.get("/trending", response_model=List[OutfitRecommendation])
async def get_trending_outfits(
    style: Optional[str] = None,
    season: Optional[str] = None,
    limit: int = Query(10, ge=1, le=50),
    rec_service: RecommendationService = Depends(get_recommendation_service)
):
    """Get trending outfit recommendations"""
    
    try:
        trending = await rec_service.get_trending_outfits(
            style=style,
            season=season,
            limit=limit
        )
        
        return trending
        
    except Exception as e:
        logger.error(f"Trending outfits fetch failed: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to fetch trending outfits")

@router.post("/similar", response_model=List[SimilarStyleRecommendation])
async def find_similar_styles(
    reference_outfit: dict,
    similarity_threshold: float = Query(0.7, ge=0.1, le=1.0),
    limit: int = Query(10, ge=1, le=30),
    rec_service: RecommendationService = Depends(get_recommendation_service)
):
    """Find similar style recommendations based on reference outfit"""
    
    try:
        similar_styles = await rec_service.find_similar_styles(
            reference_outfit=reference_outfit,
            similarity_threshold=similarity_threshold,
            limit=limit
        )
        
        return similar_styles
        
    except Exception as e:
        logger.error(f"Similar style search failed: {str(e)}")
        raise HTTPException(status_code=500, detail="Similar style search failed")

@router.get("/weather-based")
async def get_weather_recommendations(
    location: str,
    days_ahead: int = Query(0, ge=0, le=7),
    user: User = Depends(get_current_user),
    rec_service: RecommendationService = Depends(get_recommendation_service)
):
    """Get weather-appropriate outfit recommendations"""
    
    try:
        recommendations = await rec_service.get_weather_based_recommendations(
            user_id=user.id,
            location=location,
            days_ahead=days_ahead
        )
        
        return recommendations
        
    except Exception as e:
        logger.error(f"Weather-based recommendations failed: {str(e)}")
        raise HTTPException(status_code=500, detail="Weather recommendations failed")
