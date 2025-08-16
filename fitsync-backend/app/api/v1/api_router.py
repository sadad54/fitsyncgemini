# pylint: disable=import-error
from fastapi import APIRouter
from app.api.v1.endpoints import analyze, auth, users, clothing
from app.api.v1.endpoints import ml_endpoints, ml_recommendations, cache_management, virtual_tryon, social

api_router = APIRouter()

# Authentication endpoints
api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])

# User management endpoints
api_router.include_router(users.router, prefix="/users", tags=["User Management"])

# Clothing and wardrobe endpoints
api_router.include_router(clothing.router, prefix="/clothing", tags=["Clothing & Wardrobe"])

# Analysis endpoints
api_router.include_router(analyze.router, prefix="/analyze", tags=["Analysis"])

# ML endpoints
api_router.include_router(ml_endpoints.router, prefix="/ml", tags=["Machine Learning"])

# ML Recommendations and Content Discovery endpoints
api_router.include_router(ml_recommendations.router, prefix="", tags=["ML Recommendations & Discovery"])

# Virtual Try-On endpoints
api_router.include_router(virtual_tryon.router, prefix="/tryon", tags=["Virtual Try-On"])

# Social endpoints
api_router.include_router(social.router, prefix="/social", tags=["Social"])

# Cache management endpoints
api_router.include_router(cache_management.router, prefix="/cache", tags=["Cache Management"])