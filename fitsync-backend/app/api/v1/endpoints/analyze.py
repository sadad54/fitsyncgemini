from fastapi import APIRouter, UploadFile, File, Depends, HTTPException, BackgroundTasks
from typing import List, Optional
import structlog

from app.services.ml_service import MLService, get_ml_service
from app.schemas.clothing import ClothingAnalysis, StyleAnalysis
from app.utils.image_processing import validate_image, process_image

router = APIRouter()
logger = structlog.get_logger()

@router.post("/body-type")
async def analyze_body_type(
    file: UploadFile = File(...),
    height: Optional[float] = None,
    weight: Optional[float] = None,
    ml_service: MLService = Depends(get_ml_service)
):
    """Analyze body type for personalized recommendations"""
    
    try:
        image_path = await process_image(file)
        
        result = await ml_service.analyze_body_type(
            image_path=image_path,
            height=height,
            weight=weight
        )
        
        return {
            "body_type": result["type"],
            "confidence": result["confidence"],
            "measurements": result["estimated_measurements"],
            "recommendations": result["style_recommendations"]
        }
        
    except Exception as e:
        logger.error(f"Body type analysis failed: {str(e)}")
        raise HTTPException(status_code=500, detail="Body analysis failed")
