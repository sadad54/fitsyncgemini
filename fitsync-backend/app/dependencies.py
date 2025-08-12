from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer
from sqlalchemy.orm import Session
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.core.security import verify_token
from app.models.user import User

security = HTTPBearer()

async def get_current_user(
    token: str = Depends(security),
    db: AsyncSession = Depends(get_db)
) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    username = verify_token(token.credentials)
    if username is None:
        raise credentials_exception
    
    result = await db.execute(select(User).where(User.email == username))
    user = result.scalar_one_or_none()
    if user is None:
        raise credentials_exception
    
    return user