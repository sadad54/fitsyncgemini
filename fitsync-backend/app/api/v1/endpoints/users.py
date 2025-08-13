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
            color_preferences=preferences.preferred_colors,
            fit_preferences=preferences.fit_preferences,
            occasion_preferences=preferences.occasion_preferences,
            brand_preferences=preferences.preferred_brands,
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
            color_preferences=preferences.preferred_colors,
            fit_preferences=preferences.fit_preferences,
            occasion_preferences=preferences.occasion_preferences,
            brand_preferences=preferences.preferred_brands,
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
            color_preferences=preferences.preferred_colors,
            fit_preferences=preferences.fit_preferences,
            occasion_preferences=preferences.occasion_preferences,
            brand_preferences=preferences.preferred_brands,
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

@router.post("/quiz-completion", response_model=StylePreferencesResponse, status_code=status.HTTP_201_CREATED)
async def complete_quiz_and_assign_archetype(
    quiz_data: dict,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> Any:
    """
    Complete quiz and assign style archetype based on answers
    """
    try:
        # Analyze quiz answers to determine style archetype
        style_archetype = _analyze_quiz_answers(quiz_data)
        
        # Check if preferences already exist
        result = await db.execute(select(StylePreferences).where(StylePreferences.user_id == current_user.id))
        existing_preferences = result.scalar_one_or_none()
        
        if existing_preferences:
            # Update existing preferences
            existing_preferences.style_archetype = style_archetype
            existing_preferences.quiz_results = quiz_data
            await db.commit()
            await db.refresh(existing_preferences)
            
            logger.info(f"Style archetype updated for user: {current_user.email} -> {style_archetype}")
            
            return StylePreferencesResponse(
                id=existing_preferences.id,
                user_id=existing_preferences.user_id,
                style_archetype=existing_preferences.style_archetype,
                color_preferences=existing_preferences.preferred_colors,
                fit_preferences=existing_preferences.fit_preferences,
                occasion_preferences=existing_preferences.occasion_preferences,
                brand_preferences=existing_preferences.preferred_brands,
                budget_range=existing_preferences.budget_range,
                created_at=existing_preferences.created_at,
                updated_at=existing_preferences.updated_at
            )
        else:
            # Create new preferences
            preferences = StylePreferences(
                user_id=current_user.id,
                style_archetype=style_archetype,
                quiz_results=quiz_data,
                preferred_colors=_get_default_colors_for_archetype(style_archetype),
                preferred_styles=[style_archetype],
                fit_preferences=_get_default_fit_preferences(style_archetype),
                occasion_preferences=_get_default_occasion_preferences(style_archetype),
                preferred_brands=[],
                budget_range={"min": 0, "max": 1000}
            )
            
            db.add(preferences)
            await db.commit()
            await db.refresh(preferences)
            
            logger.info(f"Style archetype assigned for user: {current_user.email} -> {style_archetype}")
            
            return StylePreferencesResponse(
                id=preferences.id,
                user_id=preferences.user_id,
                style_archetype=preferences.style_archetype,
                color_preferences=preferences.preferred_colors,
                fit_preferences=preferences.fit_preferences,
                occasion_preferences=preferences.occasion_preferences,
                brand_preferences=preferences.preferred_brands,
                budget_range=preferences.budget_range,
                created_at=preferences.created_at,
                updated_at=preferences.updated_at
            )
        
    except Exception as e:
        await db.rollback()
        logger.error(f"Error completing quiz for user {current_user.email}: {e}")
        raise

def _analyze_quiz_answers(quiz_data: dict) -> str:
    """
    Analyze quiz answers to determine style archetype
    """
    # Define scoring system for each archetype
    archetype_scores = {
        'minimalist': 0,
        'classic': 0,
        'bohemian': 0,
        'streetwear': 0,
        'elegant': 0,
        'romantic': 0,
        'natural': 0,
        'dramatic': 0,
        'gamine': 0,
        'creative': 0
    }
    
    # Question 1: Ideal weekend outfit
    weekend_outfit = quiz_data.get('weekend_outfit', '')
    if 'comfortable jeans' in weekend_outfit.lower():
        archetype_scores['natural'] += 2
        archetype_scores['minimalist'] += 1
    elif 'flowy dress' in weekend_outfit.lower():
        archetype_scores['romantic'] += 2
        archetype_scores['bohemian'] += 1
    elif 'tailored pants' in weekend_outfit.lower():
        archetype_scores['classic'] += 2
        archetype_scores['elegant'] += 1
    elif 'athleisure' in weekend_outfit.lower():
        archetype_scores['streetwear'] += 2
        archetype_scores['natural'] += 1
    
    # Question 2: Color palette preference
    color_palette = quiz_data.get('color_palette', '')
    if 'neutral tones' in color_palette.lower():
        archetype_scores['minimalist'] += 2
        archetype_scores['classic'] += 1
    elif 'earthy and warm' in color_palette.lower():
        archetype_scores['natural'] += 2
        archetype_scores['bohemian'] += 1
    elif 'bright and bold' in color_palette.lower():
        archetype_scores['dramatic'] += 2
        archetype_scores['creative'] += 1
    elif 'pastels and soft' in color_palette.lower():
        archetype_scores['romantic'] += 2
        archetype_scores['elegant'] += 1
    
    # Question 3: Shoe style preference
    shoe_style = quiz_data.get('shoe_style', '')
    if 'classic leather' in shoe_style.lower():
        archetype_scores['classic'] += 2
        archetype_scores['elegant'] += 1
    elif 'strappy sandals' in shoe_style.lower():
        archetype_scores['romantic'] += 2
        archetype_scores['bohemian'] += 1
    elif 'minimalist sneakers' in shoe_style.lower():
        archetype_scores['minimalist'] += 2
        archetype_scores['streetwear'] += 1
    elif 'statement heels' in shoe_style.lower():
        archetype_scores['dramatic'] += 2
        archetype_scores['creative'] += 1
    
    # Question 4: Accessories approach
    accessories = quiz_data.get('accessories', '')
    if 'less is more' in accessories.lower():
        archetype_scores['minimalist'] += 2
        archetype_scores['classic'] += 1
    elif 'layered and eclectic' in accessories.lower():
        archetype_scores['bohemian'] += 2
        archetype_scores['creative'] += 1
    elif 'bold architectural' in accessories.lower():
        archetype_scores['dramatic'] += 2
        archetype_scores['elegant'] += 1
    elif 'no accessories' in accessories.lower():
        archetype_scores['minimalist'] += 2
        archetype_scores['natural'] += 1
    
    # Question 5: Print preference
    print_preference = quiz_data.get('print_preference', '')
    if 'solid colors' in print_preference.lower():
        archetype_scores['minimalist'] += 2
        archetype_scores['classic'] += 1
    elif 'floral or paisley' in print_preference.lower():
        archetype_scores['romantic'] += 2
        archetype_scores['bohemian'] += 1
    elif 'geometric or abstract' in print_preference.lower():
        archetype_scores['creative'] += 2
        archetype_scores['dramatic'] += 1
    elif 'animal print' in print_preference.lower():
        archetype_scores['dramatic'] += 2
        archetype_scores['streetwear'] += 1
    
    # Return the archetype with the highest score
    return max(archetype_scores.items(), key=lambda x: x[1])[0]

def _get_default_colors_for_archetype(archetype: str) -> List[str]:
    """Get default color preferences for each archetype"""
    color_mapping = {
        'minimalist': ['#000000', '#FFFFFF', '#808080', '#F5F5F5'],
        'classic': ['#000080', '#FFFFFF', '#000000', '#8B4513'],
        'bohemian': ['#8B4513', '#228B22', '#FF4500', '#4B0082'],
        'streetwear': ['#000000', '#FF0000', '#0000FF', '#FFFF00'],
        'elegant': ['#000000', '#FFFFFF', '#C0C0C0', '#800080'],
        'romantic': ['#FFB6C1', '#DDA0DD', '#F0E68C', '#FF69B4'],
        'natural': ['#228B22', '#8B4513', '#F4A460', '#DEB887'],
        'dramatic': ['#FF0000', '#000000', '#FFD700', '#800080'],
        'gamine': ['#000000', '#FFFFFF', '#FF69B4', '#00CED1'],
        'creative': ['#FF4500', '#00CED1', '#FF69B4', '#32CD32']
    }
    return color_mapping.get(archetype, ['#000000', '#FFFFFF'])

def _get_default_fit_preferences(archetype: str) -> dict:
    """Get default fit preferences for each archetype"""
    fit_mapping = {
        'minimalist': {'tailored': 0.8, 'regular': 0.6, 'loose': 0.2},
        'classic': {'tailored': 0.9, 'regular': 0.7, 'loose': 0.1},
        'bohemian': {'loose': 0.9, 'regular': 0.5, 'tailored': 0.2},
        'streetwear': {'regular': 0.8, 'loose': 0.6, 'tailored': 0.3},
        'elegant': {'tailored': 0.9, 'regular': 0.6, 'loose': 0.1},
        'romantic': {'regular': 0.7, 'loose': 0.6, 'tailored': 0.4},
        'natural': {'regular': 0.8, 'loose': 0.7, 'tailored': 0.3},
        'dramatic': {'tailored': 0.7, 'regular': 0.6, 'loose': 0.4},
        'gamine': {'tailored': 0.6, 'regular': 0.8, 'loose': 0.3},
        'creative': {'regular': 0.7, 'loose': 0.6, 'tailored': 0.5}
    }
    return fit_mapping.get(archetype, {'regular': 0.7, 'tailored': 0.5, 'loose': 0.3})

def _get_default_occasion_preferences(archetype: str) -> dict:
    """Get default occasion preferences for each archetype"""
    occasion_mapping = {
        'minimalist': {'casual': 0.8, 'business': 0.7, 'formal': 0.6, 'party': 0.4},
        'classic': {'business': 0.9, 'formal': 0.8, 'casual': 0.6, 'party': 0.5},
        'bohemian': {'casual': 0.9, 'party': 0.7, 'business': 0.3, 'formal': 0.2},
        'streetwear': {'casual': 0.9, 'party': 0.8, 'business': 0.2, 'formal': 0.1},
        'elegant': {'formal': 0.9, 'business': 0.8, 'party': 0.7, 'casual': 0.5},
        'romantic': {'party': 0.8, 'casual': 0.7, 'formal': 0.6, 'business': 0.4},
        'natural': {'casual': 0.9, 'business': 0.5, 'formal': 0.4, 'party': 0.6},
        'dramatic': {'party': 0.9, 'formal': 0.7, 'casual': 0.6, 'business': 0.5},
        'gamine': {'casual': 0.8, 'party': 0.7, 'business': 0.5, 'formal': 0.4},
        'creative': {'party': 0.8, 'casual': 0.7, 'business': 0.5, 'formal': 0.5}
    }
    return occasion_mapping.get(archetype, {'casual': 0.7, 'business': 0.5, 'formal': 0.5, 'party': 0.6})
