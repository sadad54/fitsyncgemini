from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class OutfitBase(BaseModel):
    name: str
    description: Optional[str] = None
    clothing_items: List[str]  # List of clothing item IDs
    is_public: bool = False

class OutfitCreate(OutfitBase):
    pass

class OutfitUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    clothing_items: Optional[List[str]] = None
    is_public: Optional[bool] = None

class Outfit(OutfitBase):
    id: str
    user_id: str
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True
