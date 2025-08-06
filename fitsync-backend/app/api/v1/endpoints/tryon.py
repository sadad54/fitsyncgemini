from fastapi import APIRouter, UploadFile, File, Depends, HTTPException, BackgroundTasks
from typing import List
import structlog
import uuid

from app.services.ml_service import MLService, get_ml_service
from app.schemas.tryon import TryOnRequest, TryOnResult
from app.core.security import get_current_user
from app.schemas.user import User

router = APIRouter()
logger = structlog.get_logger()

@router.post("/generate", response_model=dict)
async def generate_tryon(
    background_tasks: BackgroundTasks,
    user_photo: UploadFile = File(...),
    outfit_items: List[str],
    pose_adjustment: bool = True,
    lighting_adjustment: bool = True,
    user: User = Depends(get_current_user),
    ml_service: MLService = Depends(get_ml_service)
):
    """Generate virtual try-on visualization"""
    
    # Generate unique job ID
    job_id = str(uuid.uuid4())
    
    try:
        # Validate inputs
        if not user_photo.content_type.startswith('image/'):
            raise HTTPException(status_code=400, detail="Invalid image format")
        
        # Start background processing
        background_tasks.add_task(
            process_tryon_job,
            job_id=job_id,
            user_photo=user_photo,
            outfit_items=outfit_items,
            pose_adjustment=pose_adjustment,
            lighting_adjustment=lighting_adjustment,
            user_id=user.id,
            ml_service=ml_service
        )
        
        return {
            "job_id": job_id,
            "status": "processing",
            "estimated_completion": "30-60 seconds",
            "result_url": f"/api/v1/tryon/results/{job_id}"
        }
        
    except Exception as e:
        logger.error(f"Try-on generation failed: {str(e)}")
        raise HTTPException(status_code=500, detail="Try-on generation failed")

@router.get("/results/{job_id}", response_model=TryOnResult)
async def get_tryon_results(
    job_id: str,
    user: User = Depends(get_current_user)
):
    """Get virtual try-on results"""
    
    try:
        # Check job status and results
        # In production, this would query a job queue/database
        result = await check_tryon_job_status(job_id, user.id)
        
        if not result:
            raise HTTPException(status_code=404, detail="Job not found")
        
        return result
        
    except Exception as e:
        logger.error(f"Try-on result retrieval failed: {str(e)}")
        raise HTTPException(status_code=500, detail="Result retrieval failed")

@router.post("/batch")
async def batch_tryon(
    background_tasks: BackgroundTasks,
    user_photo: UploadFile = File(...),
    outfit_combinations: List[List[str]],
    user: User = Depends(get_current_user),
    ml_service: MLService = Depends(get_ml_service)
):
    """Generate multiple try-on visualizations in batch"""
    
    batch_id = str(uuid.uuid4())
    
    try:
        # Start batch processing
        background_tasks.add_task(
            process_batch_tryon,
            batch_id=batch_id,
            user_photo=user_photo,
            outfit_combinations=outfit_combinations,
            user_id=user.id,
            ml_service=ml_service
        )
        
        return {
            "batch_id": batch_id,
            "status": "processing",
            "total_combinations": len(outfit_combinations),
            "estimated_completion": f"{len(outfit_combinations) * 45} seconds"
        }
        
    except Exception as e:
        logger.error(f"Batch try-on failed: {str(e)}")
        raise HTTPException(status_code=500, detail="Batch try-on failed")

async def process_tryon_job(job_id: str, user_photo: UploadFile, outfit_items: List[str], 
                           pose_adjustment: bool, lighting_adjustment: bool, 
                           user_id: str, ml_service: MLService):
    """Background task to process try-on generation"""
    
    try:
        # Process the try-on generation
        result = await ml_service.generate_virtual_tryon(
            user_photo=user_photo,
            outfit_items=outfit_items,
            pose_adjustment=pose_adjustment,
            lighting_adjustment=lighting_adjustment
        )
        
        # Store result in database/cache
        await store_tryon_result(job_id, user_id, result)
        
        logger.info(f"Try-on job {job_id} completed successfully")
        
    except Exception as e:
        logger.error(f"Try-on job {job_id} failed: {str(e)}")
        await store_tryon_error(job_id, user_id, str(e))

async def process_batch_tryon(batch_id: str, user_photo: UploadFile, 
                             outfit_combinations: List[List[str]], 
                             user_id: str, ml_service: MLService):
    """Background task to process batch try-on generation"""
    
    results = []
    
    for i, outfit_items in enumerate(outfit_combinations):
        try:
            result = await ml_service.generate_virtual_tryon(
                user_photo=user_photo,
                outfit_items=outfit_items,
                pose_adjustment=True,
                lighting_adjustment=True
            )
            
            results.append({
                "combination_index": i,
                "status": "success",
                "result": result
            })
            
        except Exception as e:
            logger.error(f"Batch try-on combination {i} failed: {str(e)}")
            results.append({
                "combination_index": i,
                "status": "error",
                "error": str(e)
            })
    
    # Store batch results
    await store_batch_tryon_results(batch_id, user_id, results)
