"""
User management endpoints for profile management and user operations
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import Any, List, Optional
import logging

from app.core.security import SecurityManager, get_current_user
from app.database import get_db
from app.schemas.user import (
    UserResponse, UserUpdate, UserProfileCreate, UserProfileUpdate, UserProfileResponse,
    StylePreferencesCreate, StylePreferencesUpdate, StylePreferencesResponse,
    BodyMeasurementsCreate, BodyMeasurementsUpdate, BodyMeasurementsResponse,
    UserDetailed, UserSearchParams, UserStats
)
from app.models.user import User, UserProfile, StylePreferences, BodyMeasurements
from app.core.exceptions import ResourceNotFoundError, ValidationError

logger = logging.getLogger(__name__)

router = APIRouter()

@router.get("/profile", response_model=UserProfileResponse)
async def get_user_profile(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Get current user's profile
    """
    try:
        profile = db.query(UserProfile).filter(UserProfile.user_id == current_user.id).first()
        
        if not profile:
            raise ResourceNotFoundError("User profile not found")
        
        return UserProfileResponse(
            id=profile.id,
            user_id=profile.user_id,
            bio=profile.bio,
            location=profile.location,
            birth_date=profile.birth_date,
            gender=profile.gender,
            phone_number=profile.phone_number,
            social_media_links=profile.social_media_links,
            created_at=profile.created_at,
            updated_at=profile.updated_at
        )
        
    except Exception as e:
        logger.error(f"Error getting user profile: {e}")
        raise

@router.post("/profile", response_model=UserProfileResponse, status_code=status.HTTP_201_CREATED)
async def create_user_profile(
    profile_data: UserProfileCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Create user profile
    """
    try:
        # Check if profile already exists
        existing_profile = db.query(UserProfile).filter(UserProfile.user_id == current_user.id).first()
        if existing_profile:
            raise ValidationError("User profile already exists")
        
        profile = UserProfile(
            user_id=current_user.id,
            bio=profile_data.bio,
            location=profile_data.location,
            birth_date=profile_data.birth_date,
            gender=profile_data.gender,
            phone_number=profile_data.phone_number,
            social_media_links=profile_data.social_media_links
        )
        
        db.add(profile)
        db.commit()
        db.refresh(profile)
        
        logger.info(f"User profile created for user: {current_user.email}")
        
        return UserProfileResponse(
            id=profile.id,
            user_id=profile.user_id,
            bio=profile.bio,
            location=profile.location,
            birth_date=profile.birth_date,
            gender=profile.gender,
            phone_number=profile.phone_number,
            social_media_links=profile.social_media_links,
            created_at=profile.created_at,
            updated_at=profile.updated_at
        )
        
    except Exception as e:
        db.rollback()
        logger.error(f"Error creating user profile: {e}")
        raise

@router.put("/profile", response_model=UserProfileResponse)
async def update_user_profile(
    profile_data: UserProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Update user profile
    """
    try:
        profile = db.query(UserProfile).filter(UserProfile.user_id == current_user.id).first()
        
        if not profile:
            raise ResourceNotFoundError("User profile not found")
        
        # Update fields
        update_data = profile_data.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(profile, field, value)
        
        db.commit()
        db.refresh(profile)
        
        logger.info(f"User profile updated for user: {current_user.email}")
        
        return UserProfileResponse(
            id=profile.id,
            user_id=profile.user_id,
            bio=profile.bio,
            location=profile.location,
            birth_date=profile.birth_date,
            gender=profile.gender,
            phone_number=profile.phone_number,
            social_media_links=profile.social_media_links,
            created_at=profile.created_at,
            updated_at=profile.updated_at
        )
        
    except Exception as e:
        db.rollback()
        logger.error(f"Error updating user profile: {e}")
        raise

@router.get("/style-preferences", response_model=StylePreferencesResponse)
async def get_style_preferences(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Get user's style preferences
    """
    try:
        preferences = db.query(StylePreferences).filter(StylePreferences.user_id == current_user.id).first()
        
        if not preferences:
            raise ResourceNotFoundError("Style preferences not found")
        
        return StylePreferencesResponse(
            id=preferences.id,
            user_id=preferences.user_id,
            style_archetype=preferences.style_archetype,
            color_preferences=preferences.color_preferences,
            brand_preferences=preferences.brand_preferences,
            price_range_min=preferences.price_range_min,
            price_range_max=preferences.price_range_max,
            size_preferences=preferences.size_preferences,
            occasion_preferences=preferences.occasion_preferences,
            seasonal_preferences=preferences.seasonal_preferences,
            created_at=preferences.created_at,
            updated_at=preferences.updated_at
        )
        
    except Exception as e:
        logger.error(f"Error getting style preferences: {e}")
        raise

@router.post("/style-preferences", response_model=StylePreferencesResponse, status_code=status.HTTP_201_CREATED)
async def create_style_preferences(
    preferences_data: StylePreferencesCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Create user's style preferences
    """
    try:
        # Check if preferences already exist
        existing_preferences = db.query(StylePreferences).filter(StylePreferences.user_id == current_user.id).first()
        if existing_preferences:
            raise ValidationError("Style preferences already exist")
        
        preferences = StylePreferences(
            user_id=current_user.id,
            style_archetype=preferences_data.style_archetype,
            color_preferences=preferences_data.color_preferences,
            brand_preferences=preferences_data.brand_preferences,
            price_range_min=preferences_data.price_range_min,
            price_range_max=preferences_data.price_range_max,
            size_preferences=preferences_data.size_preferences,
            occasion_preferences=preferences_data.occasion_preferences,
            seasonal_preferences=preferences_data.seasonal_preferences
        )
        
        db.add(preferences)
        db.commit()
        db.refresh(preferences)
        
        logger.info(f"Style preferences created for user: {current_user.email}")
        
        return StylePreferencesResponse(
            id=preferences.id,
            user_id=preferences.user_id,
            style_archetype=preferences.style_archetype,
            color_preferences=preferences.color_preferences,
            brand_preferences=preferences.brand_preferences,
            price_range_min=preferences.price_range_min,
            price_range_max=preferences.price_range_max,
            size_preferences=preferences.size_preferences,
            occasion_preferences=preferences.occasion_preferences,
            seasonal_preferences=preferences.seasonal_preferences,
            created_at=preferences.created_at,
            updated_at=preferences.updated_at
        )
        
    except Exception as e:
        db.rollback()
        logger.error(f"Error creating style preferences: {e}")
        raise

@router.put("/style-preferences", response_model=StylePreferencesResponse)
async def update_style_preferences(
    preferences_data: StylePreferencesUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Update user's style preferences
    """
    try:
        preferences = db.query(StylePreferences).filter(StylePreferences.user_id == current_user.id).first()
        
        if not preferences:
            raise ResourceNotFoundError("Style preferences not found")
        
        # Update fields
        update_data = preferences_data.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(preferences, field, value)
        
        db.commit()
        db.refresh(preferences)
        
        logger.info(f"Style preferences updated for user: {current_user.email}")
        
        return StylePreferencesResponse(
            id=preferences.id,
            user_id=preferences.user_id,
            style_archetype=preferences.style_archetype,
            color_preferences=preferences.color_preferences,
            brand_preferences=preferences.brand_preferences,
            price_range_min=preferences.price_range_min,
            price_range_max=preferences.price_range_max,
            size_preferences=preferences.size_preferences,
            occasion_preferences=preferences.occasion_preferences,
            seasonal_preferences=preferences.seasonal_preferences,
            created_at=preferences.created_at,
            updated_at=preferences.updated_at
        )
        
    except Exception as e:
        db.rollback()
        logger.error(f"Error updating style preferences: {e}")
        raise

@router.get("/body-measurements", response_model=BodyMeasurementsResponse)
async def get_body_measurements(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Get user's body measurements
    """
    try:
        measurements = db.query(BodyMeasurements).filter(BodyMeasurements.user_id == current_user.id).first()
        
        if not measurements:
            raise ResourceNotFoundError("Body measurements not found")
        
        return BodyMeasurementsResponse(
            id=measurements.id,
            user_id=measurements.user_id,
            height=measurements.height,
            weight=measurements.weight,
            chest_circumference=measurements.chest_circumference,
            waist_circumference=measurements.waist_circumference,
            hip_circumference=measurements.hip_circumference,
            shoulder_width=measurements.shoulder_width,
            inseam_length=measurements.inseam_length,
            arm_length=measurements.arm_length,
            body_type=measurements.body_type,
            created_at=measurements.created_at,
            updated_at=measurements.updated_at
        )
        
    except Exception as e:
        logger.error(f"Error getting body measurements: {e}")
        raise

@router.post("/body-measurements", response_model=BodyMeasurementsResponse, status_code=status.HTTP_201_CREATED)
async def create_body_measurements(
    measurements_data: BodyMeasurementsCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Create user's body measurements
    """
    try:
        # Check if measurements already exist
        existing_measurements = db.query(BodyMeasurements).filter(BodyMeasurements.user_id == current_user.id).first()
        if existing_measurements:
            raise ValidationError("Body measurements already exist")
        
        measurements = BodyMeasurements(
            user_id=current_user.id,
            height=measurements_data.height,
            weight=measurements_data.weight,
            chest_circumference=measurements_data.chest_circumference,
            waist_circumference=measurements_data.waist_circumference,
            hip_circumference=measurements_data.hip_circumference,
            shoulder_width=measurements_data.shoulder_width,
            inseam_length=measurements_data.inseam_length,
            arm_length=measurements_data.arm_length,
            body_type=measurements_data.body_type
        )
        
        db.add(measurements)
        db.commit()
        db.refresh(measurements)
        
        logger.info(f"Body measurements created for user: {current_user.email}")
        
        return BodyMeasurementsResponse(
            id=measurements.id,
            user_id=measurements.user_id,
            height=measurements.height,
            weight=measurements.weight,
            chest_circumference=measurements.chest_circumference,
            waist_circumference=measurements.waist_circumference,
            hip_circumference=measurements.hip_circumference,
            shoulder_width=measurements.shoulder_width,
            inseam_length=measurements.inseam_length,
            arm_length=measurements.arm_length,
            body_type=measurements.body_type,
            created_at=measurements.created_at,
            updated_at=measurements.updated_at
        )
        
    except Exception as e:
        db.rollback()
        logger.error(f"Error creating body measurements: {e}")
        raise

@router.put("/body-measurements", response_model=BodyMeasurementsResponse)
async def update_body_measurements(
    measurements_data: BodyMeasurementsUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Update user's body measurements
    """
    try:
        measurements = db.query(BodyMeasurements).filter(BodyMeasurements.user_id == current_user.id).first()
        
        if not measurements:
            raise ResourceNotFoundError("Body measurements not found")
        
        # Update fields
        update_data = measurements_data.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(measurements, field, value)
        
        db.commit()
        db.refresh(measurements)
        
        logger.info(f"Body measurements updated for user: {current_user.email}")
        
        return BodyMeasurementsResponse(
            id=measurements.id,
            user_id=measurements.user_id,
            height=measurements.height,
            weight=measurements.weight,
            chest_circumference=measurements.chest_circumference,
            waist_circumference=measurements.waist_circumference,
            hip_circumference=measurements.hip_circumference,
            shoulder_width=measurements.shoulder_width,
            inseam_length=measurements.inseam_length,
            arm_length=measurements.arm_length,
            body_type=measurements.body_type,
            created_at=measurements.created_at,
            updated_at=measurements.updated_at
        )
        
    except Exception as e:
        db.rollback()
        logger.error(f"Error updating body measurements: {e}")
        raise

@router.get("/search", response_model=List[UserResponse])
async def search_users(
    query: Optional[str] = Query(None, description="Search query"),
    style_archetype: Optional[str] = Query(None, description="Style archetype filter"),
    location: Optional[str] = Query(None, description="Location filter"),
    limit: int = Query(10, ge=1, le=100, description="Number of results to return"),
    offset: int = Query(0, ge=0, description="Number of results to skip"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Search for users
    """
    try:
        # Build query
        user_query = db.query(User).filter(User.is_active == True)
        
        # Apply filters
        if query:
            user_query = user_query.filter(
                (User.username.contains(query)) |
                (User.first_name.contains(query)) |
                (User.last_name.contains(query))
            )
        
        if style_archetype:
            user_query = user_query.join(UserProfile).join(StylePreferences).filter(
                StylePreferences.style_archetype == style_archetype
            )
        
        if location:
            user_query = user_query.join(UserProfile).filter(
                UserProfile.location.contains(location)
            )
        
        # Exclude current user
        user_query = user_query.filter(User.id != current_user.id)
        
        # Apply pagination
        users = user_query.offset(offset).limit(limit).all()
        
        return [
            UserResponse(
                id=user.id,
                email=user.email,
                username=user.username,
                first_name=user.first_name,
                last_name=user.last_name,
                is_active=user.is_active,
                is_verified=user.is_verified,
                created_at=user.created_at
            )
            for user in users
        ]
        
    except Exception as e:
        logger.error(f"Error searching users: {e}")
        raise

@router.get("/{user_id}", response_model=UserDetailed)
async def get_user_by_id(
    user_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Get user by ID (public profile)
    """
    try:
        user = db.query(User).filter(User.id == user_id, User.is_active == True).first()
        
        if not user:
            raise ResourceNotFoundError("User not found")
        
        # Get user profile
        profile = db.query(UserProfile).filter(UserProfile.user_id == user_id).first()
        
        return UserDetailed(
            id=user.id,
            email=user.email,
            username=user.username,
            first_name=user.first_name,
            last_name=user.last_name,
            is_active=user.is_active,
            is_verified=user.is_verified,
            created_at=user.created_at,
            profile=profile
        )
        
    except Exception as e:
        logger.error(f"Error getting user by ID: {e}")
        raise

@router.get("/stats/me", response_model=UserStats)
async def get_user_stats(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Get current user's statistics
    """
    try:
        # This would typically include various user statistics
        # For now, we'll return basic stats
        stats = UserStats(
            total_outfits=0,  # Would be calculated from database
            total_items=0,    # Would be calculated from database
            followers_count=0, # Would be calculated from database
            following_count=0, # Would be calculated from database
            total_likes=0,    # Would be calculated from database
            total_shares=0    # Would be calculated from database
        )
        
        return stats
        
    except Exception as e:
        logger.error(f"Error getting user stats: {e}")
        raise
