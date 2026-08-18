import json
from typing import Any, Dict, List, Optional

from app.core.cache import cache
from app.core.config import settings
from app.external_apis.google_places import GooglePlacesClient


class LocationService:
    def __init__(self):
        self.places_client = GooglePlacesClient()
        self.cache = cache

    async def get_nearby_places(self, lat: float, lon: float, radius: int = 5000) -> List[Dict[str, Any]]:
        cache_key = f"places:nearby:{lat}:{lon}:{radius}"

        cached_data = await self.cache.get(cache_key)
        if cached_data:
            return json.loads(cached_data)["places"]

        places_data = await self.places_client.find_nearby_fashion_stores(lat, lon, radius)

        await self.cache.set(cache_key, json.dumps(places_data), settings.CACHE_TTL_PLACES)
        return places_data["places"]

    async def search_places(self, query: str, lat: Optional[float] = None, lon: Optional[float] = None) -> List[Dict[str, Any]]:
        cache_key = f"places:search:{query}:{lat}:{lon}"

        cached_data = await self.cache.get(cache_key)
        if cached_data:
            return json.loads(cached_data)["places"]

        places_data = await self.places_client.text_search(query, lat, lon)

        await self.cache.set(cache_key, json.dumps(places_data), settings.CACHE_TTL_PLACES)
        return places_data["places"]
