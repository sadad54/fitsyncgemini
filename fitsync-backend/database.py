from sqlalchemy import Column, String, Float, DateTime, Boolean, Text, JSON, Integer, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid

Base = declarative_base()

class User(Base):
    __tablename__ = "users"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    email = Column(String, unique=True, index=True, nullable=True)
    full_name = Column(String, nullable=True)
    style_archetype = Column(String, nullable=True)
    preferences = Column(JSON, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=funcpost("/clothing", response_model=ClothingAnalysis)
async def analyze_clothing(
    file: UploadFile = File(...),
    include_attributes: bool = True,
    include_style_scores: bool = True,
    ml_service: MLService = Depends(get_ml_service)
):
    """Advanced clothing analysis with fashion attributes"""
    
    # Validate image
    if not validate_image(file):
        raise HTTPException(status_code=400, detail="Invalid image format")
    
    try:
        # Process image
        image_path = await process_image(file)
        
        # Perform analysis
        result = await ml_service.analyze_clothing(
            image_path=image_path,
            include_attributes=include_attributes,
            include_style_scores=include_style_scores
        )
        
        logger.info(f"Clothing analysis completed for {file.filename}")
        return result
        
    except Exception as e:
        logger.error(f"Clothing analysis failed: {str(e)}")
        raise HTTPException(status_code=500, detail="Analysis failed")

@router.post("/style", response_model=StyleAnalysis)
async def analyze_style(
    file: UploadFile = File(...),
    user_preferences: Optional[dict] = None,
    ml_service: MLService = Depends(get_ml_service)
):
    """Analyze personal style and fashion archetype"""
    
    try:
        image_path = await process_image(file)
        
        result = await ml_service.analyze_style(
            image_path=image_path,
            user_preferences=user_preferences
        )
        
        return result
        
    except Exception as e:
        logger.error(f"Style analysis failed: {str(e)}")
        raise HTTPException(status_code=500, detail="Style analysis failed")

@router.post("/color-palette")
async def analyze_color_palette(
    file: UploadFile = File(...),
    ml_service: MLService = Depends(get_ml_service)
):
    """Analyze personal color palette"""
    
    try:
        image_path = await process_image(file)
        
        result = await ml_service.analyze_color_palette(image_path)
        
        return {
            "dominant_colors": result["colors"],
            "color_harmony_score": result["harmony_score"],
            "seasonal_analysis": result["seasonal_compatibility"],
            "recommended_colors": result["recommendations"]
        }
        
    except Exception as e:
        logger.error(f"Color palette analysis failed: {str(e)}")
        raise HTTPException(status_code=500, detail="Color analysis failed")

@router.post("/body-type", response_model=BodyTypeAnalysis)     