from pydantic import BaseModel, EmailStr, Field, validator
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum

class GenderEnum(str, Enum):
    MALE = "male"
    FEMALE = "female"
    OTHER = "other"
    PREFER_NOT_TO_SAY = "prefer_not_to_say"

class BodyTypeEnum(str, Enum):
    RECTANGULAR = "rectangular"
    TRIANGLE = "triangle"
    INVERTED_TRIANGLE = "inverted_triangle"
    HOURGLASS = "hourglass"
    OVAL = "oval"

class StyleArchetypeEnum(str, Enum):
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

# Base schemas
class UserBase(BaseModel):
    email: EmailStr
    username: str = Field(..., min_length=3, max_length=50, pattern="^[a-zA-Z0-9_]+$")

class UserCreate(UserBase):
    password: str = Field(..., min_length=8, max_length=128)
    confirm_password: str
    first_name: str = Field(..., min_length=1, max_length=100)
    last_name: str = Field(..., min_length=1, max_length=100)
    
    @validator('confirm_password')
    def passwords_match(cls, v, values):
        if 'password' in values and v != values['password']:
            raise ValueError('Passwords do not match')
        return v
    
    @validator('password')
    def validate_password_strength(cls, v):
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters long')
        if not any(c.isupper() for c in v):
            raise ValueError('Password must contain at least one uppercase letter')
        if not any(c.islower() for c in v):
            raise ValueError('Password must contain at least one lowercase letter')
        if not any(c.isdigit() for c in v):
            raise ValueError('Password must contain at least one number')
        if not any(c in "!@#$%^&*()_+-=[]{}|;:,.<>?" for c in v):
            raise ValueError('Password must contain at least one special character')
        return v

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserUpdate(BaseModel):
    email: Optional[EmailStr] = None
    username: Optional[str] = Field(None, min_length=3, max_length=50, pattern="^[a-zA-Z0-9_]+$")
    is_active: Optional[bool] = None

class UserResponse(BaseModel):
    id: int
    email: str
    username: str
    first_name: Optional[str] = None  # Add these fields
    last_name: Optional[str] = None   # Add these fields
    is_active: bool
    is_verified: bool
    created_at: datetime
    last_login: Optional[datetime] = None
    
    class Config:
        from_attributes = True

# Profile schemas
class UserProfileBase(BaseModel):
    first_name: Optional[str] = Field(None, max_length=100)
    last_name: Optional[str] = Field(None, max_length=100)
    gender: Optional[GenderEnum] = None
    date_of_birth: Optional[datetime] = None
    height_cm: Optional[float] = Field(None, ge=50, le=300)
    weight_kg: Optional[float] = Field(None, ge=20, le=500)
    bio: Optional[str] = Field(None, max_length=1000)
    location: Optional[str] = Field(None, max_length=200)
    latitude: Optional[float] = Field(None, ge=-90, le=90)
    longitude: Optional[float] = Field(None, ge=-180, le=180)
    timezone: Optional[str] = Field(None, max_length=50)
    language: Optional[str] = Field(None, max_length=10)

class UserProfileCreate(UserProfileBase):
    pass

class UserProfileUpdate(UserProfileBase):
    profile_image_url: Optional[str] = Field(None, max_length=500)

class UserProfileResponse(UserProfileBase):
    id: int
    user_id: int
    profile_image_url: Optional[str] = None
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

# Style preferences schemas
class StylePreferencesBase(BaseModel):
    preferred_colors: Optional[List[str]] = Field(None, max_items=20)
    preferred_styles: Optional[List[StyleArchetypeEnum]] = Field(None, max_items=10)
    preferred_brands: Optional[List[str]] = Field(None, max_items=50)
    budget_range: Optional[Dict[str, float]] = None
    occasion_preferences: Optional[Dict[str, float]] = None
    sustainability_importance: Optional[float] = Field(None, ge=0, le=1)
    comfort_importance: Optional[float] = Field(None, ge=0, le=1)
    style_importance: Optional[float] = Field(None, ge=0, le=1)

class StylePreferencesCreate(StylePreferencesBase):
    pass

class StylePreferencesUpdate(StylePreferencesBase):
    pass

class StylePreferencesResponse(StylePreferencesBase):
    id: int
    user_id: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

# Body measurements schemas
class BodyMeasurementsBase(BaseModel):
    body_type: Optional[BodyTypeEnum] = None
    chest_cm: Optional[float] = Field(None, ge=50, le=200)
    waist_cm: Optional[float] = Field(None, ge=40, le=200)
    hips_cm: Optional[float] = Field(None, ge=50, le=200)
    inseam_cm: Optional[float] = Field(None, ge=50, le=150)
    shoulder_cm: Optional[float] = Field(None, ge=30, le=80)
    arm_length_cm: Optional[float] = Field(None, ge=40, le=100)
    neck_cm: Optional[float] = Field(None, ge=20, le=60)
    shoe_size: Optional[float] = Field(None, ge=1, le=20)

class BodyMeasurementsCreate(BodyMeasurementsBase):
    pass

class BodyMeasurementsUpdate(BodyMeasurementsBase):
    pass

class BodyMeasurementsResponse(BodyMeasurementsBase):
    id: int
    user_id: int
    measurements_date: datetime
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

# Authentication schemas
class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int

class TokenData(BaseModel):
    user_id: Optional[int] = None
    username: Optional[str] = None

class RefreshToken(BaseModel):
    refresh_token: str

class PasswordReset(BaseModel):
    email: EmailStr

class PasswordResetConfirm(BaseModel):
    token: str
    new_password: str = Field(..., min_length=8, max_length=128)
    confirm_password: str
    
    @validator('confirm_password')
    def passwords_match(cls, v, values):
        if 'new_password' in values and v != values['new_password']:
            raise ValueError('Passwords do not match')
        return v

class EmailVerification(BaseModel):
    token: str

# User interaction schemas
class UserInteractionBase(BaseModel):
    interaction_type: str = Field(..., max_length=50)
    target_type: Optional[str] = Field(None, max_length=50)
    target_id: Optional[int] = None
    interaction_data: Optional[Dict[str, Any]] = None

class UserInteractionCreate(UserInteractionBase):
    pass

class UserInteractionResponse(UserInteractionBase):
    id: int
    user_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

# Social connection schemas
class UserConnectionBase(BaseModel):
    followed_id: int

class UserConnectionCreate(UserConnectionBase):
    pass

class UserConnectionResponse(UserConnectionBase):
    id: int
    user_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

# Style insights schemas
class StyleInsightsBase(BaseModel):
    insight_type: str = Field(..., max_length=50)
    insight_data: Dict[str, Any]
    confidence_score: float = Field(..., ge=0, le=1)

class StyleInsightsCreate(StyleInsightsBase):
    pass

class StyleInsightsResponse(StyleInsightsBase):
    id: int
    user_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

# Complete user schemas
class UserWithProfile(UserResponse):
    profile: Optional[UserProfileResponse] = None
    preferences: Optional[StylePreferencesResponse] = None
    measurements: Optional[BodyMeasurementsResponse] = None

class UserDetailed(UserWithProfile):
    insights: List[StyleInsightsResponse] = []
    connections_count: int = 0
    followers_count: int = 0

# Search and filter schemas
class UserSearchParams(BaseModel):
    username: Optional[str] = None
    location: Optional[str] = None
    style_archetype: Optional[StyleArchetypeEnum] = None
    gender: Optional[GenderEnum] = None
    limit: int = Field(20, ge=1, le=100)
    offset: int = Field(0, ge=0)

class UserStats(BaseModel):
    total_users: int
    active_users: int
    verified_users: int
    new_users_today: int
    new_users_this_week: int
    new_users_this_month: int
