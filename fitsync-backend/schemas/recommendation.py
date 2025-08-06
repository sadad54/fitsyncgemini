from pydantic import BaseModel
from typing import List, Dict, Optional
from datetime import datetime
class OutfitItem(BaseModel):
    id: str = Field(..., description="Item identifier")
    name: str = Field(..., description="Item name")
    category: str = Field(..., description="Item category")
    image_url: Optional[str] = Field(None, description="Item image URL")
    brand: Optional[str] = Field(None, description="Brand name")
    price: Optional[float] = Field(None, description="Item price")

class StyleScores(BaseModel):
    style_compatibility: float = Field(..., ge=0, le=1)
    color_harmony: float = Field(..., ge=0, le=1)
    occasion_appropriateness: float = Field(..., ge=0, le=1)
    personal_preference: float = Field(..., ge=0, le=1)

class OutfitRecommendation(BaseModel):
    id: str = Field(..., description="Recommendation identifier")
    name: str = Field(..., description="Outfit name")
    items: List[str] = Field(..., description="List of item IDs")
    style_scores: StyleScores = Field(..., description="Detailed scoring")
    total_score: float = Field(..., ge=0, le=1, description="Overall compatibility score")
    description: str = Field(..., description="Outfit description")
    tags: List[str] = Field(..., description="Outfit tags")
    occasion: Optional[str] = Field(None, description="Recommended occasion")
    weather_suitability: Optional[Dict[str, bool]] = Field(None, description="Weather conditions")
    estimated_cost: Optional[float] = Field(None, description="Estimated total cost")
    sustainability_score: Optional[float] = Field(None, description="Environmental impact score")

class SimilarStyleRecommendation(BaseModel):
    id: str = Field(..., description="Recommendation identifier")
    similarity_score: float = Field(..., ge=0, le=1, description="Similarity to reference")
    outfit: OutfitRecommendation = Field(..., description="Similar outfit recommendation")
    differences: List[str] = Field(..., description="Key differences from reference")
    inspiration_source: Optional[str] = Field(None, description="Source of inspiration")
