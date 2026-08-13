from fastapi import APIRouter, Depends
from app.models.user import User, UserUpdate
from app.api.dependencies import get_current_user
from app.services.unified_auth_service import auth_service

router = APIRouter()


@router.get("/me", response_model=User)
async def get_current_user_info(current_user: User = Depends(get_current_user)):
    return current_user


@router.put("/me", response_model=User)
async def update_user_info(
    user_update: UserUpdate,
    current_user: User = Depends(get_current_user),
):
    updates = user_update.model_dump(exclude_unset=True)
    return await auth_service.update_profile(current_user.user_id, updates)
