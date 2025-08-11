# Import all schemas for easy access
from .user import (
    # User schemas
    UserBase, UserCreate, UserLogin, UserUpdate, UserResponse,
    UserProfileBase, UserProfileCreate, UserProfileUpdate, UserProfileResponse,
    StylePreferencesBase, StylePreferencesCreate, StylePreferencesUpdate, StylePreferencesResponse,
    BodyMeasurementsBase, BodyMeasurementsCreate, BodyMeasurementsUpdate, BodyMeasurementsResponse,
    
    # Authentication schemas
    Token, TokenData, RefreshToken, PasswordReset, PasswordResetConfirm, EmailVerification,
    
    # User interaction schemas
    UserInteractionBase, UserInteractionCreate, UserInteractionResponse,
    UserConnectionBase, UserConnectionCreate, UserConnectionResponse,
    StyleInsightsBase, StyleInsightsCreate, StyleInsightsResponse,
    
    # Complete user schemas
    UserWithProfile, UserDetailed,
    
    # Search and filter schemas
    UserSearchParams, UserStats,
    
    # Enums
    GenderEnum, BodyTypeEnum, StyleArchetypeEnum
)

from .clothing import (
    # Clothing item schemas
    ClothingItemBase, ClothingItemCreate, ClothingItemUpdate, ClothingItemResponse,
    
    # Outfit schemas
    OutfitCombinationBase, OutfitCombinationCreate, OutfitCombinationUpdate, OutfitCombinationResponse,
    OutfitWithItems,
    
    # Outfit item schemas
    OutfitItemBase, OutfitItemCreate, OutfitItemResponse,
    
    # Outfit rating schemas
    OutfitRatingBase, OutfitRatingCreate, OutfitRatingResponse,
    
    # Style attributes schemas
    StyleAttributesBase, StyleAttributesCreate, StyleAttributesResponse,
    
    # Virtual try-on schemas
    VirtualTryOnBase, VirtualTryOnCreate, VirtualTryOnResponse,
    
    # Analysis schemas
    ClothingAnalysisRequest, ClothingAnalysisResponse,
    StyleAnalysisRequest, StyleAnalysisResponse,
    
    # Search and filter schemas
    ClothingSearchParams, OutfitSearchParams,
    
    # Statistics schemas
    WardrobeStats, OutfitStats,
    
    # Enums
    ClothingCategoryEnum, ClothingSubcategoryEnum, SeasonEnum, OccasionEnum
)

from .recommendation import (
    # Recommendation schemas
    RecommendationBase, OutfitRecommendation, ItemRecommendation, StyleRecommendation, TrendRecommendation,
    RecommendationRequest, RecommendationResponse,
    
    # Social schemas
    FashionChallengeBase, FashionChallengeCreate, FashionChallengeUpdate, FashionChallengeResponse,
    ChallengeSubmissionBase, ChallengeSubmissionCreate, ChallengeSubmissionResponse,
    ChallengeVoteBase, ChallengeVoteCreate, ChallengeVoteResponse,
    
    # Style post schemas
    StylePostBase, StylePostCreate, StylePostUpdate, StylePostResponse,
    PostLikeBase, PostLikeCreate, PostLikeResponse,
    PostCommentBase, PostCommentCreate, PostCommentResponse,
    
    # Style inspiration schemas
    StyleInspirationBase, StyleInspirationCreate, StyleInspirationUpdate, StyleInspirationResponse,
    
    # Fashion trend schemas
    FashionTrendBase, FashionTrendCreate, FashionTrendUpdate, FashionTrendResponse,
    
    # Search and filter schemas
    RecommendationSearchParams, ChallengeSearchParams, PostSearchParams, TrendSearchParams,
    
    # Statistics schemas
    RecommendationStats, SocialStats, TrendStats,
    
    # Enums
    RecommendationTypeEnum, RecommendationSourceEnum, TrendCategoryEnum
)

# Export all schemas
__all__ = [
    # User schemas
    "UserBase", "UserCreate", "UserLogin", "UserUpdate", "UserResponse",
    "UserProfileBase", "UserProfileCreate", "UserProfileUpdate", "UserProfileResponse",
    "StylePreferencesBase", "StylePreferencesCreate", "StylePreferencesUpdate", "StylePreferencesResponse",
    "BodyMeasurementsBase", "BodyMeasurementsCreate", "BodyMeasurementsUpdate", "BodyMeasurementsResponse",
    "Token", "TokenData", "RefreshToken", "PasswordReset", "PasswordResetConfirm", "EmailVerification",
    "UserInteractionBase", "UserInteractionCreate", "UserInteractionResponse",
    "UserConnectionBase", "UserConnectionCreate", "UserConnectionResponse",
    "StyleInsightsBase", "StyleInsightsCreate", "StyleInsightsResponse",
    "UserWithProfile", "UserDetailed", "UserSearchParams", "UserStats",
    "GenderEnum", "BodyTypeEnum", "StyleArchetypeEnum",
    
    # Clothing schemas
    "ClothingItemBase", "ClothingItemCreate", "ClothingItemUpdate", "ClothingItemResponse",
    "OutfitCombinationBase", "OutfitCombinationCreate", "OutfitCombinationUpdate", "OutfitCombinationResponse",
    "OutfitWithItems", "OutfitItemBase", "OutfitItemCreate", "OutfitItemResponse",
    "OutfitRatingBase", "OutfitRatingCreate", "OutfitRatingResponse",
    "StyleAttributesBase", "StyleAttributesCreate", "StyleAttributesResponse",
    "VirtualTryOnBase", "VirtualTryOnCreate", "VirtualTryOnResponse",
    "ClothingAnalysisRequest", "ClothingAnalysisResponse",
    "StyleAnalysisRequest", "StyleAnalysisResponse",
    "ClothingSearchParams", "OutfitSearchParams", "WardrobeStats", "OutfitStats",
    "ClothingCategoryEnum", "ClothingSubcategoryEnum", "SeasonEnum", "OccasionEnum",
    
    # Recommendation and social schemas
    "RecommendationBase", "OutfitRecommendation", "ItemRecommendation", "StyleRecommendation", "TrendRecommendation",
    "RecommendationRequest", "RecommendationResponse",
    "FashionChallengeBase", "FashionChallengeCreate", "FashionChallengeUpdate", "FashionChallengeResponse",
    "ChallengeSubmissionBase", "ChallengeSubmissionCreate", "ChallengeSubmissionResponse",
    "ChallengeVoteBase", "ChallengeVoteCreate", "ChallengeVoteResponse",
    "StylePostBase", "StylePostCreate", "StylePostUpdate", "StylePostResponse",
    "PostLikeBase", "PostLikeCreate", "PostLikeResponse",
    "PostCommentBase", "PostCommentCreate", "PostCommentResponse",
    "StyleInspirationBase", "StyleInspirationCreate", "StyleInspirationUpdate", "StyleInspirationResponse",
    "FashionTrendBase", "FashionTrendCreate", "FashionTrendUpdate", "FashionTrendResponse",
    "RecommendationSearchParams", "ChallengeSearchParams", "PostSearchParams", "TrendSearchParams",
    "RecommendationStats", "SocialStats", "TrendStats",
    "RecommendationTypeEnum", "RecommendationSourceEnum", "TrendCategoryEnum"
]
