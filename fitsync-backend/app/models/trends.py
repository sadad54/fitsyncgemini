"""
Trends and Fashion Data Models
"""

from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, Text, JSON, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from enum import Enum

Base = declarative_base()

class TrendDirection(str, Enum):
    UP = "up"
    DOWN = "down"
    STABLE = "stable"

class FashionTrend(Base):
    """Fashion trends tracking table"""
    __tablename__ = "fashion_trends"
    
    id = Column(Integer, primary_key=True, index=True)
    trend_name = Column(String(200), nullable=False, index=True)
    trend_description = Column(Text)
    category = Column(String(50), nullable=False)  # color, style, pattern, item, etc.
    
    # Trend metrics
    popularity_score = Column(Float, default=0.0)  # 0-1 scale
    growth_rate = Column(Float, default=0.0)  # -1 to 1 scale
    direction = Column(String(10), default=TrendDirection.STABLE.value)
    
    # Social metrics
    engagement = Column(Integer, default=0)
    posts_count = Column(Integer, default=0)
    social_mentions = Column(Integer, default=0)
    hashtag_count = Column(Integer, default=0)
    
    # Additional data
    tags = Column(JSON)  # List of associated tags
    image_url = Column(String(500))
    confidence_level = Column(Float, default=0.5)
    
    # Metadata
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

class StyleInfluencer(Base):
    """Style influencers and trend setters"""
    __tablename__ = "style_influencers"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    handle = Column(String(100), nullable=False, unique=True)
    
    # Profile info
    bio = Column(Text)
    profile_image_url = Column(String(500))
    
    # Metrics
    followers_count = Column(Integer, default=0)
    engagement_rate = Column(Float, default=0.0)  # 0-1 scale
    influence_score = Column(Float, default=0.0)  # 0-1 scale
    
    # Trending info
    trend_setter_type = Column(String(100))  # e.g., "Sustainable fashion", "Street style"
    recent_trend = Column(String(200))
    
    # Geographic scope
    location = Column(String(200))
    scope = Column(String(20), default="global")  # global, local
    
    # Metadata
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

class ExploreContent(Base):
    """Explore screen content - style posts, outfits, etc."""
    __tablename__ = "explore_content"
    
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(200), nullable=False)
    content_type = Column(String(50), default="style_post")  # style_post, outfit, lookbook
    
    # Author info
    author_id = Column(Integer, ForeignKey("users.id"))
    author_name = Column(String(100), nullable=False)
    author_avatar_url = Column(String(500))
    
    # Content
    description = Column(Text)
    image_url = Column(String(500), nullable=False)
    tags = Column(JSON)  # List of style tags
    
    # Engagement metrics
    likes_count = Column(Integer, default=0)
    views_count = Column(Integer, default=0)
    shares_count = Column(Integer, default=0)
    comments_count = Column(Integer, default=0)
    
    # Categorization
    category = Column(String(50))  # tops, bottoms, etc.
    style_archetype = Column(String(50))  # minimalist, streetwear, etc.
    
    # Trending status
    is_trending = Column(Boolean, default=False)
    trending_score = Column(Float, default=0.0)
    
    # Metadata
    is_public = Column(Boolean, default=True)
    is_featured = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

class NearbyLocation(Base):
    """Location-based content for nearby screen"""
    __tablename__ = "nearby_locations"
    
    id = Column(Integer, primary_key=True, index=True)
    location_type = Column(String(20), nullable=False)  # person, event, hotspot
    
    # Basic info
    name = Column(String(200), nullable=False)
    description = Column(Text)
    image_url = Column(String(500))
    
    # Location
    latitude = Column(Float, nullable=False, index=True)
    longitude = Column(Float, nullable=False, index=True)
    address = Column(String(500))
    city = Column(String(100))
    country = Column(String(100))
    
    # Type-specific data stored as JSON
    # For person: {style, mutualConnections, recentOutfit, isOnline}
    # For event: {date, attendees, category}
    # For hotspot: {type, popularStyles, rating, checkIns}
    location_metadata = Column(JSON)
    
    # Associated user (for person type)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    
    # Visibility
    is_active = Column(Boolean, default=True)
    is_public = Column(Boolean, default=True)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # For events - expiry date
    expires_at = Column(DateTime(timezone=True), nullable=True)

class TrendInsight(Base):
    """Fashion insights by category"""
    __tablename__ = "trend_insights"
    
    id = Column(Integer, primary_key=True, index=True)
    category = Column(String(50), nullable=False)  # colors, patterns, silhouettes, accessories
    
    # Trending and declining items
    trending_items = Column(JSON)  # List of trending items in this category
    declining_items = Column(JSON)  # List of declining items
    
    # Scope and timeframe
    scope = Column(String(20), default="global")  # global, local
    timeframe = Column(String(20), default="week")  # day, week, month
    
    # Confidence and metadata
    confidence_score = Column(Float, default=0.0)
    data_points = Column(Integer, default=0)  # Number of data points used
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    valid_until = Column(DateTime(timezone=True))  # When this insight expires
