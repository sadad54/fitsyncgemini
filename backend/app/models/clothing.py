from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from enum import Enum

class ClothingCategory(str, Enum):
    TOP = "top"
    BOTTOM = "bottom"
    DRESS = "dress"
    OUTERWEAR = "outerwear"
    SHOES = "shoes"
    ACCESSORIES = "accessories"

class ClothingItemBase(BaseModel):
    name: str
    category: ClothingCategory
    color: str
    brand: Optional[str] = None
    description: Optional[str] = None
    image_url: str

class ClothingItemCreate(ClothingItemBase):
    pass

class ClothingItemUpdate(BaseModel):
    name: Optional[str] = None
    category: Optional[ClothingCategory] = None
    color: Optional[str] = None
    brand: Optional[str] = None
    description: Optional[str] = None
    image_url: Optional[str] = None

class ClothingItem(ClothingItemBase):
    id: str
    user_id: str
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True
```

