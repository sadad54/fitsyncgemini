from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List

from app.database import get_db
from app.dependencies import get_current_user
from app.services.ml_service import MLService
from app.models.user import User
from app.models.clothing import ClothingItem
from app.schemas.clothing import ClothingAnalysisResponse

router = APIRouter()
ml_service = MLService()

@router.post("/clothing", response_model=ClothingAnalysisResponse)
async def analyze_clothing(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Analyze clothing items in uploaded image"""
    
    # Validate file type
    if not file.content_type.startswith('image/'):
        raise HTTPException(status_code=400, detail="File must be an image")
    
    try:
        # Read image data
        image_data = await file.read()
        
        # Analyze with ML service
        analysis_result = await ml_service.analyze_clothing_image(image_data)
        
        # Save analysis to database (optional)
        # TODO: Save analysis results for user history
        
        return ClothingAnalysisResponse(**analysis_result)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Analysis failed: {str(e)}")

@router.post("/style")
async def analyze_style(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Analyze user's overall style preferences"""
    
    # Get user's clothing history
    result = await db.execute(select(ClothingItem).where(ClothingItem.user_id == current_user.id))
    clothing_items = result.scalars().all()
    
    if not clothing_items:
        raise HTTPException(status_code=404, detail="No clothing items found for analysis")
    
    # Convert to analysis format
    clothing_history = [
        {
            'id': item.id,
            'category': item.category,
            'color_primary': item.color_primary,
            'style_tags': item.style_tags or [],
            'fit_type': item.fit_type
        }
        for item in clothing_items
    ]
    
    # Analyze style preferences
    from app.models.recommendation.style_matcher import StyleMatcher
    style_matcher = StyleMatcher()
    style_analysis = style_matcher.analyze_user_style(clothing_history)
    
    return {
        'user_id': current_user.id,
        'style_scores': style_analysis,
        'dominant_style': max(style_analysis.items(), key=lambda x: x[1])[0],
        'item_count': len(clothing_items)
    }

@router.post("/color-palette")
async def analyze_color_palette(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """Analyze personal color palette from user photo"""
    
    if not file.content_type.startswith('image/'):
        raise HTTPException(status_code=400, detail="File must be an image")
    
    try:
        image_data = await file.read()
        
        # TODO: Implement skin tone analysis
        # This would use computer vision to analyze skin tone
        # and recommend complementary colors
        
        # Placeholder response
        return {
            'skin_tone': 'warm',
            'season': 'autumn',
            'recommended_colors': ['burgundy', 'forest_green', 'rust', 'cream'],
            'colors_to_avoid': ['bright_pink', 'electric_blue']
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Color analysis failed: {str(e)}")

@router.post("/body-type")
async def analyze_body_type(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """Analyze body type for better fit recommendations"""
    
    if not file.content_type.startswith('image/'):
        raise HTTPException(status_code=400, detail="File must be an image")
    
    try:
        image_data = await file.read()
        
        # TODO: Implement body type analysis using pose estimation
        # This would use MediaPipe or similar for body measurements
        
        # Placeholder response
        return {
            'body_type': 'rectangle',
            'fit_recommendations': {
                'tops': ['fitted', 'structured'],
                'bottoms': ['high_waisted', 'wide_leg'],
                'dresses': ['wrap', 'fit_and_flare']
            },
            'style_tips': [
                'Create curves with belted waists',
                'Add volume with layering',
                'Choose structured shoulders'
            ]
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Body type analysis failed: {str(e)}")