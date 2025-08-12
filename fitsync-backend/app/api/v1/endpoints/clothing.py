"""
Clothing management endpoints for wardrobe and outfit operations
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query, UploadFile, File
from sqlalchemy.orm import Session
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Any, List, Optional
import logging

from app.core.security import SecurityManager, get_current_user
from app.database import get_db
from app.schemas.clothing import (
    ClothingItemCreate, ClothingItemUpdate, ClothingItemResponse,
    OutfitCombinationCreate, OutfitCombinationUpdate, OutfitCombinationResponse,
    OutfitWithItems, ClothingSearchParams, OutfitSearchParams,
    WardrobeStats, OutfitStats
)
from app.models.clothing import ClothingItem, OutfitCombination, OutfitItem
from app.models.user import User
from app.core.exceptions import ResourceNotFoundError, ValidationError

logger = logging.getLogger(__name__)

router = APIRouter()

@router.post("/upload", response_model=ClothingItemResponse, status_code=status.HTTP_201_CREATED)
async def upload_clothing_item(
    name: str,
    category: str,
    subcategory: str,
    color: str,
    brand: Optional[str] = None,
    size: Optional[str] = None,
    price: Optional[float] = None,
    season: Optional[str] = None,
    occasion: Optional[str] = None,
    image: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> Any:
    """
    Upload a new clothing item
    """
    try:
        # Validate file type
        if not image.content_type.startswith('image/'):
            raise ValidationError("File must be an image")
        
        # Save image (in production, you'd upload to cloud storage)
        # For now, we'll just store the filename
        image_filename = f"{current_user.id}_{image.filename}"
        
        # Create clothing item
        clothing_item = ClothingItem(
            user_id=current_user.id,
            name=name,
            category=category,
            subcategory=subcategory,
            color=color,
            brand=brand,
            size=size,
            price=price,
            season=season,
            occasion=occasion,
            image_url=image_filename,
            is_active=True
        )
        
        db.add(clothing_item)
        await db.commit()
        await db.refresh(clothing_item)
        
        logger.info(f"Clothing item uploaded by user: {current_user.email}")
        
        return ClothingItemResponse(
            id=clothing_item.id,
            user_id=clothing_item.user_id,
            name=clothing_item.name,
            category=clothing_item.category,
            subcategory=clothing_item.subcategory,
            color=clothing_item.color,
            brand=clothing_item.brand,
            size=clothing_item.size,
            price=clothing_item.price,
            season=clothing_item.season,
            occasion=clothing_item.occasion,
            image_url=clothing_item.image_url,
            is_active=clothing_item.is_active,
            created_at=clothing_item.created_at,
            updated_at=clothing_item.updated_at
        )
        
    except Exception as e:
        await db.rollback()
        logger.error(f"Error uploading clothing item: {e}")
        raise

@router.get("/items", response_model=List[ClothingItemResponse])
async def get_user_wardrobe(
    category: Optional[str] = Query(None, description="Filter by category"),
    subcategory: Optional[str] = Query(None, description="Filter by subcategory"),
    color: Optional[str] = Query(None, description="Filter by color"),
    season: Optional[str] = Query(None, description="Filter by season"),
    limit: int = Query(20, ge=1, le=100, description="Number of results to return"),
    offset: int = Query(0, ge=0, description="Number of results to skip"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> Any:
    """
    Get user's wardrobe items with filters
    """
    try:
        query = select(ClothingItem).where(
            ClothingItem.user_id == current_user.id,
            ClothingItem.is_active == True
        )
        
        if category:
            query = query.where(ClothingItem.category == category)
        if subcategory:
            query = query.where(ClothingItem.subcategory == subcategory)
        if color:
            query = query.where(ClothingItem.color == color)
        if season:
            query = query.where(ClothingItem.season == season)
        
        query = query.limit(limit).offset(offset)
        
        result = await db.execute(query)
        items = result.scalars().all()
        
        return [ClothingItemResponse.from_orm(item) for item in items]
        
    except Exception as e:
        logger.error(f"Error getting user wardrobe: {e}")
        raise

@router.get("/items/{item_id}", response_model=ClothingItemResponse)
async def get_clothing_item(
    item_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> Any:
    """
    Get specific clothing item
    """
    try:
        result = await db.execute(select(ClothingItem).where(
            ClothingItem.id == item_id,
            ClothingItem.user_id == current_user.id,
            ClothingItem.is_active == True
        ))
        item = result.scalar_one_or_none()
        
        if not item:
            raise ResourceNotFoundError("Clothing item not found")
        
        return ClothingItemResponse.from_orm(item)
        
    except Exception as e:
        logger.error(f"Error getting clothing item: {e}")
        raise

@router.put("/items/{item_id}", response_model=ClothingItemResponse)
async def update_clothing_item(
    item_id: int,
    item_data: ClothingItemUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> Any:
    """
    Update clothing item
    """
    try:
        result = await db.execute(select(ClothingItem).where(
            ClothingItem.id == item_id,
            ClothingItem.user_id == current_user.id,
            ClothingItem.is_active == True
        ))
        item = result.scalar_one_or_none()
        
        if not item:
            raise ResourceNotFoundError("Clothing item not found")
        
        # Update fields
        for field, value in item_data.dict(exclude_unset=True).items():
            setattr(item, field, value)
        
        await db.commit()
        await db.refresh(item)
        
        logger.info(f"Clothing item updated by user: {current_user.email}")
        
        return ClothingItemResponse.from_orm(item)
        
    except Exception as e:
        await db.rollback()
        logger.error(f"Error updating clothing item: {e}")
        raise

@router.delete("/items/{item_id}")
async def delete_clothing_item(
    item_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> Any:
    """
    Delete clothing item (soft delete)
    """
    try:
        result = await db.execute(select(ClothingItem).where(
            ClothingItem.id == item_id,
            ClothingItem.user_id == current_user.id,
            ClothingItem.is_active == True
        ))
        item = result.scalar_one_or_none()
        
        if not item:
            raise ResourceNotFoundError("Clothing item not found")
        
        item.is_active = False
        await db.commit()
        
        logger.info(f"Clothing item deleted by user: {current_user.email}")
        
        return {"message": "Clothing item deleted successfully"}
        
    except Exception as e:
        await db.rollback()
        logger.error(f"Error deleting clothing item: {e}")
        raise

@router.post("/outfits", response_model=OutfitCombinationResponse, status_code=status.HTTP_201_CREATED)
async def create_outfit(
    outfit_data: OutfitCombinationCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> Any:
    """
    Create a new outfit combination
    """
    try:
        # Create outfit
        outfit = OutfitCombination(
            user_id=current_user.id,
            name=outfit_data.name,
            description=outfit_data.description,
            season=outfit_data.season,
            occasion=outfit_data.occasion,
            is_favorite=outfit_data.is_favorite,
            is_active=True
        )
        
        db.add(outfit)
        await db.flush()  # Get the outfit ID
        
        # Add outfit items
        for item_data in outfit_data.items:
            outfit_item = OutfitItem(
                outfit_id=outfit.id,
                clothing_item_id=item_data.clothing_item_id,
                position=item_data.position
            )
            db.add(outfit_item)
        
        await db.commit()
        await db.refresh(outfit)
        
        logger.info(f"Outfit created by user: {current_user.email}")
        
        return OutfitCombinationResponse.from_orm(outfit)
        
    except Exception as e:
        await db.rollback()
        logger.error(f"Error creating outfit: {e}")
        raise

@router.get("/outfits", response_model=List[OutfitCombinationResponse])
async def get_user_outfits(
    season: Optional[str] = Query(None, description="Filter by season"),
    occasion: Optional[str] = Query(None, description="Filter by occasion"),
    is_favorite: Optional[bool] = Query(None, description="Filter by favorite status"),
    limit: int = Query(20, ge=1, le=100, description="Number of results to return"),
    offset: int = Query(0, ge=0, description="Number of results to skip"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> Any:
    """
    Get user's outfits with filters
    """
    try:
        query = select(OutfitCombination).where(
            OutfitCombination.user_id == current_user.id,
            OutfitCombination.is_active == True
        )
        
        if season:
            query = query.where(OutfitCombination.season == season)
        if occasion:
            query = query.where(OutfitCombination.occasion == occasion)
        if is_favorite is not None:
            query = query.where(OutfitCombination.is_favorite == is_favorite)
        
        query = query.limit(limit).offset(offset)
        
        result = await db.execute(query)
        outfits = result.scalars().all()
        
        return [OutfitCombinationResponse.from_orm(outfit) for outfit in outfits]
        
    except Exception as e:
        logger.error(f"Error getting user outfits: {e}")
        raise

@router.get("/outfits/{outfit_id}", response_model=OutfitWithItems)
async def get_outfit_with_items(
    outfit_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> Any:
    """
    Get outfit with its items
    """
    try:
        result = await db.execute(select(OutfitCombination).where(
            OutfitCombination.id == outfit_id,
            OutfitCombination.user_id == current_user.id,
            OutfitCombination.is_active == True
        ))
        outfit = result.scalar_one_or_none()
        
        if not outfit:
            raise ResourceNotFoundError("Outfit not found")
        
        # Get outfit items
        result = await db.execute(select(OutfitItem).where(OutfitItem.outfit_id == outfit_id))
        outfit_items = result.scalars().all()
        
        # Get clothing items for each outfit item
        clothing_items = []
        for outfit_item in outfit_items:
            result = await db.execute(select(ClothingItem).where(
                ClothingItem.id == outfit_item.clothing_item_id,
                ClothingItem.is_active == True
            ))
            clothing_item = result.scalar_one_or_none()
            if clothing_item:
                clothing_items.append(clothing_item)
        
        return OutfitWithItems(
            outfit=OutfitCombinationResponse.from_orm(outfit),
            items=clothing_items
        )
        
    except Exception as e:
        logger.error(f"Error getting outfit with items: {e}")
        raise

@router.put("/outfits/{outfit_id}", response_model=OutfitCombinationResponse)
async def update_outfit(
    outfit_id: int,
    outfit_data: OutfitCombinationUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> Any:
    """
    Update outfit
    """
    try:
        result = await db.execute(select(OutfitCombination).where(
            OutfitCombination.id == outfit_id,
            OutfitCombination.user_id == current_user.id,
            OutfitCombination.is_active == True
        ))
        outfit = result.scalar_one_or_none()
        
        if not outfit:
            raise ResourceNotFoundError("Outfit not found")
        
        # Update fields
        for field, value in outfit_data.dict(exclude_unset=True).items():
            setattr(outfit, field, value)
        
        await db.commit()
        await db.refresh(outfit)
        
        logger.info(f"Outfit updated by user: {current_user.email}")
        
        return OutfitCombinationResponse.from_orm(outfit)
        
    except Exception as e:
        await db.rollback()
        logger.error(f"Error updating outfit: {e}")
        raise

@router.delete("/outfits/{outfit_id}")
async def delete_outfit(
    outfit_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> Any:
    """
    Delete outfit (soft delete)
    """
    try:
        result = await db.execute(select(OutfitCombination).where(
            OutfitCombination.id == outfit_id,
            OutfitCombination.user_id == current_user.id,
            OutfitCombination.is_active == True
        ))
        outfit = result.scalar_one_or_none()
        
        if not outfit:
            raise ResourceNotFoundError("Outfit not found")
        
        # Delete outfit items
        await db.execute(select(OutfitItem).where(OutfitItem.outfit_id == outfit_id).delete())
        
        # Soft delete outfit
        outfit.is_active = False
        await db.commit()
        
        logger.info(f"Outfit deleted by user: {current_user.email}")
        
        return {"message": "Outfit deleted successfully"}
        
    except Exception as e:
        await db.rollback()
        logger.error(f"Error deleting outfit: {e}")
        raise

@router.get("/stats/wardrobe", response_model=WardrobeStats)
async def get_wardrobe_stats(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> Any:
    """
    Get wardrobe statistics
    """
    try:
        # Get total items
        result = await db.execute(select(ClothingItem).where(
            ClothingItem.user_id == current_user.id,
            ClothingItem.is_active == True
        ))
        total_items = len(result.scalars().all())
        
        # Get categories
        result = await db.execute(select(ClothingItem.category).where(
            ClothingItem.user_id == current_user.id,
            ClothingItem.is_active == True
        ))
        categories = [row[0] for row in result.fetchall()]
        
        # Get colors
        result = await db.execute(select(ClothingItem.color).where(
            ClothingItem.user_id == current_user.id,
            ClothingItem.is_active == True
        ))
        colors = [row[0] for row in result.fetchall()]
        
        return WardrobeStats(
            total_items=total_items,
            categories=list(set(categories)),
            colors=list(set(colors))
        )
        
    except Exception as e:
        logger.error(f"Error getting wardrobe stats: {e}")
        raise
