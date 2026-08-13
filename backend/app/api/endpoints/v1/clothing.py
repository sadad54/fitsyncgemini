from typing import Optional

from fastapi import APIRouter, Depends, File, Form, UploadFile

from app.api.dependencies import get_current_user, validate_image_file
from app.models.clothing import ClothingItem, ClothingItemUpdate
from app.models.user import User
from app.services.clothing_service import clothing_service

router = APIRouter()


@router.post("/", response_model=ClothingItem)
async def create_clothing_item(
    name: str = Form(...),
    category: Optional[str] = Form(None),
    brand: Optional[str] = Form(None),
    notes: Optional[str] = Form(None),
    image: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
):
    await validate_image_file(image)
    image_bytes = await image.read()
    return await clothing_service.create_clothing_item(
        user_id=current_user.user_id,
        name=name,
        image_bytes=image_bytes,
        category=category,
        brand=brand,
        notes=notes,
    )


@router.get("/stats")
async def get_clothing_stats(current_user: User = Depends(get_current_user)):
    return await clothing_service.get_stats(current_user.user_id)


@router.get("/")
async def list_clothing_items(
    category: Optional[str] = None,
    search: Optional[str] = None,
    current_user: User = Depends(get_current_user),
):
    items, total = await clothing_service.list_clothing_items(current_user.user_id, category, search)
    return {"items": items, "total": total}


@router.get("/{item_id}", response_model=ClothingItem)
async def get_clothing_item(item_id: str, current_user: User = Depends(get_current_user)):
    return await clothing_service.get_clothing_item(current_user.user_id, item_id)


@router.put("/{item_id}", response_model=ClothingItem)
async def update_clothing_item(
    item_id: str,
    update_data: ClothingItemUpdate,
    current_user: User = Depends(get_current_user),
):
    updates = update_data.model_dump(exclude_unset=True)
    return await clothing_service.update_clothing_item(current_user.user_id, item_id, updates)


@router.delete("/{item_id}")
async def delete_clothing_item(item_id: str, current_user: User = Depends(get_current_user)):
    await clothing_service.delete_clothing_item(current_user.user_id, item_id)
    return {"deleted": True}
