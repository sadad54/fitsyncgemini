from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException
from typing import List, Optional
import json
from app.services.clothing_service import clothing_service
from app.api.dependencies import get_current_user, validate_image_file
from app.core.database import db

router = APIRouter()

@router.post("/")
async def create_clothing_item(
    name: str = Form(...),
    category: str = Form(None),
    colors: str = Form(None),  # JSON string of color list
    tags: str = Form(None),    # JSON string of tag list
    image: UploadFile = File(...),
    current_user: dict = Depends(get_current_user)
):
    """Create a new clothing item with AI analysis"""
    
    # Validate image
    await validate_image_file(image)
    
    # Parse JSON fields
    colors_list = json.loads(colors) if colors else []
    tags_list = json.loads(tags) if tags else []
    
    # Read image data
    image_data = await image.read()
    
    # Additional info from form data
    additional_info = {
        "manual_category": category,
        "manual_colors": colors_list,
        "tags": tags_list,
        "purchase_date": None,  # Could add this to form
        "brand": None,          # Could add this to form
        "price": None           # Could add this to form
    }
    
    result = await clothing_service.create_clothing_item(
        user_id=current_user["id"],
        name=name,
        image_data=image_data,
        additional_info=additional_info
    )
    
    return result

@router.get("/")
async def get_clothing_items(
    category: Optional[str] = None,
    color: Optional[str] = None,
    tag: Optional[str] = None,
    limit: int = 50,
    offset: int = 0,
    current_user: dict = Depends(get_current_user)
):
    """Get user's clothing items with optional filters"""
    
    filters = {}
    if category:
        filters["category"] = category
    if color:
        filters["color"] = color
    if tag:
        filters["tag"] = tag
    
    result = await db.get_clothing_items(
        user_id=current_user["id"],
        filters=filters,
        limit=limit,
        offset=offset
    )
    
    return {
        "success": True,
        "items": result.data if result.data else [],
        "total": len(result.data) if result.data else 0
    }

@router.get("/{item_id}")
async def get_clothing_item(
    item_id: str,
    current_user: dict = Depends(get_current_user)
):
    """Get specific clothing item details"""
    
    result = await db.get_clothing_item(item_id, current_user["id"])
    
    if not result.data:
        raise HTTPException(status_code=404, detail="Clothing item not found")
    
    return {
        "success": True,
        "item": result.data[0]
    }

@router.put("/{item_id}")
async def update_clothing_item(
    item_id: str,
    update_data: dict,
    current_user: dict = Depends(get_current_user)
):
    """Update clothing item details"""
    
    # Verify ownership
    existing = await db.get_clothing_item(item_id, current_user["id"])
    if not existing.data:
        raise HTTPException(status_code=404, detail="Clothing item not found")
    
    result = await db.update_clothing_item(item_id, current_user["id"], update_data)
    
    return {
        "success": True,
        "updated_item": result.data[0] if result.data else None
    }

@router.delete("/{item_id}")
async def delete_clothing_item(
    item_id: str,
    current_user: dict = Depends(get_current_user)
):
    """Delete clothing item"""
    
    # Verify ownership
    existing = await db.get_clothing_item(item_id, current_user["id"])
    if not existing.data:
        raise HTTPException(status_code=404, detail="Clothing item not found")
    
    result = await db.delete_clothing_item(item_id, current_user["id"])
    
    return {
        "success": True,
        "message": "Clothing item deleted successfully"
    }

@router.get("/analyze/compatibility")
async def analyze_wardrobe_compatibility(
    current_user: dict = Depends(get_current_user)
):
    """Analyze wardrobe compatibility and get outfit suggestions"""
    
    return await clothing_service.analyze_wardrobe_compatibility(current_user["id"])

@router.get("/recommendations/smart")
async def get_smart_recommendations(
    occasion: Optional[str] = "casual",
    weather_lat: Optional[float] = None,
    weather_lon: Optional[float] = None,
    budget_range: Optional[str] = "medium",
    current_user: dict = Depends(get_current_user)
):
    """Get AI-powered clothing recommendations"""
    
    # Get weather data if coordinates provided
    weather_data = None
    if weather_lat and weather_lon:
        from app.external_apis.weather_client import weather_client
        weather_data = await weather_client.get_current_weather(
            weather_lat, weather_lon, current_user["id"]
        )
    
    return await clothing_service.get_smart_clothing_recommendations(
        user_id=current_user["id"],
        occasion=occasion,
        weather=weather_data,
        budget_range=budget_range
    )