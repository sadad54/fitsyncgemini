from fastapi import APIRouter, Depends, HTTPException
from app.services.weather_service import WeatherService
from app.api.dependencies import get_optional_user
from typing import Dict, Any

router = APIRouter()

@router.get("/current")
async def get_current_weather(
    lat: float,
    lon: float,
    weather_service: WeatherService = Depends(),
    current_user = Depends(get_optional_user)
):
    return await weather_service.get_current_weather(lat, lon)

@router.get("/forecast")
async def get_weather_forecast(
    lat: float,
    lon: float,
    weather_service: WeatherService = Depends(),
    current_user = Depends(get_optional_user)
):
    return await weather_service.get_forecast(lat, lon)
