"""
Clothing management endpoints for wardrobe and outfit operations
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query, UploadFile, File
from sqlalchemy.orm import Session
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
    db: Session = Depends(get_db)
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
        db.commit()
        db.refresh(clothing_item)
        
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
        db.rollback()
        logger.error(f"Error uploading clothing item: {e}")
        raise

@router.get("/items", response_model=List[ClothingItemResponse])
async def get_user_wardrobe(
    category: Optional[str] = Query(None, description="Filter by category"),
    color: Optional[str] = Query(None, description="Filter by color"),
    season: Optional[str] = Query(None, description="Filter by season"),
    limit: int = Query(20, ge=1, le=100, description="Number of results to return"),
    offset: int = Query(0, ge=0, description="Number of results to skip"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Get user's wardrobe items
    """
    try:
        # Build query
        query = db.query(ClothingItem).filter(
            ClothingItem.user_id == current_user.id,
            ClothingItem.is_active == True
        )
        
        # Apply filters
        if category:
            query = query.filter(ClothingItem.category == category)
        if color:
            query = query.filter(ClothingItem.color == color)
        if season:
            query = query.filter(ClothingItem.season == season)
        
        # Apply pagination
        items = query.offset(offset).limit(limit).all()
        
        return [
            ClothingItemResponse(
                id=item.id,
                user_id=item.user_id,
                name=item.name,
                category=item.category,
                subcategory=item.subcategory,
                color=item.color,
                brand=item.brand,
                size=item.size,
                price=item.price,
                season=item.season,
                occasion=item.occasion,
                image_url=item.image_url,
                is_active=item.is_active,
                created_at=item.created_at,
                updated_at=item.updated_at
            )
            for item in items
        ]
        
    except Exception as e:
        logger.error(f"Error getting user wardrobe: {e}")
        raise

@router.get("/items/{item_id}", response_model=ClothingItemResponse)
async def get_clothing_item(
    item_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Get specific clothing item
    """
    try:
        item = db.query(ClothingItem).filter(
            ClothingItem.id == item_id,
            ClothingItem.user_id == current_user.id
        ).first()
        
        if not item:
            raise ResourceNotFoundError("Clothing item not found")
        
        return ClothingItemResponse(
            id=item.id,
            user_id=item.user_id,
            name=item.name,
            category=item.category,
            subcategory=item.subcategory,
            color=item.color,
            brand=item.brand,
            size=item.size,
            price=item.price,
            season=item.season,
            occasion=item.occasion,
            image_url=item.image_url,
            is_active=item.is_active,
            created_at=item.created_at,
            updated_at=item.updated_at
        )
        
    except Exception as e:
        logger.error(f"Error getting clothing item: {e}")
        raise

@router.put("/items/{item_id}", response_model=ClothingItemResponse)
async def update_clothing_item(
    item_id: int,
    item_data: ClothingItemUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Update clothing item
    """
    try:
        item = db.query(ClothingItem).filter(
            ClothingItem.id == item_id,
            ClothingItem.user_id == current_user.id
        ).first()
        
        if not item:
            raise ResourceNotFoundError("Clothing item not found")
        
        # Update fields
        update_data = item_data.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(item, field, value)
        
        db.commit()
        db.refresh(item)
        
        logger.info(f"Clothing item updated by user: {current_user.email}")
        
        return ClothingItemResponse(
            id=item.id,
            user_id=item.user_id,
            name=item.name,
            category=item.category,
            subcategory=item.subcategory,
            color=item.color,
            brand=item.brand,
            size=item.size,
            price=item.price,
            season=item.season,
            occasion=item.occasion,
            image_url=item.image_url,
            is_active=item.is_active,
            created_at=item.created_at,
            updated_at=item.updated_at
        )
        
    except Exception as e:
        db.rollback()
        logger.error(f"Error updating clothing item: {e}")
        raise

@router.delete("/items/{item_id}")
async def delete_clothing_item(
    item_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Delete clothing item (soft delete)
    """
    try:
        item = db.query(ClothingItem).filter(
            ClothingItem.id == item_id,
            ClothingItem.user_id == current_user.id
        ).first()
        
        if not item:
            raise ResourceNotFoundError("Clothing item not found")
        
        # Soft delete
        item.is_active = False
        db.commit()
        
        logger.info(f"Clothing item deleted by user: {current_user.email}")
        
        return {"message": "Clothing item deleted successfully"}
        
    except Exception as e:
        db.rollback()
        logger.error(f"Error deleting clothing item: {e}")
        raise

@router.post("/outfits", response_model=OutfitCombinationResponse, status_code=status.HTTP_201_CREATED)
async def create_outfit(
    outfit_data: OutfitCombinationCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
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
            is_favorite=outfit_data.is_favorite
        )
        
        db.add(outfit)
        db.commit()
        db.refresh(outfit)
        
        # Add outfit items
        for item_id in outfit_data.item_ids:
            outfit_item = OutfitItem(
                outfit_id=outfit.id,
                clothing_item_id=item_id
            )
            db.add(outfit_item)
        
        db.commit()
        
        logger.info(f"Outfit created by user: {current_user.email}")
        
        return OutfitCombinationResponse(
            id=outfit.id,
            user_id=outfit.user_id,
            name=outfit.name,
            description=outfit.description,
            season=outfit.season,
            occasion=outfit.occasion,
            is_favorite=outfit.is_favorite,
            created_at=outfit.created_at,
            updated_at=outfit.updated_at
        )
        
    except Exception as e:
        db.rollback()
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
    db: Session = Depends(get_db)
) -> Any:
    """
    Get user's outfits
    """
    try:
        # Build query
        query = db.query(OutfitCombination).filter(
            OutfitCombination.user_id == current_user.id
        )
        
        # Apply filters
        if season:
            query = query.filter(OutfitCombination.season == season)
        if occasion:
            query = query.filter(OutfitCombination.occasion == occasion)
        if is_favorite is not None:
            query = query.filter(OutfitCombination.is_favorite == is_favorite)
        
        # Apply pagination
        outfits = query.offset(offset).limit(limit).all()
        
        return [
            OutfitCombinationResponse(
                id=outfit.id,
                user_id=outfit.user_id,
                name=outfit.name,
                description=outfit.description,
                season=outfit.season,
                occasion=outfit.occasion,
                is_favorite=outfit.is_favorite,
                created_at=outfit.created_at,
                updated_at=outfit.updated_at
            )
            for outfit in outfits
        ]
        
    except Exception as e:
        logger.error(f"Error getting user outfits: {e}")
        raise

@router.get("/outfits/{outfit_id}", response_model=OutfitWithItems)
async def get_outfit_with_items(
    outfit_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Get outfit with its items
    """
    try:
        outfit = db.query(OutfitCombination).filter(
            OutfitCombination.id == outfit_id,
            OutfitCombination.user_id == current_user.id
        ).first()
        
        if not outfit:
            raise ResourceNotFoundError("Outfit not found")
        
        # Get outfit items
        outfit_items = db.query(OutfitItem).filter(OutfitItem.outfit_id == outfit_id).all()
        
        # Get clothing items
        clothing_items = []
        for outfit_item in outfit_items:
            clothing_item = db.query(ClothingItem).filter(
                ClothingItem.id == outfit_item.clothing_item_id
            ).first()
            if clothing_item:
                clothing_items.append(ClothingItemResponse(
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
                ))
        
        return OutfitWithItems(
            outfit=OutfitCombinationResponse(
                id=outfit.id,
                user_id=outfit.user_id,
                name=outfit.name,
                description=outfit.description,
                season=outfit.season,
                occasion=outfit.occasion,
                is_favorite=outfit.is_favorite,
                created_at=outfit.created_at,
                updated_at=outfit.updated_at
            ),
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
    db: Session = Depends(get_db)
) -> Any:
    """
    Update outfit
    """
    try:
        outfit = db.query(OutfitCombination).filter(
            OutfitCombination.id == outfit_id,
            OutfitCombination.user_id == current_user.id
        ).first()
        
        if not outfit:
            raise ResourceNotFoundError("Outfit not found")
        
        # Update fields
        update_data = outfit_data.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(outfit, field, value)
        
        db.commit()
        db.refresh(outfit)
        
        logger.info(f"Outfit updated by user: {current_user.email}")
        
        return OutfitCombinationResponse(
            id=outfit.id,
            user_id=outfit.user_id,
            name=outfit.name,
            description=outfit.description,
            season=outfit.season,
            occasion=outfit.occasion,
            is_favorite=outfit.is_favorite,
            created_at=outfit.created_at,
            updated_at=outfit.updated_at
        )
        
    except Exception as e:
        db.rollback()
        logger.error(f"Error updating outfit: {e}")
        raise

@router.delete("/outfits/{outfit_id}")
async def delete_outfit(
    outfit_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Delete outfit
    """
    try:
        outfit = db.query(OutfitCombination).filter(
            OutfitCombination.id == outfit_id,
            OutfitCombination.user_id == current_user.id
        ).first()
        
        if not outfit:
            raise ResourceNotFoundError("Outfit not found")
        
        # Delete outfit items first
        db.query(OutfitItem).filter(OutfitItem.outfit_id == outfit_id).delete()
        
        # Delete outfit
        db.delete(outfit)
        db.commit()
        
        logger.info(f"Outfit deleted by user: {current_user.email}")
        
        return {"message": "Outfit deleted successfully"}
        
    except Exception as e:
        db.rollback()
        logger.error(f"Error deleting outfit: {e}")
        raise

@router.get("/stats/wardrobe", response_model=WardrobeStats)
async def get_wardrobe_stats(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Get wardrobe statistics
    """
    try:
        # Calculate stats
        total_items = db.query(ClothingItem).filter(
            ClothingItem.user_id == current_user.id,
            ClothingItem.is_active == True
        ).count()
        
        # Category breakdown
        categories = db.query(ClothingItem.category).filter(
            ClothingItem.user_id == current_user.id,
            ClothingItem.is_active == True
        ).distinct().all()
        
        category_count = len(categories)
        
        # Color breakdown
        colors = db.query(ClothingItem.color).filter(
            ClothingItem.user_id == current_user.id,
            ClothingItem.is_active == True
        ).distinct().all()
        
        color_count = len(colors)
        
        return WardrobeStats(
            total_items=total_items,
            category_count=category_count,
            color_count=color_count,
            total_outfits=0,  # Would be calculated
            favorite_outfits=0  # Would be calculated
        )
        
    except Exception as e:
        logger.error(f"Error getting wardrobe stats: {e}")
        raise
