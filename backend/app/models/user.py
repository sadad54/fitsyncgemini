from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime

class UserBase(BaseModel):
    email: EmailStr
    username: str
    full_name: Optional[str] = None

class UserCreate(UserBase):
    password: str

class UserUpdate(BaseModel):
    email: Optional[EmailStr] = None
    username: Optional[str] = None
    full_name: Optional[str] = None
    bio: Optional[str] = None
    profile_image: Optional[str] = None

class User(UserBase):
    id: str
    created_at: datetime
    updated_at: datetime
    bio: Optional[str] = None
    profile_image: Optional[str] = None
    
    class Config:
        from_attributes = True
