import json
from uuid import UUID
from fastapi import APIRouter, Depends, File, Form, UploadFile, HTTPException
from app.api.dependencies import get_current_user, validate_image_file
from app.models.tryon import TryOnResult
from app.models.user import User
from app.services.tryon_service import tryon_service

router = APIRouter()


@router.post("/", response_model=TryOnResult, status_code=202)
async def create_tryon(
    item_ids: str = Form(...),
    person_image: UploadFile = File(...),
    seed: int = Form(42, ge=0, le=2147483647),
    current_user: User = Depends(get_current_user),
):
    try:
        parsed = json.loads(item_ids)
        if not isinstance(parsed, list) or not 1 <= len(parsed) <= 2 or not all(isinstance(x, str) for x in parsed):
            raise ValueError()
        parsed = [str(UUID(x)) for x in parsed]
        if len(set(parsed)) != len(parsed):
            raise ValueError()
    except (ValueError, TypeError, AttributeError):
        raise HTTPException(422, "item_ids must contain one or two distinct closet item UUIDs")
    await validate_image_file(person_image)
    return await tryon_service.create_tryon(current_user.user_id, await person_image.read(), parsed, seed=seed)


@router.get("/")
async def list_tryons(current_user: User = Depends(get_current_user)):
    results, total = await tryon_service.list_tryons(current_user.user_id)
    return {"results": results, "total": total}


@router.get("/{tryon_id}", response_model=TryOnResult)
async def get_tryon(tryon_id: UUID, current_user: User = Depends(get_current_user)):
    return await tryon_service.get_tryon(current_user.user_id, str(tryon_id))


@router.delete("/{tryon_id}")
async def delete_tryon(tryon_id: UUID, current_user: User = Depends(get_current_user)):
    await tryon_service.delete_tryon(current_user.user_id, str(tryon_id))
    return {"deleted": True}
