from sqlalchemy import Column, Integer, String, DateTime, Boolean, Float, Text, JSON, ForeignKey, Enum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base
import enum

class ClothingCategoryEnum(enum.Enum):
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

class ClothingSubcategoryEnum(enum.Enum):
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

class SeasonEnum(enum.Enum):
    SPRING = "spring"
    SUMMER = "summer"
    FALL = "fall"
    WINTER = "winter"
    ALL_SEASON = "all_season"

class OccasionEnum(enum.Enum):
    CASUAL = "casual"
    BUSINESS = "business"
    FORMAL = "formal"
    SPORTY = "sporty"
    EVENING = "evening"
    BEACH = "beach"
    OUTDOOR = "outdoor"
    PARTY = "party"

class ClothingItem(Base):
    __tablename__ = "clothing_items"
    
    id = Column(Integer, primary_key=True, index=True)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    name = Column(String(200), nullable=False)
    category = Column(Enum(ClothingCategoryEnum), nullable=False)
    subcategory = Column(Enum(ClothingSubcategoryEnum))
    brand = Column(String(100))
    color = Column(String(50))
    color_hex = Column(String(7))  # Hex color code
    pattern = Column(String(100))  # "solid", "striped", "floral", etc.
    material = Column(String(100))
    size = Column(String(20))
    price = Column(Float)
    purchase_date = Column(DateTime)
    image_url = Column(String(500))
    thumbnail_url = Column(String(500))
    
    # Style attributes
    seasons = Column(JSON)  # List of seasons
    occasions = Column(JSON)  # List of occasions
    style_tags = Column(JSON)  # List of style tags
    fit_type = Column(String(50))  # "loose", "fitted", "oversized"
    neckline = Column(String(50))  # For tops/dresses
    sleeve_type = Column(String(50))  # For tops/dresses
    length = Column(String(50))  # "short", "medium", "long"
    
    # ML analysis results
    detected_attributes = Column(JSON)  # ML-detected attributes
    color_analysis = Column(JSON)  # Color palette analysis
    style_classification = Column(JSON)  # Style archetype classification
    body_type_compatibility = Column(JSON)  # Compatibility scores
    
    # Metadata
    is_favorite = Column(Boolean, default=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    owner = relationship("User", back_populates="wardrobe")
    outfit_items = relationship("OutfitItem", back_populates="clothing_item")

class OutfitCombination(Base):
    __tablename__ = "outfit_combinations"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    name = Column(String(200))
    description = Column(Text)
    
    # Style attributes
    style_archetype = Column(String(100))
    color_scheme = Column(JSON)  # Color palette analysis
    occasion = Column(Enum(OccasionEnum))
    season = Column(Enum(SeasonEnum))
    style_tags = Column(JSON)
    
    # ML analysis
    style_score = Column(Float)  # Overall style compatibility score
    color_harmony_score = Column(Float)  # Color harmony score
    body_type_compatibility = Column(JSON)
    
    # Social features
    is_public = Column(Boolean, default=False)
    likes_count = Column(Integer, default=0)
    shares_count = Column(Integer, default=0)
    
    # Metadata
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    user = relationship("User", back_populates="outfits")
    items = relationship("OutfitItem", back_populates="outfit")
    ratings = relationship("OutfitRating", back_populates="outfit")

class OutfitItem(Base):
    __tablename__ = "outfit_items"
    
    id = Column(Integer, primary_key=True, index=True)
    outfit_id = Column(Integer, ForeignKey("outfit_combinations.id"), nullable=False)
    clothing_item_id = Column(Integer, ForeignKey("clothing_items.id"), nullable=False)
    position_order = Column(Integer)  # Order in the outfit
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    outfit = relationship("OutfitCombination", back_populates="items")
    clothing_item = relationship("ClothingItem", back_populates="outfit_items")

class OutfitRating(Base):
    __tablename__ = "outfit_ratings"
    
    id = Column(Integer, primary_key=True, index=True)
    outfit_id = Column(Integer, ForeignKey("outfit_combinations.id"), nullable=False)
    rater_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    rating = Column(Float)  # 1-5 scale
    comment = Column(Text)
    rating_categories = Column(JSON)  # {"style": 4, "color": 5, "fit": 3}
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    outfit = relationship("OutfitCombination", back_populates="ratings")
    rater = relationship("User")

class StyleAttributes(Base):
    __tablename__ = "style_attributes"
    
    id = Column(Integer, primary_key=True, index=True)
    clothing_item_id = Column(Integer, ForeignKey("clothing_items.id"), nullable=False)
    attribute_type = Column(String(50))  # "color", "pattern", "fit", "style"
    attribute_name = Column(String(100))
    attribute_value = Column(String(200))
    confidence_score = Column(Float)  # ML confidence score
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    clothing_item = relationship("ClothingItem")

class VirtualTryOn(Base):
    __tablename__ = "virtual_tryon"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    outfit_id = Column(Integer, ForeignKey("outfit_combinations.id"), nullable=False)
    user_image_url = Column(String(500))
    result_image_url = Column(String(500))
    status = Column(String(50))  # "processing", "completed", "failed"
    processing_time = Column(Float)  # Processing time in seconds
    quality_score = Column(Float)  # Result quality score
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    completed_at = Column(DateTime(timezone=True))
    
    # Relationships
    user = relationship("User")
    outfit = relationship("OutfitCombination")