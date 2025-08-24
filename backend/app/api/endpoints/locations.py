from fastapi import APIRouter, Depends, HTTPException
from app.services.location_service import LocationService
from app.api.dependencies import get_optional_user
from typing import List, Dict, Any

router = APIRouter()

@router.get("/nearby")
async def get_nearby_places(
    lat: float,
    lon: float,
    radius: int = 5000,
    location_service: LocationService = Depends(),
    current_user = Depends(get_optional_user)
):
    return await location_service.get_nearby_places(lat, lon, radius)

@router.get("/search")
async def search_places(
    query: str,
    lat: float = None,
    lon: float = None,
    location_service: LocationService = Depends(),
    current_user = Depends(get_optional_user)
):
    return await location_service.search_places(query, lat, lon)
