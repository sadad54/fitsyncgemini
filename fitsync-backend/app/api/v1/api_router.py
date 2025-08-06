from fastapi import APIRouter
from app.api.v1.endpoints import analyze, recommend, tryon, social, user, trends

router = APIRouter()

# Include all endpoint routers with proper tags
router.include_router(analyze.router, prefix="/analyze", tags=["Analysis"])
router.include_router(recommend.router, prefix="/recommend", tags=["Recommendations"])
router.include_router(tryon.router, prefix="/tryon", tags=["Virtual Try-On"])
router.include_router(social.router, prefix="/social", tags=["Social Features"])
router.include_router(user.router, prefix="/user", tags=["User Management"])
router.include_router(trends.router, prefix="/trends", tags=["Fashion Trends"])

