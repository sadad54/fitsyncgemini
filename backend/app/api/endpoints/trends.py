from typing import List, Optional

from fastapi import APIRouter, HTTPException

from app.models.trends import Trend, TrendAnalysis
from app.services.trend_service import trend_service

router = APIRouter()


@router.get("/", response_model=List[Trend])
async def get_trends(category: Optional[str] = None, limit: int = 20):
    return await trend_service.get_current_trends(category=category, limit=limit)


@router.get("/analysis", response_model=TrendAnalysis)
async def get_trend_analysis():
    return await trend_service.analyze_trends()


@router.get("/{trend_id}", response_model=Trend)
async def get_trend(trend_id: str):
    trend = await trend_service.get_trend(trend_id)
    if not trend:
        raise HTTPException(status_code=404, detail="Trend not found")
    return trend
