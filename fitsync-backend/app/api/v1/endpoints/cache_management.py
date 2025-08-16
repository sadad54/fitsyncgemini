"""
Cache Management Endpoints
"""

from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import JSONResponse
from typing import Optional, Dict, Any

from app.core.security import get_current_user
from app.models.user import User
from app.services.cache_service import CacheService

router = APIRouter()

@router.get("/stats")
async def get_cache_stats(
    current_user: User = Depends(get_current_user)
):
    """Get cache statistics (admin only)"""
    try:
        # Check if user is admin (implement your admin check logic)
        if not getattr(current_user, 'is_admin', False):
            raise HTTPException(status_code=403, detail="Admin access required")
        
        stats = CacheService.get_cache_stats()
        return JSONResponse(content=stats)
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get cache stats: {str(e)}")

@router.post("/clear")
async def clear_cache(
    cache_type: Optional[str] = Query(None, description="Specific cache type to clear"),
    current_user: User = Depends(get_current_user)
):
    """Clear cache entries (admin only)"""
    try:
        # Check if user is admin
        if not getattr(current_user, 'is_admin', False):
            raise HTTPException(status_code=403, detail="Admin access required")
        
        if cache_type:
            # Clear specific cache type (not implemented in simple version)
            return JSONResponse(content={
                "message": f"Cache type '{cache_type}' clearing not implemented in simple cache",
                "status": "warning"
            })
        else:
            # Clear all cache
            CacheService.clear_all_cache()
            return JSONResponse(content={
                "message": "All cache entries cleared",
                "status": "success"
            })
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to clear cache: {str(e)}")

@router.post("/invalidate/user/{user_id}")
async def invalidate_user_cache(
    user_id: int,
    current_user: User = Depends(get_current_user)
):
    """Invalidate cache entries for a specific user"""
    try:
        # Users can invalidate their own cache, admins can invalidate any user's cache
        if current_user.id != user_id and not getattr(current_user, 'is_admin', False):
            raise HTTPException(status_code=403, detail="Can only invalidate your own cache")
        
        CacheService.invalidate_user_cache(user_id)
        return JSONResponse(content={
            "message": f"Cache invalidated for user {user_id}",
            "status": "success"
        })
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to invalidate user cache: {str(e)}")

@router.post("/invalidate/location")
async def invalidate_location_cache(
    lat: float = Query(..., description="Latitude"),
    lng: float = Query(..., description="Longitude"),
    radius_km: float = Query(10.0, description="Radius in kilometers"),
    current_user: User = Depends(get_current_user)
):
    """Invalidate location-based cache entries"""
    try:
        # Check if user is admin
        if not getattr(current_user, 'is_admin', False):
            raise HTTPException(status_code=403, detail="Admin access required")
        
        CacheService.invalidate_location_cache(lat, lng, radius_km)
        return JSONResponse(content={
            "message": f"Location cache invalidated around ({lat}, {lng}) within {radius_km}km",
            "status": "success"
        })
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to invalidate location cache: {str(e)}")

@router.get("/health")
async def cache_health_check():
    """Check cache service health"""
    try:
        stats = CacheService.get_cache_stats()
        
        # Determine health status
        if stats.get("error"):
            status = "unhealthy"
            message = f"Cache error: {stats['error']}"
        elif stats.get("total_keys", 0) > 10000:  # Arbitrary limit
            status = "warning"
            message = "High cache usage detected"
        else:
            status = "healthy"
            message = "Cache service operating normally"
        
        return JSONResponse(content={
            "status": status,
            "message": message,
            "stats": stats
        })
        
    except Exception as e:
        return JSONResponse(
            status_code=500,
            content={
                "status": "unhealthy",
                "message": f"Cache health check failed: {str(e)}",
                "stats": {}
            }
        )

@router.post("/warm-up")
async def warm_up_cache(
    current_user: User = Depends(get_current_user)
):
    """Warm up frequently accessed cache entries (admin only)"""
    try:
        # Check if user is admin
        if not getattr(current_user, 'is_admin', False):
            raise HTTPException(status_code=403, detail="Admin access required")
        
        # Warm up categories (most frequently accessed)
        from app.schemas.clothing import ClothingCategoryEnum
        categories = [category.value for category in ClothingCategoryEnum]
        CacheService.set_categories(categories)
        
        # You could add more warm-up operations here
        # For example, warm up popular trending styles, etc.
        
        return JSONResponse(content={
            "message": "Cache warm-up completed",
            "warmed_items": ["categories"],
            "status": "success"
        })
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to warm up cache: {str(e)}")
