# app/main.py
from __future__ import annotations

import time
from pathlib import Path
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.responses import JSONResponse, Response
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST

from app.api.v1.api_router import api_router
from app.config import settings
from app.core.logging import api_logger, LoggingMiddleware  # optional
from app.core.exceptions import FitSyncException, handle_fitsync_exception
from app.database import init_db, check_db_connection
from app.core.security import rate_limiter
from app.services.ml_model_manager import ml_model_manager

# -----------------------------------------------------------------------------
# Prometheus metrics
# -----------------------------------------------------------------------------
REQUEST_COUNT = Counter(
    "http_requests_total", "Total HTTP requests", ["method", "endpoint", "status"]
)
REQUEST_LATENCY = Histogram("http_request_duration_seconds", "HTTP request latency")

# -----------------------------------------------------------------------------
# Utilities
# -----------------------------------------------------------------------------
def _ensure_local_dirs() -> None:
    """Create local working directories defined in .env."""
    dirs = {
        Path(getattr(settings, "upload_directory", "./uploads")),
        Path(getattr(settings, "model_cache_dir", "./models")),
        Path(getattr(settings, "chroma_persist_directory", "./chroma_db")),
        Path("./logs"),
    }
    for d in dirs:
        try:
            d.mkdir(parents=True, exist_ok=True)
        except Exception as e:
            api_logger.warning(f"Could not create dir {d}: {e}")

# -----------------------------------------------------------------------------
# Lifespan: startup/shutdown
# -----------------------------------------------------------------------------
@asynccontextmanager
async def lifespan(app: FastAPI):
    api_logger.info("Starting FitSync API server...")

    _ensure_local_dirs()

    # Initialize database
    try:
        await init_db()
        api_logger.info("Database initialized successfully")
    except Exception as e:
        api_logger.error(f"Database initialization failed: {e}")
        raise

    # Check database connectivity
    ok = await check_db_connection()
    if not ok:
        api_logger.error("Database connection check failed")
        raise RuntimeError("Database connection failed")

    # Initialize ML models (don’t hard-fail in dev)
    try:
        await ml_model_manager.initialize()
        api_logger.info("ML models initialized successfully")
    except Exception as e:
        api_logger.error(f"ML model initialization failed: {e}")
        if getattr(settings, "environment", "development") == "production":
            raise

    api_logger.info("FitSync API server started successfully")
    yield

    # Shutdown
    api_logger.info("Shutting down FitSync API server...")
    try:
        await ml_model_manager.cleanup()
    except Exception as e:
        api_logger.warning(f"ML model cleanup error: {e}")

# -----------------------------------------------------------------------------
# Create FastAPI app
# -----------------------------------------------------------------------------
app = FastAPI(
    title=getattr(settings, "app_name", "FitSync API"),
    version=getattr(settings, "version", "1.0.0"),
    description=(
        "AI-Powered Fashion Assistant API with ML-driven recommendations, "
        "virtual try-on, and social features"
    ),
    docs_url="/docs" if getattr(settings, "debug", True) else None,
    redoc_url="/redoc" if getattr(settings, "debug", True) else None,
    openapi_url="/openapi.json" if getattr(settings, "debug", True) else None,
    lifespan=lifespan,
)

# -----------------------------------------------------------------------------
# CORS (single block) — allow any localhost / 127.0.0.1 port (no cookies)
# -----------------------------------------------------------------------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=[],  # using regex instead
    allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_methods=["*"],
    allow_headers=["*"],
    allow_credentials=False,  # must be False with wildcard/regex origins
)

# If you ever need cookies, switch to explicit origins and set allow_credentials=True:
# DEV_ORIGINS = ["http://localhost:50952", "http://127.0.0.1:50952"]
# app.add_middleware(
#     CORSMiddleware,
#     allow_origins=DEV_ORIGINS,
#     allow_methods=["*"],
#     allow_headers=["*"],
#     allow_credentials=True,
# )

# -----------------------------------------------------------------------------
# Optional structured logging middleware (enable if you want)
# -----------------------------------------------------------------------------
# app.add_middleware(LoggingMiddleware)

# -----------------------------------------------------------------------------
# Other middleware
# -----------------------------------------------------------------------------
@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    response.headers["X-Process-Time"] = f"{process_time:.6f}"
    return response

@app.middleware("http")
async def rate_limit_middleware(request: Request, call_next):
    user_id = "anonymous"  # TODO: extract from JWT when auth is wired up
    limit = int(getattr(settings, "rate_limit_per_minute", 60))
    if hasattr(rate_limiter, "is_allowed") and not rate_limiter.is_allowed(user_id, limit):
        return JSONResponse(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            content={
                "error": {
                    "code": "RATE_LIMIT_EXCEEDED",
                    "message": f"Rate limit exceeded: {limit} requests per minute",
                }
            },
        )
    return await call_next(request)

@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    duration = time.time() - start_time

    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.url.path,
        status=response.status_code,
    ).inc()
    REQUEST_LATENCY.observe(duration)

    if hasattr(api_logger, "log_api_request"):
        api_logger.log_api_request(
            method=request.method,
            path=request.url.path,
            status_code=response.status_code,
            duration=duration,
        )
    return response

app.add_middleware(GZipMiddleware, minimum_size=1000)

# -----------------------------------------------------------------------------
# Exception handlers
# -----------------------------------------------------------------------------
@app.exception_handler(FitSyncException)
async def fitsync_exception_handler(request: Request, exc: FitSyncException):
    if hasattr(api_logger, "log_error"):
        api_logger.log_error(
            error_type=exc.error_code,
            error_message=exc.message,
            details=exc.details,
        )
    return JSONResponse(
        status_code=exc.status_code,
        content=handle_fitsync_exception(exc),
    )

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    if hasattr(api_logger, "log_error"):
        api_logger.log_error(
            error_type="VALIDATION_ERROR",
            error_message="Request validation failed",
            details={"errors": exc.errors()},
        )
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "error": {
                "code": "VALIDATION_ERROR",
                "message": "Request validation failed",
                "details": exc.errors(),
            }
        },
    )

@app.exception_handler(StarletteHTTPException)
async def http_exception_handler(request: Request, exc: StarletteHTTPException):
    if hasattr(api_logger, "log_error"):
        api_logger.log_error(
            error_type="HTTP_ERROR",
            error_message=exc.detail,
            details={"status_code": exc.status_code},
        )
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": {
                "code": "HTTP_ERROR",
                "message": exc.detail,
                "status_code": exc.status_code,
            }
        },
    )

@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    if hasattr(api_logger, "log_error"):
        api_logger.log_error(
            error_type="INTERNAL_SERVER_ERROR",
            error_message=str(exc),
        )
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "error": {
                "code": "INTERNAL_SERVER_ERROR",
                "message": "An internal server error occurred",
            }
        },
    )

# -----------------------------------------------------------------------------
# Health & Metrics
# -----------------------------------------------------------------------------
@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "timestamp": time.time(),
        "version": getattr(settings, "version", "1.0.0"),
        "environment": getattr(settings, "environment", "development"),
    }

@app.get("/health/detailed")
async def detailed_health_check():
    health_status = {
        "status": "healthy",
        "timestamp": time.time(),
        "version": getattr(settings, "version", "1.0.0"),
        "environment": getattr(settings, "environment", "development"),
        "services": {},
    }

    try:
        db_healthy = await check_db_connection()
        health_status["services"]["database"] = {
            "status": "healthy" if db_healthy else "unhealthy",
        }
    except Exception as e:
        health_status["services"]["database"] = {
            "status": "unhealthy",
            "error": str(e),
        }

    try:
        ml_status = await ml_model_manager.get_model_status()
        health_status["services"]["ml_models"] = ml_status
    except Exception as e:
        health_status["services"]["ml_models"] = {
            "status": "unhealthy",
            "error": str(e),
        }

    health_status["services"]["cache"] = {"status": "healthy"}

    all_healthy = all(
        svc.get("status") == "healthy" for svc in health_status["services"].values()
    )
    health_status["status"] = "healthy" if all_healthy else "degraded"
    return health_status

@app.get("/metrics")
async def metrics():
    return Response(content=generate_latest(), media_type=CONTENT_TYPE_LATEST)

# -----------------------------------------------------------------------------
# Root & Routers
# -----------------------------------------------------------------------------
@app.get("/")
async def root():
    return {
        "message": "FitSync API is running!",
        "version": getattr(settings, "version", "1.0.0"),
        "environment": getattr(settings, "environment", "development"),
        "docs": "/docs" if getattr(settings, "debug", True) else None,
        "health": "/health",
        "metrics": "/metrics",
    }

app.include_router(api_router, prefix="/api/v1")

# -----------------------------------------------------------------------------
# Dev runner
# -----------------------------------------------------------------------------
if __name__ == "__main__":
    import uvicorn

    host = getattr(settings, "host", "0.0.0.0")
    port = int(getattr(settings, "port", 8000))
    debug = bool(getattr(settings, "debug", True))
    workers = int(getattr(settings, "workers", 1))
    log_level = getattr(settings, "log_level", "info")

    uvicorn.run(
        "app.main:app",
        host=host,
        port=port,
        reload=debug,
        workers=workers if not debug else 1,
        log_level=log_level,
    )
