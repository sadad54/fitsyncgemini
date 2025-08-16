"""
Virtual Try-On Schemas
"""

from pydantic import BaseModel, Field, validator
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum

# Enums
class ViewModeEnum(str, Enum):
    AR = "ar"
    MIRROR = "mirror"

class TryOnStatusEnum(str, Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"

class ProcessingQualityEnum(str, Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"

# Base schemas
class TryOnFeatureBase(BaseModel):
    id: str = Field(..., pattern="^[a-z_]+$")
    name: str = Field(..., min_length=1, max_length=100)
    description: str = Field(..., min_length=1, max_length=500)
    is_premium: bool = False
    processing_cost: float = Field(0.0, ge=0.0)
    accuracy_improvement: float = Field(0.0, ge=0.0, le=1.0)

class TryOnFeatureResponse(TryOnFeatureBase):
    is_available: bool
    requires_gpu: bool
    min_device_capability: Optional[str] = None
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

# Session schemas
class TryOnSessionCreate(BaseModel):
    session_name: Optional[str] = Field(None, max_length=200)
    view_mode: ViewModeEnum = ViewModeEnum.AR
    device_info: Optional[Dict[str, Any]] = Field(None, description="Device capabilities and specs")

class TryOnSessionUpdate(BaseModel):
    status: Optional[TryOnStatusEnum] = None
    processing_progress: Optional[float] = Field(None, ge=0.0, le=1.0)
    error_message: Optional[str] = None
    result_image_url: Optional[str] = Field(None, max_length=500)
    confidence_score: Optional[float] = Field(None, ge=0.0, le=1.0)

class TryOnSessionResponse(BaseModel):
    id: str
    user_id: int
    session_name: Optional[str] = None
    view_mode: ViewModeEnum
    status: TryOnStatusEnum
    processing_progress: float
    error_message: Optional[str] = None
    result_image_url: Optional[str] = None
    confidence_score: Optional[float] = None
    processing_time_ms: Optional[int] = None
    created_at: datetime
    updated_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

# Outfit attempt schemas
class ClothingItemForTryOn(BaseModel):
    id: str
    name: str
    category: str
    image_url: str
    color: Optional[str] = None
    size: Optional[str] = None
    brand: Optional[str] = None

class TryOnOutfitAttemptCreate(BaseModel):
    outfit_name: str = Field(..., min_length=1, max_length=200)
    occasion: Optional[str] = Field(None, max_length=100)
    clothing_items: List[ClothingItemForTryOn] = Field(..., min_items=1)

class FitAnalysisDetail(BaseModel):
    item_id: str
    fit_score: float = Field(..., ge=0.0, le=1.0)
    size_recommendation: Optional[str] = None
    fit_issues: List[str] = Field(default_factory=list)
    measurements: Optional[Dict[str, float]] = None

class ColorAnalysisDetail(BaseModel):
    item_id: str
    color_accuracy: float = Field(..., ge=0.0, le=1.0)
    lighting_adjusted: bool = False
    recommended_lighting: Optional[str] = None

class TryOnOutfitAttemptUpdate(BaseModel):
    confidence_score: Optional[float] = Field(None, ge=0.0, le=1.0)
    fit_analysis: Optional[List[FitAnalysisDetail]] = None
    color_analysis: Optional[List[ColorAnalysisDetail]] = None
    style_score: Optional[float] = Field(None, ge=0.0, le=1.0)
    result_image_url: Optional[str] = Field(None, max_length=500)
    user_rating: Optional[int] = Field(None, ge=1, le=5)
    is_favorite: Optional[bool] = None

class TryOnOutfitAttemptResponse(BaseModel):
    id: str
    session_id: str
    outfit_name: str
    occasion: Optional[str] = None
    clothing_items: List[ClothingItemForTryOn]
    confidence_score: Optional[float] = None
    fit_analysis: Optional[List[FitAnalysisDetail]] = None
    color_analysis: Optional[List[ColorAnalysisDetail]] = None
    style_score: Optional[float] = None
    user_rating: Optional[int] = None
    is_favorite: bool = False
    is_shared: bool = False
    processing_time_ms: Optional[int] = None
    result_image_url: Optional[str] = None
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

# User preferences schemas
class TryOnPreferencesBase(BaseModel):
    default_view_mode: ViewModeEnum = ViewModeEnum.AR
    auto_save_results: bool = True
    share_anonymously: bool = False
    enabled_features: Dict[str, bool] = Field(default_factory=lambda: {
        "lighting": True,
        "fit": True,
        "movement": False
    })
    processing_quality: ProcessingQualityEnum = ProcessingQualityEnum.HIGH
    max_processing_time: int = Field(30, ge=5, le=120)
    store_images: bool = True
    allow_analytics: bool = True

class TryOnPreferencesCreate(TryOnPreferencesBase):
    pass

class TryOnPreferencesUpdate(BaseModel):
    default_view_mode: Optional[ViewModeEnum] = None
    auto_save_results: Optional[bool] = None
    share_anonymously: Optional[bool] = None
    enabled_features: Optional[Dict[str, bool]] = None
    processing_quality: Optional[ProcessingQualityEnum] = None
    max_processing_time: Optional[int] = Field(None, ge=5, le=120)
    store_images: Optional[bool] = None
    allow_analytics: Optional[bool] = None

class TryOnPreferencesResponse(TryOnPreferencesBase):
    id: int
    user_id: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

# API Response schemas
class TryOnDashboardResponse(BaseModel):
    """Dashboard data for try-on screen"""
    recent_sessions: List[TryOnSessionResponse]
    available_features: List[TryOnFeatureResponse]
    user_preferences: TryOnPreferencesResponse
    quick_outfits: List[Dict[str, Any]]  # Pre-configured outfit suggestions
    stats: Dict[str, Any]  # Usage statistics

class TryOnProcessingResponse(BaseModel):
    """Real-time processing status"""
    session_id: str
    status: TryOnStatusEnum
    progress: float = Field(..., ge=0.0, le=1.0)
    estimated_completion_seconds: Optional[int] = None
    current_step: Optional[str] = None
    error_message: Optional[str] = None

# Outfit suggestions for try-on
class QuickOutfitSuggestion(BaseModel):
    id: str
    name: str
    occasion: str
    items: List[str]  # Item names
    confidence: float = Field(..., ge=0.0, le=1.0)
    preview_image_url: Optional[str] = None
    estimated_processing_time: int  # seconds

class TryOnRecommendationsResponse(BaseModel):
    """Outfit recommendations optimized for try-on"""
    quick_suggestions: List[QuickOutfitSuggestion]
    user_wardrobe_combinations: List[QuickOutfitSuggestion]
    trending_looks: List[QuickOutfitSuggestion]
    weather_appropriate: List[QuickOutfitSuggestion]

# Analytics schemas
class TryOnAnalyticsCreate(BaseModel):
    session_id: str
    total_outfits_tried: int = 0
    session_duration_seconds: Optional[int] = None
    user_interactions: Optional[Dict[str, Any]] = None
    session_rating: Optional[int] = Field(None, ge=1, le=5)

class DeviceCapabilities(BaseModel):
    """Device capability information for optimal try-on experience"""
    camera_resolution: Optional[str] = None
    has_depth_sensor: bool = False
    cpu_cores: Optional[int] = None
    ram_gb: Optional[float] = None
    gpu_available: bool = False
    ar_support: bool = False
    platform: str  # ios, android, web
    
    @validator('platform')
    def validate_platform(cls, v):
        allowed_platforms = ['ios', 'android', 'web']
        if v.lower() not in allowed_platforms:
            raise ValueError(f'Platform must be one of {allowed_platforms}')
        return v.lower()

# Error responses
class TryOnErrorResponse(BaseModel):
    error_code: str
    error_message: str
    retry_after_seconds: Optional[int] = None
    suggested_actions: List[str] = Field(default_factory=list)

# Batch processing schemas
class BatchTryOnRequest(BaseModel):
    session_id: str
    outfits: List[TryOnOutfitAttemptCreate]
    priority: str = Field("normal", pattern="^(low|normal|high)$")
    
class BatchTryOnResponse(BaseModel):
    batch_id: str
    session_id: str
    total_outfits: int
    estimated_completion_time: int  # seconds
    status: str
    created_at: datetime
