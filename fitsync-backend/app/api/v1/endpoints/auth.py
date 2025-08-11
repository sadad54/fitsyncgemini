"""
Authentication endpoints for user registration, login, and token management
"""

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from typing import Any
import logging

from app.core.security import SecurityManager, get_current_user
from app.database import get_db
from app.schemas.user import (
    UserCreate, UserResponse, UserLogin, Token, RefreshToken,
    PasswordReset, PasswordResetConfirm, EmailVerification
)
from app.models.user import User
from app.core.exceptions import AuthenticationError, ValidationError

logger = logging.getLogger(__name__)

router = APIRouter()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register_user(user_data: UserCreate, db: Session = Depends(get_db)) -> Any:
    """
    Register a new user
    """
    try:
        # Check if user already exists
        existing_user = db.query(User).filter(User.email == user_data.email).first()
        if existing_user:
            raise ValidationError("User with this email already exists")
        
        # Create new user
        hashed_password = SecurityManager.hash_password(user_data.password)
        user = User(
            email=user_data.email,
            username=user_data.username,
            hashed_password=hashed_password,
            first_name=user_data.first_name,
            last_name=user_data.last_name,
            is_active=True,
            is_verified=False
        )
        
        db.add(user)
        db.commit()
        db.refresh(user)
        
        logger.info(f"New user registered: {user.email}")
        
        return UserResponse(
            id=user.id,
            email=user.email,
            username=user.username,
            first_name=user.first_name,
            last_name=user.last_name,
            is_active=user.is_active,
            is_verified=user.is_verified,
            created_at=user.created_at
        )
        
    except Exception as e:
        db.rollback()
        logger.error(f"Error registering user: {e}")
        raise

@router.post("/login", response_model=Token)
async def login_user(user_credentials: UserLogin, db: Session = Depends(get_db)) -> Any:
    """
    Login user and return access token
    """
    try:
        # Find user by email
        user = db.query(User).filter(User.email == user_credentials.email).first()
        if not user:
            raise AuthenticationError("Invalid email or password")
        
        # Verify password
        if not SecurityManager.verify_password(user_credentials.password, user.hashed_password):
            raise AuthenticationError("Invalid email or password")
        
        # Check if user is active
        if not user.is_active:
            raise AuthenticationError("User account is deactivated")
        
        # Generate access token
        access_token = SecurityManager.create_access_token(
            data={"sub": str(user.id), "email": user.email}
        )
        
        # Generate refresh token
        refresh_token = SecurityManager.create_refresh_token(
            data={"sub": str(user.id)}
        )
        
        logger.info(f"User logged in: {user.email}")
        
        return Token(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer",
            expires_in=3600  # 1 hour
        )
        
    except Exception as e:
        logger.error(f"Error during login: {e}")
        raise

@router.post("/refresh", response_model=Token)
async def refresh_token(refresh_data: RefreshToken, db: Session = Depends(get_db)) -> Any:
    """
    Refresh access token using refresh token
    """
    try:
        # Verify refresh token
        payload = SecurityManager.verify_refresh_token(refresh_data.refresh_token)
        user_id = payload.get("sub")
        
        if not user_id:
            raise AuthenticationError("Invalid refresh token")
        
        # Get user
        user = db.query(User).filter(User.id == int(user_id)).first()
        if not user or not user.is_active:
            raise AuthenticationError("User not found or inactive")
        
        # Generate new access token
        access_token = SecurityManager.create_access_token(
            data={"sub": str(user.id), "email": user.email}
        )
        
        # Generate new refresh token
        new_refresh_token = SecurityManager.create_refresh_token(
            data={"sub": str(user.id)}
        )
        
        logger.info(f"Token refreshed for user: {user.email}")
        
        return Token(
            access_token=access_token,
            refresh_token=new_refresh_token,
            token_type="bearer",
            expires_in=3600
        )
        
    except Exception as e:
        logger.error(f"Error refreshing token: {e}")
        raise

@router.post("/logout")
async def logout_user(db: Session = Depends(get_db), 
                     current_user: User = Depends(get_current_user)) -> Any:
    """
    Logout user (invalidate tokens)
    """
    try:
        # In a real implementation, you would add the token to a blacklist
        # For now, we'll just return a success message
        logger.info(f"User logged out: {current_user.email}")
        
        return {"message": "Successfully logged out"}
        
    except Exception as e:
        logger.error(f"Error during logout: {e}")
        raise

@router.post("/forgot-password")
async def forgot_password(password_reset: PasswordReset, db: Session = Depends(get_db)) -> Any:
    """
    Send password reset email
    """
    try:
        # Find user by email
        user = db.query(User).filter(User.email == password_reset.email).first()
        if not user:
            # Don't reveal if user exists or not
            return {"message": "If the email exists, a password reset link has been sent"}
        
        # Generate password reset token
        reset_token = SecurityManager.create_password_reset_token(
            data={"sub": str(user.id), "email": user.email}
        )
        
        # In a real implementation, send email with reset link
        # For now, we'll just log it
        logger.info(f"Password reset requested for: {user.email}, token: {reset_token}")
        
        return {"message": "If the email exists, a password reset link has been sent"}
        
    except Exception as e:
        logger.error(f"Error in forgot password: {e}")
        raise

@router.post("/reset-password")
async def reset_password(reset_data: PasswordResetConfirm, db: Session = Depends(get_db)) -> Any:
    """
    Reset password using reset token
    """
    try:
        # Verify reset token
        payload = SecurityManager.verify_password_reset_token(reset_data.token)
        user_id = payload.get("sub")
        
        if not user_id:
            raise AuthenticationError("Invalid or expired reset token")
        
        # Get user
        user = db.query(User).filter(User.id == int(user_id)).first()
        if not user:
            raise AuthenticationError("User not found")
        
        # Hash new password
        hashed_password = SecurityManager.hash_password(reset_data.new_password)
        user.hashed_password = hashed_password
        
        db.commit()
        
        logger.info(f"Password reset for user: {user.email}")
        
        return {"message": "Password successfully reset"}
        
    except Exception as e:
        db.rollback()
        logger.error(f"Error resetting password: {e}")
        raise

@router.post("/verify-email")
async def verify_email(verification_data: EmailVerification, db: Session = Depends(get_db)) -> Any:
    """
    Verify user email address
    """
    try:
        # Verify verification token
        payload = SecurityManager.verify_email_verification_token(verification_data.token)
        user_id = payload.get("sub")
        
        if not user_id:
            raise AuthenticationError("Invalid or expired verification token")
        
        # Get user
        user = db.query(User).filter(User.id == int(user_id)).first()
        if not user:
            raise AuthenticationError("User not found")
        
        # Mark user as verified
        user.is_verified = True
        db.commit()
        
        logger.info(f"Email verified for user: {user.email}")
        
        return {"message": "Email successfully verified"}
        
    except Exception as e:
        db.rollback()
        logger.error(f"Error verifying email: {e}")
        raise

@router.post("/resend-verification")
async def resend_verification_email(db: Session = Depends(get_db),
                                  current_user: User = Depends(get_current_user)) -> Any:
    """
    Resend email verification
    """
    try:
        if current_user.is_verified:
            raise ValidationError("Email is already verified")
        
        # Generate verification token
        verification_token = SecurityManager.create_email_verification_token(
            data={"sub": str(current_user.id), "email": current_user.email}
        )
        
        # In a real implementation, send email with verification link
        logger.info(f"Verification email resent for: {current_user.email}, token: {verification_token}")
        
        return {"message": "Verification email sent"}
        
    except Exception as e:
        logger.error(f"Error resending verification email: {e}")
        raise

@router.get("/me", response_model=UserResponse)
async def get_current_user_info(current_user: User = Depends(get_current_user)) -> Any:
    """
    Get current user information
    """
    try:
        return UserResponse(
            id=current_user.id,
            email=current_user.email,
            username=current_user.username,
            first_name=current_user.first_name,
            last_name=current_user.last_name,
            is_active=current_user.is_active,
            is_verified=current_user.is_verified,
            created_at=current_user.created_at
        )
        
    except Exception as e:
        logger.error(f"Error getting current user info: {e}")
        raise
