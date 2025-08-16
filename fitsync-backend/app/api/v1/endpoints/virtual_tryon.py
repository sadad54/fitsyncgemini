"""
Virtual Try-On API Endpoints
"""

from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File
from fastapi.responses import JSONResponse
from typing import Optional, List
from sqlalchemy.orm import Session

from app.core.security import get_current_user
from app.models.user import User
from app.database import get_db
from app.services.virtual_tryon_service import VirtualTryOnService
from app.schemas.virtual_tryon import (
    TryOnSessionCreate, TryOnSessionUpdate, TryOnSessionResponse,
    TryOnOutfitAttemptCreate, TryOnOutfitAttemptResponse,
    TryOnPreferencesResponse, TryOnPreferencesUpdate,
    TryOnDashboardResponse, TryOnProcessingResponse,
    QuickOutfitSuggestion, DeviceCapabilities
)

router = APIRouter()

# ============================================================================
# SESSION MANAGEMENT
# ============================================================================

@router.post("/sessions", response_model=TryOnSessionResponse)
async def create_tryon_session(
    session_data: TryOnSessionCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create a new virtual try-on session"""
    try:
        session = await VirtualTryOnService.create_session(db, current_user, session_data)
        return TryOnSessionResponse.from_orm(session)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create session: {str(e)}")

@router.get("/sessions/{session_id}", response_model=TryOnSessionResponse)
async def get_tryon_session(
    session_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get try-on session details"""
    try:
        session = await VirtualTryOnService.get_session_with_attempts(db, session_id, current_user)
        if not session:
            raise HTTPException(status_code=404, detail="Session not found")
        return TryOnSessionResponse.from_orm(session)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get session: {str(e)}")

@router.put("/sessions/{session_id}", response_model=TryOnSessionResponse)
async def update_tryon_session(
    session_id: str,
    update_data: TryOnSessionUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update try-on session"""
    try:
        session = await VirtualTryOnService.update_session(db, session_id, current_user, update_data)
        if not session:
            raise HTTPException(status_code=404, detail="Session not found")
        return TryOnSessionResponse.from_orm(session)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update session: {str(e)}")

@router.get("/sessions", response_model=List[TryOnSessionResponse])
async def get_user_tryon_sessions(
    limit: int = Query(10, ge=1, le=50),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get user's try-on sessions"""
    try:
        sessions = await VirtualTryOnService.get_user_sessions(db, current_user, limit)
        return [TryOnSessionResponse.from_orm(session) for session in sessions]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get sessions: {str(e)}")

# ============================================================================
# OUTFIT ATTEMPTS
# ============================================================================

@router.post("/sessions/{session_id}/outfits", response_model=TryOnOutfitAttemptResponse)
async def add_outfit_to_session(
    session_id: str,
    outfit_data: TryOnOutfitAttemptCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Add outfit attempt to session"""
    try:
        attempt = await VirtualTryOnService.add_outfit_attempt(db, session_id, current_user, outfit_data)
        if not attempt:
            raise HTTPException(status_code=404, detail="Session not found")
        return TryOnOutfitAttemptResponse.from_orm(attempt)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to add outfit: {str(e)}")

@router.post("/sessions/{session_id}/outfits/{attempt_id}/process")
async def process_outfit_tryon(
    session_id: str,
    attempt_id: str,
    user_image: Optional[UploadFile] = File(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Process virtual try-on for an outfit"""
    try:
        # Read image data if provided
        image_data = None
        if user_image:
            image_data = await user_image.read()
            
            # Validate image
            if len(image_data) > 10 * 1024 * 1024:  # 10MB limit
                raise HTTPException(status_code=413, detail="Image too large")
        
        # Start processing
        attempt = await VirtualTryOnService.process_outfit_tryon(
            db, session_id, attempt_id, current_user, image_data
        )
        
        if not attempt:
            raise HTTPException(status_code=404, detail="Outfit attempt not found")
        
        return JSONResponse(content={
            "message": "Processing started",
            "attempt_id": attempt_id,
            "session_id": session_id,
            "status": "processing"
        })
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to process try-on: {str(e)}")

@router.get("/sessions/{session_id}/outfits/{attempt_id}/status")
async def get_processing_status(
    session_id: str,
    attempt_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get processing status for outfit attempt"""
    try:
        session = await VirtualTryOnService.get_session_with_attempts(db, session_id, current_user)
        if not session:
            raise HTTPException(status_code=404, detail="Session not found")
        
        # Find the specific attempt
        attempt = next((a for a in session.outfit_attempts if a.id == attempt_id), None)
        if not attempt:
            raise HTTPException(status_code=404, detail="Outfit attempt not found")
        
        # Estimate completion time based on processing progress
        estimated_completion = None
        if session.status == "processing" and session.processing_progress > 0:
            remaining_progress = 1.0 - session.processing_progress
            estimated_completion = int(remaining_progress * 30)  # Rough estimate
        
        return TryOnProcessingResponse(
            session_id=session_id,
            status=session.status,
            progress=session.processing_progress,
            estimated_completion_seconds=estimated_completion,
            current_step="Processing virtual try-on",
            error_message=session.error_message
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get status: {str(e)}")

@router.post("/sessions/{session_id}/outfits/{attempt_id}/rate")
async def rate_outfit_attempt(
    session_id: str,
    attempt_id: str,
    rating: int = Query(..., ge=1, le=5),
    is_favorite: bool = Query(False),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Rate an outfit attempt"""
    try:
        attempt = await VirtualTryOnService.rate_outfit_attempt(
            db, attempt_id, current_user, rating, is_favorite
        )
        
        if not attempt:
            raise HTTPException(status_code=404, detail="Outfit attempt not found")
        
        return JSONResponse(content={
            "message": "Rating saved",
            "attempt_id": attempt_id,
            "rating": rating,
            "is_favorite": is_favorite
        })
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to rate outfit: {str(e)}")

# ============================================================================
# DASHBOARD AND RECOMMENDATIONS
# ============================================================================

@router.get("/dashboard")
async def get_tryon_dashboard(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get try-on dashboard data"""
    try:
        # Get recent sessions
        recent_sessions = await VirtualTryOnService.get_user_sessions(db, current_user, 5)
        
        # Get available features
        available_features = await VirtualTryOnService.get_available_features(db)
        
        # Get user preferences
        user_preferences = await VirtualTryOnService.get_user_preferences(db, current_user)
        
        # Get quick outfit suggestions
        quick_outfits = await VirtualTryOnService.get_quick_outfit_suggestions(db, current_user, 3)
        
        # Generate stats
        stats = {
            "total_sessions": len(recent_sessions),
            "total_outfits_tried": sum(len(session.outfit_attempts or []) for session in recent_sessions),
            "favorite_count": sum(
                len([a for a in (session.outfit_attempts or []) if a.is_favorite]) 
                for session in recent_sessions
            ),
            "average_confidence": 0.87  # Mock average
        }
        
        dashboard_data = {
            "recent_sessions": [TryOnSessionResponse.from_orm(session) for session in recent_sessions],
            "available_features": available_features,
            "user_preferences": TryOnPreferencesResponse.from_orm(user_preferences),
            "quick_outfits": [outfit.dict() for outfit in quick_outfits],
            "stats": stats
        }
        
        return JSONResponse(content=dashboard_data)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get dashboard: {str(e)}")

@router.get("/suggestions/quick", response_model=List[QuickOutfitSuggestion])
async def get_quick_outfit_suggestions(
    limit: int = Query(3, ge=1, le=10),
    occasion: Optional[str] = Query(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get quick outfit suggestions for try-on"""
    try:
        suggestions = await VirtualTryOnService.get_quick_outfit_suggestions(db, current_user, limit)
        
        # Filter by occasion if provided
        if occasion:
            suggestions = [s for s in suggestions if occasion.lower() in s.occasion.lower()]
        
        return suggestions
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get suggestions: {str(e)}")

# ============================================================================
# USER PREFERENCES
# ============================================================================

@router.get("/preferences", response_model=TryOnPreferencesResponse)
async def get_user_tryon_preferences(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get user's try-on preferences"""
    try:
        preferences = await VirtualTryOnService.get_user_preferences(db, current_user)
        return TryOnPreferencesResponse.from_orm(preferences)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get preferences: {str(e)}")

@router.put("/preferences", response_model=TryOnPreferencesResponse)
async def update_user_tryon_preferences(
    update_data: TryOnPreferencesUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update user's try-on preferences"""
    try:
        preferences = await VirtualTryOnService.get_user_preferences(db, current_user)
        
        # Update fields
        if update_data.default_view_mode is not None:
            preferences.default_view_mode = update_data.default_view_mode.value
        if update_data.auto_save_results is not None:
            preferences.auto_save_results = update_data.auto_save_results
        if update_data.share_anonymously is not None:
            preferences.share_anonymously = update_data.share_anonymously
        if update_data.enabled_features is not None:
            preferences.enabled_features = update_data.enabled_features
        if update_data.processing_quality is not None:
            preferences.processing_quality = update_data.processing_quality.value
        if update_data.max_processing_time is not None:
            preferences.max_processing_time = update_data.max_processing_time
        if update_data.store_images is not None:
            preferences.store_images = update_data.store_images
        if update_data.allow_analytics is not None:
            preferences.allow_analytics = update_data.allow_analytics
        
        db.commit()
        db.refresh(preferences)
        
        return TryOnPreferencesResponse.from_orm(preferences)
        
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to update preferences: {str(e)}")

# ============================================================================
# FEATURES AND CAPABILITIES
# ============================================================================

@router.get("/features")
async def get_available_features(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get available try-on features"""
    try:
        features = await VirtualTryOnService.get_available_features(db)
        return JSONResponse(content={"features": features})
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get features: {str(e)}")

@router.post("/device/capabilities")
async def check_device_capabilities(
    device_info: DeviceCapabilities,
    current_user: User = Depends(get_current_user)
):
    """Check device capabilities for optimal try-on experience"""
    try:
        # Analyze device capabilities
        recommendations = []
        optimal_settings = {
            "view_mode": "ar",
            "processing_quality": "high",
            "recommended_features": ["lighting", "fit"]
        }
        
        # Adjust based on device capabilities
        if not device_info.ar_support:
            optimal_settings["view_mode"] = "mirror"
            recommendations.append("AR not supported, using mirror mode")
        
        if not device_info.gpu_available:
            optimal_settings["processing_quality"] = "medium"
            optimal_settings["recommended_features"] = ["lighting"]
            recommendations.append("Limited GPU, reducing quality for better performance")
        
        if device_info.ram_gb and device_info.ram_gb < 4:
            optimal_settings["processing_quality"] = "low"
            recommendations.append("Low RAM detected, using optimized settings")
        
        return JSONResponse(content={
            "device_supported": True,
            "optimal_settings": optimal_settings,
            "recommendations": recommendations,
            "estimated_performance": {
                "processing_speed": "fast" if device_info.gpu_available else "medium",
                "quality_level": optimal_settings["processing_quality"],
                "supported_features": optimal_settings["recommended_features"]
            }
        })
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to check capabilities: {str(e)}")

# ============================================================================
# SHARING AND EXPORT
# ============================================================================

@router.post("/sessions/{session_id}/share")
async def share_tryon_session(
    session_id: str,
    share_options: dict = {},
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Share try-on session results"""
    try:
        session = await VirtualTryOnService.get_session_with_attempts(db, session_id, current_user)
        if not session:
            raise HTTPException(status_code=404, detail="Session not found")
        
        # Generate shareable link (mock implementation)
        share_link = f"https://fitsync.app/shared/tryon/{session_id}"
        
        return JSONResponse(content={
            "share_link": share_link,
            "expires_at": "2025-02-20T00:00:00Z",
            "share_options": share_options
        })
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to share session: {str(e)}")
