from fastapi import APIRouter, Depends, Query
from typing import Optional, Tuple
from app.services.recommendation_service import recommendation_service
from app.api.dependencies import get_current_user

router = APIRouter()

@router.get("/daily")
async def get_daily_recommendations(
    occasion: str = Query("casual", description="Occasion for the outfit"),
    weather_lat: Optional[float] = Query(None, description="Latitude for weather data"),
    weather_lon: Optional[float] = Query(None, description="Longitude for weather data"),
    date: Optional[str] = Query(None, description="Date for recommendations (ISO format)"),
    current_user: dict = Depends(get_current_user)
):
    """Get daily outfit recommendations"""
    
    location = None
    if weather_lat and weather_lon:
        location = (weather_lat, weather_lon)
    
    return await recommendation_service.get_daily_outfit_recommendations(
        user_id=current_user["id"],
        occasion=occasion,
        location=location,
        date=date
    )

@router.get("/occasion/{occasion}")
async def get_occasion_recommendations(
    occasion: str,
    event_type: Optional[str] = Query(None, description="Specific event type"),
    dress_code: Optional[str] = Query(None, description="Dress code if known"),
    duration: Optional[str] = Query(None, description="Event duration"),
    current_user: dict = Depends(get_current_user)
):
    """Get recommendations for specific occasions"""
    
    additional_context = {}
    if event_type:
        additional_context["event_type"] = event_type
    if dress_code:
        additional_context["dress_code"] = dress_code
    if duration:
        additional_context["duration"] = duration
    
    return await recommendation_service.get_occasion_specific_recommendations(
        user_id=current_user["id"],
        occasion=occasion,
        additional_context=additional_context
    )

@router.get("/style-insights")
async def get_style_insights(
    current_user: dict = Depends(get_current_user)
):
    """Get personalized style insights and improvement suggestions"""
    
    return await recommendation_service.get_personalized_style_insights(
        user_id=current_user["id"]
    )

@router.get("/seasonal/{season}")
async def get_seasonal_plan(
    season: str,
    budget_range: str = Query("medium", description="Budget range: low, medium, high"),
    current_user: dict = Depends(get_current_user)
):
    """Get seasonal wardrobe planning recommendations"""
    
    return await recommendation_service.get_seasonal_wardrobe_plan(
        user_id=current_user["id"],
        season=season,
        budget_range=budget_range
    )

@router.post("/feedback")
async def provide_recommendation_feedback(
    feedback_data: dict,
    current_user: dict = Depends(get_current_user)
):
    """Provide feedback on recommendations to improve future suggestions"""
    
    # Save feedback for machine learning improvements
    feedback_record = {
        "user_id": current_user["id"],
        "recommendation_id": feedback_data.get("recommendation_id"),
        "rating": feedback_data.get("rating"),
        "feedback_type": feedback_data.get("type"),
        "comments": feedback_data.get("comments"),
        "was_helpful": feedback_data.get("was_helpful"),
        "timestamp": datetime.utcnow()
    }
    
    result = await db.save_recommendation_feedback(feedback_record)
    
    return {
        "success": True,
        "message": "Feedback saved successfully. This helps improve future recommendations!"
    }