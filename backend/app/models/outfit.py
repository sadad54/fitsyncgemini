from datetime import datetime
from typing import Any, Dict, List, Optional

from pydantic import BaseModel


class Outfit(BaseModel):
    id: str
    user_id: str
    name: str
    item_ids: List[str] = []
    occasion: str
    weather_context: Optional[Dict[str, Any]] = None
    score: float
    explanation: str
    saved: bool = False
    favorited: bool = False
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class OutfitGenerateRequest(BaseModel):
    occasion: str
    use_weather: bool = False
    latitude: Optional[float] = None
    longitude: Optional[float] = None


class OutfitFeedback(BaseModel):
    rating: int
    reason: Optional[str] = None
