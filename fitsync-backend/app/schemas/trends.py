"""
Trends and Fashion Data Schemas
"""

from pydantic import BaseModel, Field, validator
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum

class TrendDirectionEnum(str, Enum):
    UP = "up"
    DOWN = "down"
    STABLE = "stable"

class LocationTypeEnum(str, Enum):
    PERSON = "person"
    EVENT = "event"
    HOTSPOT = "hotspot"

class ContentTypeEnum(str, Enum):
    STYLE_POST = "style_post"
    OUTFIT = "outfit"
    LOOKBOOK = "lookbook"

# Fashion Trend Schemas
class FashionTrendBase(BaseModel):
    trend_name: str = Field(..., min_length=1, max_length=200)
    trend_description: Optional[str] = None
    category: str = Field(..., max_length=50)
    popularity_score: float = Field(0.0, ge=0.0, le=1.0)
    growth_rate: float = Field(0.0, ge=-1.0, le=1.0)
    direction: TrendDirectionEnum = TrendDirectionEnum.STABLE
    engagement: int = Field(0, ge=0)
    posts_count: int = Field(0, ge=0)
    tags: Optional[List[str]] = Field(None, max_items=20)
    image_url: Optional[str] = Field(None, max_length=500)

class FashionTrendCreate(FashionTrendBase):
    pass

class FashionTrendResponse(FashionTrendBase):
    id: int
    social_mentions: int
    hashtag_count: int
    confidence_level: float
    is_active: bool
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

# Style Influencer Schemas
class StyleInfluencerBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    handle: str = Field(..., min_length=1, max_length=100)
    bio: Optional[str] = Field(None, max_length=1000)
    profile_image_url: Optional[str] = Field(None, max_length=500)
    followers_count: int = Field(0, ge=0)
    engagement_rate: float = Field(0.0, ge=0.0, le=1.0)
    trend_setter_type: Optional[str] = Field(None, max_length=100)
    recent_trend: Optional[str] = Field(None, max_length=200)
    location: Optional[str] = Field(None, max_length=200)
    scope: str = Field("global", pattern="^(global|local)$")

class StyleInfluencerCreate(StyleInfluencerBase):
    pass

class StyleInfluencerResponse(StyleInfluencerBase):
    id: int
    influence_score: float
    is_active: bool
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

# Explore Content Schemas
class ExploreContentBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    content_type: ContentTypeEnum = ContentTypeEnum.STYLE_POST
    author_name: str = Field(..., min_length=1, max_length=100)
    author_avatar_url: Optional[str] = Field(None, max_length=500)
    description: Optional[str] = Field(None, max_length=2000)
    image_url: str = Field(..., max_length=500)
    tags: Optional[List[str]] = Field(None, max_items=20)
    category: Optional[str] = Field(None, max_length=50)
    style_archetype: Optional[str] = Field(None, max_length=50)

class ExploreContentCreate(ExploreContentBase):
    author_id: int

class ExploreContentResponse(ExploreContentBase):
    id: int
    author_id: Optional[int] = None
    likes_count: int
    views_count: int
    shares_count: int
    comments_count: int
    is_trending: bool
    trending_score: float
    is_public: bool
    is_featured: bool
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

# Nearby Location Schemas
class NearbyLocationBase(BaseModel):
    location_type: LocationTypeEnum
    name: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=1000)
    image_url: Optional[str] = Field(None, max_length=500)
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    address: Optional[str] = Field(None, max_length=500)
    city: Optional[str] = Field(None, max_length=100)
    country: Optional[str] = Field(None, max_length=100)
    location_metadata: Optional[Dict[str, Any]] = None

class NearbyLocationCreate(NearbyLocationBase):
    user_id: Optional[int] = None
    expires_at: Optional[datetime] = None

class NearbyLocationResponse(NearbyLocationBase):
    id: int
    user_id: Optional[int] = None
    is_active: bool
    is_public: bool
    created_at: datetime
    updated_at: Optional[datetime] = None
    expires_at: Optional[datetime] = None
    
    # Computed field for distance (added by service layer)
    distance: Optional[str] = None
    
    class Config:
        from_attributes = True

# Trend Insight Schemas
class TrendInsightBase(BaseModel):
    category: str = Field(..., max_length=50)
    trending_items: List[str] = Field(..., max_items=20)
    declining_items: List[str] = Field(..., max_items=20)
    scope: str = Field("global", pattern="^(global|local)$")
    timeframe: str = Field("week", pattern="^(day|week|month)$")
    confidence_score: float = Field(0.0, ge=0.0, le=1.0)

class TrendInsightCreate(TrendInsightBase):
    data_points: int = Field(0, ge=0)
    valid_until: datetime

class TrendInsightResponse(TrendInsightBase):
    id: int
    data_points: int
    created_at: datetime
    valid_until: datetime
    
    class Config:
        from_attributes = True

# API Response Schemas (matching frontend models)
class OutfitSuggestionItem(BaseModel):
    id: str
    name: str
    category: str
    imageUrl: str
    isMain: bool = False

class WeatherInfo(BaseModel):
    temperature: float
    condition: str
    unit: str = "°C"

class OutfitSuggestionResponse(BaseModel):
    id: str
    name: str
    occasion: str
    items: List[OutfitSuggestionItem]
    matchPercentage: float = Field(..., ge=0.0, le=1.0)
    description: str
    weatherInfo: WeatherInfo
    isFavorite: bool = False

class StyleFocusResponse(BaseModel):
    title: str
    description: str
    weatherInfo: WeatherInfo
    recommendations: List[str]

class OutfitRecommendationsResponse(BaseModel):
    suggestions: List[OutfitSuggestionResponse]
    styleFocus: StyleFocusResponse

class TrendingStyleResponse(BaseModel):
    name: str
    growth: str
    color: str

class ExploreItemResponse(BaseModel):
    id: int
    title: str
    author: str
    authorAvatar: str
    likes: int
    views: int
    tags: List[str]
    image: str
    trending: bool

class TrendingNowResponse(BaseModel):
    id: str
    title: str
    growth: str
    trend: TrendDirectionEnum
    description: str
    image: str
    tags: List[str]
    engagement: int
    posts: int

class FashionInsightResponse(BaseModel):
    category: str
    trending: List[str]
    declining: List[str]

class InfluencerSpotlightResponse(BaseModel):
    id: str
    name: str
    handle: str
    trendSetter: str
    followers: str
    engagement: str
    recentTrend: str

class NearbyPersonResponse(BaseModel):
    id: str
    name: str
    avatar: str
    distance: str
    style: str
    mutualConnections: int
    recentOutfit: str
    isOnline: bool
    latitude: float
    longitude: float

class NearbyEventResponse(BaseModel):
    id: str
    title: str
    location: str
    distance: str
    date: str
    attendees: int
    image: str
    category: str
    latitude: float
    longitude: float

class NearbyHotspotResponse(BaseModel):
    id: str
    name: str
    type: str
    distance: str
    popularStyles: List[str]
    rating: float
    checkIns: int
    latitude: float
    longitude: float

class NearbyMapResponse(BaseModel):
    center: Dict[str, float]  # {"latitude": float, "longitude": float}
    people: List[NearbyPersonResponse]
    events: List[NearbyEventResponse]
    hotspots: List[NearbyHotspotResponse]
