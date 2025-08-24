from app.external_apis.weather_client import WeatherClient
from app.core.cache import get_cache
from app.core.config import settings
from typing import Dict, Any
import json

class WeatherService:
    def __init__(self):
        self.weather_client = WeatherClient()
        self.cache = get_cache()

    async def get_current_weather(self, lat: float, lon: float) -> Dict[str, Any]:
        cache_key = f"weather:current:{lat}:{lon}"
        
        # Check cache first
        cached_data = await self.cache.get(cache_key)
        if cached_data:
            return json.loads(cached_data)
        
        # Get from API
        weather_data = await self.weather_client.get_current_weather(lat, lon)
        
        # Cache the result
        await self.cache.set(cache_key, json.dumps(weather_data), settings.CACHE_TTL_WEATHER)
        
        return weather_data

    async def get_forecast(self, lat: float, lon: float) -> Dict[str, Any]:
        cache_key = f"weather:forecast:{lat}:{lon}"
        
        # Check cache first
        cached_data = await self.cache.get(cache_key)
        if cached_data:
            return json.loads(cached_data)
        
        # Get from API
        forecast_data = await self.weather_client.get_forecast(lat, lon)
        
        # Cache the result
        await self.cache.set(cache_key, json.dumps(forecast_data), settings.CACHE_TTL_WEATHER)
        
        return forecast_data