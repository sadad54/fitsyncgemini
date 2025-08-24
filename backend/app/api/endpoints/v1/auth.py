from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from app.core.security import create_access_token, verify_password, get_password_hash
from app.core.database import get_db
from app.models.user import UserCreate, User, UserUpdate
from app.api.dependencies import get_current_user
from datetime import timedelta
from app.core.config import settings

router = APIRouter()

@router.post("/register", response_model=User)
async def register(user_data: UserCreate, db = Depends(get_db)):
    # Check if user already exists
    existing_user = db.table("users").select("*").eq("email", user_data.email).execute()
    if existing_user.data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # Hash password
    hashed_password = get_password_hash(user_data.password)
    
    # Create user
    user_dict = user_data.dict()
    user_dict["password_hash"] = hashed_password
    del user_dict["password"]
    
    result = db.table("users").insert(user_dict).execute()
    return User(**result.data[0])

@router.post("/login")
async def login(form_data: OAuth2PasswordRequestForm = Depends(), db = Depends(get_db)):
    # Find user
    user_data = db.table("users").select("*").eq("email", form_data.username).execute()
    if not user_data.data:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )
    
    user = user_data.data[0]
    
    # Verify password
    if not verify_password(form_data.password, user["password_hash"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )
    
    # Create access token
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user["id"]}, expires_delta=access_token_expires
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": User(**user)
    }

@router.get("/me", response_model=User)
async def get_current_user_info(current_user: User = Depends(get_current_user)):
    return current_user

@router.put("/me", response_model=User)
async def update_user_info(
    user_update: UserUpdate,
    current_user: User = Depends(get_current_user),
    db = Depends(get_db)
):
    update_data = user_update.dict(exclude_unset=True)
    result = db.table("users").update(update_data).eq("id", current_user.id).execute()
    return User(**result.data[0])
