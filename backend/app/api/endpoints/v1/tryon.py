from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, BackgroundTasks
from typing import List, Optional, Dict
import uuid
import asyncio
import json
from datetime import datetime
from app.external_apis.huggingface_virtual_tryon import huggingface_virtual_tryon_client
from app.api.dependencies import get_current_user
from app.services.tryon_service import tryon_service
from app.models.user import User
from app.core.database import get_db
from fastapi.responses import JSONResponse

router = APIRouter()

@router.post("/session/create")
async def create_tryon_session(
    session_name: Optional[str] = Form(None),
    view_mode: str = Form("ar"),  # ar or mirror
    current_user: User = Depends(get_current_user)
):
    """Create a new virtual try-on session - matches your Flutter VirtualTryOnViewModel"""
    
    try:
        session = await tryon_service.create_tryon_session(
            user_id=current_user.id,
            session_name=session_name,
            view_mode=view_mode
        )
        
        return {
            "success": True,
            "session_id": session["session"]["id"],
            "session": session["session"],
            "message": "Session created successfully"
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to create session: {str(e)}"
        )

@router.post("/process")
async def process_virtual_tryon(
    background_tasks: BackgroundTasks,
    session_id: str = Form(...),
    user_image: UploadFile = File(..., description="User's photo from camera"),
    selected_outfit_index: int = Form(0),
    tryon_type: str = Form("full_body"),  # full_body, upper_body, lower_body
    processing_quality: str = Form("high"),  # low, medium, high - matches ProcessingQuality enum
    current_user: User = Depends(get_current_user)
):
    """
    Process virtual try-on - matches your Flutter screen's _startTryOn method
    This endpoint handles the processing while your Flutter app shows progress
    """
    
    # Validate inputs
    if user_image.content_type not in ["image/jpeg", "image/png", "image/webp"]:
        raise HTTPException(status_code=400, detail="Invalid image format")
    
    if user_image.size > 10 * 1024 * 1024:  # 10MB limit
        raise HTTPException(status_code=400, detail="Image too large (max 10MB)")
    
    try:
        # Read user image
        user_image_data = await user_image.read()
        
        # Get user's outfit suggestions (you'll need to implement this based on your wardrobe data)
        outfit_suggestions = await get_user_outfit_suggestions(current_user.id)
        
        if not outfit_suggestions or selected_outfit_index >= len(outfit_suggestions):
            raise HTTPException(status_code=400, detail="Invalid outfit selection")
        
        selected_outfit = outfit_suggestions[selected_outfit_index]
        
        # Start processing in background
        background_tasks.add_task(
            process_tryon_background,
            session_id,
            user_image_data,
            selected_outfit,
            current_user.id,
            tryon_type,
            processing_quality
        )
        
        return {
            "success": True,
            "session_id": session_id,
            "processing_started": True,
            "estimated_time_seconds": get_estimated_processing_time(processing_quality),
            "message": "Processing started - check status endpoint for updates"
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to start processing: {str(e)}"
        )

@router.get("/session/{session_id}/status")
async def get_session_status(
    session_id: str,
    current_user: User = Depends(get_current_user)
):
    """
    Get processing status - your Flutter app can poll this endpoint
    Matches your VirtualTryOnState.isProcessing and processingProgress
    """
    
    try:
        session_data = await tryon_service.get_tryon_session(session_id, current_user.id)
        
        if not session_data["success"]:
            raise HTTPException(status_code=404, detail="Session not found")
        
        session = session_data["session"]
        
        return {
            "success": True,
            "session_id": session_id,
            "status": session.get("status", "pending"),  # pending, processing, completed, failed
            "processing_progress": session.get("processing_progress", 0.0),  # 0.0 to 1.0
            "is_processing": session.get("status") == "processing",
            "result_available": session.get("status") == "completed",
            "error_message": session.get("error_message"),
            "confidence_score": session.get("confidence_score"),
            "processing_time_ms": session.get("processing_time_ms"),
            "completed_at": session.get("completed_at"),
            "attempts": session_data.get("attempts", [])
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get session status: {str(e)}"
        )

@router.get("/session/{session_id}/result")
async def get_tryon_result(
    session_id: str,
    current_user: User = Depends(get_current_user)
):
    """Get the final try-on result with all details"""
    
    try:
        session_data = await tryon_service.get_tryon_session(session_id, current_user.id)
        
        if not session_data["success"]:
            raise HTTPException(status_code=404, detail="Session not found")
        
        session = session_data["session"]
        attempts = session_data.get("attempts", [])
        
        if session.get("status") != "completed":
            raise HTTPException(status_code=400, detail="Processing not completed")
        
        # Get the best result
        best_attempt = max(attempts, key=lambda x: x.get("confidence_score", 0)) if attempts else None
        
        if not best_attempt:
            raise HTTPException(status_code=404, detail="No results found")
        
        return {
            "success": True,
            "session_id": session_id,
            "result": {
                "image_url": best_attempt.get("result_image_url"),
                "confidence_score": best_attempt.get("confidence_score", 0),
                "quality_metrics": {
                    "fit_score": best_attempt.get("fit_analysis", {}).get("fit_score", 0),
                    "color_harmony": best_attempt.get("fit_analysis", {}).get("color_harmony", 0),
                    "style_compatibility": best_attempt.get("fit_analysis", {}).get("style_compatibility", 0)
                },
                "outfit_info": {
                    "name": best_attempt.get("outfit_name"),
                    "items": [item.get("name") for item in best_attempt.get("clothing_items", [])],
                    "categories": [item.get("category") for item in best_attempt.get("clothing_items", [])]
                }
            },
            "all_attempts": attempts,
            "processing_stats": {
                "total_time_ms": session.get("processing_time_ms", 0),
                "method_used": best_attempt.get("method_used", "huggingface"),
                "processing_quality": session.get("processing_quality", "high")
            }
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get result: {str(e)}"
        )

@router.post("/session/{session_id}/rate")
async def rate_tryon_result(
    session_id: str,
    rating: int = Form(..., ge=1, le=5),
    is_favorite: bool = Form(False),
    notes: Optional[str] = Form(None),
    current_user: User = Depends(get_current_user)
):
    """Rate and save try-on result - matches your _saveLook method"""
    
    try:
        # Get the session's best attempt
        session_data = await tryon_service.get_tryon_session(session_id, current_user.id)
        attempts = session_data.get("attempts", [])
        
        if not attempts:
            raise HTTPException(status_code=404, detail="No attempts found")
        
        best_attempt = max(attempts, key=lambda x: x.get("confidence_score", 0))
        
        result = await tryon_service.save_tryon_result(
            session_id=session_id,
            attempt_id=best_attempt["id"],
            user_id=current_user.id,
            is_favorite=is_favorite,
            user_rating=rating,
            notes=notes
        )
        
        return {
            "success": True,
            "message": "Rating saved successfully",
            "is_favorite": is_favorite,
            "rating": rating
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to save rating: {str(e)}"
        )

@router.post("/session/{session_id}/share")
async def share_tryon_result(
    session_id: str,
    current_user: User = Depends(get_current_user)
):
    """Generate shareable link - matches your _shareResult method"""
    
    try:
        # Generate a shareable link or code
        share_code = f"tryon_{session_id}_{uuid.uuid4().hex[:8]}"
        
        # Store share information in database
        share_data = {
            "session_id": session_id,
            "user_id": current_user.id,
            "share_code": share_code,
            "created_at": datetime.utcnow(),
            "is_public": True
        }
        
        # Save to database (implement this based on your database structure)
        # await db.create_share_link(share_data)
        
        share_url = f"https://your-app-domain.com/shared/tryon/{share_code}"
        
        return {
            "success": True,
            "share_url": share_url,
            "share_code": share_code,
            "expires_at": None,  # No expiration for now
            "message": "Share link generated successfully"
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to create share link: {str(e)}"
        )

@router.get("/outfits/suggestions")
async def get_outfit_suggestions(
    occasion: Optional[str] = None,
    weather: Optional[str] = None,
    current_user: User = Depends(get_current_user)
):
    """
    Get outfit suggestions for the user
    This populates your VirtualTryOnState.outfitSuggestions
    """
    
    try:
        # Get user's wardrobe items
        db = await get_db()
        wardrobe_result = db.table("clothing_items").select("*").eq("user_id", current_user.id).execute()
        wardrobe_items = wardrobe_result.data if wardrobe_result.data else []
        
        if not wardrobe_items:
            return {
                "success": True,
                "suggestions": [],
                "message": "Add clothing items to your wardrobe to get suggestions"
            }
        
        # Generate suggestions using your AI service
        from app.external_apis.groq_client import groq_client
        
        user_preferences = {
            "occasion": occasion or "casual",
            "weather": weather or "moderate",
            "style_preferences": ["modern", "comfortable"]  # Get from user profile
        }
        
        recommendations = await groq_client.generate_outfit_recommendations(
            wardrobe_data=wardrobe_items,
            occasion=user_preferences["occasion"],
            weather={"condition": user_preferences["weather"]},
            user_preferences=user_preferences,
            user_id=current_user.id
        )
        
        # Format suggestions for Flutter app
        suggestions = []
        if recommendations["success"]:
            for i, rec in enumerate(recommendations["recommendations"]["outfit_recommendations"][:5]):
                suggestions.append({
                    "id": i,
                    "name": rec.get("name", f"Outfit {i+1}"),
                    "items": rec.get("items", []),
                    "description": rec.get("description", ""),
                    "confidence": rec.get("confidence", 0.8),
                    "occasion": occasion or "casual",
                    "clothing_item_ids": rec.get("items", [])  # IDs to fetch actual items
                })
        
        return {
            "success": True,
            "suggestions": suggestions,
            "total_count": len(suggestions),
            "user_wardrobe_count": len(wardrobe_items)
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get suggestions: {str(e)}"
        )

@router.get("/features")
async def get_available_features():
    """
    Get available smart features
    Populates your VirtualTryOnState.availableFeatures
    """
    
    features = [
        {
            "id": "auto_fit_adjustment",
            "name": "Auto Fit Adjustment",
            "description": "Automatically adjust clothing fit to your body type",
            "enabled": True,
            "premium": False
        },
        {
            "id": "color_matching",
            "name": "Smart Color Matching",
            "description": "AI-powered color coordination suggestions",
            "enabled": True,
            "premium": False
        },
        {
            "id": "style_analysis",
            "name": "Style Analysis",
            "description": "Get detailed style insights and recommendations",
            "enabled": True,
            "premium": False
        },
        {
            "id": "body_type_optimization",
            "name": "Body Type Optimization",
            "description": "Optimize clothing placement based on your body type",
            "enabled": False,
            "premium": True
        },
        {
            "id": "advanced_lighting",
            "name": "Advanced Lighting",
            "description": "Simulate different lighting conditions",
            "enabled": False,
            "premium": True
        }
    ]
    
    return {
        "success": True,
        "features": features
    }

@router.post("/features/toggle")
async def toggle_feature(
    feature_id: str = Form(...),
    enabled: bool = Form(...),
    current_user: User = Depends(get_current_user)
):
    """Toggle a smart feature on/off"""
    
    # Store user preference
    # await db.update_user_preference(current_user.id, f"feature_{feature_id}", enabled)
    
    return {
        "success": True,
        "feature_id": feature_id,
        "enabled": enabled,
        "message": f"Feature {'enabled' if enabled else 'disabled'}"
    }

@router.get("/history")
async def get_tryon_history(
    limit: int = 20,
    status_filter: Optional[str] = None,
    current_user: User = Depends(get_current_user)
):
    """Get user's try-on history"""
    
    try:
        history = await tryon_service.get_user_tryon_history(
            user_id=current_user.id,
            limit=limit,
            status_filter=status_filter
        )
        
        return {
            "success": True,
            "sessions": history["sessions"],
            "statistics": history["statistics"],
            "pagination": {
                "total": len(history["sessions"]),
                "limit": limit,
                "has_more": len(history["sessions"]) >= limit
            }
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get history: {str(e)}"
        )

# Helper functions

async def get_user_outfit_suggestions(user_id: str) -> List[Dict]:
    """Get outfit suggestions for a user"""
    
    # This would typically fetch from your database
    # For now, return mock data that matches your Flutter structure
    return [
        {
            "id": 0,
            "name": "Casual Weekend",
            "items": ["Blue Jeans", "White T-Shirt", "Sneakers"],
            "confidence": 0.92,
            "occasion": "casual",
            "clothing_item_ids": ["item1", "item2", "item3"]
        },
        {
            "id": 1,
            "name": "Office Ready",
            "items": ["Black Trousers", "Blue Shirt", "Blazer"],
            "confidence": 0.88,
            "occasion": "business",
            "clothing_item_ids": ["item4", "item5", "item6"]
        },
        {
            "id": 2,
            "name": "Date Night",
            "items": ["Black Dress", "Heels", "Jewelry"],
            "confidence": 0.95,
            "occasion": "formal",
            "clothing_item_ids": ["item7", "item8", "item9"]
        }
    ]

async def process_tryon_background(
    session_id: str,
    user_image_data: bytes,
    selected_outfit: Dict,
    user_id: str,
    tryon_type: str,
    processing_quality: str
):
    """Background task for processing virtual try-on"""
    
    try:
        # Update session status
        await tryon_service.update_session_status(session_id, "processing", 0.1)
        
        # Get clothing item images
        clothing_images = []
        for item_id in selected_outfit["clothing_item_ids"]:
            # Fetch clothing item image from database
            # item_image = await get_clothing_item_image(item_id)
            # clothing_images.append(item_image)
            pass
        
        await tryon_service.update_session_status(session_id, "processing", 0.3)
        
        # Process with Hugging Face (using first clothing item for now)
        if clothing_images:
            result = await huggingface_virtual_tryon_client.virtual_tryon(
                person_image=user_image_data,
                clothing_image=clothing_images[0],  # Use first item
                user_id=user_id,
                tryon_type=tryon_type
            )
            
            await tryon_service.update_session_status(session_id, "processing", 0.8)
            
            # Save result
            if result["success"]:
                await tryon_service.save_session_result(session_id, result)
                await tryon_service.update_session_status(session_id, "completed", 1.0)
            else:
                await tryon_service.update_session_status(session_id, "failed", 0)
        else:
            await tryon_service.update_session_status(session_id, "failed", 0)
            
    except Exception as e:
        await tryon_service.update_session_status(session_id, "failed", 0, str(e))

def get_estimated_processing_time(quality: str) -> int:
    """Get estimated processing time in seconds"""
    
    time_map = {
        "low": 15,      # Fast processing
        "medium": 30,   # Balanced
        "high": 60      # Best quality
    }
    
    return time_map.get(quality, 30)