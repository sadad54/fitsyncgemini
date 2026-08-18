import json
from typing import Optional

from fastapi import APIRouter, Depends, File, Form, UploadFile

from app.api.dependencies import get_current_user, validate_image_file
from app.models.tryon import TryOnResult
from app.models.user import User
from app.services.tryon_service import tryon_service

router = APIRouter()


@router.post("/", response_model=TryOnResult)
async def create_tryon(
    item_ids: Optional[str] = Form(None),
    person_image: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
):
    await validate_image_file(person_image)
    image_bytes = await person_image.read()
    parsed_ids = []
    if item_ids:
        try:
            parsed_ids = json.loads(item_ids)
        except ValueError:
            parsed_ids = []
    return await tryon_service.create_tryon(current_user.user_id, image_bytes, parsed_ids)


@router.get("/")
async def list_tryons(current_user: User = Depends(get_current_user)):
    results, total = await tryon_service.list_tryons(current_user.user_id)
    return {"results": results, "total": total}


@router.get("/{tryon_id}", response_model=TryOnResult)
async def get_tryon(tryon_id: str, current_user: User = Depends(get_current_user)):
    return await tryon_service.get_tryon(current_user.user_id, tryon_id)


@router.delete("/{tryon_id}")
async def delete_tryon(tryon_id: str, current_user: User = Depends(get_current_user)):
    await tryon_service.delete_tryon(current_user.user_id, tryon_id)
    return {"deleted": True}
