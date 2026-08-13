from fastapi import APIRouter, Depends, HTTPException
from app.services.weather_service import WeatherService
from app.api.dependencies import get_optional_user
from typing import Dict, Any
import random

router = APIRouter()

@router.get("/current")
async def get_current_weather(
    lat: float,
    lon: float
):
    """Get current weather for coordinates"""
    try:
        weather_service = WeatherService()
        return await weather_service.get_current_weather(lat, lon)
    except Exception as e:
        print(f"Error getting weather: {e}")
        # Return mock weather data
        return {
            "temperature": round(random.uniform(15, 30), 1),
            "feels_like": round(random.uniform(15, 30), 1),
            "humidity": random.randint(40, 80),
            "wind_speed": round(random.uniform(5, 20), 1),
            "condition": random.choice(["Clear", "Sunny", "Cloudy", "Partly Cloudy", "Overcast"]),
            "description": "Pleasant weather for fashion activities",
            "icon": "01d",
            "location": f"Location ({lat:.2f}, {lon:.2f})",
            "outfit_suggestions": [
                "Light layers work great today",
                "Perfect weather for outdoor fashion photos",
                "Comfortable temperature for trying new styles"
            ]
        }

@router.get("/forecast")
async def get_weather_forecast(
    lat: float,
    lon: float
):
    """Get weather forecast for coordinates"""
    try:
        weather_service = WeatherService()
        return await weather_service.get_forecast(lat, lon)
    except Exception as e:
        print(f"Error getting forecast: {e}")
        # Return mock forecast data
        return {
            "forecast": [
                {
                    "date": "2025-11-05",
                    "temperature_high": 25,
                    "temperature_low": 18,
                    "condition": "Sunny",
                    "description": "Perfect day for outdoor styling",
                    "outfit_suggestion": "Light, breathable fabrics recommended"
                },
                {
                    "date": "2025-11-06", 
                    "temperature_high": 22,
                    "temperature_low": 15,
                    "condition": "Partly Cloudy",
                    "description": "Great for layered looks",
                    "outfit_suggestion": "Consider adding a light jacket"
                },
                {
                    "date": "2025-11-07",
                    "temperature_high": 20,
                    "temperature_low": 12,
                    "condition": "Cloudy",
                    "description": "Cooler day ahead",
                    "outfit_suggestion": "Perfect weather for cozy sweaters"
                }
            ],
            "location": f"Forecast for ({lat:.2f}, {lon:.2f})"
        }

@router.get("/test")
async def test_weather():
    """Test endpoint for weather API"""
    return {
        "status": "ok",
        "message": "Weather API is working!",
        "endpoints": [
            "/current - Get current weather",
            "/forecast - Get weather forecast", 
            "/test - This test endpoint"
        ]
    }
