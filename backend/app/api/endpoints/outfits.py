from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from app.models.outfit import Outfit, OutfitCreate, OutfitUpdate
from app.services.outfit_service import OutfitService
from app.api.dependencies import get_current_user, get_optional_user
from typing import List
import uuid

router = APIRouter()

@router.post("/", response_model=Outfit)
async def create_outfit(
    outfit_data: OutfitCreate,
    current_user = Depends(get_current_user),
    outfit_service: OutfitService = Depends()
):
    return await outfit_service.create_outfit(outfit_data, current_user.id)

@router.get("/", response_model=List[Outfit])
async def get_outfits(
    current_user = Depends(get_current_user),
    outfit_service: OutfitService = Depends()
):
    return await outfit_service.get_user_outfits(current_user.id)

@router.get("/{outfit_id}", response_model=Outfit)
async def get_outfit(
    outfit_id: str,
    current_user = Depends(get_current_user),
    outfit_service: OutfitService = Depends()
):
    outfit = await outfit_service.get_outfit(outfit_id, current_user.id)
    if not outfit:
        raise HTTPException(status_code=404, detail="Outfit not found")
    return outfit

@router.put("/{outfit_id}", response_model=Outfit)
async def update_outfit(
    outfit_id: str,
    outfit_data: OutfitUpdate,
    current_user = Depends(get_current_user),
    outfit_service: OutfitService = Depends()
):
    outfit = await outfit_service.update_outfit(outfit_id, outfit_data, current_user.id)
    if not outfit:
        raise HTTPException(status_code=404, detail="Outfit not found")
    return outfit

@router.delete("/{outfit_id}")
async def delete_outfit(
    outfit_id: str,
    current_user = Depends(get_current_user),
    outfit_service: OutfitService = Depends()
):
    success = await outfit_service.delete_outfit(outfit_id, current_user.id)
    if not success:
        raise HTTPException(status_code=404, detail="Outfit not found")
    return {"message": "Outfit deleted successfully"}

@router.post("/{outfit_id}/share")
async def share_outfit(
    outfit_id: str,
    current_user = Depends(get_current_user),
    outfit_service: OutfitService = Depends()
):
    return await outfit_service.share_outfit(outfit_id, current_user.id)
```

```

