# pylint: disable=import-error
"""
Social (Style Posts) Schemas
"""

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


class StylePostCreate(BaseModel):
    image_url: str = Field(..., max_length=500)
    caption: Optional[str] = Field(None, max_length=2000)
    outfit_id: int
    tags: Optional[List[str]] = Field(default_factory=list, max_items=50)
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    location: Optional[str] = Field(None, max_length=200)


class StylePostResponse(BaseModel):
    id: int
    userId: int
    userName: str
    userAvatarUrl: Optional[str] = None
    imageUrl: str
    caption: Optional[str] = None
    outfitId: int
    tags: List[str] = []
    likesCount: int
    commentsCount: int
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    location: Optional[str] = None
    createdAt: datetime


