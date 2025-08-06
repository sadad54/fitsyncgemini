from sqlalchemy import Column, String, Float, DateTime, Boolean, Text, JSON, Integer, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid

Base = declarative_base()

class User(Base):
    __tablename__ = "users"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    email = Column(String, unique=True, index=True, nullable=True)
    full_name = Column(String, nullable=True)
    style_archetype = Column(String, nullable=True)
    preferences = Column(JSON, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    wardrobe_items = relationship("WardrobeItem", back_populates="owner")
    outfit_combinations = relationship("OutfitCombination", back_populates="user")
    style_analyses = relationship("StyleAnalysis", back_populates="user")

class WardrobeItem(Base):
    __tablename__ = "wardrobe_items"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    name = Column(String, nullable=False)
    category = Column(String, nullable=False)  # tops, bottoms, shoes, accessories
    subcategory = Column(String, nullable=True)  # t-shirt, jeans, sneakers, etc.
    brand = Column(String, nullable=True)
    color_palette = Column(JSON, nullable=True)  # Dominant colors
    style_attributes = Column(JSON, nullable=True)  # Style tags and scores
    image_url = Column(String, nullable=True)
    purchase_date = Column(DateTime, nullable=True)
    price = Column(Float, nullable=True)
    sustainability_score = Column(Float, nullable=True)
    usage_count = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    owner = relationship("User", back_populates="wardrobe_items")

class OutfitCombination(Base):
    __tablename__ = "outfit_combinations"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    name = Column(String, nullable=False)
    item_ids = Column(JSON, nullable=False)  # List of wardrobe item IDs
    occasion = Column(String, nullable=True)
    season = Column(String, nullable=True)
    weather_conditions = Column(JSON, nullable=True)
    style_scores = Column(JSON, nullable=True)
    user_rating = Column(Integer, nullable=True)  # 1-5 rating
    worn_count = Column(Integer, default=0)
    last_worn = Column(DateTime, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    user = relationship("User", back_populates="outfit_combinations")

class StyleAnalysisResult(Base):
    __tablename__ = "style_analyses"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    analysis_type = Column(String, nullable=False)  # clothing, style, color, body
    image_url = Column(String, nullable=True)
    results = Column(JSON, nullable=False)
    confidence_score = Column(Float, nullable=True)
    model_version = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    user = relationship("User", back_populates="style_analyses")

class TryOnJob(Base):
    __tablename__ = "tryon_jobs"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    status = Column(String, default="processing")  # processing, completed, failed
    user_photo_url = Column(String, nullable=False)
    outfit_items = Column(JSON, nullable=False)
    result_url = Column(String, nullable=True)
    quality_score = Column(Float, nullable=True)
    processing_time = Column(Float, nullable=True)
    error_message = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    completed_at = Column(DateTime, nullable=True)
    expires_at = Column(DateTime, nullable=True)

class SocialInteraction(Base):
    __tablename__ = "social_interactions"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    target_user_id = Column(String, ForeignKey("users.id"), nullable=True)
    interaction_type = Column(String, nullable=False)  # like, comment, follow, rate
    content_id = Column(String, nullable=True)  # outfit_id, challenge_id, etc.
    content_type = Column(String, nullable=True)  # outfit, challenge, profile
    metadata = Column(JSON, nullable=True)  # rating, comment text, etc.
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class FashionTrend(Base):
    __tablename__ = "fashion_trends"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    category = Column(String, nullable=False)  # color, style, item, pattern
    trend_score = Column(Float, nullable=False)  # 0-1 trending intensity
    season = Column(String, nullable=True)
    demographic_tags = Column(JSON, nullable=True)  # age groups, styles, etc.
    source_data = Column(JSON, nullable=True)  # social media metrics, runway data
    start_date = Column(DateTime, nullable=True)
    peak_date = Column(DateTime, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
