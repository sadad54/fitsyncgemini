from fastapi import APIRouter
from app.api.v1.endpoints import detect, color, suggest

router = APIRouter()

router.include_router(detect.router, tags=["Detection"])
router.include_router(color.router, tags=["Color"])
router.include_router(suggest.router, tags=["Suggestions"])
