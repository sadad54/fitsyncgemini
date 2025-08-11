from pydantic_settings import BaseSettings
from pydantic import Field
from typing import Optional, List
import os

class Settings(BaseSettings):
    # App Configuration
    app_name: str = "FitSync API"
    version: str = "1.0.0"
    debug: bool = Field(default=False, description="Enable debug mode")
    environment: str = Field(default="development", description="Environment: development, staging, production")
    
    # Server Configuration
    host: str = Field(default="0.0.0.0", description="Server host")
    port: int = Field(default=8000, description="Server port")
    workers: int = Field(default=1, description="Number of worker processes")
    
    # Database Configuration
    database_url: str = Field(..., description="PostgreSQL database URL")
    redis_url: str = Field(default="redis://localhost:6379", description="Redis URL for caching")
    
    # Security Configuration
    secret_key: str = Field(..., description="Secret key for JWT tokens")
    access_token_expire_minutes: int = Field(default=30, description="JWT token expiration time")
    refresh_token_expire_days: int = Field(default=7, description="Refresh token expiration time")
    algorithm: str = Field(default="HS256", description="JWT algorithm")
    
    # ML Model Configuration
    model_cache_dir: str = Field(default="./models", description="Directory for ML model cache")
    enable_gpu: bool = Field(default=False, description="Enable GPU acceleration")
    gpu_device: str = Field(default="cuda:0", description="GPU device to use")
    
    # Model Paths
    clothing_detection_model: str = Field(default="yolov8n.pt", description="Clothing detection model path")
    pose_estimation_model: str = Field(default="pose_estimation.pt", description="Pose estimation model path")
    style_classification_model: str = Field(default="style_classifier.pt", description="Style classification model path")
    virtual_tryon_model: str = Field(default="tryon_model.pt", description="Virtual try-on model path")
    
    # Cloud Storage Configuration
    aws_access_key_id: Optional[str] = Field(default=None, description="AWS access key ID")
    aws_secret_access_key: Optional[str] = Field(default=None, description="AWS secret access key")
    aws_region: str = Field(default="us-east-1", description="AWS region")
    s3_bucket_name: str = Field(default="fitsync-storage", description="S3 bucket for file storage")
    
    # Vector Database Configuration
    chroma_persist_directory: str = Field(default="./chroma_db", description="ChromaDB persistence directory")
    faiss_index_path: str = Field(default="./faiss_index", description="FAISS index path")
    
    # API Configuration
    cors_origins: List[str] = Field(default=["*"], description="Allowed CORS origins")
    rate_limit_per_minute: int = Field(default=60, description="Rate limit per minute per user")
    
    # Monitoring Configuration
    sentry_dsn: Optional[str] = Field(default=None, description="Sentry DSN for error tracking")
    prometheus_enabled: bool = Field(default=True, description="Enable Prometheus metrics")
    
    # External APIs
    weather_api_key: Optional[str] = Field(default=None, description="Weather API key")
    openai_api_key: Optional[str] = Field(default=None, description="OpenAI API key for advanced features")
    
    # File Upload Configuration
    max_file_size: int = Field(default=10 * 1024 * 1024, description="Maximum file size in bytes (10MB)")
    allowed_image_types: List[str] = Field(default=["image/jpeg", "image/png", "image/webp"], description="Allowed image types")
    upload_directory: str = Field(default="./uploads", description="Directory for file uploads")
    
    # Cache Configuration
    cache_ttl: int = Field(default=3600, description="Cache TTL in seconds")
    recommendation_cache_ttl: int = Field(default=1800, description="Recommendation cache TTL")
    
    # Social Features
    enable_location_services: bool = Field(default=True, description="Enable location-based features")
    max_nearby_distance: float = Field(default=50.0, description="Maximum distance for nearby users (km)")
    
    # Performance Configuration
    batch_size: int = Field(default=32, description="Batch size for ML processing")
    max_concurrent_requests: int = Field(default=10, description="Maximum concurrent ML requests")
    
    # Logging Configuration
    log_level: str = Field(default="INFO", description="Logging level")
    log_format: str = Field(default="json", description="Log format: json or text")
    
    model_config = {
        "env_file": ".env",
        "env_file_encoding": "utf-8",
        "case_sensitive": False,
        "extra": "ignore",
        "protected_namespaces": ("settings_",)
    }

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        # Create necessary directories
        os.makedirs(self.model_cache_dir, exist_ok=True)
        os.makedirs(self.upload_directory, exist_ok=True)
        os.makedirs(self.chroma_persist_directory, exist_ok=True)
        os.makedirs(os.path.dirname(self.faiss_index_path), exist_ok=True)

settings = Settings()