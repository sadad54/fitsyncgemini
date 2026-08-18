from fastapi import APIRouter, Depends

from app.api.dependencies import get_current_user
from app.models.outfit import Outfit, OutfitFeedback, OutfitGenerateRequest
from app.models.user import User
from app.services.outfit_service import outfit_service

router = APIRouter()


@router.post("/generate", response_model=Outfit)
async def generate_outfit(
    request: OutfitGenerateRequest,
    current_user: User = Depends(get_current_user),
):
    return await outfit_service.generate_outfit(
        user_id=current_user.user_id,
        occasion=request.occasion,
        use_weather=request.use_weather,
        latitude=request.latitude,
        longitude=request.longitude,
    )


@router.get("/")
async def list_outfits(
    saved_only: bool = False,
    current_user: User = Depends(get_current_user),
):
    outfits, total = await outfit_service.list_outfits(current_user.user_id, saved_only)
    return {"outfits": outfits, "total": total}


@router.post("/{outfit_id}/save", response_model=Outfit)
async def save_outfit(outfit_id: str, current_user: User = Depends(get_current_user)):
    return await outfit_service.save_outfit(current_user.user_id, outfit_id)


@router.post("/{outfit_id}/favorite", response_model=Outfit)
async def favorite_outfit(outfit_id: str, current_user: User = Depends(get_current_user)):
    return await outfit_service.favorite_outfit(current_user.user_id, outfit_id)


@router.post("/{outfit_id}/feedback")
async def feedback_outfit(
    outfit_id: str,
    feedback: OutfitFeedback,
    current_user: User = Depends(get_current_user),
):
    await outfit_service.record_feedback(current_user.user_id, outfit_id, feedback.rating, feedback.reason)
    return {"recorded": True}
