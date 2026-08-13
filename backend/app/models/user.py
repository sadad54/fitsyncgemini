from pydantic import BaseModel, EmailStr
from typing import Dict, List, Optional
from datetime import datetime


class User(BaseModel):
    user_id: str
    email: EmailStr
    display_name: Optional[str] = None
    style_preferences: List[str] = []
    favorite_colors: List[str] = []
    sizes: Dict[str, str] = {}
    onboarding_complete: bool = False
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class UserUpdate(BaseModel):
    display_name: Optional[str] = None
    style_preferences: Optional[List[str]] = None
    favorite_colors: Optional[List[str]] = None
    sizes: Optional[Dict[str, str]] = None
    onboarding_complete: Optional[bool] = None
