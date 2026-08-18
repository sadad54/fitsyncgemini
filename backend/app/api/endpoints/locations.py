from typing import Optional

from fastapi import APIRouter
from loguru import logger

from app.services.location_service import LocationService

router = APIRouter()
location_service = LocationService()


@router.get("/nearby")
async def get_nearby_places(lat: float, lon: float, radius: int = 5000):
    """Get nearby fashion-related places. Returns an empty list (not fabricated
    data) if the Google Places API is unavailable, so callers can distinguish
    'no results near you' from 'we couldn't reach the provider'."""
    try:
        places = await location_service.get_nearby_places(lat, lon, radius)
        return {"places": places, "total_count": len(places), "search_radius": radius, "center": {"lat": lat, "lng": lon}}
    except Exception as e:
        logger.warning(f"get_nearby_places failed: {e}")
        return {"places": [], "total_count": 0, "search_radius": radius, "center": {"lat": lat, "lng": lon}, "error": "provider_unavailable"}


@router.get("/search")
async def search_places(query: str, lat: Optional[float] = None, lon: Optional[float] = None):
    """Search for places by query."""
    try:
        places = await location_service.search_places(query, lat, lon)
        return {"places": places, "query": query, "total_count": len(places)}
    except Exception as e:
        logger.warning(f"search_places failed: {e}")
        return {"places": [], "query": query, "total_count": 0, "error": "provider_unavailable"}
