"""
User Service for business logic related to user management
"""

from sqlalchemy.orm import Session
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Optional, Dict, Any
import logging
from datetime import datetime, timedelta

from app.models.user import User, UserProfile, StylePreferences, BodyMeasurements
from app.schemas.user import (
    UserCreate, UserUpdate, UserProfileCreate, UserProfileUpdate,
    StylePreferencesCreate, StylePreferencesUpdate,
    BodyMeasurementsCreate, BodyMeasurementsUpdate
)
from app.core.security import SecurityManager
from app.core.exceptions import ValidationError, ResourceNotFoundError

logger = logging.getLogger(__name__)

class UserService:
    """Service class for user-related business logic"""
    
    @staticmethod
    async def create_user(db: AsyncSession, user_data: UserCreate) -> User:
        """
        Create a new user
        
        Args:
            db: Database session
            user_data: User creation data
            
        Returns:
            Created user
        """
        try:
            # Check if user already exists
            result = await db.execute(select(User).where(User.email == user_data.email))
            existing_user = result.scalar_one_or_none()
            if existing_user:
                raise ValidationError("User with this email already exists")
            
            # Hash password
            hashed_password = SecurityManager.hash_password(user_data.password)
            
            # Create user
            user = User(
                email=user_data.email,
                username=user_data.username,
                hashed_password=hashed_password,
                first_name=user_data.first_name,
                last_name=user_data.last_name,
                is_active=True,
                is_verified=False
            )
            
            db.add(user)
            await db.commit()
            await db.refresh(user)
            
            logger.info(f"User created: {user.email}")
            return user
            
        except Exception as e:
            await db.rollback()
            logger.error(f"Error creating user: {e}")
            raise
    
    @staticmethod
    async def get_user_by_id(db: AsyncSession, user_id: int) -> Optional[User]:
        """
        Get user by ID
        
        Args:
            db: Database session
            user_id: User ID
            
        Returns:
            User object or None
        """
        try:
            result = await db.execute(select(User).where(User.id == user_id))
            return result.scalar_one_or_none()
        except Exception as e:
            logger.error(f"Error getting user by ID: {e}")
            raise
    
    @staticmethod
    async def get_user_by_email(db: AsyncSession, email: str) -> Optional[User]:
        """
        Get user by email
        
        Args:
            db: Database session
            email: User email
            
        Returns:
            User object or None
        """
        try:
            result = await db.execute(select(User).where(User.email == email))
            return result.scalar_one_or_none()
        except Exception as e:
            logger.error(f"Error getting user by email: {e}")
            raise
    
    @staticmethod
    async def update_user(db: AsyncSession, user_id: int, user_data: UserUpdate) -> User:
        """
        Update user information
        
        Args:
            db: Database session
            user_id: User ID
            user_data: User update data
            
        Returns:
            Updated user
        """
        try:
            result = await db.execute(select(User).where(User.id == user_id))
            user = result.scalar_one_or_none()
            if not user:
                raise ResourceNotFoundError("User not found")
            
            # Update fields
            for field, value in user_data.dict(exclude_unset=True).items():
                setattr(user, field, value)
            
            await db.commit()
            await db.refresh(user)
            
            logger.info(f"User updated: {user.email}")
            return user
            
        except Exception as e:
            await db.rollback()
            logger.error(f"Error updating user: {e}")
            raise
    
    @staticmethod
    async def deactivate_user(db: AsyncSession, user_id: int) -> User:
        """
        Deactivate user account
        
        Args:
            db: Database session
            user_id: User ID
            
        Returns:
            Deactivated user
        """
        try:
            result = await db.execute(select(User).where(User.id == user_id))
            user = result.scalar_one_or_none()
            if not user:
                raise ResourceNotFoundError("User not found")
            
            user.is_active = False
            user.deactivated_at = datetime.utcnow()
            
            await db.commit()
            await db.refresh(user)
            
            logger.info(f"User deactivated: {user.email}")
            return user
            
        except Exception as e:
            await db.rollback()
            logger.error(f"Error deactivating user: {e}")
            raise
    
    @staticmethod
    async def create_user_profile(db: AsyncSession, user_id: int, profile_data: UserProfileCreate) -> UserProfile:
        """
        Create user profile
        
        Args:
            db: Database session
            user_id: User ID
            profile_data: Profile creation data
            
        Returns:
            Created profile
        """
        try:
            # Check if profile already exists
            result = await db.execute(select(UserProfile).where(UserProfile.user_id == user_id))
            existing_profile = result.scalar_one_or_none()
            if existing_profile:
                raise ValidationError("User profile already exists")
            
            # Create profile
            profile = UserProfile(
                user_id=user_id,
                **profile_data.dict()
            )
            
            db.add(profile)
            await db.commit()
            await db.refresh(profile)
            
            logger.info(f"User profile created for user: {user_id}")
            return profile
            
        except Exception as e:
            await db.rollback()
            logger.error(f"Error creating user profile: {e}")
            raise
    
    @staticmethod
    async def update_user_profile(db: AsyncSession, user_id: int, profile_data: UserProfileUpdate) -> UserProfile:
        """
        Update user profile
        
        Args:
            db: Database session
            user_id: User ID
            profile_data: Profile update data
            
        Returns:
            Updated profile
        """
        try:
            result = await db.execute(select(UserProfile).where(UserProfile.user_id == user_id))
            profile = result.scalar_one_or_none()
            if not profile:
                raise ResourceNotFoundError("User profile not found")
            
            # Update fields
            for field, value in profile_data.dict(exclude_unset=True).items():
                setattr(profile, field, value)
            
            await db.commit()
            await db.refresh(profile)
            
            logger.info(f"User profile updated for user: {user_id}")
            return profile
            
        except Exception as e:
            await db.rollback()
            logger.error(f"Error updating user profile: {e}")
            raise
    
    @staticmethod
    async def create_style_preferences(db: AsyncSession, user_id: int, preferences_data: StylePreferencesCreate) -> StylePreferences:
        """
        Create style preferences
        
        Args:
            db: Database session
            user_id: User ID
            preferences_data: Preferences creation data
            
        Returns:
            Created preferences
        """
        try:
            # Check if preferences already exist
            result = await db.execute(select(StylePreferences).where(StylePreferences.user_id == user_id))
            existing_preferences = result.scalar_one_or_none()
            if existing_preferences:
                raise ValidationError("Style preferences already exist")
            
            # Create preferences
            preferences = StylePreferences(
                user_id=user_id,
                **preferences_data.dict()
            )
            
            db.add(preferences)
            await db.commit()
            await db.refresh(preferences)
            
            logger.info(f"Style preferences created for user: {user_id}")
            return preferences
            
        except Exception as e:
            await db.rollback()
            logger.error(f"Error creating style preferences: {e}")
            raise
    
    @staticmethod
    async def update_style_preferences(db: AsyncSession, user_id: int, preferences_data: StylePreferencesUpdate) -> StylePreferences:
        """
        Update style preferences
        
        Args:
            db: Database session
            user_id: User ID
            preferences_data: Preferences update data
            
        Returns:
            Updated preferences
        """
        try:
            result = await db.execute(select(StylePreferences).where(StylePreferences.user_id == user_id))
            preferences = result.scalar_one_or_none()
            if not preferences:
                raise ResourceNotFoundError("Style preferences not found")
            
            # Update fields
            for field, value in preferences_data.dict(exclude_unset=True).items():
                setattr(preferences, field, value)
            
            await db.commit()
            await db.refresh(preferences)
            
            logger.info(f"Style preferences updated for user: {user_id}")
            return preferences
            
        except Exception as e:
            await db.rollback()
            logger.error(f"Error updating style preferences: {e}")
            raise
    
    @staticmethod
    async def create_body_measurements(db: AsyncSession, user_id: int, measurements_data: BodyMeasurementsCreate) -> BodyMeasurements:
        """
        Create body measurements
        
        Args:
            db: Database session
            user_id: User ID
            measurements_data: Measurements creation data
            
        Returns:
            Created measurements
        """
        try:
            # Check if measurements already exist
            result = await db.execute(select(BodyMeasurements).where(BodyMeasurements.user_id == user_id))
            existing_measurements = result.scalar_one_or_none()
            if existing_measurements:
                raise ValidationError("Body measurements already exist")
            
            # Create measurements
            measurements = BodyMeasurements(
                user_id=user_id,
                **measurements_data.dict()
            )
            
            db.add(measurements)
            await db.commit()
            await db.refresh(measurements)
            
            logger.info(f"Body measurements created for user: {user_id}")
            return measurements
            
        except Exception as e:
            await db.rollback()
            logger.error(f"Error creating body measurements: {e}")
            raise
    
    @staticmethod
    async def update_body_measurements(db: AsyncSession, user_id: int, measurements_data: BodyMeasurementsUpdate) -> BodyMeasurements:
        """
        Update body measurements
        
        Args:
            db: Database session
            user_id: User ID
            measurements_data: Measurements update data
            
        Returns:
            Updated measurements
        """
        try:
            result = await db.execute(select(BodyMeasurements).where(BodyMeasurements.user_id == user_id))
            measurements = result.scalar_one_or_none()
            if not measurements:
                raise ResourceNotFoundError("Body measurements not found")
            
            # Update fields
            for field, value in measurements_data.dict(exclude_unset=True).items():
                setattr(measurements, field, value)
            
            await db.commit()
            await db.refresh(measurements)
            
            logger.info(f"Body measurements updated for user: {user_id}")
            return measurements
            
        except Exception as e:
            await db.rollback()
            logger.error(f"Error updating body measurements: {e}")
            raise
    
    @staticmethod
    async def search_users(db: AsyncSession, query: Optional[str] = None, 
                    style_archetype: Optional[str] = None,
                    location: Optional[str] = None,
                    limit: int = 10, offset: int = 0,
                    exclude_user_id: Optional[int] = None) -> List[User]:
        """
        Search users with filters
        
        Args:
            db: Database session
            query: Search query
            style_archetype: Style archetype filter
            location: Location filter
            limit: Result limit
            offset: Result offset
            exclude_user_id: User ID to exclude
            
        Returns:
            List of users
        """
        try:
            user_query = select(User).where(User.is_active == True)
            
            if exclude_user_id:
                user_query = user_query.where(User.id != exclude_user_id)
            
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
            return result.scalars().all()
            
        except Exception as e:
            logger.error(f"Error searching users: {e}")
            raise
    
    @staticmethod
    async def get_user_statistics(db: AsyncSession, user_id: int) -> Dict[str, Any]:
        """
        Get user statistics
        
        Args:
            db: Database session
            user_id: User ID
            
        Returns:
            User statistics
        """
        try:
            result = await db.execute(select(User).where(User.id == user_id))
            user = result.scalar_one_or_none()
            if not user:
                raise ResourceNotFoundError("User not found")
            
            # Calculate statistics
            stats = {
                "user_id": user_id,
                "total_outfits": 0,  # TODO: Implement
                "total_items": 0,    # TODO: Implement
                "favorite_styles": [], # TODO: Implement
                "last_activity": user.last_login
            }
            
            return stats
            
        except Exception as e:
            logger.error(f"Error getting user statistics: {e}")
            raise
    
    @staticmethod
    async def verify_user_email(db: AsyncSession, user_id: int) -> User:
        """
        Verify user email
        
        Args:
            db: Database session
            user_id: User ID
            
        Returns:
            Verified user
        """
        try:
            result = await db.execute(select(User).where(User.id == user_id))
            user = result.scalar_one_or_none()
            if not user:
                raise ResourceNotFoundError("User not found")
            
            user.is_verified = True
            user.verified_at = datetime.utcnow()
            
            await db.commit()
            await db.refresh(user)
            
            logger.info(f"User email verified: {user.email}")
            return user
            
        except Exception as e:
            await db.rollback()
            logger.error(f"Error verifying user email: {e}")
            raise
    
    @staticmethod
    async def change_user_password(db: AsyncSession, user_id: int, new_password: str) -> User:
        """
        Change user password
        
        Args:
            db: Database session
            user_id: User ID
            new_password: New password
            
        Returns:
            Updated user
        """
        try:
            result = await db.execute(select(User).where(User.id == user_id))
            user = result.scalar_one_or_none()
            if not user:
                raise ResourceNotFoundError("User not found")
            
            # Hash new password
            hashed_password = SecurityManager.hash_password(new_password)
            user.hashed_password = hashed_password
            
            await db.commit()
            await db.refresh(user)
            
            logger.info(f"User password changed: {user.email}")
            return user
            
        except Exception as e:
            await db.rollback()
            logger.error(f"Error changing user password: {e}")
            raise
