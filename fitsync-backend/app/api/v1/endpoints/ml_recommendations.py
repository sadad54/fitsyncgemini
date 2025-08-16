"""
ML Recommendations and Content Discovery Endpoints
"""

from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import JSONResponse
from typing import Optional
import math
import json

from app.core.security import get_current_user
from app.models.user import User
from app.schemas.clothing import ClothingCategoryEnum
from app.services.enhanced_ml_service import enhanced_ml_service
from app.services.trends_service import TrendsService
from app.services.cache_service import CacheService, hash_context
from app.database import get_db
from sqlalchemy.orm import Session

router = APIRouter()

# Utility functions
def calculate_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculate distance between two points using Haversine formula"""
    R = 6371  # Earth's radius in kilometers
    
    lat1_rad = math.radians(lat1)
    lon1_rad = math.radians(lon1)
    lat2_rad = math.radians(lat2)
    lon2_rad = math.radians(lon2)
    
    dlat = lat2_rad - lat1_rad
    dlon = lon2_rad - lon1_rad
    
    a = math.sin(dlat/2)**2 + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(dlon/2)**2
    c = 2 * math.asin(math.sqrt(a))
    
    return R * c

# ============================================================================
# OUTFIT SUGGESTIONS ENDPOINTS
# ============================================================================

@router.get("/recommendations/outfits")
async def get_outfit_recommendations(
    context: Optional[str] = Query(None, description="JSON-encoded context"),
    limit: int = Query(10, ge=1, le=50),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get personalized outfit recommendations"""
    try:
        # Parse context if provided
        context_data = {}
        if context:
            try:
                context_data = json.loads(context)
            except json.JSONDecodeError:
                pass
        
        # Generate cache key
        context_hash = hash_context(context_data) if context_data else None
        
        # Check cache first
        cached_result = CacheService.get_outfit_recommendations(
            current_user.id, context_hash, limit
        )
        if cached_result:
            return JSONResponse(content=cached_result)
        
        # Get fresh recommendations from service
        recommendations = await TrendsService.get_outfit_recommendations(
            db, current_user, context_data, limit
        )
        
        # Cache the result
        CacheService.set_outfit_recommendations(
            current_user.id, recommendations, context_hash, limit
        )
        
        return JSONResponse(content=recommendations)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get recommendations: {str(e)}")

# ============================================================================
# EXPLORE ENDPOINTS
# ============================================================================

@router.get("/explore/categories")
async def get_explore_categories(
    current_user: User = Depends(get_current_user)
):
    """Get clothing categories for explore screen"""
    try:
        # Check cache first
        cached_categories = CacheService.get_categories()
        if cached_categories:
            return JSONResponse(content={"categories": cached_categories})
        
        # Get fresh data
        categories = [category.value for category in ClothingCategoryEnum]
        
        # Cache the result
        CacheService.set_categories(categories)
        
        return JSONResponse(content={"categories": categories})
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get categories: {str(e)}")

@router.get("/explore/trending-styles")
async def get_trending_styles(
    limit: int = Query(10, ge=1, le=50),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get trending styles for explore screen"""
    try:
        # Check cache first
        cached_styles = CacheService.get_trending_styles(limit)
        if cached_styles:
            return JSONResponse(content={"styles": cached_styles})
        
        # Get fresh data from service
        styles = TrendsService.get_trending_styles(db, limit)
        styles_data = [style.dict() for style in styles]
        
        # Cache the result
        CacheService.set_trending_styles(styles_data, limit)
        
        return JSONResponse(content={"styles": styles_data})
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get trending styles: {str(e)}")

@router.get("/explore/items")
async def get_explore_items(
    category: Optional[str] = Query(None),
    trending: Optional[bool] = Query(None),
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get explore items (style posts, outfits, etc.)"""
    try:
        # Check cache first
        cached_items = CacheService.get_explore_items(category, trending, limit, offset)
        if cached_items:
            return JSONResponse(content=cached_items)
        
        # Get fresh data from service
        items, total = TrendsService.get_explore_items(db, category, trending, limit, offset)
        items_data = [item.dict() for item in items]
        
        result = {"items": items_data, "total": total}
        
        # Cache the result
        CacheService.set_explore_items(result, category, trending, limit, offset)
        
        return JSONResponse(content=result)
        # This section is now handled by the service layer above
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get explore items: {str(e)}")

# ============================================================================
# TRENDS ENDPOINTS
# ============================================================================

@router.get("/trends/trending-now")
async def get_trending_now(
    scope: str = Query("global", pattern="^(global|local)$"),
    timeframe: str = Query("week", pattern="^(day|week|month)$"),
    limit: int = Query(10, ge=1, le=50),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get trending fashion items and styles"""
    try:
        # Check cache first
        cached_trending = CacheService.get_trending_now(scope, timeframe, limit)
        if cached_trending:
            return JSONResponse(content={"trendingNow": cached_trending})
        
        # Get fresh data from service
        trending_items = TrendsService.get_trending_now(db, scope, timeframe, limit)
        trending_data = [item.dict() for item in trending_items]
        
        # Cache the result
        CacheService.set_trending_now(trending_data, scope, timeframe, limit)
        
        return JSONResponse(content={"trendingNow": trending_data})
        trending_items = [
            {
                "id": "t_001",
                "title": "Quiet Luxury",
                "growth": "+21%",
                "trend": "up",
                "description": "Understated premium staples gaining popularity.",
                "image": "https://example.com/trend1.jpg",
                "tags": ["elegant", "minimalist"],
                "engagement": 14230,
                "posts": 980
            },
            {
                "id": "t_002",
                "title": "Tech Wear",
                "growth": "+18%",
                "trend": "up",
                "description": "Functional fashion meets futuristic design.",
                "image": "https://example.com/trend2.jpg",
                "tags": ["streetwear", "functional"],
                "engagement": 12100,
                "posts": 756
            },
            {
                "id": "t_003",
                "title": "Cottage Core",
                "growth": "+13%",
                "trend": "up",
                "description": "Romantic, rural-inspired aesthetic.",
                "image": "https://example.com/trend3.jpg",
                "tags": ["bohemian", "romantic"],
                "engagement": 9840,
                "posts": 623
            },
            {
                "id": "t_004",
                "title": "Y2K Revival",
                "growth": "-5%",
                "trend": "down",
                "description": "Early 2000s fashion making a comeback.",
                "image": "https://example.com/trend4.jpg",
                "tags": ["retro", "bold"],
                "engagement": 7560,
                "posts": 445
            }
        ]
        
        return JSONResponse(content={"trendingNow": trending_items[:limit]})
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get trending items: {str(e)}")

@router.get("/trends/fashion-insights")
async def get_fashion_insights(
    scope: str = Query("global", pattern="^(global|local)$"),
    timeframe: str = Query("week", pattern="^(day|week|month)$"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get fashion insights and trend analysis"""
    try:
        # Check cache first
        cached_insights = CacheService.get_fashion_insights(scope, timeframe)
        if cached_insights:
            return JSONResponse(content={"insights": cached_insights})
        
        # Get fresh data from service
        insights = TrendsService.get_fashion_insights(db, scope, timeframe)
        insights_data = [insight.dict() for insight in insights]
        
        # Cache the result
        CacheService.set_fashion_insights(insights_data, scope, timeframe)
        
        return JSONResponse(content={"insights": insights_data})
        # This section is now handled by the service layer above
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get fashion insights: {str(e)}")

@router.get("/trends/influencer-spotlight")
async def get_influencer_spotlight(
    scope: str = Query("global", pattern="^(global|local)$"),
    limit: int = Query(10, ge=1, le=50),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get influencer spotlight for trending setters"""
    try:
        # Check cache first
        cached_spotlight = CacheService.get_influencer_spotlight(scope, limit)
        if cached_spotlight:
            return JSONResponse(content={"spotlight": cached_spotlight})
        
        # Get fresh data from service
        influencers = TrendsService.get_influencer_spotlight(db, scope, limit)
        influencers_data = [inf.dict() for inf in influencers]
        
        # Cache the result
        CacheService.set_influencer_spotlight(influencers_data, scope, limit)
        
        return JSONResponse(content={"spotlight": influencers_data})
        # This section is now handled by the service layer above
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get influencer spotlight: {str(e)}")

# ============================================================================
# NEARBY ENDPOINTS (Map-ready with coordinates)
# ============================================================================

@router.get("/nearby/people")
async def get_nearby_people(
    lat: float = Query(..., description="User latitude"),
    lng: float = Query(..., description="User longitude"),
    radius_km: float = Query(5.0, ge=0.1, le=50.0),
    limit: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get nearby people with fashion interests"""
    try:
        # Check cache first
        cached_people = CacheService.get_nearby_data(
            "people", lat, lng, radius_km, limit
        )
        if cached_people:
            return JSONResponse(content={"people": cached_people})
        
        # Get fresh data from service
        people = TrendsService.get_nearby_people(db, lat, lng, radius_km, limit)
        people_data = [person.dict() for person in people]
        
        # Cache the result
        CacheService.set_nearby_data(
            "people", people_data, lat, lng, radius_km, limit
        )
        
        return JSONResponse(content={"people": people_data})
        # This section is now handled by the service layer above
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get nearby people: {str(e)}")

@router.get("/nearby/events")
async def get_nearby_events(
    lat: float = Query(..., description="User latitude"),
    lng: float = Query(..., description="User longitude"),
    radius_km: float = Query(5.0, ge=0.1, le=50.0),
    limit: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get nearby fashion events"""
    try:
        # Check cache first
        cached_events = CacheService.get_nearby_data(
            "events", lat, lng, radius_km, limit
        )
        if cached_events:
            return JSONResponse(content={"events": cached_events})
        
        # Get fresh data from service
        events = TrendsService.get_nearby_events(db, lat, lng, radius_km, limit)
        events_data = [event.dict() for event in events]
        
        # Cache the result
        CacheService.set_nearby_data(
            "events", events_data, lat, lng, radius_km, limit
        )
        
        return JSONResponse(content={"events": events_data})
        # This section is now handled by the service layer above
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get nearby events: {str(e)}")

@router.get("/nearby/hotspots")
async def get_nearby_hotspots(
    lat: float = Query(..., description="User latitude"),
    lng: float = Query(..., description="User longitude"),
    radius_km: float = Query(5.0, ge=0.1, le=50.0),
    limit: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get nearby fashion hotspots"""
    try:
        # Check cache first
        cached_hotspots = CacheService.get_nearby_data(
            "hotspots", lat, lng, radius_km, limit
        )
        if cached_hotspots:
            return JSONResponse(content={"hotspots": cached_hotspots})
        
        # Get fresh data from service
        hotspots = TrendsService.get_nearby_hotspots(db, lat, lng, radius_km, limit)
        hotspots_data = [hotspot.dict() for hotspot in hotspots]
        
        # Cache the result
        CacheService.set_nearby_data(
            "hotspots", hotspots_data, lat, lng, radius_km, limit
        )
        
        return JSONResponse(content={"hotspots": hotspots_data})
        # This section is now handled by the service layer above
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get nearby hotspots: {str(e)}")

@router.get("/nearby/map")
async def get_nearby_map_data(
    lat: float = Query(..., description="User latitude"),
    lng: float = Query(..., description="User longitude"),
    radius_km: float = Query(5.0, ge=0.1, le=50.0),
    limit_people: int = Query(10, ge=1, le=50),
    limit_events: int = Query(10, ge=1, le=50),
    limit_hotspots: int = Query(10, ge=1, le=50),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get combined nearby data for map overlay"""
    try:
        # Check cache first
        cached_map_data = CacheService.get_nearby_data(
            "map", lat, lng, radius_km, 
            limit_people=limit_people, 
            limit_events=limit_events, 
            limit_hotspots=limit_hotspots
        )
        if cached_map_data:
            return JSONResponse(content=cached_map_data)
        
        # Get fresh data from services
        people = TrendsService.get_nearby_people(db, lat, lng, radius_km, limit_people)
        events = TrendsService.get_nearby_events(db, lat, lng, radius_km, limit_events)
        hotspots = TrendsService.get_nearby_hotspots(db, lat, lng, radius_km, limit_hotspots)
        
        map_data = {
            "center": {"latitude": lat, "longitude": lng},
            "people": [person.dict() for person in people],
            "events": [event.dict() for event in events],
            "hotspots": [hotspot.dict() for hotspot in hotspots]
        }
        
        # Cache the result
        CacheService.set_nearby_data(
            "map", map_data, lat, lng, radius_km,
            limit_people=limit_people,
            limit_events=limit_events,
            limit_hotspots=limit_hotspots
        )
        
        return JSONResponse(content=map_data)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get map data: {str(e)}")
