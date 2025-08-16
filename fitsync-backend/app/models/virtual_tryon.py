"""
Virtual Try-On Models
"""

from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, Text, JSON, ForeignKey, Enum as SQLEnum
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from enum import Enum
import uuid

Base = declarative_base()

class ViewModeEnum(str, Enum):
    AR = "ar"
    MIRROR = "mirror"

class TryOnStatusEnum(str, Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"

class TryOnSession(Base):
    """Virtual try-on session tracking"""
    __tablename__ = "tryon_sessions"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    session_name = Column(String(200), nullable=True)
    
    # Session configuration
    view_mode = Column(String(20), default=ViewModeEnum.AR.value)
    device_info = Column(JSON)  # Camera specs, device type, etc.
    
    # Processing status
    status = Column(String(20), default=TryOnStatusEnum.PENDING.value)
    processing_progress = Column(Float, default=0.0)  # 0.0 to 1.0
    error_message = Column(Text, nullable=True)
    
    # Results
    result_image_url = Column(String(500), nullable=True)
    confidence_score = Column(Float, nullable=True)  # Overall fit confidence
    processing_time_ms = Column(Integer, nullable=True)
    
    # Metadata
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    completed_at = Column(DateTime(timezone=True), nullable=True)
    
    # Relationships
    user = relationship("User", back_populates="tryon_sessions")
    outfit_attempts = relationship("TryOnOutfitAttempt", back_populates="session")

class TryOnOutfitAttempt(Base):
    """Individual outfit try-on attempts within a session"""
    __tablename__ = "tryon_outfit_attempts"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    session_id = Column(String, ForeignKey("tryon_sessions.id"), nullable=False)
    
    # Outfit information
    outfit_name = Column(String(200), nullable=False)
    occasion = Column(String(100), nullable=True)
    clothing_items = Column(JSON)  # List of clothing item IDs and details
    
    # Try-on results
    confidence_score = Column(Float, nullable=True)  # Fit confidence for this outfit
    fit_analysis = Column(JSON)  # Detailed fit analysis per item
    color_analysis = Column(JSON)  # Color matching analysis
    style_score = Column(Float, nullable=True)  # Style compatibility score
    
    # User feedback
    user_rating = Column(Integer, nullable=True)  # 1-5 stars
    is_favorite = Column(Boolean, default=False)
    is_shared = Column(Boolean, default=False)
    
    # Processing details
    processing_time_ms = Column(Integer, nullable=True)
    result_image_url = Column(String(500), nullable=True)
    
    # Metadata
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    session = relationship("TryOnSession", back_populates="outfit_attempts")

class TryOnFeature(Base):
    """Smart features available for try-on"""
    __tablename__ = "tryon_features"
    
    id = Column(String, primary_key=True)  # 'lighting', 'fit', 'movement', etc.
    name = Column(String(100), nullable=False)
    description = Column(String(500), nullable=False)
    
    # Feature configuration
    is_premium = Column(Boolean, default=False)
    processing_cost = Column(Float, default=0.0)  # Processing time multiplier
    accuracy_improvement = Column(Float, default=0.0)  # Expected accuracy boost
    
    # Status
    is_available = Column(Boolean, default=True)
    requires_gpu = Column(Boolean, default=False)
    min_device_capability = Column(String(50), nullable=True)
    
    # Metadata
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

class UserTryOnPreferences(Base):
    """User preferences for try-on features"""
    __tablename__ = "user_tryon_preferences"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, unique=True)
    
    # Default settings
    default_view_mode = Column(String(20), default=ViewModeEnum.AR.value)
    auto_save_results = Column(Boolean, default=True)
    share_anonymously = Column(Boolean, default=False)
    
    # Feature preferences (JSON of feature_id: enabled)
    enabled_features = Column(JSON, default=lambda: {
        "lighting": True,
        "fit": True,
        "movement": False
    })
    
    # Quality settings
    processing_quality = Column(String(20), default="high")  # low, medium, high
    max_processing_time = Column(Integer, default=30)  # seconds
    
    # Privacy settings
    store_images = Column(Boolean, default=True)
    allow_analytics = Column(Boolean, default=True)
    
    # Metadata
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    user = relationship("User", back_populates="tryon_preferences")

class TryOnAnalytics(Base):
    """Analytics for try-on usage and performance"""
    __tablename__ = "tryon_analytics"
    
    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(String, ForeignKey("tryon_sessions.id"), nullable=False)
    
    # Usage metrics
    total_outfits_tried = Column(Integer, default=0)
    session_duration_seconds = Column(Integer, nullable=True)
    user_interactions = Column(JSON)  # Button clicks, gestures, etc.
    
    # Performance metrics
    average_processing_time = Column(Float, nullable=True)
    success_rate = Column(Float, nullable=True)
    error_count = Column(Integer, default=0)
    
    # User satisfaction
    session_rating = Column(Integer, nullable=True)  # 1-5 stars
    completion_rate = Column(Float, nullable=True)  # How much of session completed
    
    # Technical metrics
    device_performance = Column(JSON)  # FPS, memory usage, etc.
    network_stats = Column(JSON)  # Upload/download times
    
    # Metadata
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    session = relationship("TryOnSession")

# Add relationships to User model (this would be added to your existing User model)
"""
# Add these to your existing User model:

tryon_sessions = relationship("TryOnSession", back_populates="user")
tryon_preferences = relationship("UserTryOnPreferences", back_populates="user", uselist=False)
"""
