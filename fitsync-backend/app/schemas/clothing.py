from pydantic import BaseModel, Field, validator
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum

class ClothingCategoryEnum(str, Enum):
    TOPS = "tops"
    BOTTOMS = "bottoms"
    DRESSES = "dresses"
    OUTERWEAR = "outerwear"
    SHOES = "shoes"
    ACCESSORIES = "accessories"
    UNDERWEAR = "underwear"
    SWIMWEAR = "swimwear"
    ACTIVEWEAR = "activewear"
    FORMALWEAR = "formalwear"

class ClothingSubcategoryEnum(str, Enum):
    # Tops
    T_SHIRTS = "t_shirts"
    SHIRTS = "shirts"
    BLOUSES = "blouses"
    SWEATERS = "sweaters"
    HOODIES = "hoodies"
    TANK_TOPS = "tank_tops"
    
    # Bottoms
    JEANS = "jeans"
    PANTS = "pants"
    SHORTS = "shorts"
    SKIRTS = "skirts"
    LEGGINGS = "leggings"
    
    # Dresses
    CASUAL_DRESSES = "casual_dresses"
    FORMAL_DRESSES = "formal_dresses"
    MAXI_DRESSES = "maxi_dresses"
    MINI_DRESSES = "mini_dresses"
    
    # Outerwear
    JACKETS = "jackets"
    COATS = "coats"
    BLAZERS = "blazers"
    CARDIGANS = "cardigans"
    
    # Shoes
    SNEAKERS = "sneakers"
    BOOTS = "boots"
    HEELS = "heels"
    FLATS = "flats"
    SANDALS = "sandals"
    
    # Accessories
    BAGS = "bags"
    JEWELRY = "jewelry"
    SCARVES = "scarves"
    BELTS = "belts"
    HATS = "hats"

class SeasonEnum(str, Enum):
    SPRING = "spring"
    SUMMER = "summer"
    FALL = "fall"
    WINTER = "winter"
    ALL_SEASON = "all_season"

class OccasionEnum(str, Enum):
    CASUAL = "casual"
    BUSINESS = "business"
    FORMAL = "formal"
    SPORTY = "sporty"
    EVENING = "evening"
    BEACH = "beach"
    OUTDOOR = "outdoor"
    PARTY = "party"

# Clothing item schemas
class ClothingItemBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=200)
    category: ClothingCategoryEnum
    subcategory: Optional[ClothingSubcategoryEnum] = None
    brand: Optional[str] = Field(None, max_length=100)
    color: Optional[str] = Field(None, max_length=50)
    color_hex: Optional[str] = Field(None, pattern="^#[0-9A-Fa-f]{6}$")
    pattern: Optional[str] = Field(None, max_length=100)
    material: Optional[str] = Field(None, max_length=100)
    size: Optional[str] = Field(None, max_length=20)
    price: Optional[float] = Field(None, ge=0)
    purchase_date: Optional[datetime] = None
    
    # Style attributes
    seasons: Optional[List[SeasonEnum]] = Field(None, max_items=4)
    occasions: Optional[List[OccasionEnum]] = Field(None, max_items=8)
    style_tags: Optional[List[str]] = Field(None, max_items=20)
    fit_type: Optional[str] = Field(None, max_length=50)
    neckline: Optional[str] = Field(None, max_length=50)
    sleeve_type: Optional[str] = Field(None, max_length=50)
    length: Optional[str] = Field(None, max_length=50)

class ClothingItemCreate(ClothingItemBase):
    image_url: Optional[str] = Field(None, max_length=500)
    thumbnail_url: Optional[str] = Field(None, max_length=500)

class ClothingItemUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=200)
    category: Optional[ClothingCategoryEnum] = None
    subcategory: Optional[ClothingSubcategoryEnum] = None
    brand: Optional[str] = Field(None, max_length=100)
    color: Optional[str] = Field(None, max_length=50)
    color_hex: Optional[str] = Field(None, pattern="^#[0-9A-Fa-f]{6}$")
    pattern: Optional[str] = Field(None, max_length=100)
    material: Optional[str] = Field(None, max_length=100)
    size: Optional[str] = Field(None, max_length=20)
    price: Optional[float] = Field(None, ge=0)
    purchase_date: Optional[datetime] = None
    image_url: Optional[str] = Field(None, max_length=500)
    thumbnail_url: Optional[str] = Field(None, max_length=500)
    seasons: Optional[List[SeasonEnum]] = Field(None, max_items=4)
    occasions: Optional[List[OccasionEnum]] = Field(None, max_items=8)
    style_tags: Optional[List[str]] = Field(None, max_items=20)
    fit_type: Optional[str] = Field(None, max_length=50)
    neckline: Optional[str] = Field(None, max_length=50)
    sleeve_type: Optional[str] = Field(None, max_length=50)
    length: Optional[str] = Field(None, max_length=50)
    is_favorite: Optional[bool] = None
    is_active: Optional[bool] = None

class ClothingItemResponse(ClothingItemBase):
    id: int
    owner_id: int
    image_url: Optional[str] = None
    thumbnail_url: Optional[str] = None
    
    # ML analysis results
    detected_attributes: Optional[Dict[str, Any]] = None
    color_analysis: Optional[Dict[str, Any]] = None
    style_classification: Optional[Dict[str, Any]] = None
    body_type_compatibility: Optional[Dict[str, Any]] = None
    
    # Metadata
    is_favorite: bool
    is_active: bool
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

# Outfit schemas
class OutfitCombinationBase(BaseModel):
    name: Optional[str] = Field(None, max_length=200)
    description: Optional[str] = Field(None, max_length=1000)
    style_archetype: Optional[str] = Field(None, max_length=100)
    occasion: Optional[OccasionEnum] = None
    season: Optional[SeasonEnum] = None
    style_tags: Optional[List[str]] = Field(None, max_items=20)
    is_public: bool = False

class OutfitCombinationCreate(OutfitCombinationBase):
    item_ids: List[int] = Field(..., min_items=1, max_items=20)

class OutfitCombinationUpdate(BaseModel):
    name: Optional[str] = Field(None, max_length=200)
    description: Optional[str] = Field(None, max_length=1000)
    style_archetype: Optional[str] = Field(None, max_length=100)
    occasion: Optional[OccasionEnum] = None
    season: Optional[SeasonEnum] = None
    style_tags: Optional[List[str]] = Field(None, max_items=20)
    is_public: Optional[bool] = None

class OutfitCombinationResponse(OutfitCombinationBase):
    id: int
    user_id: int
    
    # ML analysis
    style_score: Optional[float] = None
    color_harmony_score: Optional[float] = None
    body_type_compatibility: Optional[Dict[str, Any]] = None
    color_scheme: Optional[Dict[str, Any]] = None
    
    # Social features
    likes_count: int
    shares_count: int
    
    # Metadata
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

class OutfitWithItems(OutfitCombinationResponse):
    items: List[ClothingItemResponse] = []

# Outfit item schemas
class OutfitItemBase(BaseModel):
    position_order: Optional[int] = Field(None, ge=0)

class OutfitItemCreate(OutfitItemBase):
    clothing_item_id: int

class OutfitItemResponse(OutfitItemBase):
    id: int
    outfit_id: int
    clothing_item_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

# Outfit rating schemas
class OutfitRatingBase(BaseModel):
    rating: float = Field(..., ge=1, le=5)
    comment: Optional[str] = Field(None, max_length=1000)
    rating_categories: Optional[Dict[str, float]] = None

class OutfitRatingCreate(OutfitRatingBase):
    pass

class OutfitRatingResponse(OutfitRatingBase):
    id: int
    outfit_id: int
    rater_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

# Style attributes schemas
class StyleAttributesBase(BaseModel):
    attribute_type: str = Field(..., max_length=50)
    attribute_name: str = Field(..., max_length=100)
    attribute_value: str = Field(..., max_length=200)
    confidence_score: float = Field(..., ge=0, le=1)

class StyleAttributesCreate(StyleAttributesBase):
    clothing_item_id: int

class StyleAttributesResponse(StyleAttributesBase):
    id: int
    clothing_item_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

# Virtual try-on schemas
class VirtualTryOnBase(BaseModel):
    outfit_id: int
    user_image_url: Optional[str] = Field(None, max_length=500)

class VirtualTryOnCreate(VirtualTryOnBase):
    pass

class VirtualTryOnResponse(VirtualTryOnBase):
    id: int
    user_id: int
    result_image_url: Optional[str] = None
    status: str
    processing_time: Optional[float] = None
    quality_score: Optional[float] = None
    created_at: datetime
    completed_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

# Analysis schemas
class ClothingAnalysisRequest(BaseModel):
    image_url: str = Field(..., max_length=500)
    analyze_colors: bool = True
    analyze_style: bool = True
    analyze_body_type: bool = True
    analyze_attributes: bool = True

class ClothingAnalysisResponse(BaseModel):
    clothing_detection: Optional[Dict[str, Any]] = None
    color_analysis: Optional[Dict[str, Any]] = None
    style_classification: Optional[Dict[str, Any]] = None
    body_type_analysis: Optional[Dict[str, Any]] = None
    attributes: Optional[List[Dict[str, Any]]] = None
    confidence_scores: Dict[str, float]
    processing_time: float

class StyleAnalysisRequest(BaseModel):
    clothing_items: List[int] = Field(..., min_items=1, max_items=20)
    user_body_type: Optional[str] = None
    occasion: Optional[OccasionEnum] = None
    season: Optional[SeasonEnum] = None

class StyleAnalysisResponse(BaseModel):
    style_score: float
    color_harmony_score: float
    body_type_compatibility: Dict[str, float]
    style_recommendations: List[str]
    color_recommendations: List[str]
    improvement_suggestions: List[str]

# Search and filter schemas
class ClothingSearchParams(BaseModel):
    category: Optional[ClothingCategoryEnum] = None
    subcategory: Optional[ClothingSubcategoryEnum] = None
    brand: Optional[str] = None
    color: Optional[str] = None
    pattern: Optional[str] = None
    material: Optional[str] = None
    size: Optional[str] = None
    price_min: Optional[float] = Field(None, ge=0)
    price_max: Optional[float] = Field(None, ge=0)
    seasons: Optional[List[SeasonEnum]] = Field(None, max_items=4)
    occasions: Optional[List[OccasionEnum]] = Field(None, max_items=8)
    style_tags: Optional[List[str]] = Field(None, max_items=20)
    is_favorite: Optional[bool] = None
    limit: int = Field(20, ge=1, le=100)
    offset: int = Field(0, ge=0)

class OutfitSearchParams(BaseModel):
    style_archetype: Optional[str] = None
    occasion: Optional[OccasionEnum] = None
    season: Optional[SeasonEnum] = None
    style_tags: Optional[List[str]] = Field(None, max_items=20)
    is_public: Optional[bool] = None
    min_style_score: Optional[float] = Field(None, ge=0, le=1)
    limit: int = Field(20, ge=1, le=100)
    offset: int = Field(0, ge=0)

# Statistics schemas
class WardrobeStats(BaseModel):
    total_items: int
    items_by_category: Dict[str, int]
    items_by_color: Dict[str, int]
    items_by_brand: Dict[str, int]
    total_value: float
    average_price: float
    most_used_items: List[Dict[str, Any]]
    least_used_items: List[Dict[str, Any]]

class OutfitStats(BaseModel):
    total_outfits: int
    public_outfits: int
    private_outfits: int
    outfits_by_occasion: Dict[str, int]
    outfits_by_season: Dict[str, int]
    average_style_score: float
    top_rated_outfits: List[Dict[str, Any]]
