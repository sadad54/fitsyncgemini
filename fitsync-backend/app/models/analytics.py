from sqlalchemy import Column, Integer, String, DateTime, Boolean, Float, Text, JSON, ForeignKey, Enum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base
import enum

class InteractionTypeEnum(enum.Enum):
    VIEW = "view"
    LIKE = "like"
    DISLIKE = "dislike"
    SAVE = "save"
    SHARE = "share"
    PURCHASE = "purchase"
    RATE = "rate"
    COMMENT = "comment"
    SEARCH = "search"
    FILTER = "filter"

class ModelTypeEnum(enum.Enum):
    CLOTHING_DETECTION = "clothing_detection"
    STYLE_CLASSIFICATION = "style_classification"
    COLOR_ANALYSIS = "color_analysis"
    BODY_TYPE_ANALYSIS = "body_type_analysis"
    RECOMMENDATION_ENGINE = "recommendation_engine"
    VIRTUAL_TRYON = "virtual_tryon"
    TREND_PREDICTION = "trend_prediction"

class UserAnalytics(Base):
    __tablename__ = "user_analytics"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    session_id = Column(String(100))
    
    # Interaction tracking
    interaction_type = Column(Enum(InteractionTypeEnum), nullable=False)
    target_type = Column(String(50))  # "outfit", "item", "recommendation", "challenge"
    target_id = Column(Integer)
    interaction_data = Column(JSON)  # Additional interaction metadata
    
    # User context
    user_agent = Column(String(500))
    ip_address = Column(String(45))
    location = Column(String(200))
    latitude = Column(Float)
    longitude = Column(Float)
    
    # Session context
    page_url = Column(String(500))
    referrer_url = Column(String(500))
    time_spent = Column(Float)  # Time spent in seconds
    
    # Metadata
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    user = relationship("User")

class ModelPrediction(Base):
    __tablename__ = "model_predictions"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    model_type = Column(Enum(ModelTypeEnum), nullable=False)
    
    # Input data
    input_data = Column(JSON)  # Input data for the model
    input_hash = Column(String(64))  # Hash of input for caching
    
    # Prediction results
    prediction_result = Column(JSON)  # Model prediction output
    confidence_score = Column(Float)  # Model confidence score
    processing_time = Column(Float)  # Processing time in seconds
    
    # Model metadata
    model_version = Column(String(50))
    model_parameters = Column(JSON)  # Model parameters used
    
    # Feedback and validation
    user_feedback = Column(JSON)  # User feedback on prediction
    is_correct = Column(Boolean)  # Whether prediction was correct
    feedback_score = Column(Float)  # User rating of prediction quality
    
    # Metadata
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    user = relationship("User")

class RecommendationHistory(Base):
    __tablename__ = "recommendation_history"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    # Recommendation details
    recommendation_type = Column(String(100))  # "outfit", "item", "style", "trend"
    recommendation_data = Column(JSON)  # Recommended items/outfits
    recommendation_score = Column(Float)  # Recommendation confidence score
    
    # Context
    context_data = Column(JSON)  # Weather, occasion, user preferences, etc.
    algorithm_used = Column(String(100))  # Algorithm that generated recommendation
    
    # User response
    user_response = Column(String(50))  # "accepted", "rejected", "ignored"
    response_time = Column(Float)  # Time to respond in seconds
    
    # Metadata
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    user = relationship("User")

class FashionTrend(Base):
    __tablename__ = "fashion_trends"
    
    id = Column(Integer, primary_key=True, index=True)
    
    # Trend identification
    trend_name = Column(String(200), nullable=False)
    trend_description = Column(Text)
    trend_category = Column(String(100))  # "color", "style", "pattern", "item"
    
    # Trend data
    trend_data = Column(JSON)  # Detailed trend information
    popularity_score = Column(Float)  # Current popularity score
    growth_rate = Column(Float)  # Growth rate over time
    seasonality = Column(JSON)  # Seasonal patterns
    
    # Geographic and demographic data
    geographic_spread = Column(JSON)  # Geographic distribution
    demographic_data = Column(JSON)  # Age, gender, etc.
    
    # Social media metrics
    social_mentions = Column(Integer, default=0)
    hashtag_count = Column(Integer, default=0)
    influencer_adoption = Column(Float, default=0.0)
    
    # Prediction data
    predicted_lifespan = Column(Integer)  # Predicted duration in days
    confidence_level = Column(Float)  # Prediction confidence
    
    # Metadata
    first_detected = Column(DateTime(timezone=True), server_default=func.now())
    last_updated = Column(DateTime(timezone=True), onupdate=func.now())
    is_active = Column(Boolean, default=True)

class StyleAnalysis(Base):
    __tablename__ = "style_analysis"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    # Analysis type
    analysis_type = Column(String(100))  # "wardrobe", "outfit", "style_evolution"
    
    # Analysis results
    analysis_data = Column(JSON)  # Detailed analysis results
    insights = Column(JSON)  # Key insights from analysis
    recommendations = Column(JSON)  # Recommendations based on analysis
    
    # Metrics
    style_consistency_score = Column(Float)
    color_diversity_score = Column(Float)
    trend_alignment_score = Column(Float)
    sustainability_score = Column(Float)
    
    # Metadata
    analysis_date = Column(DateTime(timezone=True), server_default=func.now())
    analysis_period = Column(String(50))  # "weekly", "monthly", "quarterly"
    
    # Relationships
    user = relationship("User")

class PerformanceMetrics(Base):
    __tablename__ = "performance_metrics"
    
    id = Column(Integer, primary_key=True, index=True)
    
    # Metric identification
    metric_name = Column(String(100), nullable=False)
    metric_category = Column(String(100))  # "api", "ml", "database", "cache"
    
    # Metric values
    metric_value = Column(Float)
    metric_unit = Column(String(20))  # "seconds", "requests", "percentage"
    
    # Context
    context_data = Column(JSON)  # Additional context for the metric
    tags = Column(JSON)  # Tags for filtering and grouping
    
    # Metadata
    recorded_at = Column(DateTime(timezone=True), server_default=func.now())
    environment = Column(String(50))  # "development", "staging", "production"

class ErrorLog(Base):
    __tablename__ = "error_logs"
    
    id = Column(Integer, primary_key=True, index=True)
    
    # Error details
    error_type = Column(String(100))
    error_message = Column(Text)
    error_traceback = Column(Text)
    
    # Context
    user_id = Column(Integer, ForeignKey("users.id"))
    request_data = Column(JSON)  # Request data when error occurred
    environment_data = Column(JSON)  # Environment information
    
    # Error handling
    is_resolved = Column(Boolean, default=False)
    resolution_notes = Column(Text)
    priority = Column(String(20))  # "low", "medium", "high", "critical"
    
    # Metadata
    occurred_at = Column(DateTime(timezone=True), server_default=func.now())
    resolved_at = Column(DateTime(timezone=True))
    
    # Relationships
    user = relationship("User")

class AITrainingData(Base):
    __tablename__ = "ai_training_data"
    
    id = Column(Integer, primary_key=True, index=True)
    
    # Data identification
    data_type = Column(String(100))  # "image", "text", "interaction"
    data_source = Column(String(100))  # "user_upload", "api", "generated"
    
    # Data content
    data_content = Column(JSON)  # Actual training data
    data_metadata = Column(JSON)  # Metadata about the data
    
    # Quality metrics
    quality_score = Column(Float)
    validation_status = Column(String(50))  # "pending", "approved", "rejected"
    validation_notes = Column(Text)
    
    # Usage tracking
    times_used = Column(Integer, default=0)
    last_used = Column(DateTime(timezone=True))
    
    # Privacy and consent
    user_consent = Column(Boolean, default=False)
    anonymized = Column(Boolean, default=True)
    
    # Metadata
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
