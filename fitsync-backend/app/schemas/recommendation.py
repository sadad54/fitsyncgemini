from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum

class RecommendationTypeEnum(str, Enum):
    OUTFIT = "outfit"
    ITEM = "item"
    STYLE = "style"
    TREND = "trend"
    COLOR = "color"
    ACCESSORY = "accessory"

class RecommendationSourceEnum(str, Enum):
    COLLABORATIVE = "collaborative"
    CONTENT_BASED = "content_based"
    HYBRID = "hybrid"
    TREND_BASED = "trend_based"
    WEATHER_BASED = "weather_based"
    OCCASION_BASED = "occasion_based"

class TrendCategoryEnum(str, Enum):
    COLOR = "color"
    STYLE = "style"
    PATTERN = "pattern"
    ITEM = "item"
    ACCESSORY = "accessory"
    FABRIC = "fabric"

# Recommendation schemas
class RecommendationBase(BaseModel):
    recommendation_type: RecommendationTypeEnum
    source: RecommendationSourceEnum
    confidence_score: float = Field(..., ge=0, le=1)
    reasoning: Optional[str] = Field(None, max_length=1000)
    metadata: Optional[Dict[str, Any]] = None

class OutfitRecommendation(RecommendationBase):
    outfit_id: int
    style_score: float = Field(..., ge=0, le=1)
    color_harmony_score: float = Field(..., ge=0, le=1)
    body_type_compatibility: Dict[str, float]
    occasion_suitability: Dict[str, float]
    weather_suitability: Optional[Dict[str, float]] = None
    sustainability_score: Optional[float] = Field(None, ge=0, le=1)

class ItemRecommendation(RecommendationBase):
    item_id: int
    category: str
    subcategory: Optional[str] = None
    brand: Optional[str] = None
    price_range: Optional[Dict[str, float]] = None
    style_compatibility: float = Field(..., ge=0, le=1)
    color_compatibility: float = Field(..., ge=0, le=1)
    fit_compatibility: float = Field(..., ge=0, le=1)

class StyleRecommendation(RecommendationBase):
    style_archetype: str
    style_description: str
    key_elements: List[str]
    color_palette: List[str]
    outfit_examples: List[int]  # List of outfit IDs
    confidence_breakdown: Dict[str, float]

class TrendRecommendation(RecommendationBase):
    trend_name: str
    trend_category: TrendCategoryEnum
    trend_description: str
    popularity_score: float = Field(..., ge=0, le=1)
    predicted_lifespan: int  # Days
    adoption_rate: float = Field(..., ge=0, le=1)
    related_items: List[int]  # List of item IDs

class RecommendationRequest(BaseModel):
    user_id: int
    recommendation_type: RecommendationTypeEnum
    context: Optional[Dict[str, Any]] = None
    filters: Optional[Dict[str, Any]] = None
    limit: int = Field(10, ge=1, le=50)

class RecommendationResponse(BaseModel):
    recommendations: List[Dict[str, Any]]
    total_count: int
    processing_time: float
    algorithm_used: str
    confidence_threshold: float

# Social schemas
class FashionChallengeBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=2000)
    challenge_type: str = Field(..., max_length=50)
    theme: Optional[str] = Field(None, max_length=100)
    requirements: Optional[Dict[str, Any]] = None
    start_date: datetime
    end_date: datetime
    max_participants: Optional[int] = Field(None, ge=1)
    prize_description: Optional[str] = Field(None, max_length=1000)
    hashtag: Optional[str] = Field(None, max_length=100)
    is_featured: bool = False

class FashionChallengeCreate(FashionChallengeBase):
    pass

class FashionChallengeUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=2000)
    challenge_type: Optional[str] = Field(None, max_length=50)
    theme: Optional[str] = Field(None, max_length=100)
    requirements: Optional[Dict[str, Any]] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    max_participants: Optional[int] = Field(None, ge=1)
    prize_description: Optional[str] = Field(None, max_length=1000)
    hashtag: Optional[str] = Field(None, max_length=100)
    is_featured: Optional[bool] = None

class FashionChallengeResponse(FashionChallengeBase):
    id: int
    created_by: Optional[int] = None
    current_participants: int
    status: str
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

class ChallengeSubmissionBase(BaseModel):
    title: Optional[str] = Field(None, max_length=200)
    description: Optional[str] = Field(None, max_length=2000)
    image_url: Optional[str] = Field(None, max_length=500)
    tags: Optional[List[str]] = Field(None, max_items=20)

class ChallengeSubmissionCreate(ChallengeSubmissionBase):
    challenge_id: int
    outfit_id: int

class ChallengeSubmissionResponse(ChallengeSubmissionBase):
    id: int
    challenge_id: int
    user_id: int
    outfit_id: int
    votes_count: int
    score: float
    is_winner: bool
    is_approved: bool
    is_featured: bool
    submitted_at: datetime
    
    class Config:
        from_attributes = True

class ChallengeVoteBase(BaseModel):
    vote_score: float = Field(..., ge=1, le=5)
    comment: Optional[str] = Field(None, max_length=1000)

class ChallengeVoteCreate(ChallengeVoteBase):
    submission_id: int

class ChallengeVoteResponse(ChallengeVoteBase):
    id: int
    submission_id: int
    voter_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

# Style post schemas
class StylePostBase(BaseModel):
    title: Optional[str] = Field(None, max_length=200)
    caption: Optional[str] = Field(None, max_length=2000)
    hashtags: Optional[List[str]] = Field(None, max_items=30)
    location: Optional[str] = Field(None, max_length=200)
    latitude: Optional[float] = Field(None, ge=-90, le=90)
    longitude: Optional[float] = Field(None, ge=-180, le=180)
    is_public: bool = True

class StylePostCreate(StylePostBase):
    outfit_id: int

class StylePostUpdate(BaseModel):
    title: Optional[str] = Field(None, max_length=200)
    caption: Optional[str] = Field(None, max_length=2000)
    hashtags: Optional[List[str]] = Field(None, max_items=30)
    location: Optional[str] = Field(None, max_length=200)
    latitude: Optional[float] = Field(None, ge=-90, le=90)
    longitude: Optional[float] = Field(None, ge=-180, le=180)
    is_public: Optional[bool] = None

class StylePostResponse(StylePostBase):
    id: int
    user_id: int
    outfit_id: int
    likes_count: int
    comments_count: int
    shares_count: int
    views_count: int
    is_featured: bool
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

class PostLikeBase(BaseModel):
    pass

class PostLikeCreate(PostLikeBase):
    post_id: int

class PostLikeResponse(PostLikeBase):
    id: int
    post_id: int
    user_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

class PostCommentBase(BaseModel):
    content: str = Field(..., min_length=1, max_length=1000)

class PostCommentCreate(PostCommentBase):
    post_id: int
    parent_comment_id: Optional[int] = None

class PostCommentResponse(PostCommentBase):
    id: int
    post_id: int
    user_id: int
    parent_comment_id: Optional[int] = None
    likes_count: int
    is_edited: bool
    is_deleted: bool
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

# Style inspiration schemas
class StyleInspirationBase(BaseModel):
    title: Optional[str] = Field(None, max_length=200)
    description: Optional[str] = Field(None, max_length=2000)
    image_url: Optional[str] = Field(None, max_length=500)
    source_url: Optional[str] = Field(None, max_length=500)
    tags: Optional[List[str]] = Field(None, max_items=20)
    style_archetype: Optional[str] = Field(None, max_length=100)
    color_palette: Optional[List[str]] = Field(None, max_items=20)
    occasion: Optional[str] = Field(None, max_length=100)
    season: Optional[str] = Field(None, max_length=100)
    is_public: bool = True

class StyleInspirationCreate(StyleInspirationBase):
    pass

class StyleInspirationUpdate(BaseModel):
    title: Optional[str] = Field(None, max_length=200)
    description: Optional[str] = Field(None, max_length=2000)
    image_url: Optional[str] = Field(None, max_length=500)
    source_url: Optional[str] = Field(None, max_length=500)
    tags: Optional[List[str]] = Field(None, max_items=20)
    style_archetype: Optional[str] = Field(None, max_length=100)
    color_palette: Optional[List[str]] = Field(None, max_items=20)
    occasion: Optional[str] = Field(None, max_length=100)
    season: Optional[str] = Field(None, max_length=100)
    is_public: Optional[bool] = None

class StyleInspirationResponse(StyleInspirationBase):
    id: int
    user_id: int
    likes_count: int
    saves_count: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

# Fashion trend schemas
class FashionTrendBase(BaseModel):
    trend_name: str = Field(..., min_length=1, max_length=200)
    trend_description: Optional[str] = Field(None, max_length=2000)
    trend_category: TrendCategoryEnum
    trend_data: Optional[Dict[str, Any]] = None
    popularity_score: float = Field(..., ge=0, le=1)
    growth_rate: float = Field(..., ge=-1, le=1)
    seasonality: Optional[Dict[str, Any]] = None
    geographic_spread: Optional[Dict[str, Any]] = None
    demographic_data: Optional[Dict[str, Any]] = None
    social_mentions: int = 0
    hashtag_count: int = 0
    influencer_adoption: float = Field(0, ge=0, le=1)
    predicted_lifespan: Optional[int] = Field(None, ge=1)
    confidence_level: float = Field(..., ge=0, le=1)

class FashionTrendCreate(FashionTrendBase):
    pass

class FashionTrendUpdate(BaseModel):
    trend_name: Optional[str] = Field(None, min_length=1, max_length=200)
    trend_description: Optional[str] = Field(None, max_length=2000)
    trend_category: Optional[TrendCategoryEnum] = None
    trend_data: Optional[Dict[str, Any]] = None
    popularity_score: Optional[float] = Field(None, ge=0, le=1)
    growth_rate: Optional[float] = Field(None, ge=-1, le=1)
    seasonality: Optional[Dict[str, Any]] = None
    geographic_spread: Optional[Dict[str, Any]] = None
    demographic_data: Optional[Dict[str, Any]] = None
    social_mentions: Optional[int] = Field(None, ge=0)
    hashtag_count: Optional[int] = Field(None, ge=0)
    influencer_adoption: Optional[float] = Field(None, ge=0, le=1)
    predicted_lifespan: Optional[int] = Field(None, ge=1)
    confidence_level: Optional[float] = Field(None, ge=0, le=1)
    is_active: Optional[bool] = None

class FashionTrendResponse(FashionTrendBase):
    id: int
    first_detected: datetime
    last_updated: Optional[datetime] = None
    is_active: bool
    
    class Config:
        from_attributes = True

# Search and filter schemas
class RecommendationSearchParams(BaseModel):
    recommendation_type: Optional[RecommendationTypeEnum] = None
    source: Optional[RecommendationSourceEnum] = None
    min_confidence: Optional[float] = Field(None, ge=0, le=1)
    max_confidence: Optional[float] = Field(None, ge=0, le=1)
    limit: int = Field(20, ge=1, le=100)
    offset: int = Field(0, ge=0)

class ChallengeSearchParams(BaseModel):
    challenge_type: Optional[str] = None
    status: Optional[str] = None
    is_featured: Optional[bool] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    limit: int = Field(20, ge=1, le=100)
    offset: int = Field(0, ge=0)

class PostSearchParams(BaseModel):
    hashtags: Optional[List[str]] = Field(None, max_items=10)
    location: Optional[str] = None
    is_public: Optional[bool] = None
    is_featured: Optional[bool] = None
    min_likes: Optional[int] = Field(None, ge=0)
    limit: int = Field(20, ge=1, le=100)
    offset: int = Field(0, ge=0)

class TrendSearchParams(BaseModel):
    trend_category: Optional[TrendCategoryEnum] = None
    min_popularity: Optional[float] = Field(None, ge=0, le=1)
    max_popularity: Optional[float] = Field(None, ge=0, le=1)
    is_active: Optional[bool] = None
    limit: int = Field(20, ge=1, le=100)
    offset: int = Field(0, ge=0)

# Statistics schemas
class RecommendationStats(BaseModel):
    total_recommendations: int
    recommendations_by_type: Dict[str, int]
    average_confidence: float
    most_popular_recommendations: List[Dict[str, Any]]
    user_engagement_rate: float

class SocialStats(BaseModel):
    total_challenges: int
    active_challenges: int
    total_submissions: int
    total_posts: int
    total_inspirations: int
    average_engagement_rate: float
    top_performing_content: List[Dict[str, Any]]

class TrendStats(BaseModel):
    total_trends: int
    active_trends: int
    trending_categories: Dict[str, int]
    average_lifespan: float
    top_trending_items: List[Dict[str, Any]]
