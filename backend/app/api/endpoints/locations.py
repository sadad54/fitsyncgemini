import math
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, HTTPException, Query
from loguru import logger

from app.services.location_service import LocationService

router = APIRouter()
location_service = LocationService()


def distance_m(lat1: float, lon1: float, lat2: float, lon2: float) -> int:
    """Great-circle distance in metres (haversine)."""
    r = 6_371_000
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp, dl = math.radians(lat2 - lat1), math.radians(lon2 - lon1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return round(2 * r * math.asin(math.sqrt(a)))


def _with_distance(places: List[Dict[str, Any]], lat: float, lon: float) -> List[Dict[str, Any]]:
    out = []
    for place in places:
        loc = place.get("location") or {}
        if "lat" in loc and "lng" in loc:
            place = {**place, "distance_m": distance_m(lat, lon, loc["lat"], loc["lng"])}
        out.append(place)
    return sorted(out, key=lambda p: p.get("distance_m", math.inf))


@router.get("/nearby")
async def get_nearby_places(
    lat: float = Query(..., ge=-90, le=90),
    lon: float = Query(..., ge=-180, le=180),
    radius: int = Query(5000, ge=100, le=50000),
):
    """Nearby fashion stores, nearest first. Returns an empty list with an error
    code (never fabricated data) if Google Places is unavailable."""
    try:
        places = await location_service.get_nearby_places(lat, lon, radius)
        places = _with_distance(places, lat, lon)
        return {"places": places, "total_count": len(places), "search_radius": radius, "center": {"lat": lat, "lng": lon}}
    except Exception as e:
        logger.warning(f"get_nearby_places failed: {e}")
        return {"places": [], "total_count": 0, "search_radius": radius, "center": {"lat": lat, "lng": lon}, "error": "provider_unavailable"}


@router.get("/search")
async def search_places(query: str = Query(..., min_length=1, max_length=100), lat: Optional[float] = None, lon: Optional[float] = None):
    """Search for places by query."""
    try:
        places = await location_service.search_places(query, lat, lon)
        if lat is not None and lon is not None:
            places = _with_distance(places, lat, lon)
        return {"places": places, "query": query, "total_count": len(places)}
    except Exception as e:
        logger.warning(f"search_places failed: {e}")
        return {"places": [], "query": query, "total_count": 0, "error": "provider_unavailable"}


@router.get("/places/{place_id}")
async def get_place(place_id: str):
    """Opening hours, contact details and reviews for one store."""
    details = await location_service.get_place_details(place_id)
    if details.get("error"):
        logger.warning(f"get_place {place_id} failed: {details['error']}")
        raise HTTPException(status_code=404 if "not found" in details["error"].lower() else 503, detail="Store details are unavailable right now")
    return {"id": place_id, **details}
