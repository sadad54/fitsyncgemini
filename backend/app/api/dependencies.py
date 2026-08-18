from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.models.user import User
from app.services.unified_auth_service import auth_service

security = HTTPBearer()
optional_security = HTTPBearer(auto_error=False)

async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)) -> User:
    """Get current authenticated user"""
    try:
        return await auth_service.get_current_user_from_token(credentials.credentials)
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication failed"
        )

async def get_optional_user(credentials: HTTPAuthorizationCredentials | None = Depends(optional_security)) -> User | None:
    """Get current user if authenticated, None otherwise. Never raises on missing/invalid auth."""
    if credentials is None:
        return None
    try:
        return await auth_service.get_current_user_from_token(credentials.credentials)
    except Exception:
        return None

# Image validation
async def validate_image_file(file):
    """Validate uploaded image file"""
    if not file.content_type.startswith('image/'):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File must be an image"
        )
    
    # Check file size (10MB limit)
    file_size = 0
    chunk_size = 1024
    while chunk := await file.read(chunk_size):
        file_size += len(chunk)
        if file_size > 10 * 1024 * 1024:  # 10MB
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="File too large. Maximum size is 10MB"
            )
    
    # Reset file pointer
    await file.seek(0)
    return file