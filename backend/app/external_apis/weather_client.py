import aiohttp
from typing import Dict, Optional
from app.core.config import settings
from app.utils.rate_limiter import rate_limiter
from fastapi import HTTPException
import redis.asyncio as redis

class WeatherClient:
    def __init__(self):
        self.base_url = settings.OPENWEATHER_BASE_URL
        self.api_key = settings.OPENWEATHER_API_KEY
        self.redis = redis.from_url(settings.REDIS_URL)
    
    async def get_current_weather(self, lat: float, lon: float, user_id: str) -> Dict:
        """Get current weather for coordinates"""
        
        # Check cache first
        cache_key = f"weather:current:{lat}:{lon}"
        cached = await self.redis.get(cache_key)
        if cached:
            return json.loads(cached)
        
        # Rate limiting
        allowed, reset_time = await rate_limiter.check_rate_limit(
            "openweather",
            settings.OPENWEATHER_RATE_LIMIT,
            86400,  # 24 hours
            user_id
        )
        
        if not allowed:
            raise HTTPException(
                status_code=429,
                detail=f"Weather API rate limit exceeded"
            )
        
        try:
            async with aiohttp.ClientSession() as session:
                async with session.get(
                    f"{self.base_url}/weather",
                    params={
                        "lat": lat,
                        "lon": lon,
                        "appid": self.api_key,
                        "units": "metric"
                    }
                ) as response:
                    
                    if response.status == 200:
                        data = await response.json()
                        
                        weather_data = {
                            "temperature": data["main"]["temp"],
                            "feels_like": data["main"]["feels_like"],
                            "humidity": data["main"]["humidity"],
                            "description": data["weather"][0]["description"],
                            "main_condition": data["weather"][0]["main"],
                            "wind_speed": data.get("wind", {}).get("speed", 0),
                            "visibility": data.get("visibility", 10000) / 1000,  # km
                            "uv_index": data.get("uvi", 0),
                            "clothing_recommendations": self._get_clothing_recommendations(
                                data["main"]["temp"],
                                data["weather"][0]["main"],
                                data.get("wind", {}).get("speed", 0)
                            )
                        }
                        
                        # Cache for 1 hour
                        await self.redis.setex(
                            cache_key,
                            settings.CACHE_TTL_WEATHER,
                            json.dumps(weather_data)
                        )
                        
                        return weather_data
                    else:
                        raise HTTPException(
                            status_code=response.status,
                            detail="Weather API error"
                        )
                        
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Weather service error: {str(e)}"
            )
    
    async def get_weather_forecast(self, lat: float, lon: float, user_id: str, days: int = 5) -> Dict:
        """Get weather forecast"""
        
        cache_key = f"weather:forecast:{lat}:{lon}:{days}"
        cached = await self.redis.get(cache_key)
        if cached:
            return json.loads(cached)
        
        # Rate limiting
        allowed, _ = await rate_limiter.check_rate_limit(
            "openweather_forecast",
            settings.OPENWEATHER_RATE_LIMIT // 2,
            86400,
            user_id
        )
        
        if not allowed:
            raise HTTPException(status_code=429, detail="Weather forecast rate limit exceeded")
        
        try:
            async with aiohttp.ClientSession() as session:
                async with session.get(
                    f"{self.base_url}/forecast",
                    params={
                        "lat": lat,
                        "lon": lon,
                        "appid": self.api_key,
                        "units": "metric",
                        "cnt": days * 8  # 8 forecasts per day (3-hour intervals)
                    }
                ) as response:
                    
                    if response.status == 200:
                        data = await response.json()
                        
                        forecast_data = {
                            "daily_forecasts": self._process_forecast_data(data["list"]),
                            "location": {
                                "city": data["city"]["name"],
                                "country": data["city"]["country"]
                            }
                        }
                        
                        # Cache for 3 hours
                        await self.redis.setex(
                            cache_key,
                            10800,  # 3 hours
                            json.dumps(forecast_data)
                        )
                        
                        return forecast_data
                    else:
                        raise HTTPException(
                            status_code=response.status,
                            detail="Weather forecast API error"
                        )
                        
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Weather forecast error: {str(e)}"
            )
    
    def _get_clothing_recommendations(self, temp: float, condition: str, wind_speed: float) -> Dict:
        """Generate clothing recommendations based on weather"""
        
        recommendations = {
            "layers": [],
            "materials": [],
            "accessories": [],
            "footwear": [],
            "colors": []
        }
        
        # Temperature-based recommendations
        if temp < 0:
            recommendations["layers"] = ["heavy coat", "sweater", "thermal underwear"]
            recommendations["materials"] = ["wool", "down", "fleece"]
            recommendations["accessories"] = ["warm hat", "gloves", "scarf"]
            recommendations["footwear"] = ["insulated boots"]
            recommendations["colors"] = ["dark colors", "earth tones"]
            
        elif temp < 10:
            recommendations["layers"] = ["jacket", "long sleeves", "pants"]
            recommendations["materials"] = ["wool", "cotton blend", "denim"]
            recommendations["accessories"] = ["light scarf", "hat"]
            recommendations["footwear"] = ["closed shoes", "boots"]
            recommendations["colors"] = ["darker shades", "jewel tones"]
            
        elif temp < 20:
            recommendations["layers"] = ["light jacket", "long sleeves", "light pants"]
            recommendations["materials"] = ["cotton", "light wool", "polyester blend"]
            recommendations["accessories"] = ["light cardigan"]
            recommendations["footwear"] = ["sneakers", "casual shoes"]
            recommendations["colors"] = ["medium tones", "pastels"]
            
        elif temp < 25:
            recommendations["layers"] = ["t-shirt", "light pants", "optional light layer"]
            recommendations["materials"] = ["cotton", "linen", "bamboo"]
            recommendations["accessories"] = ["sunglasses"]
            recommendations["footwear"] = ["sneakers", "loafers"]
            recommendations["colors"] = ["bright colors", "pastels"]
            
        else:  # temp >= 25
            recommendations["layers"] = ["t-shirt", "shorts", "tank tops"]
            recommendations["materials"] = ["cotton", "linen", "moisture-wicking"]
            recommendations["accessories"] = ["sunglasses", "hat", "sunscreen"]
            recommendations["footwear"] = ["sandals", "breathable shoes"]
            recommendations["colors"] = ["light colors", "whites", "pastels"]
        
        # Weather condition adjustments
        if condition.lower() in ["rain", "drizzle", "thunderstorm"]:
            recommendations["accessories"].append("umbrella")
            recommendations["materials"].append("waterproof")
            recommendations["footwear"] = ["waterproof shoes", "rain boots"]
            
        elif condition.lower() in ["snow", "sleet"]:
            recommendations["footwear"] = ["insulated boots", "waterproof boots"]
            recommendations["accessories"].extend(["warm hat", "gloves"])
            
        elif condition.lower() in ["clear", "sunny"]:
            recommendations["accessories"].extend(["sunglasses", "hat"])
            recommendations["colors"] = ["UV-protective colors", "light colors"]
        
        # Wind adjustments
        if wind_speed > 15:  # High wind
            recommendations["accessories"].append("windbreaker")
            recommendations["materials"].append("wind-resistant")
        
        return recommendations
    
    def _process_forecast_data(self, forecast_list: List[Dict]) -> List[Dict]:
        """Process forecast data into daily summaries"""
        daily_data = {}
        
        for item in forecast_list:
            date = item["dt_txt"].split()[0]  # Extract date
            
            if date not in daily_data:
                daily_data[date] = {
                    "date": date,
                    "temps": [],
                    "conditions": [],
                    "humidity": [],
                    "wind_speeds": []
                }
            
            daily_data[date]["temps"].append(item["main"]["temp"])
            daily_data[date]["conditions"].append(item["weather"][0]["main"])
            daily_data[date]["humidity"].append(item["main"]["humidity"])
            daily_data[date]["wind_speeds"].append(item.get("wind", {}).get("speed", 0))
        
        # Create daily summaries
        daily_forecasts = []
        for date, data in daily_data.items():
            daily_forecast = {
                "date": date,
                "temp_min": min(data["temps"]),
                "temp_max": max(data["temps"]),
                "temp_avg": sum(data["temps"]) / len(data["temps"]),
                "main_condition": max(set(data["conditions"]), key=data["conditions"].count),
                "avg_humidity": sum(data["humidity"]) / len(data["humidity"]),
                "avg_wind_speed": sum(data["wind_speeds"]) / len(data["wind_speeds"]),
                "clothing_recommendations": self._get_clothing_recommendations(
                    sum(data["temps"]) / len(data["temps"]),
                    max(set(data["conditions"]), key=data["conditions"].count),
                    sum(data["wind_speeds"]) / len(data["wind_speeds"])
                )
            }
            daily_forecasts.append(daily_forecast)
        
        return sorted(daily_forecasts, key=lambda x: x["date"])

weather_client = WeatherClient()