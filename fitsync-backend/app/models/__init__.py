# Import all models to ensure they are registered with SQLAlchemy
from .user import (
    User, UserProfile, StylePreferences, BodyMeasurements, 
    UserInteraction, UserConnection, StyleInsights,
    GenderEnum, BodyTypeEnum, StyleArchetypeEnum
)

from .clothing import (
    ClothingItem, OutfitCombination, OutfitItem, OutfitRating,
    StyleAttributes, VirtualTryOn,
    ClothingCategoryEnum, ClothingSubcategoryEnum, SeasonEnum, OccasionEnum
)

from .social import (
    FashionChallenge, ChallengeSubmission, ChallengeVote,
    StylePost, PostLike, PostComment, StyleInspiration,
    StyleEvent, EventAttendance,
    ChallengeStatusEnum, ChallengeTypeEnum
)

from .analytics import (
    UserAnalytics, ModelPrediction, RecommendationHistory,
    FashionTrend, StyleAnalysis, PerformanceMetrics,
    ErrorLog, AITrainingData,
    InteractionTypeEnum, ModelTypeEnum
)

# Export all models for easy access
__all__ = [
    # User models
    "User", "UserProfile", "StylePreferences", "BodyMeasurements",
    "UserInteraction", "UserConnection", "StyleInsights",
    "GenderEnum", "BodyTypeEnum", "StyleArchetypeEnum",
    
    # Clothing models
    "ClothingItem", "OutfitCombination", "OutfitItem", "OutfitRating",
    "StyleAttributes", "VirtualTryOn",
    "ClothingCategoryEnum", "ClothingSubcategoryEnum", "SeasonEnum", "OccasionEnum",
    
    # Social models
    "FashionChallenge", "ChallengeSubmission", "ChallengeVote",
    "StylePost", "PostLike", "PostComment", "StyleInspiration",
    "StyleEvent", "EventAttendance",
    "ChallengeStatusEnum", "ChallengeTypeEnum",
    
    # Analytics models
    "UserAnalytics", "ModelPrediction", "RecommendationHistory",
    "FashionTrend", "StyleAnalysis", "PerformanceMetrics",
    "ErrorLog", "AITrainingData",
    "InteractionTypeEnum", "ModelTypeEnum"
]
