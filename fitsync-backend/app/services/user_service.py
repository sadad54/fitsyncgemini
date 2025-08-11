"""
User Service for business logic related to user management
"""

from sqlalchemy.orm import Session
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
    def create_user(db: Session, user_data: UserCreate) -> User:
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
            existing_user = db.query(User).filter(User.email == user_data.email).first()
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
            db.commit()
            db.refresh(user)
            
            logger.info(f"User created: {user.email}")
            return user
            
        except Exception as e:
            db.rollback()
            logger.error(f"Error creating user: {e}")
            raise
    
    @staticmethod
    def get_user_by_id(db: Session, user_id: int) -> Optional[User]:
        """
        Get user by ID
        
        Args:
            db: Database session
            user_id: User ID
            
        Returns:
            User object or None
        """
        try:
            return db.query(User).filter(User.id == user_id).first()
        except Exception as e:
            logger.error(f"Error getting user by ID: {e}")
            raise
    
    @staticmethod
    def get_user_by_email(db: Session, email: str) -> Optional[User]:
        """
        Get user by email
        
        Args:
            db: Database session
            email: User email
            
        Returns:
            User object or None
        """
        try:
            return db.query(User).filter(User.email == email).first()
        except Exception as e:
            logger.error(f"Error getting user by email: {e}")
            raise
    
    @staticmethod
    def update_user(db: Session, user_id: int, user_data: UserUpdate) -> User:
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
            user = db.query(User).filter(User.id == user_id).first()
            if not user:
                raise ResourceNotFoundError("User not found")
            
            # Update fields
            update_data = user_data.dict(exclude_unset=True)
            for field, value in update_data.items():
                setattr(user, field, value)
            
            db.commit()
            db.refresh(user)
            
            logger.info(f"User updated: {user.email}")
            return user
            
        except Exception as e:
            db.rollback()
            logger.error(f"Error updating user: {e}")
            raise
    
    @staticmethod
    def deactivate_user(db: Session, user_id: int) -> User:
        """
        Deactivate user account
        
        Args:
            db: Database session
            user_id: User ID
            
        Returns:
            Deactivated user
        """
        try:
            user = db.query(User).filter(User.id == user_id).first()
            if not user:
                raise ResourceNotFoundError("User not found")
            
            user.is_active = False
            db.commit()
            db.refresh(user)
            
            logger.info(f"User deactivated: {user.email}")
            return user
            
        except Exception as e:
            db.rollback()
            logger.error(f"Error deactivating user: {e}")
            raise
    
    @staticmethod
    def create_user_profile(db: Session, user_id: int, profile_data: UserProfileCreate) -> UserProfile:
        """
        Create user profile
        
        Args:
            db: Database session
            user_id: User ID
            profile_data: Profile creation data
            
        Returns:
            Created user profile
        """
        try:
            # Check if profile already exists
            existing_profile = db.query(UserProfile).filter(UserProfile.user_id == user_id).first()
            if existing_profile:
                raise ValidationError("User profile already exists")
            
            profile = UserProfile(
                user_id=user_id,
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
            
            logger.info(f"User profile created for user: {user_id}")
            return profile
            
        except Exception as e:
            db.rollback()
            logger.error(f"Error creating user profile: {e}")
            raise
    
    @staticmethod
    def update_user_profile(db: Session, user_id: int, profile_data: UserProfileUpdate) -> UserProfile:
        """
        Update user profile
        
        Args:
            db: Database session
            user_id: User ID
            profile_data: Profile update data
            
        Returns:
            Updated user profile
        """
        try:
            profile = db.query(UserProfile).filter(UserProfile.user_id == user_id).first()
            if not profile:
                raise ResourceNotFoundError("User profile not found")
            
            # Update fields
            update_data = profile_data.dict(exclude_unset=True)
            for field, value in update_data.items():
                setattr(profile, field, value)
            
            db.commit()
            db.refresh(profile)
            
            logger.info(f"User profile updated for user: {user_id}")
            return profile
            
        except Exception as e:
            db.rollback()
            logger.error(f"Error updating user profile: {e}")
            raise
    
    @staticmethod
    def create_style_preferences(db: Session, user_id: int, preferences_data: StylePreferencesCreate) -> StylePreferences:
        """
        Create user style preferences
        
        Args:
            db: Database session
            user_id: User ID
            preferences_data: Style preferences creation data
            
        Returns:
            Created style preferences
        """
        try:
            # Check if preferences already exist
            existing_preferences = db.query(StylePreferences).filter(StylePreferences.user_id == user_id).first()
            if existing_preferences:
                raise ValidationError("Style preferences already exist")
            
            preferences = StylePreferences(
                user_id=user_id,
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
            
            logger.info(f"Style preferences created for user: {user_id}")
            return preferences
            
        except Exception as e:
            db.rollback()
            logger.error(f"Error creating style preferences: {e}")
            raise
    
    @staticmethod
    def update_style_preferences(db: Session, user_id: int, preferences_data: StylePreferencesUpdate) -> StylePreferences:
        """
        Update user style preferences
        
        Args:
            db: Database session
            user_id: User ID
            preferences_data: Style preferences update data
            
        Returns:
            Updated style preferences
        """
        try:
            preferences = db.query(StylePreferences).filter(StylePreferences.user_id == user_id).first()
            if not preferences:
                raise ResourceNotFoundError("Style preferences not found")
            
            # Update fields
            update_data = preferences_data.dict(exclude_unset=True)
            for field, value in update_data.items():
                setattr(preferences, field, value)
            
            db.commit()
            db.refresh(preferences)
            
            logger.info(f"Style preferences updated for user: {user_id}")
            return preferences
            
        except Exception as e:
            db.rollback()
            logger.error(f"Error updating style preferences: {e}")
            raise
    
    @staticmethod
    def create_body_measurements(db: Session, user_id: int, measurements_data: BodyMeasurementsCreate) -> BodyMeasurements:
        """
        Create user body measurements
        
        Args:
            db: Database session
            user_id: User ID
            measurements_data: Body measurements creation data
            
        Returns:
            Created body measurements
        """
        try:
            # Check if measurements already exist
            existing_measurements = db.query(BodyMeasurements).filter(BodyMeasurements.user_id == user_id).first()
            if existing_measurements:
                raise ValidationError("Body measurements already exist")
            
            measurements = BodyMeasurements(
                user_id=user_id,
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
            
            logger.info(f"Body measurements created for user: {user_id}")
            return measurements
            
        except Exception as e:
            db.rollback()
            logger.error(f"Error creating body measurements: {e}")
            raise
    
    @staticmethod
    def update_body_measurements(db: Session, user_id: int, measurements_data: BodyMeasurementsUpdate) -> BodyMeasurements:
        """
        Update user body measurements
        
        Args:
            db: Database session
            user_id: User ID
            measurements_data: Body measurements update data
            
        Returns:
            Updated body measurements
        """
        try:
            measurements = db.query(BodyMeasurements).filter(BodyMeasurements.user_id == user_id).first()
            if not measurements:
                raise ResourceNotFoundError("Body measurements not found")
            
            # Update fields
            update_data = measurements_data.dict(exclude_unset=True)
            for field, value in update_data.items():
                setattr(measurements, field, value)
            
            db.commit()
            db.refresh(measurements)
            
            logger.info(f"Body measurements updated for user: {user_id}")
            return measurements
            
        except Exception as e:
            db.rollback()
            logger.error(f"Error updating body measurements: {e}")
            raise
    
    @staticmethod
    def search_users(db: Session, query: Optional[str] = None, 
                    style_archetype: Optional[str] = None,
                    location: Optional[str] = None,
                    limit: int = 10, offset: int = 0,
                    exclude_user_id: Optional[int] = None) -> List[User]:
        """
        Search for users with filters
        
        Args:
            db: Database session
            query: Search query
            style_archetype: Style archetype filter
            location: Location filter
            limit: Number of results to return
            offset: Number of results to skip
            exclude_user_id: User ID to exclude from results
            
        Returns:
            List of users
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
            
            if exclude_user_id:
                user_query = user_query.filter(User.id != exclude_user_id)
            
            # Apply pagination
            users = user_query.offset(offset).limit(limit).all()
            
            return users
            
        except Exception as e:
            logger.error(f"Error searching users: {e}")
            raise
    
    @staticmethod
    def get_user_statistics(db: Session, user_id: int) -> Dict[str, Any]:
        """
        Get user statistics
        
        Args:
            db: Database session
            user_id: User ID
            
        Returns:
            Dictionary with user statistics
        """
        try:
            # This would typically include various user statistics
            # For now, we'll return basic stats
            stats = {
                "total_outfits": 0,  # Would be calculated from database
                "total_items": 0,    # Would be calculated from database
                "followers_count": 0, # Would be calculated from database
                "following_count": 0, # Would be calculated from database
                "total_likes": 0,    # Would be calculated from database
                "total_shares": 0    # Would be calculated from database
            }
            
            return stats
            
        except Exception as e:
            logger.error(f"Error getting user statistics: {e}")
            raise
    
    @staticmethod
    def verify_user_email(db: Session, user_id: int) -> User:
        """
        Verify user email address
        
        Args:
            db: Database session
            user_id: User ID
            
        Returns:
            Updated user
        """
        try:
            user = db.query(User).filter(User.id == user_id).first()
            if not user:
                raise ResourceNotFoundError("User not found")
            
            user.is_verified = True
            db.commit()
            db.refresh(user)
            
            logger.info(f"Email verified for user: {user.email}")
            return user
            
        except Exception as e:
            db.rollback()
            logger.error(f"Error verifying user email: {e}")
            raise
    
    @staticmethod
    def change_user_password(db: Session, user_id: int, new_password: str) -> User:
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
            user = db.query(User).filter(User.id == user_id).first()
            if not user:
                raise ResourceNotFoundError("User not found")
            
            # Hash new password
            hashed_password = SecurityManager.hash_password(new_password)
            user.hashed_password = hashed_password
            
            db.commit()
            db.refresh(user)
            
            logger.info(f"Password changed for user: {user.email}")
            return user
            
        except Exception as e:
            db.rollback()
            logger.error(f"Error changing user password: {e}")
            raise
