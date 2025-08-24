from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from datetime import datetime

class TrendBase(BaseModel):
    name: str
    description: str
    category: str
    confidence_score: float

class Trend(TrendBase):
    id: str
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

class TrendAnalysis(BaseModel):
    top_trends: List[Trend]
    category_breakdown: Dict[str, int]
    confidence_distribution: Dict[str, float]
    analysis_date: datetime
