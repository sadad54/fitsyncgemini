"""
ML-specific API endpoints for model interactions
"""

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, BackgroundTasks
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from typing import Dict, Any, Optional
import asyncio

from app.database import get_db
from app.core.security import SecurityManager, get_current_user
from app.models.user import User
from app.services.enhanced_ml_service import enhanced_ml_service
from app.services.ml_model_manager import ml_model_manager
from app.core.exceptions import MLModelError

router = APIRouter()

@router.post("/analyze/clothing")
async def analyze_clothing_image(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Analyze clothing items in uploaded image"""
    
    if not file.content_type.startswith('image/'):
        raise HTTPException(status_code=400, detail="File must be an image")
    
    try:
        image_data = await file.read()
        result = await enhanced_ml_service.analyze_clothing_image(image_data, current_user.id)
        return JSONResponse(content=result)
        
    except MLModelError as e:
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Analysis failed: {str(e)}")

@router.post("/pose/estimate")
async def estimate_body_pose(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """Estimate body pose and measurements"""
    
    if not file.content_type.startswith('image/'):
        raise HTTPException(status_code=400, detail="File must be an image")
    
    try:
        image_data = await file.read()
        result = await enhanced_ml_service.estimate_body_pose(image_data)
        return JSONResponse(content=result)
        
    except MLModelError as e:
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Pose estimation failed: {str(e)}")

@router.post("/virtual-tryon")
async def generate_virtual_tryon(
    person_image: UploadFile = File(...),
    clothing_image: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """Generate virtual try-on visualization"""
    
    if not person_image.content_type.startswith('image/') or not clothing_image.content_type.startswith('image/'):
        raise HTTPException(status_code=400, detail="Both files must be images")
    
    try:
        person_data = await person_image.read()
        clothing_data = await clothing_image.read()
        
        result = await enhanced_ml_service.generate_virtual_tryon(person_data, clothing_data)
        return JSONResponse(content=result)
        
    except MLModelError as e:
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Virtual try-on failed: {str(e)}")

@router.get("/recommendations")
async def get_recommendations(
    context: Optional[Dict[str, Any]] = None,
    current_user: User = Depends(get_current_user)
):
    """Get personalized recommendations"""
    
    try:
        result = await enhanced_ml_service.get_user_recommendations(current_user.id, context)
        return JSONResponse(content=result)
        
    except MLModelError as e:
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Recommendation generation failed: {str(e)}")

@router.get("/models/status")
async def get_model_status(
    current_user: User = Depends(get_current_user)
):
    """Get status of all ML models"""
    
    try:
        status = await enhanced_ml_service.get_model_status()
        return JSONResponse(content=status)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get model status: {str(e)}")

@router.post("/models/reload")
async def reload_models(
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_user)
):
    """Reload ML models (admin only)"""
    
    # Check if user is admin (implement your admin check logic)
    if not current_user.is_admin:  # Add this field to your User model
        raise HTTPException(status_code=403, detail="Admin access required")
    
    try:
        # Reload models in background
        background_tasks.add_task(ml_model_manager.cleanup)
        background_tasks.add_task(ml_model_manager.initialize)
        
        return {"message": "Model reload initiated", "status": "success"}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Model reload failed: {str(e)}")
