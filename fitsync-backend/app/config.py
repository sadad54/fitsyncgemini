from pydantic_settings import BaseSettings
from typing import List, Optional

class Settings(BaseSettings):
    # App settings
    APP_NAME: str = "FitSync AI Backend"
    ENVIRONMENT: str = "development"
    DEBUG: bool = True
    VERSION: str = "2.0.0"
    
    # API settings
    API_PREFIX: str = "/api/v1"
    ALLOWED_HOSTS: List[str] = ["*"]
    CORS_ORIGINS: List[str] = ["*"]
    
    # Database
    DATABASE_URL: str = "postgresql://user:password@localhost:5432/fitsync"
    
    # Redis
    REDIS_URL: str = "redis://localhost:6379"
    
    # ML Model settings
    MODEL_CACHE_DIR: str = "./models"
    YOLO_MODEL_PATH: str = "yolov8n.pt"
    ENABLE_GPU: bool = True
    
    # AWS S3 (for image storage)
    AWS_ACCESS_KEY_ID: Optional[str] = None
    AWS_SECRET_ACCESS_KEY: Optional[str] = None
    AWS_BUCKET_NAME: Optional[str] = None
    AWS_REGION: str = "us-east-1"
    
    # External APIs
    WEATHER_API_KEY: Optional[str] = None
    FASHION_TRENDS_API_KEY: Optional[str] = None
    
    # Security
    SECRET_KEY: str = "your-secret-key-here"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # Rate limiting
    RATE_LIMIT_REQUESTS: int = 100
    RATE_LIMIT_PERIOD: int = 60  # seconds
    
    class Config:
        env_file = ".env"

settings = Settings()
