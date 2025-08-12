from sqlalchemy import Column, Integer, String, DateTime, Boolean, Float, Text, JSON, ForeignKey, Enum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base
import enum

class GenderEnum(enum.Enum):
    MALE = "male"
    FEMALE = "female"
    OTHER = "other"
    PREFER_NOT_TO_SAY = "prefer_not_to_say"

class BodyTypeEnum(enum.Enum):
    RECTANGULAR = "rectangular"
    TRIANGLE = "triangle"
    INVERTED_TRIANGLE = "inverted_triangle"
    HOURGLASS = "hourglass"
    OVAL = "oval"

class StyleArchetypeEnum(enum.Enum):
    CLASSIC = "classic"
    ROMANTIC = "romantic"
    NATURAL = "natural"
    DRAMATIC = "dramatic"
    GAMINE = "gamine"
    CREATIVE = "creative"
    ELEGANT = "elegant"
    BOHEMIAN = "bohemian"
    MINIMALIST = "minimalist"
    STREETWEAR = "streetwear"

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    username = Column(String(100), unique=True, index=True, nullable=False)
    first_name = Column(String(100))  # Add this field
    last_name = Column(String(100))   # Add this field
    hashed_password = Column(String(255), nullable=False)
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    last_login = Column(DateTime(timezone=True))
    
    # Relationships
    profile = relationship("UserProfile", back_populates="user", uselist=False)
    preferences = relationship("StylePreferences", back_populates="user", uselist=False)
    measurements = relationship("BodyMeasurements", back_populates="user", uselist=False)
    wardrobe = relationship("ClothingItem", back_populates="owner")
    outfits = relationship("OutfitCombination", back_populates="user")
    interactions = relationship("UserInteraction", back_populates="user")
    social_connections = relationship("UserConnection", foreign_keys="UserConnection.user_id", back_populates="user")
    followers = relationship("UserConnection", foreign_keys="UserConnection.followed_id", back_populates="followed")

class UserProfile(Base):
    __tablename__ = "user_profiles"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    first_name = Column(String(100))
    last_name = Column(String(100))
    gender = Column(Enum(GenderEnum))
    date_of_birth = Column(DateTime)
    height_cm = Column(Float)
    weight_kg = Column(Float)
    bio = Column(Text)
    profile_image_url = Column(String(500))
    location = Column(String(200))
    latitude = Column(Float)
    longitude = Column(Float)
    timezone = Column(String(50))
    language = Column(String(10), default="en")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    user = relationship("User", back_populates="profile")

class StylePreferences(Base):
    __tablename__ = "style_preferences"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    preferred_colors = Column(JSON)  # List of color hex codes
    preferred_styles = Column(JSON)  # List of style archetypes
    preferred_brands = Column(JSON)  # List of brand names
    budget_range = Column(JSON)  # {"min": 0, "max": 1000}
    occasion_preferences = Column(JSON)  # {"casual": 0.8, "formal": 0.6, ...}
    sustainability_importance = Column(Float, default=0.5)  # 0-1 scale
    comfort_importance = Column(Float, default=0.8)  # 0-1 scale
    style_importance = Column(Float, default=0.7)  # 0-1 scale
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    user = relationship("User", back_populates="preferences")

class BodyMeasurements(Base):
    __tablename__ = "body_measurements"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    body_type = Column(Enum(BodyTypeEnum))
    chest_cm = Column(Float)
    waist_cm = Column(Float)
    hips_cm = Column(Float)
    inseam_cm = Column(Float)
    shoulder_cm = Column(Float)
    arm_length_cm = Column(Float)
    neck_cm = Column(Float)
    shoe_size = Column(Float)
    measurements_date = Column(DateTime(timezone=True), server_default=func.now())
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    user = relationship("User", back_populates="measurements")

class UserInteraction(Base):
    __tablename__ = "user_interactions"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    interaction_type = Column(String(50))  # "like", "dislike", "save", "share", "purchase"
    target_type = Column(String(50))  # "outfit", "item", "recommendation"
    target_id = Column(Integer)
    interaction_data = Column(JSON)  # Additional interaction metadata
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    user = relationship("User", back_populates="interactions")

class UserConnection(Base):
    __tablename__ = "user_connections"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)  # Follower
    followed_id = Column(Integer, ForeignKey("users.id"), nullable=False)  # Following
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    user = relationship("User", foreign_keys=[user_id], back_populates="social_connections")
    followed = relationship("User", foreign_keys=[followed_id], back_populates="followers")

class StyleInsights(Base):
    __tablename__ = "style_insights"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    insight_type = Column(String(50))  # "color_analysis", "style_pattern", "body_type_insight"
    insight_data = Column(JSON)
    confidence_score = Column(Float)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    user = relationship("User")