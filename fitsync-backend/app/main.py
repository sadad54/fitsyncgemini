from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.responses import JSONResponse
import structlog
import time
from contextlib import asynccontextmanager

from app.config import settings
from app.api.v1.api_router import router as api_router
from app.core.exceptions import FitSyncException
from app.core.logging import setup_logging
from app.database import create_tables
from app.services.ml_service import MLService

# Setup structured logging
setup_logging()
logger = structlog.get_logger()

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan management"""
    logger.info("Starting FitSync AI Backend...")
    
    # Initialize database
    await create_tables()
    
    # Initialize ML models
    ml_service = MLService()
    await ml_service.initialize_models()
    app.state.ml_service = ml_service
    
    logger.info("FitSync AI Backend started successfully")
    yield
    
    logger.info("Shutting down FitSync AI Backend...")

app = FastAPI(
    title="FitSync AI Backend",
    description="Advanced AI-powered fashion recommendation system",
    version="2.0.0",
    lifespan=lifespan,
    docs_url="/api/docs",
    redoc_url="/api/redoc"
)

# Security middleware
if settings.ENVIRONMENT == "production":
    app.add_middleware(
        TrustedHostMiddleware, 
        allowed_hosts=settings.ALLOWED_HOSTS
    )

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Request timing middleware
@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    response.headers["X-Process-Time"] = str(process_time)
    
    # Log request details
    logger.info(
        "Request processed",
        method=request.method,
        url=str(request.url),
        process_time=process_time,
        status_code=response.status_code
    )
    return response

# Exception handler
@app.exception_handler(FitSyncException)
async def fitsync_exception_handler(request: Request, exc: FitSyncException):
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.detail, "error_code": exc.error_code}
    )

# Include API routes
app.include_router(api_router, prefix="/api/v1")

@app.get("/")
async def root():
    return {
        "message": "FitSync AI Backend v2.0",
        "status": "running",
        "features": [
            "Advanced clothing detection",
            "AI-powered outfit recommendations", 
            "Virtual try-on technology",
            "Style compatibility analysis",
            "Social fashion features"
        ]
    }

@app.get("/health")
async def health_check():
    """Health check endpoint for monitoring"""
    return {
        "status": "healthy",
        "timestamp": time.time(),
        "version": "2.0.0"
    }

