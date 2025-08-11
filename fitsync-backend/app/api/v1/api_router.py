from fastapi import APIRouter
from app.api.v1.endpoints import analyze, auth, users, clothing
from app.api.v1.endpoints import ml_endpoints

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