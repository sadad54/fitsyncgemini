from fastapi import Depends
from sqlalchemy.orm import Session
from app.database import get_db
from app.services.ml_service import MLService
from app.services.recommendation_service import RecommendationService
from app.services.social_service import SocialService

def get_ml_service() -> MLService:
    """Dependency injection for ML service"""
    # In production, this would be a singleton or cached instance
    return MLService()

def get_recommendation_service(
    ml_service: MLService = Depends(get_ml_service),
    db: Session = Depends(get_db)
) -> RecommendationService:
    """Dependency injection for recommendation service"""
    return RecommendationService(ml_service, db)

def get_social_service(db: Session = Depends(get_db)) -> SocialService:
    """Dependency injection for social service"""
    return SocialService(db)

# 6. app/schemas/clothing.py (Pydantic models)
from pydantic import BaseModel, Field
from typing import List, Dict, Optional, Any
from datetime import datetime

class ColorAnalysis(BaseModel):
    dominant_colors: List[str] = Field(..., description="Hex color codes")
    color_names: List[str] = Field(..., description="Human-readable color names")
    harmony_score: float = Field(..., ge=0, le=1, description="Color harmony score")
    seasonal_compatibility: Dict[str, float] = Field(..., description="Seasonal palette scores")
    color_temperature: str = Field(..., description="warm, cool, or neutral")

class StyleAttributes(BaseModel):
    pattern: str = Field(..., description="Pattern type")
    material: str = Field(..., description="Material type")
    formality: str = Field(..., description="Formality level")
    style: str = Field(..., description="Style category")
    sleeve_length: Optional[str] = None
    neckline: Optional[str] = None
    fit: Optional[str] = None

class ClothingItem(BaseModel):
    category: str = Field(..., description="Clothing category")
    confidence: float = Field(..., ge=0, le=1, description="Detection confidence")
    bbox: List[float] = Field(..., description="Bounding box coordinates")
    attributes: StyleAttributes
    style_scores: Dict[str, float] = Field(..., description="Style compatibility scores")
    occasions: List[str] = Field(..., description="Appropriate occasions")

class ClothingAnalysis(BaseModel):
    detected_items: List[ClothingItem]
    total_items: int
    analysis_metadata: Dict[str, Any]
    color_analysis: Optional[ColorAnalysis] = None

class StyleAnalysis(BaseModel):
    style_archetype: str = Field(..., description="Primary style archetype")
    confidence: float = Field(..., ge=0, le=1)
    secondary_styles: List[Dict[str, float]] = Field(..., description="Secondary style matches")
    personality_traits: List[str] = Field(..., description="Associated personality traits")
    recommendations: List[str] = Field(..., description="Style recommendations")
    color_palette: Optional[ColorAnalysis] = None

class BodyTypeAnalysis(BaseModel):
    body_type: str = Field(..., description="Detected body type")
    confidence: float = Field(..., ge=0, le=1)
    measurements: Dict[str, float] = Field(..., description="Estimated measurements")
    recommendations: List[str] = Field(..., description="Style recommendations for body type")
