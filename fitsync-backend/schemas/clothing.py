from pydantic import BaseModel, Field
from typing import List, Dict, Optional, Any
from datetime import datetime

class BoundingBox(BaseModel):
    x1: float = Field(..., description="Left coordinate")
    y1: float = Field(..., description="Top coordinate") 
    x2: float = Field(..., description="Right coordinate")
    y2: float = Field(..., description="Bottom coordinate")

class ClothingAttributes(BaseModel):
    color: Dict[str, Any] = Field(..., description="Color analysis results")
    pattern: str = Field(..., description="Pattern type (solid, striped, etc.)")
    material: str = Field(..., description="Estimated material type")
    style: str = Field(..., description="Style classification")
    formality: str = Field(..., description="Formality level")
    season_compatibility: List[str] = Field(..., description="Suitable seasons")

class ClothingItem(BaseModel):
    category: str = Field(..., description="Clothing category")
    confidence: float = Field(..., ge=0, le=1, description="Detection confidence")
    bbox: BoundingBox = Field(..., description="Bounding box coordinates")
    attributes: ClothingAttributes = Field(..., description="Detailed attributes")
    style_scores: Dict[str, float] = Field(..., description="Style compatibility scores")
    occasions: List[str] = Field(..., description="Appropriate occasions")

class ClothingAnalysis(BaseModel):
    detected_items: List[ClothingItem] = Field(..., description="Detected clothing items")
    total_items: int = Field(..., description="Total number of detected items")
    analysis_metadata: Dict[str, Any] = Field(..., description="Analysis metadata")
    processing_time_ms: Optional[float] = Field(None, description="Processing time in milliseconds")

class StyleAnalysis(BaseModel):
    style_archetype: str = Field(..., description="Dominant style archetype")
    confidence: float = Field(..., ge=0, le=1, description="Classification confidence")
    secondary_styles: List[Dict[str, float]] = Field(..., description="Secondary style influences")
    personality_traits: List[str] = Field(..., description="Associated personality traits")
    recommended_colors: List[str] = Field(..., description="Recommended color palette")
    style_evolution_suggestions: List[str] = Field(..., description="Style development suggestions")
