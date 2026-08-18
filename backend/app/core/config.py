# app/core/config.py
import os
from pathlib import Path
from dotenv import load_dotenv
from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import List, Optional
from pydantic import Field, AliasChoices, field_validator

# Load .env file from backend root directory
env_path = Path(__file__).parent.parent.parent / ".env"
load_dotenv(env_path)

class Settings(BaseSettings):
    # Load from .env and ignore unknown variables (prevents "Extra inputs are not permitted")
    model_config = SettingsConfigDict(env_file=str(env_path), extra="ignore")

    # ---- Core app settings ----
    # Defaults here are the safe-by-default posture for an unconfigured
    # environment (e.g. a fresh container with no .env mounted yet) — local
    # dev explicitly opts into DEBUG via .env, not the other way around.
    ENV: str = os.getenv("ENV", "production")
    DEBUG: bool = os.getenv("DEBUG", "false").lower() in ("1", "true", "yes")
    API_V1_STR: str = os.getenv("API_V1_STR", "/api/v1")

    # ---- CORS / host allowlists ----
    # Comma-separated. Empty in production means "reject all browser origins"
    # rather than falling back to a wildcard.
    CORS_ALLOWED_ORIGINS: str = os.getenv("CORS_ALLOWED_ORIGINS", "")
    ALLOWED_HOSTS: str = os.getenv("ALLOWED_HOSTS", "")

    @property
    def cors_origins(self) -> List[str]:
        if self.ENV != "production":
            # Expo dev clients hit the API from an arbitrary LAN IP:port and
            # from the web preview's localhost origin — both change per
            # machine, so dev trusts any origin rather than hand-listing IPs.
            return ["*"]
        origins = [o.strip() for o in self.CORS_ALLOWED_ORIGINS.split(",") if o.strip()]
        return origins

    @property
    def trusted_hosts(self) -> List[str]:
        if self.ENV != "production":
            return ["*"]
        hosts = [h.strip() for h in self.ALLOWED_HOSTS.split(",") if h.strip()]
        return hosts or ["*"]

    # ---- Supabase ----
    SUPABASE_URL: str = os.getenv("SUPABASE_URL", "https://eixnacajmchafxkbtmnr.supabase.co")
    SUPABASE_SERVICE_ROLE_KEY: str = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")
    SUPABASE_ANON_KEY: str = os.getenv("SUPABASE_ANON_KEY", "")
    SUPABASE_DB_URL: Optional[str] = os.getenv("SUPABASE_DB_URL")

    # ---- Hugging Face ----
    # Support either HUGGINGFACE_TOKEN (preferred) or hf_api_key (legacy)
    HUGGINGFACE_TOKEN: str = os.getenv("HUGGINGFACE_TOKEN", "hf_placeholder")

    # ---- Google / Maps / Vision (map legacy names to canonical fields) ----
    GOOGLE_CLOUD_PROJECT_ID: Optional[str] = Field(
        default=None,
        validation_alias=AliasChoices("GOOGLE_CLOUD_PROJECT_ID", "google_cloud_project"),
    )
    GOOGLE_PLACES_API_KEY: str = os.getenv("GOOGLE_PLACES_API_KEY", "placeholder")
    GOOGLE_PLACES_BASE_URL: str = os.getenv("GOOGLE_PLACES_BASE_URL", "https://maps.googleapis.com/maps/api/place")
    GOOGLE_PLACES_RATE_LIMIT: int = int(os.getenv("GOOGLE_PLACES_RATE_LIMIT", "500"))
    CACHE_TTL_PLACES: int = int(os.getenv("CACHE_TTL_PLACES", "86400"))
    GOOGLE_CLOUD_VISION_API_KEY: Optional[str] = Field(
        default="placeholder",
        validation_alias=AliasChoices("GOOGLE_CLOUD_VISION_API_KEY", "google_vision_api_key"),
    )
    GOOGLE_CLOUD_CREDENTIALS_PATH: str = os.getenv("GOOGLE_CLOUD_CREDENTIALS_PATH", "secrets/service_account.json")
    GOOGLE_VISION_RATE_LIMIT: int = int(os.getenv("GOOGLE_VISION_RATE_LIMIT", "30"))
    # If you keep a numeric limit in .env (string there), Pydantic will coerce to int
    PLACES_RATE_LIMIT: Optional[int] = Field(
        default=100,
        validation_alias=AliasChoices("PLACES_RATE_LIMIT", "places_rate_limit"),
    )

    # ---- Other external APIs you mentioned ----
    OPENWEATHER_BASE_URL: str = os.getenv("OPENWEATHER_BASE_URL", "https://api.openweathermap.org/data/2.5")
    OPENWEATHER_API_KEY: Optional[str] = os.getenv("OPENWEATHER_API_KEY", "placeholder")
    OPENWEATHER_RATE_LIMIT: int = int(os.getenv("OPENWEATHER_RATE_LIMIT", "100"))
    CACHE_TTL_WEATHER: int = int(os.getenv("CACHE_TTL_WEATHER", "3600"))
    GROQ_API_KEY: str = os.getenv("GROQ_API_KEY", "placeholder")
    GROQ_BASE_URL: str = os.getenv("GROQ_BASE_URL", "https://api.groq.com/openai/v1")
    REDIS_URL: Optional[str] = os.getenv("REDIS_URL", "redis://localhost:6379/0")

settings = Settings()
