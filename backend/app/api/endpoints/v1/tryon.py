from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException
from typing import List
import json
from app.services.tryon_service import tryon_service
from app.api.dependencies import get_current_user, validate_image_file

router = APIRouter()

@router.post("/sessions")
async def create_tryon_session(
    session_name: str = Form(None),
    view_mode: str = Form("ar"),
    current_user: dict = Depends(get_current_user)
):
    """Create a new virtual try-on session"""
    
    return await tryon_service.create_tryon_session(
        user_id=current_user["id"],
        session_name=session_name,
        view_mode=view_mode
    )

@router.post("/sessions/{session_id}/tryon")
async def perform_virtual_tryon(
    session_id: str,
    clothing_items: str = Form(...),  # JSON string of clothing item IDs
    user_image: UploadFile = File(...),
    current_user: dict = Depends(get_current_user)
):
    """Perform virtual try-on with clothing items"""
    
    # Validate image
    await validate_image_file(user_image)
    
    # Parse clothing items
    try:
        clothing_item_ids = json.loads(clothing_items)
        if not isinstance(clothing_item_ids, list):
            raise ValueError("Clothing items must be a list")
    except (json.JSONDecodeError, ValueError) as e:
        raise HTTPException(status_code=400, detail=f"Invalid clothing_items format: {str(e)}")
    
    # Read image data
    user_image_data = await user_image.read()
    
    return await tryon_service.perform_virtual_tryon(
        session_id=session_id,
        user_image=user_image_data,
        clothing_items=clothing_item_ids,
        user_id=current_user["id"]
    )

@router.get("/sessions/{session_id}")
async def get_tryon_session(
    session_id: str,
    current_user: dict = Depends(get_current_user)
):
    """Get try-on session details"""
    
    return await tryon_service.get_tryon_session(session_id, current_user["id"])

@router.get("/sessions")
async def get_tryon_history(
    limit: int = 20,
    status_filter: str = None,
    current_user: dict = Depends(get_current_user)
):
    """Get user's virtual try-on history"""
    
    return await tryon_service.get_user_tryon_history(
        user_id=current_user["id"],
        limit=limit,
        status_filter=status_filter
    )

@router.put("/sessions/{session_id}/attempts/{attempt_id}")
async def save_tryon_result(
    session_id: str,
    attempt_id: str,
    is_favorite: bool = Form(False),
    user_rating: int = Form(None),
    notes: str = Form(None),
    current_user: dict = Depends(get_current_user)
):
    """Save or update try-on result with user preferences"""
    
    return await tryon_service.save_tryon_result(
        session_id=session_id,
        attempt_id=attempt_id,
        user_id=current_user["id"],
        is_favorite=is_favorite,
        user_rating=user_rating,
        notes=notes
    )

@router.get("/analytics")
async def get_tryon_analytics(
    current_user: dict = Depends(get_current_user)
):
    """Get user's virtual try-on analytics"""
    
    return await tryon_service.get_tryon_analytics(current_user["id"])