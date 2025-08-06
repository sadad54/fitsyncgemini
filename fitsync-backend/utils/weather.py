import aiohttp
import asyncio
from typing import Dict, Any, Optional
import structlog
from app.config import settings

logger = structlog.get_logger()

class WeatherService:
    """Weather API integration for outfit recommendations"""
    
    def __init__(self):
        self.api_key = settings.WEATHER_API_KEY
        self.base_url = "http://api.openweathermap.org/data/2.5"
    
    async def get_weather_forecast(self, location: str, days_ahead: int = 0) -> Dict[str, Any]:
        """Get weather forecast for location"""
        
        if not self.api_key:
            # Return mock data if no API key
            return self._get_mock_weather_data(location, days_ahead)
        
        try:
            async with aiohttp.ClientSession() as session:
                if days_ahead == 0:
                    # Current weather
                    url = f"{self.base_url}/weather"
                    params = {
                        "q": location,
                        "appid": self.api_key,
                        "units": "metric"
                    }
                else:
                    # Forecast
                    url = f"{self.base_url}/forecast"
                    params = {
                        "q": location,
                        "appid": self.api_key,
                        "units": "metric",
                        "cnt": days_ahead * 8  # 8 forecasts per day (3-hour intervals)
                    }
                
                async with session.get(url, params=params) as response:
                    if response.status == 200:
                        data = await response.json()
                        return self._parse_weather_data(data, days_ahead)
                    else:
                        logger.warning(f"Weather API error: {response.status}")
                        return self._get_mock_weather_data(location, days_ahead)
        
        except Exception as e:
            logger.error(f"Weather service error: {str(e)}")
            return self._get_mock_weather_data(location, days_ahead)
    
    def _parse_weather_data(self, data: Dict[str, Any], days_ahead: int) -> Dict[str, Any]:
        """Parse weather API response"""
        
        if days_ahead == 0:
            # Current weather
            return {
                "location": data["name"],
                "temperature": data["main"]["temp"],
                "feels_like": data["main"]["feels_like"],
                "humidity": data["main"]["humidity"],
                "description": data["weather"][0]["description"],
                "icon": data["weather"][0]["icon"],
                "wind_speed": data["wind"]["speed"],
                "rain_probability": 0,  # Not available in current weather
                "uv_index": None,  # Would need separate UV API call
                "outfit_recommendations": self._generate_weather_outfit_suggestions(
                    data["main"]["temp"], data["weather"][0]["main"], data["main"]["humidity"]
                )
            }
        else:
            # Forecast data
            forecasts = []
            for item in data["list"]:
                forecast = {
                    "datetime": item["dt_txt"],
                    "temperature": item["main"]["temp"],
                    "description": item["weather"][0]["description"],
                    "rain_probability": item.get("pop", 0) * 100,
                    "wind_speed": item["wind"]["speed"]
                }
                forecasts.append(forecast)
            
            return {
                "location": data["city"]["name"],
                "forecasts": forecasts,
                "daily_summary": self._generate_daily_summary(forecasts)
            }
    
    def _get_mock_weather_data(self, location: str, days_ahead: int) -> Dict[str, Any]:
        """Generate mock weather data for testing"""
        
        base_temp = 22  # Base temperature in Celsius
        
        if days_ahead == 0:
            return {
                "location": location,
                "temperature": base_temp,
                "feels_like": base_temp + 2,
                "humidity": 65,
                "description": "partly cloudy",
                "icon": "02d",
                "wind_speed": 5.2,
                "rain_probability": 20,
                "uv_index": 6,
                "outfit_recommendations": self._generate_weather_outfit_suggestions(
                    base_temp, "Clouds", 65
                )
            }
        else:
            # Generate mock forecast
            forecasts = []
            for day in range(days_ahead + 1):
                temp_variation = (day % 3 - 1) * 3  # Vary temperature slightly
                forecasts.append({
                    "day": day,
                    "temperature": base_temp + temp_variation,
                    "description": "partly cloudy",
                    "rain_probability": 20 + (day * 10) % 60,
                    "wind_speed": 5.0 + day * 0.5
                })
            
            return {
                "location": location,
                "forecasts": forecasts,
                "daily_summary": self._generate_daily_summary(forecasts)
            }
    
    def _generate_weather_outfit_suggestions(self, temperature: float, 
                                           condition: str, humidity: int) -> Dict[str, Any]:
        """Generate outfit suggestions based on weather"""
        
        suggestions = {
            "layers": [],
            "materials": [],
            "colors": [],
            "accessories": [],
            "footwear": [],
            "special_considerations": []
        }
        
        # Temperature-based suggestions
        if temperature < 5:
            suggestions["layers"] = ["heavy coat", "sweater", "long pants", "thermal underwear"]
            suggestions["materials"] = ["wool", "down", "fleece"]
            suggestions["accessories"] = ["gloves", "scarf", "warm hat"]
            suggestions["footwear"] = ["boots", "warm socks"]
        elif temperature < 15:
            suggestions["layers"] = ["jacket", "sweater or hoodie", "long pants"]
            suggestions["materials"] = ["denim", "cotton blend", "light wool"]
            suggestions["accessories"] = ["light scarf"]
            suggestions["footwear"] = ["closed shoes", "sneakers"]
        elif temperature < 25:
            suggestions["layers"] = ["light jacket or cardigan", "t-shirt or blouse", "pants or jeans"]
            suggestions["materials"] = ["cotton", "linen blend"]
            suggestions["footwear"] = ["sneakers", "loafers", "flats"]
        else:
            suggestions["layers"] = ["t-shirt", "shorts or light pants"]
            suggestions["materials"] = ["cotton", "linen", "breathable fabrics"]
            suggestions["accessories"] = ["sunglasses", "hat"]
            suggestions["footwear"] = ["sandals", "breathable shoes"]
        
        # Condition-based suggestions
        if "rain" in condition.lower():
            suggestions["accessories"].extend(["umbrella", "waterproof jacket"])
            suggestions["footwear"] = ["waterproof shoes", "boots"]
            suggestions["special_considerations"].append("choose quick-dry materials")
        
        if "sun" in condition.lower() or "clear" in condition.lower():
            suggestions["accessories"].extend(["sunglasses", "sun hat"])
            suggestions["colors"].append("light colors to reflect heat")
            suggestions["special_considerations"].append("UV protection recommended")
        
        # Humidity considerations
        if humidity > 70:
            suggestions["materials"] = ["breathable cotton", "moisture-wicking fabrics"]
            suggestions["special_considerations"].append("choose loose-fitting clothes")
        
        return suggestions
    
    def _generate_daily_summary(self, forecasts: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Generate daily weather summary"""
        
        if not forecasts:
            return {}
        
        temps = [f["temperature"] for f in forecasts]
        rain_probs = [f["rain_probability"] for f in forecasts]
        
        return {
            "min_temperature": min(temps),
            "max_temperature": max(temps),
            "average_temperature": sum(temps) / len(temps),
            "max_rain_probability": max(rain_probs),
            "general_recommendation": self._get_daily_outfit_recommendation(
                min(temps), max(temps), max(rain_probs)
            )
        }
    
    def _get_daily_outfit_recommendation(self, min_temp: float, max_temp: float, 
                                       max_rain_prob: float) -> str:
        """Get general outfit recommendation for the day"""
        
        temp_range = max_temp - min_temp
        
        if temp_range > 10:
            base_rec = "Layer-friendly outfit recommended due to temperature variation"
        elif max_temp < 10:
            base_rec = "Warm clothing essential"
        elif max_temp > 30:
            base_rec = "Light, breathable clothing recommended"
        else:
            base_rec = "Comfortable casual wear suitable"
        
        if max_rain_prob > 50:
            base_rec += ". Don't forget waterproof gear!"
        
        return base_rec
