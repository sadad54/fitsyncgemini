from pydantic_settings import BaseSettings
from typing import Optional, List

class Settings(BaseSettings):
    # API Settings
    API_V1_STR: str = "/api/v1"
    SECRET_KEY: str
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 8
    
    # Supabase Settings
    SUPABASE_URL: str
    SUPABASE_SERVICE_ROLE_KEY: str
    SUPABASE_ANON_KEY: str
    
    # External APIs - Phase 1 (Core)
    GOOGLE_CLOUD_VISION_API_KEY: str
    GOOGLE_CLOUD_PROJECT_ID: str
    REPLICATE_API_KEY: str  # For virtual try-on (free tier available)
    OPENWEATHER_API_KEY: str
    OPENWEATHER_BASE_URL: str = "https://api.openweathermap.org/data/2.5"
    GOOGLE_PLACES_API_KEY: str
    GOOGLE_PLACES_BASE_URL: str = "https://maps.googleapis.com/maps/api/place"
    
    # External APIs - Phase 2 (Enhancement)
    GROQ_API_KEY: str
    GROQ_BASE_URL: str = "https://api.groq.com/openai/v1"
    HUGGINGFACE_TOKEN: Optional[str] = None  # For free virtual try-on models (from .env)
    INSTAGRAM_CLIENT_ID: str
    INSTAGRAM_CLIENT_SECRET: str
    GOOGLE_LENS_API_KEY: str
    
    # External APIs - Phase 3 (Analytics)
    GOOGLE_TRENDS_API_KEY: Optional[str] = None
    TWITTER_BEARER_TOKEN: Optional[str] = None
    PINTEREST_ACCESS_TOKEN: Optional[str] = None
    
    # Redis Settings
    REDIS_URL: str = "redis://localhost:6379"
    
    # Rate Limiting
    GOOGLE_VISION_RATE_LIMIT: int = 1000  # per day
    FASHION_AI_RATE_LIMIT: int = 100      # per hour
    OPENWEATHER_RATE_LIMIT: int = 1000    # per day
    GOOGLE_PLACES_RATE_LIMIT: int = 100   # per day
    
    # Image Processing
    MAX_IMAGE_SIZE: int = 10 * 1024 * 1024  # 10MB
    ALLOWED_IMAGE_TYPES: List[str] = ["image/jpeg", "image/png", "image/webp"]
    
    # Cache Settings
    CACHE_TTL_WEATHER: int = 3600         # 1 hour
    CACHE_TTL_PLACES: int = 86400         # 24 hours
    CACHE_TTL_TRENDS: int = 3600          # 1 hour
    
    class Config:
        env_file = ".env"

settings = Settings()