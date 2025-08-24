from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from contextlib import asynccontextmanager
import redis.asyncio as redis
from loguru import logger

from app.core.config import settings
from app.api.endpoints.v1 import auth, clothing, tryon
from app.api.endpoints import outfits, trends, community, weather, locations
from app.core.database import init_db
from app.core.cache import init_cache


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("Starting FitSync Backend...")
    await init_db()
    await init_cache()
    logger.info("FitSync Backend started successfully!")
    
    yield
    
    # Shutdown
    logger.info("Shutting down FitSync Backend...")


app = FastAPI(
    title="FitSync API",
    description="AI-powered fashion recommendation and virtual try-on platform",
    version="1.0.0",
    lifespan=lifespan
)

# Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure properly for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=["*"]  # Configure properly for production
)

# Include routers
app.include_router(auth.router, prefix=f"{settings.API_V1_STR}/auth", tags=["Authentication"])
app.include_router(clothing.router, prefix=f"{settings.API_V1_STR}/clothing", tags=["Clothing"])
app.include_router(outfits.router, prefix=f"{settings.API_V1_STR}/outfits", tags=["Outfits"])
app.include_router(tryon.router, prefix=f"{settings.API_V1_STR}/tryon", tags=["Virtual Try-On"])
app.include_router(trends.router, prefix=f"{settings.API_V1_STR}/trends", tags=["Trends"])
app.include_router(community.router, prefix=f"{settings.API_V1_STR}/community", tags=["Community"])
app.include_router(weather.router, prefix=f"{settings.API_V1_STR}/weather", tags=["Weather"])
app.include_router(locations.router, prefix=f"{settings.API_V1_STR}/locations", tags=["Locations"])


@app.get("/")
async def root():
    return {"message": "Welcome to FitSync API", "version": "1.0.0"}


@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "fitsync-backend"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
