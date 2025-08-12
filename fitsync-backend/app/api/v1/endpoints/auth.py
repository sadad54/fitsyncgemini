from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import IntegrityError
from app.database import get_db
from app.models.user import User, UserProfile
from app.schemas.auth import UserRegister, UserLogin, UserResponse, TokenResponse
from app.core.security import SecurityManager, get_current_user
from app.core.exceptions import DuplicateResourceError, AuthenticationError, handle_fitsync_exception
from app.core.logging import user_logger
import re

router = APIRouter()

@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register_user(user_data: UserRegister, db: AsyncSession = Depends(get_db)):
    """Register a new user with proper validation and error handling"""
    
    # Check if user already exists
    result = await db.execute(select(User).where(User.email == user_data.email))
    existing_email = result.scalar_one_or_none()
    if existing_email:
        raise DuplicateResourceError("User", "email", user_data.email)
    
    result = await db.execute(select(User).where(User.username == user_data.username))
    existing_username = result.scalar_one_or_none()
    if existing_username:
        raise DuplicateResourceError("User", "username", user_data.username)
    
    try:
        # Hash password
        hashed_password = SecurityManager.get_password_hash(user_data.password)
        
        # Create user
        db_user = User(
            email=user_data.email,
            username=user_data.username,
            hashed_password=hashed_password,
            is_active=True,
            is_verified=False
        )
        
        db.add(db_user)
        await db.flush()  # Get the user ID without committing
        
        # Create user profile
        db_profile = UserProfile(
            user_id=db_user.id,
            first_name=user_data.first_name,
            last_name=user_data.last_name
        )
        
        db.add(db_profile)
        await db.commit()
        await db.refresh(db_user)
        
        user_logger.info(f"New user registered: {user_data.email}")
        return UserResponse.from_orm(db_user)
        
    except IntegrityError as e:
        await db.rollback()
        user_logger.error(f"Database integrity error during registration: {e}")
        
        # Parse the specific constraint violation
        error_msg = str(e.orig).lower()
        if "email" in error_msg:
            raise DuplicateResourceError("User", "email", user_data.email)
        elif "username" in error_msg:
            raise DuplicateResourceError("User", "username", user_data.username)
        else:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail={
                    "error": {
                        "code": "DUPLICATE_RESOURCE",
                        "message": "User with provided information already exists"
                    }
                }
            )
    except Exception as e:
        await db.rollback()
        user_logger.error(f"Unexpected error during registration: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "error": {
                    "code": "INTERNAL_SERVER_ERROR",
                    "message": "Registration failed due to server error"
                }
            }
        )

@router.post("/login", response_model=TokenResponse)
async def login_user(login_data: UserLogin, db: AsyncSession = Depends(get_db)):
    """Authenticate user and return tokens"""
    
    # Find user by email
    result = await db.execute(select(User).where(User.email == login_data.email))
    user = result.scalar_one_or_none()
    
    if not user:
        user_logger.warning(f"Login attempt with non-existent email: {login_data.email}")
        raise AuthenticationError("Invalid email or password")
    
    # Verify password
    if not SecurityManager.verify_password(login_data.password, user.hashed_password):
        user_logger.warning(f"Failed login attempt for user: {user.email}")
        raise AuthenticationError("Invalid email or password")
    
    if not user.is_active:
        user_logger.warning(f"Login attempt by inactive user: {user.email}")
        raise AuthenticationError("Account is deactivated")
    
    try:
        # Create tokens
        access_token = SecurityManager.create_access_token({"sub": str(user.id)})
        refresh_token = SecurityManager.create_refresh_token({"sub": str(user.id)})
        
        # Update last login
        from datetime import datetime
        user.last_login = datetime.utcnow()
        await db.commit()
        
        user_logger.info(f"Successful login: {user.email}")
        
        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            user=UserResponse.from_orm(user)
        )
        
    except Exception as e:
        user_logger.error(f"Token generation error for user {user.email}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "error": {
                    "code": "TOKEN_GENERATION_ERROR",
                    "message": "Failed to generate authentication tokens"
                }
            }
        )

@router.get("/me", response_model=UserResponse)
async def get_current_user_info(current_user: User = Depends(get_current_user)):
    """Get current user information"""
    return UserResponse.from_orm(current_user)

@router.post("/logout")
async def logout_user(current_user: User = Depends(get_current_user)):
    """Logout user (client should discard tokens)"""
    user_logger.info(f"User logged out: {current_user.email}")
    return {"message": "Successfully logged out"}