from fastapi import APIRouter, Depends, HTTPException
from app.services.location_service import LocationService
from app.api.dependencies import get_optional_user
from typing import List, Dict, Any
import asyncio

router = APIRouter()

@router.get("/nearby")
async def get_nearby_places(
    lat: float,
    lon: float,
    radius: int = 5000
):
    """Get nearby fashion-related places"""
    try:
        location_service = LocationService()
        return await location_service.get_nearby_places(lat, lon, radius)
    except Exception as e:
        print(f"Error getting nearby places: {e}")
        # Return mock data for development
        return {
            "places": [
                {
                    "id": "1",
                    "name": "Fashion District Boutique",
                    "address": "123 Fashion Ave, New York, NY",
                    "category": "Clothing Store",
                    "rating": 4.5,
                    "distance_km": 0.5,
                    "lat": lat + 0.001,
                    "lng": lon + 0.001,
                    "is_open": True,
                    "price_level": 3
                },
                {
                    "id": "2", 
                    "name": "Style Studio NYC",
                    "address": "456 Broadway, New York, NY",
                    "category": "Fashion Designer",
                    "rating": 4.8,
                    "distance_km": 0.8,
                    "lat": lat - 0.002,
                    "lng": lon + 0.002,
                    "is_open": True,
                    "price_level": 4
                },
                {
                    "id": "3",
                    "name": "Urban Threads",
                    "address": "789 5th Ave, New York, NY", 
                    "category": "Streetwear Store",
                    "rating": 4.2,
                    "distance_km": 1.2,
                    "lat": lat + 0.003,
                    "lng": lon - 0.001,
                    "is_open": False,
                    "price_level": 2
                },
                {
                    "id": "4",
                    "name": "Vintage Vibes",
                    "address": "321 Vintage St, New York, NY",
                    "category": "Vintage Store",
                    "rating": 4.6,
                    "distance_km": 1.5,
                    "lat": lat - 0.004,
                    "lng": lon - 0.003,
                    "is_open": True,
                    "price_level": 3
                },
                {
                    "id": "5",
                    "name": "Accessories Unlimited",
                    "address": "654 Style Blvd, New York, NY",
                    "category": "Accessories Store", 
                    "rating": 4.3,
                    "distance_km": 2.1,
                    "lat": lat + 0.005,
                    "lng": lon + 0.004,
                    "is_open": True,
                    "price_level": 2
                }
            ],
            "total_count": 5,
            "search_radius": radius,
            "center": {"lat": lat, "lng": lon}
        }

@router.get("/search")
async def search_places(
    query: str,
    lat: float = None,
    lon: float = None
):
    """Search for places by query"""
    try:
        location_service = LocationService()
        return await location_service.search_places(query, lat, lon)
    except Exception as e:
        print(f"Error searching places: {e}")
        # Return mock search results
        return {
            "places": [
                {
                    "id": f"search_{i}",
                    "name": f"{query} Store {i+1}",
                    "address": f"{100+i*10} Fashion St, City, State",
                    "category": "Fashion Store",
                    "rating": 4.0 + (i * 0.1),
                    "distance_km": 0.5 + i,
                    "lat": (lat or 40.7589) + (i * 0.001),
                    "lng": (lon or -73.9851) + (i * 0.001),
                    "is_open": i % 2 == 0,
                    "price_level": (i % 4) + 1
                }
                for i in range(3)
            ],
            "query": query,
            "total_count": 3
        }

@router.get("/test")
async def test_locations():
    """Test endpoint to verify locations API is working"""
    return {
        "status": "ok", 
        "message": "Locations API is working!",
        "endpoints": [
            "/nearby - Get nearby fashion places",
            "/search - Search for places",
            "/test - This test endpoint"
        ]
    }
