# app/core/logging.py
from __future__ import annotations

import logging
import sys
import uuid
from datetime import datetime
from typing import Any, Dict, Optional

import structlog
from app.config import settings

# ---------------------------
# Structlog configuration
# ---------------------------
def _get_processors():
    procs = [
        structlog.contextvars.merge_contextvars,   # merge bound contextvars
        structlog.stdlib.add_log_level,
        structlog.stdlib.add_logger_name,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
    ]
    if settings.log_format.lower() == "json":
        procs.append(structlog.processors.JSONRenderer())
    else:
        procs.append(structlog.dev.ConsoleRenderer())
    return procs

structlog.configure(
    processors=_get_processors(),
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
    wrapper_class=structlog.stdlib.BoundLogger,
    cache_logger_on_first_use=True,
)

# Standard logging -> stdout; avoid file writes in dev
logging.basicConfig(
    level=getattr(logging, settings.log_level.upper(), logging.INFO),
    handlers=[logging.StreamHandler(sys.stdout)],
)

def get_logger(name: str) -> structlog.BoundLogger:
    return structlog.get_logger(name)

class FitSyncLogger:
    def __init__(self, name: str):
        self.logger = get_logger(name)

    # convenience
    def info(self, msg: str, **kw): self.logger.info(msg, **kw)
    def warning(self, msg: str, **kw): self.logger.warning(msg, **kw)
    def error(self, msg: str, **kw): self.logger.error(msg, **kw)
    def debug(self, msg: str, **kw): self.logger.debug(msg, **kw)
    def critical(self, msg: str, **kw): self.logger.critical(msg, **kw)

    # domain helpers
    def log_api_request(self, *, method: str, path: str, status_code: int, duration: float,
                        user_id: Optional[str] = None, request_id: Optional[str] = None,
                        bytes_sent: Optional[int] = None, user_agent: Optional[str] = None):
        self.info(
            "API Request",
            method=method,
            path=path,
            status_code=status_code,
            duration_ms=round(duration * 1000, 3),
            bytes_sent=bytes_sent,
            user_agent=user_agent,
            user_id=user_id,
            request_id=request_id,
        )

    def log_error(self, *, error_type: str, error_message: str, request_id: Optional[str] = None, **kw):
        self.error(
            "Application Error",
            error_type=error_type,
            error_message=error_message,
            request_id=request_id,
            **kw,
        )

api_logger = FitSyncLogger("api")
ml_logger = FitSyncLogger("ml")
user_logger = FitSyncLogger("user")
db_logger = FitSyncLogger("database")
cache_logger = FitSyncLogger("cache")

# ---------------------------
# Sentry (optional)
# ---------------------------
if getattr(settings, "sentry_dsn", None) and settings.sentry_dsn not in (None, "", "your-sentry-dsn-here"):
    import sentry_sdk
    from sentry_sdk.integrations.fastapi import FastApiIntegration
    from sentry_sdk.integrations.sqlalchemy import SqlalchemyIntegration

    sentry_sdk.init(
        dsn=settings.sentry_dsn,
        environment=settings.environment,
        integrations=[FastApiIntegration(), SqlalchemyIntegration()],
        traces_sample_rate=0.1,
        profiles_sample_rate=0.1,
    )

# ---------------------------
# ASGI middleware with status capture
# ---------------------------
class LoggingMiddleware:
    """
    Logs each HTTP request with status, duration, bytes, user-agent, and a request_id.
    Skips very noisy endpoints like /metrics and CORS preflights by default.
    """

    def __init__(self, app, *, skip_paths: tuple[str, ...] = ("/metrics", "/health", "/health/detailed")):
        self.app = app
        self.skip_paths = set(skip_paths)

    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            return await self.app(scope, receive, send)

        method = scope.get("method")
        path = scope.get("path")
        client = scope.get("client")
        client_ip = client[0] if client else None
        req_id = str(uuid.uuid4())

        # skip extremely noisy stuff
        if path in self.skip_paths or method == "OPTIONS":
            return await self.app(scope, receive, send)

        start = datetime.utcnow()
        status_code_holder = {"status": 0}
        bytes_sent_holder = {"bytes": 0}
        user_agent = None
        # get UA from headers
        for k, v in scope.get("headers", []):
            if k.decode("latin1").lower() == "user-agent":
                user_agent = v.decode("latin1")
                break

        async def send_wrapper(message):
            if message["type"] == "http.response.start":
                status_code_holder["status"] = message.get("status", 0)
            elif message["type"] == "http.response.body":
                body = message.get("body", b"")
                if isinstance(body, (bytes, bytearray)):
                    bytes_sent_holder["bytes"] += len(body)
            await send(message)

        try:
            await self.app(scope, receive, send_wrapper)
        finally:
            duration = (datetime.utcnow() - start).total_seconds()
            api_logger.log_api_request(
                method=method or "",
                path=path or "",
                status_code=status_code_holder["status"],
                duration=duration,
                user_id=None,  # plug your auth extraction if needed
                request_id=req_id,
                bytes_sent=bytes_sent_holder["bytes"],
                user_agent=user_agent,
            )
