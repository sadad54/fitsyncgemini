from app.external_apis.google_places import GooglePlacesClient
from app.core.cache import get_cache
from app.core.config import settings
from typing import List, Dict, Any, Optional
import json

class LocationService:
    def __init__(self):
        self.places_client = GooglePlacesClient()
        self.cache = get_cache()

    async def get_nearby_places(self, lat: float, lon: float, radius: int = 5000) -> List[Dict[str, Any]]:
        cache_key = f"places:nearby:{lat}:{lon}:{radius}"
        
        # Check cache first
        cached_data = await self.cache.get(cache_key)
        if cached_data:
            return json.loads(cached_data)
        
        # Get from API
        places_data = await self.places_client.get_nearby_places(lat, lon, radius)
        
        # Cache the result
        await self.cache.set(cache_key, json.dumps(places_data), settings.CACHE_TTL_PLACES)
        
        return places_data

    async def search_places(self, query: str, lat: Optional[float] = None, lon: Optional[float] = None) -> List[Dict[str, Any]]:
        cache_key = f"places:search:{query}:{lat}:{lon}"
        
        # Check cache first
        cached_data = await self.cache.get(cache_key)
        if cached_data:
            return json.loads(cached_data)
        
        # Get from API
        places_data = await self.places_client.search_places(query, lat, lon)
        
        # Cache the result
        await self.cache.set(cache_key, json.dumps(places_data), settings.CACHE_TTL_PLACES)
        
        return places_data