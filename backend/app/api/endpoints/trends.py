from fastapi import APIRouter, Depends, HTTPException
from app.models.trends import Trend, TrendAnalysis
from app.services.trend_service import TrendService
from app.api.dependencies import get_optional_user
from typing import List

router = APIRouter()

@router.get("/", response_model=List[Trend])
async def get_trends(
    trend_service: TrendService = Depends(),
    current_user = Depends(get_optional_user)
):
    return await trend_service.get_current_trends()

@router.get("/analysis", response_model=TrendAnalysis)
async def get_trend_analysis(
    trend_service: TrendService = Depends(),
    current_user = Depends(get_optional_user)
):
    return await trend_service.analyze_trends()

@router.get("/{trend_id}", response_model=Trend)
async def get_trend(
    trend_id: str,
    trend_service: TrendService = Depends()
):
    trend = await trend_service.get_trend(trend_id)
    if not trend:
        raise HTTPException(status_code=404, detail="Trend not found")
    return trend


