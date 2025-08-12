"""
User management endpoints for profile management and user operations
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
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
    db: AsyncSession = Depends(get_db)
) -> Any:
    """
    Get current user's profile
    """
    try:
        result = await db.execute(select(UserProfile).where(UserProfile.user_id == current_user.id))
        profile = result.scalar_one_or_none()
        
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
    db: AsyncSession = Depends(get_db)
) -> Any:
    """
    Create user profile
    """
    try:
        # Check if profile already exists
        result = await db.execute(select(UserProfile).where(UserProfile.user_id == current_user.id))
        existing_profile = result.scalar_one_or_none()
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
        await db.commit()
        await db.refresh(profile)
        
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
        await db.rollback()
        logger.error(f"Error creating user profile: {e}")
        raise

@router.put("/profile", response_model=UserProfileResponse)
async def update_user_profile(
    profile_data: UserProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> Any:
    """
    Update user profile
    """
    try:
        result = await db.execute(select(UserProfile).where(UserProfile.user_id == current_user.id))
        profile = result.scalar_one_or_none()
        
        if not profile:
            raise ResourceNotFoundError("User profile not found")
        
        # Update fields
        for field, value in profile_data.dict(exclude_unset=True).items():
            setattr(profile, field, value)
        
        await db.commit()
        await db.refresh(profile)
        
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
        await db.rollback()
        logger.error(f"Error updating user profile: {e}")
        raise

@router.get("/style-preferences", response_model=StylePreferencesResponse)
async def get_style_preferences(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> Any:
    """
    Get user style preferences
    """
    try:
        result = await db.execute(select(StylePreferences).where(StylePreferences.user_id == current_user.id))
        preferences = result.scalar_one_or_none()
        
        if not preferences:
            raise ResourceNotFoundError("Style preferences not found")
        
        return StylePreferencesResponse(
            id=preferences.id,
            user_id=preferences.user_id,
            style_archetype=preferences.style_archetype,
            color_preferences=preferences.color_preferences,
            fit_preferences=preferences.fit_preferences,
            occasion_preferences=preferences.occasion_preferences,
            brand_preferences=preferences.brand_preferences,
            budget_range=preferences.budget_range,
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
    db: AsyncSession = Depends(get_db)
) -> Any:
    """
    Create user style preferences
    """
    try:
        # Check if preferences already exist
        result = await db.execute(select(StylePreferences).where(StylePreferences.user_id == current_user.id))
        existing_preferences = result.scalar_one_or_none()
        if existing_preferences:
            raise ValidationError("Style preferences already exist")
        
        preferences = StylePreferences(
            user_id=current_user.id,
            style_archetype=preferences_data.style_archetype,
            color_preferences=preferences_data.color_preferences,
            fit_preferences=preferences_data.fit_preferences,
            occasion_preferences=preferences_data.occasion_preferences,
            brand_preferences=preferences_data.brand_preferences,
            budget_range=preferences_data.budget_range
        )
        
        db.add(preferences)
        await db.commit()
        await db.refresh(preferences)
        
        logger.info(f"Style preferences created for user: {current_user.email}")
        
        return StylePreferencesResponse(
            id=preferences.id,
            user_id=preferences.user_id,
            style_archetype=preferences.style_archetype,
            color_preferences=preferences.color_preferences,
            fit_preferences=preferences.fit_preferences,
            occasion_preferences=preferences.occasion_preferences,
            brand_preferences=preferences.brand_preferences,
            budget_range=preferences.budget_range,
            created_at=preferences.created_at,
            updated_at=preferences.updated_at
        )
        
    except Exception as e:
        await db.rollback()
        logger.error(f"Error creating style preferences: {e}")
        raise

@router.put("/style-preferences", response_model=StylePreferencesResponse)
async def update_style_preferences(
    preferences_data: StylePreferencesUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> Any:
    """
    Update user style preferences
    """
    try:
        result = await db.execute(select(StylePreferences).where(StylePreferences.user_id == current_user.id))
        preferences = result.scalar_one_or_none()
        
        if not preferences:
            raise ResourceNotFoundError("Style preferences not found")
        
        # Update fields
        for field, value in preferences_data.dict(exclude_unset=True).items():
            setattr(preferences, field, value)
        
        await db.commit()
        await db.refresh(preferences)
        
        logger.info(f"Style preferences updated for user: {current_user.email}")
        
        return StylePreferencesResponse(
            id=preferences.id,
            user_id=preferences.user_id,
            style_archetype=preferences.style_archetype,
            color_preferences=preferences.color_preferences,
            fit_preferences=preferences.fit_preferences,
            occasion_preferences=preferences.occasion_preferences,
            brand_preferences=preferences.brand_preferences,
            budget_range=preferences.budget_range,
            created_at=preferences.created_at,
            updated_at=preferences.updated_at
        )
        
    except Exception as e:
        await db.rollback()
        logger.error(f"Error updating style preferences: {e}")
        raise

@router.get("/body-measurements", response_model=BodyMeasurementsResponse)
async def get_body_measurements(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> Any:
    """
    Get user body measurements
    """
    try:
        result = await db.execute(select(BodyMeasurements).where(BodyMeasurements.user_id == current_user.id))
        measurements = result.scalar_one_or_none()
        
        if not measurements:
            raise ResourceNotFoundError("Body measurements not found")
        
        return BodyMeasurementsResponse(
            id=measurements.id,
            user_id=measurements.user_id,
            height=measurements.height,
            weight=measurements.weight,
            chest=measurements.chest,
            waist=measurements.waist,
            hips=measurements.hips,
            inseam=measurements.inseam,
            shoulder_width=measurements.shoulder_width,
            arm_length=measurements.arm_length,
            neck=measurements.neck,
            shoe_size=measurements.shoe_size,
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
    db: AsyncSession = Depends(get_db)
) -> Any:
    """
    Create user body measurements
    """
    try:
        # Check if measurements already exist
        result = await db.execute(select(BodyMeasurements).where(BodyMeasurements.user_id == current_user.id))
        existing_measurements = result.scalar_one_or_none()
        if existing_measurements:
            raise ValidationError("Body measurements already exist")
        
        measurements = BodyMeasurements(
            user_id=current_user.id,
            height=measurements_data.height,
            weight=measurements_data.weight,
            chest=measurements_data.chest,
            waist=measurements_data.waist,
            hips=measurements_data.hips,
            inseam=measurements_data.inseam,
            shoulder_width=measurements_data.shoulder_width,
            arm_length=measurements_data.arm_length,
            neck=measurements_data.neck,
            shoe_size=measurements_data.shoe_size
        )
        
        db.add(measurements)
        await db.commit()
        await db.refresh(measurements)
        
        logger.info(f"Body measurements created for user: {current_user.email}")
        
        return BodyMeasurementsResponse(
            id=measurements.id,
            user_id=measurements.user_id,
            height=measurements.height,
            weight=measurements.weight,
            chest=measurements.chest,
            waist=measurements.waist,
            hips=measurements.hips,
            inseam=measurements.inseam,
            shoulder_width=measurements.shoulder_width,
            arm_length=measurements.arm_length,
            neck=measurements.neck,
            shoe_size=measurements.shoe_size,
            created_at=measurements.created_at,
            updated_at=measurements.updated_at
        )
        
    except Exception as e:
        await db.rollback()
        logger.error(f"Error creating body measurements: {e}")
        raise

@router.put("/body-measurements", response_model=BodyMeasurementsResponse)
async def update_body_measurements(
    measurements_data: BodyMeasurementsUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> Any:
    """
    Update user body measurements
    """
    try:
        result = await db.execute(select(BodyMeasurements).where(BodyMeasurements.user_id == current_user.id))
        measurements = result.scalar_one_or_none()
        
        if not measurements:
            raise ResourceNotFoundError("Body measurements not found")
        
        # Update fields
        for field, value in measurements_data.dict(exclude_unset=True).items():
            setattr(measurements, field, value)
        
        await db.commit()
        await db.refresh(measurements)
        
        logger.info(f"Body measurements updated for user: {current_user.email}")
        
        return BodyMeasurementsResponse(
            id=measurements.id,
            user_id=measurements.user_id,
            height=measurements.height,
            weight=measurements.weight,
            chest=measurements.chest,
            waist=measurements.waist,
            hips=measurements.hips,
            inseam=measurements.inseam,
            shoulder_width=measurements.shoulder_width,
            arm_length=measurements.arm_length,
            neck=measurements.neck,
            shoe_size=measurements.shoe_size,
            created_at=measurements.created_at,
            updated_at=measurements.updated_at
        )
        
    except Exception as e:
        await db.rollback()
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
    db: AsyncSession = Depends(get_db)
) -> Any:
    """
    Search users with filters
    """
    try:
        user_query = select(User).where(User.is_active == True)
        
        if query:
            user_query = user_query.where(
                User.username.contains(query) |
                User.first_name.contains(query) |
                User.last_name.contains(query)
            )
        
        if style_archetype:
            # Join with style preferences if needed
            pass
        
        if location:
            # Join with user profile if needed
            pass
        
        user_query = user_query.limit(limit).offset(offset)
        
        result = await db.execute(user_query)
        users = result.scalars().all()
        
        return [UserResponse.from_orm(user) for user in users]
        
    except Exception as e:
        logger.error(f"Error searching users: {e}")
        raise

@router.get("/{user_id}", response_model=UserDetailed)
async def get_user_by_id(
    user_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> Any:
    """
    Get user by ID
    """
    try:
        result = await db.execute(select(User).where(User.id == user_id, User.is_active == True))
        user = result.scalar_one_or_none()
        
        if not user:
            raise ResourceNotFoundError("User not found")
        
        result = await db.execute(select(UserProfile).where(UserProfile.user_id == user_id))
        profile = result.scalar_one_or_none()
        
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
    db: AsyncSession = Depends(get_db)
) -> Any:
    """
    Get current user statistics
    """
    try:
        # Calculate statistics
        stats = {
            "user_id": current_user.id,
            "total_outfits": 0,  # TODO: Implement
            "total_items": 0,    # TODO: Implement
            "favorite_styles": [], # TODO: Implement
            "last_activity": current_user.last_login
        }
        
        return UserStats(**stats)
        
    except Exception as e:
        logger.error(f"Error getting user stats: {e}")
        raise
