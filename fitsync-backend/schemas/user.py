from pydantic import BaseModel, EmailStr
from typing import Optional, List, Dict
from datetime import datetime

class UserBase(BaseModel):
    email: EmailStr
    full_name: Optional[str] = None
    style_archetype: Optional[str] = None
    body_type: Optional[str] = None
    preferences: Optional[Dict] = None
    location: Optional[str] = None

class UserCreate(UserBase):
    password: str

class User(UserBase):
    id: str
    is_active: bool = True
    created_at: datetime
    
    class Config:
        from_attributes = True
