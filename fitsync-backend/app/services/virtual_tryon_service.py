"""
Virtual Try-On Service
"""

import asyncio
import uuid
from typing import List, Dict, Any, Optional, Tuple
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_, desc

from app.models.virtual_tryon import (
    TryOnSession, TryOnOutfitAttempt, TryOnFeature, 
    UserTryOnPreferences, TryOnAnalytics,
    ViewModeEnum, TryOnStatusEnum
)
from app.models.user import User
from app.schemas.virtual_tryon import (
    TryOnSessionCreate, TryOnSessionUpdate, TryOnOutfitAttemptCreate,
    TryOnPreferencesCreate, QuickOutfitSuggestion, DeviceCapabilities,
    FitAnalysisDetail, ColorAnalysisDetail
)
from app.services.enhanced_ml_service import enhanced_ml_service
from app.services.cache_service import CacheService
import logging

logger = logging.getLogger(__name__)

class VirtualTryOnService:
    """Service for handling virtual try-on functionality"""
    
    @staticmethod
    async def create_session(
        db: Session, 
        user: User, 
        session_data: TryOnSessionCreate
    ) -> TryOnSession:
        """Create a new try-on session"""
        try:
            session = TryOnSession(
                user_id=user.id,
                session_name=session_data.session_name,
                view_mode=session_data.view_mode.value,
                device_info=session_data.device_info or {},
                status=TryOnStatusEnum.PENDING.value
            )
            
            db.add(session)
            db.commit()
            db.refresh(session)
            
            logger.info(f"Created try-on session {session.id} for user {user.id}")
            return session
            
        except Exception as e:
            logger.error(f"Error creating try-on session: {e}")
            db.rollback()
            raise

    @staticmethod
    async def update_session(
        db: Session,
        session_id: str,
        user: User,
        update_data: TryOnSessionUpdate
    ) -> Optional[TryOnSession]:
        """Update try-on session"""
        try:
            session = db.query(TryOnSession).filter(
                TryOnSession.id == session_id,
                TryOnSession.user_id == user.id
            ).first()
            
            if not session:
                return None
            
            # Update fields
            if update_data.status:
                session.status = update_data.status.value
                if update_data.status == TryOnStatusEnum.COMPLETED:
                    session.completed_at = datetime.utcnow()
            
            if update_data.processing_progress is not None:
                session.processing_progress = update_data.processing_progress
            
            if update_data.error_message is not None:
                session.error_message = update_data.error_message
            
            if update_data.result_image_url:
                session.result_image_url = update_data.result_image_url
            
            if update_data.confidence_score is not None:
                session.confidence_score = update_data.confidence_score
            
            session.updated_at = datetime.utcnow()
            
            db.commit()
            db.refresh(session)
            
            return session
            
        except Exception as e:
            logger.error(f"Error updating try-on session: {e}")
            db.rollback()
            raise

    @staticmethod
    async def add_outfit_attempt(
        db: Session,
        session_id: str,
        user: User,
        outfit_data: TryOnOutfitAttemptCreate
    ) -> Optional[TryOnOutfitAttempt]:
        """Add outfit attempt to session"""
        try:
            # Verify session belongs to user
            session = db.query(TryOnSession).filter(
                TryOnSession.id == session_id,
                TryOnSession.user_id == user.id
            ).first()
            
            if not session:
                return None
            
            attempt = TryOnOutfitAttempt(
                session_id=session_id,
                outfit_name=outfit_data.outfit_name,
                occasion=outfit_data.occasion,
                clothing_items=[item.dict() for item in outfit_data.clothing_items]
            )
            
            db.add(attempt)
            db.commit()
            db.refresh(attempt)
            
            logger.info(f"Added outfit attempt {attempt.id} to session {session_id}")
            return attempt
            
        except Exception as e:
            logger.error(f"Error adding outfit attempt: {e}")
            db.rollback()
            raise

    @staticmethod
    async def process_outfit_tryon(
        db: Session,
        session_id: str,
        attempt_id: str,
        user: User,
        user_image_data: bytes = None
    ) -> Optional[TryOnOutfitAttempt]:
        """Process virtual try-on for an outfit"""
        try:
            # Get attempt and session
            attempt = db.query(TryOnOutfitAttempt).join(TryOnSession).filter(
                TryOnOutfitAttempt.id == attempt_id,
                TryOnSession.id == session_id,
                TryOnSession.user_id == user.id
            ).first()
            
            if not attempt:
                return None
            
            # Update session status
            await VirtualTryOnService.update_session(
                db, session_id, user, 
                TryOnSessionUpdate(
                    status=TryOnStatusEnum.PROCESSING,
                    processing_progress=0.1
                )
            )
            
            # Simulate ML processing (replace with actual ML service call)
            start_time = datetime.utcnow()
            
            # Step 1: Analyze clothing items (30% progress)
            await VirtualTryOnService.update_session(
                db, session_id, user,
                TryOnSessionUpdate(processing_progress=0.3)
            )
            await asyncio.sleep(1)  # Simulate processing time
            
            # Step 2: Generate virtual try-on (70% progress)
            await VirtualTryOnService.update_session(
                db, session_id, user,
                TryOnSessionUpdate(processing_progress=0.7)
            )
            
            # Call ML service for actual processing
            try:
                ml_result = await enhanced_ml_service.generate_virtual_tryon(
                    user.id,
                    {
                        "outfit_items": attempt.clothing_items,
                        "user_preferences": await VirtualTryOnService._get_user_preferences_dict(db, user),
                        "session_config": {
                            "view_mode": attempt.session.view_mode,
                            "quality": "high"
                        }
                    }
                )
                
                # Process ML results
                confidence_score = ml_result.get("confidence", 0.85)
                result_image_url = ml_result.get("result_image_url", "https://example.com/tryon_result.jpg")
                
            except Exception as ml_error:
                logger.error(f"ML processing error: {ml_error}")
                # Use mock data as fallback
                confidence_score = 0.85
                result_image_url = "https://example.com/tryon_result.jpg"
            
            # Generate fit analysis
            fit_analysis = VirtualTryOnService._generate_fit_analysis(attempt.clothing_items)
            color_analysis = VirtualTryOnService._generate_color_analysis(attempt.clothing_items)
            style_score = VirtualTryOnService._calculate_style_score(attempt.clothing_items, user)
            
            # Update attempt with results
            processing_time = int((datetime.utcnow() - start_time).total_seconds() * 1000)
            
            attempt.confidence_score = confidence_score
            attempt.fit_analysis = [analysis.dict() for analysis in fit_analysis]
            attempt.color_analysis = [analysis.dict() for analysis in color_analysis]
            attempt.style_score = style_score
            attempt.result_image_url = result_image_url
            attempt.processing_time_ms = processing_time
            attempt.updated_at = datetime.utcnow()
            
            # Complete session
            await VirtualTryOnService.update_session(
                db, session_id, user,
                TryOnSessionUpdate(
                    status=TryOnStatusEnum.COMPLETED,
                    processing_progress=1.0,
                    confidence_score=confidence_score,
                    result_image_url=result_image_url
                )
            )
            
            db.commit()
            db.refresh(attempt)
            
            return attempt
            
        except Exception as e:
            logger.error(f"Error processing outfit try-on: {e}")
            # Update session with error
            await VirtualTryOnService.update_session(
                db, session_id, user,
                TryOnSessionUpdate(
                    status=TryOnStatusEnum.FAILED,
                    error_message=str(e)
                )
            )
            db.rollback()
            raise

    @staticmethod
    def _generate_fit_analysis(clothing_items: List[Dict[str, Any]]) -> List[FitAnalysisDetail]:
        """Generate fit analysis for clothing items"""
        fit_analysis = []
        
        for item in clothing_items:
            # Mock fit analysis - replace with actual ML analysis
            fit_score = 0.8 + (hash(item['id']) % 20) / 100  # Random score between 0.8-1.0
            
            fit_issues = []
            if fit_score < 0.85:
                fit_issues.append("Slightly loose in the waist")
            if fit_score < 0.9:
                fit_issues.append("Consider size adjustment")
            
            analysis = FitAnalysisDetail(
                item_id=item['id'],
                fit_score=min(fit_score, 1.0),
                size_recommendation=item.get('size', 'M'),
                fit_issues=fit_issues,
                measurements={
                    "chest": 36.0,
                    "waist": 32.0,
                    "length": 28.0
                }
            )
            fit_analysis.append(analysis)
        
        return fit_analysis

    @staticmethod
    def _generate_color_analysis(clothing_items: List[Dict[str, Any]]) -> List[ColorAnalysisDetail]:
        """Generate color analysis for clothing items"""
        color_analysis = []
        
        for item in clothing_items:
            # Mock color analysis
            color_accuracy = 0.85 + (hash(item['name']) % 15) / 100
            
            analysis = ColorAnalysisDetail(
                item_id=item['id'],
                color_accuracy=min(color_accuracy, 1.0),
                lighting_adjusted=True,
                recommended_lighting="Natural daylight"
            )
            color_analysis.append(analysis)
        
        return color_analysis

    @staticmethod
    def _calculate_style_score(clothing_items: List[Dict[str, Any]], user: User) -> float:
        """Calculate style compatibility score"""
        # Mock style calculation - replace with actual ML analysis
        base_score = 0.8
        
        # Bonus for matching categories
        categories = [item.get('category', '') for item in clothing_items]
        if len(set(categories)) > 1:  # Multiple categories = good mix
            base_score += 0.1
        
        # Random variation based on user preferences
        user_variation = (hash(str(user.id)) % 20) / 100
        return min(base_score + user_variation, 1.0)

    @staticmethod
    async def get_user_preferences(
        db: Session,
        user: User
    ) -> UserTryOnPreferences:
        """Get or create user try-on preferences"""
        try:
            preferences = db.query(UserTryOnPreferences).filter(
                UserTryOnPreferences.user_id == user.id
            ).first()
            
            if not preferences:
                # Create default preferences
                preferences = UserTryOnPreferences(
                    user_id=user.id,
                    default_view_mode=ViewModeEnum.AR.value,
                    enabled_features={
                        "lighting": True,
                        "fit": True,
                        "movement": False
                    }
                )
                db.add(preferences)
                db.commit()
                db.refresh(preferences)
            
            return preferences
            
        except Exception as e:
            logger.error(f"Error getting user preferences: {e}")
            raise

    @staticmethod
    async def _get_user_preferences_dict(db: Session, user: User) -> Dict[str, Any]:
        """Get user preferences as dictionary"""
        prefs = await VirtualTryOnService.get_user_preferences(db, user)
        return {
            "view_mode": prefs.default_view_mode,
            "quality": prefs.processing_quality,
            "features": prefs.enabled_features,
            "max_time": prefs.max_processing_time
        }

    @staticmethod
    async def get_available_features(db: Session) -> List[TryOnFeature]:
        """Get available try-on features"""
        try:
            # Check cache first
            cached_features = CacheService.get("tryon_features")
            if cached_features:
                return cached_features
            
            features = db.query(TryOnFeature).filter(
                TryOnFeature.is_available == True
            ).all()
            
            # Cache for 1 hour
            CacheService.set("tryon_features", features, 3600)
            
            return features
            
        except Exception as e:
            logger.error(f"Error getting available features: {e}")
            # Return default features
            return VirtualTryOnService._get_default_features()

    @staticmethod
    def _get_default_features() -> List[Dict[str, Any]]:
        """Get default try-on features"""
        return [
            {
                "id": "lighting",
                "name": "Smart Lighting",
                "description": "Adjusts colors based on environment",
                "is_premium": False,
                "is_available": True,
                "requires_gpu": False
            },
            {
                "id": "fit",
                "name": "Fit Analysis",
                "description": "Real-time fit assessment",
                "is_premium": False,
                "is_available": True,
                "requires_gpu": True
            },
            {
                "id": "movement",
                "name": "Movement Tracking",
                "description": "See how clothes move with you",
                "is_premium": True,
                "is_available": True,
                "requires_gpu": True
            }
        ]

    @staticmethod
    async def get_quick_outfit_suggestions(
        db: Session,
        user: User,
        limit: int = 3
    ) -> List[QuickOutfitSuggestion]:
        """Get quick outfit suggestions for try-on"""
        try:
            # Get user's clothing items
            from app.models.clothing import ClothingItem
            
            user_items = db.query(ClothingItem).filter(
                ClothingItem.owner_id == user.id,
                ClothingItem.is_active == True
            ).limit(20).all()
            
            suggestions = []
            
            # Create outfit combinations
            outfit_types = [
                {"name": "Business Casual", "occasion": "Work Meeting"},
                {"name": "Weekend Vibes", "occasion": "Casual Outing"},
                {"name": "Date Night", "occasion": "Evening Out"}
            ]
            
            for i, outfit_type in enumerate(outfit_types[:limit]):
                # Select items for outfit (simplified logic)
                outfit_items = []
                if user_items:
                    # Take a subset of user's items
                    selected_items = user_items[i:i+3] if len(user_items) > i+2 else user_items[:3]
                    outfit_items = [item.name for item in selected_items]
                else:
                    # Default outfit items
                    outfit_items = ["Sample Top", "Sample Bottom", "Sample Accessory"]
                
                confidence = 0.88 + (i * 0.02)  # Varying confidence scores
                
                suggestion = QuickOutfitSuggestion(
                    id=f"quick_{i+1}",
                    name=outfit_type["name"],
                    occasion=outfit_type["occasion"],
                    items=outfit_items,
                    confidence=confidence,
                    estimated_processing_time=15 + (i * 5)
                )
                suggestions.append(suggestion)
            
            return suggestions
            
        except Exception as e:
            logger.error(f"Error getting outfit suggestions: {e}")
            # Return default suggestions
            return [
                QuickOutfitSuggestion(
                    id="default_1",
                    name="Smart Casual",
                    occasion="Versatile",
                    items=["Button Shirt", "Chinos", "Loafers"],
                    confidence=0.92,
                    estimated_processing_time=15
                )
            ]

    @staticmethod
    async def get_user_sessions(
        db: Session,
        user: User,
        limit: int = 10
    ) -> List[TryOnSession]:
        """Get user's recent try-on sessions"""
        try:
            sessions = db.query(TryOnSession).filter(
                TryOnSession.user_id == user.id
            ).order_by(desc(TryOnSession.created_at)).limit(limit).all()
            
            return sessions
            
        except Exception as e:
            logger.error(f"Error getting user sessions: {e}")
            return []

    @staticmethod
    async def get_session_with_attempts(
        db: Session,
        session_id: str,
        user: User
    ) -> Optional[TryOnSession]:
        """Get session with all outfit attempts"""
        try:
            session = db.query(TryOnSession).filter(
                TryOnSession.id == session_id,
                TryOnSession.user_id == user.id
            ).first()
            
            if session:
                # Load attempts
                session.outfit_attempts = db.query(TryOnOutfitAttempt).filter(
                    TryOnOutfitAttempt.session_id == session_id
                ).order_by(TryOnOutfitAttempt.created_at).all()
            
            return session
            
        except Exception as e:
            logger.error(f"Error getting session with attempts: {e}")
            return None

    @staticmethod
    async def rate_outfit_attempt(
        db: Session,
        attempt_id: str,
        user: User,
        rating: int,
        is_favorite: bool = False
    ) -> Optional[TryOnOutfitAttempt]:
        """Rate an outfit attempt"""
        try:
            attempt = db.query(TryOnOutfitAttempt).join(TryOnSession).filter(
                TryOnOutfitAttempt.id == attempt_id,
                TryOnSession.user_id == user.id
            ).first()
            
            if not attempt:
                return None
            
            attempt.user_rating = rating
            attempt.is_favorite = is_favorite
            attempt.updated_at = datetime.utcnow()
            
            db.commit()
            db.refresh(attempt)
            
            return attempt
            
        except Exception as e:
            logger.error(f"Error rating outfit attempt: {e}")
            db.rollback()
            return None
