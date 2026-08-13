from datetime import datetime
from typing import Any, Dict, List, Literal, Optional

from pydantic import BaseModel

ClothingCategory = Literal[
    "tops", "bottoms", "dresses", "outerwear", "footwear", "accessories", "activewear", "unknown"
]


class ClothingItem(BaseModel):
    id: str
    user_id: str
    name: str
    image_url: Optional[str] = None
    category: ClothingCategory
    subcategory: Optional[str] = None
    colors: List[str] = []
    tags: List[str] = []
    seasons: List[str] = []
    occasions: List[str] = []
    brand: Optional[str] = None
    notes: Optional[str] = None
    analysis: Dict[str, Any] = {}
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class ClothingItemUpdate(BaseModel):
    name: Optional[str] = None
    image_url: Optional[str] = None
    category: Optional[ClothingCategory] = None
    subcategory: Optional[str] = None
    colors: Optional[List[str]] = None
    tags: Optional[List[str]] = None
    seasons: Optional[List[str]] = None
    occasions: Optional[List[str]] = None
    brand: Optional[str] = None
    notes: Optional[str] = None
