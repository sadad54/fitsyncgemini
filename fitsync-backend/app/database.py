# app/database.py
from __future__ import annotations

import logging
from typing import AsyncGenerator, Generator, Optional

from sqlalchemy import event, text
from sqlalchemy.pool import QueuePool
from sqlalchemy.orm import declarative_base

# Try to be resilient to different settings attribute names
from app.config import settings

# SQLAlchemy 2.0 imports (async + sync)
from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy import create_engine  # sync engine
from sqlalchemy.orm import sessionmaker  # sync session

logger = logging.getLogger(__name__)

# -----------------------------------------------------------------------------
# Helpers to read config, regardless of naming (DATABASE_URL vs database_url)
# -----------------------------------------------------------------------------
def _get_db_url() -> str:
    url = getattr(settings, "DATABASE_URL", None) or getattr(settings, "database_url", None)
    if not url:
        raise RuntimeError("DATABASE_URL / database_url not found in settings.")
    return url

def _get_debug() -> bool:
    if hasattr(settings, "DEBUG"):
        return bool(getattr(settings, "DEBUG"))
    if hasattr(settings, "debug"):
        return bool(getattr(settings, "debug"))
    return False

DB_URL: str = _get_db_url()
DEBUG: bool = _get_debug()

IS_ASYNC: bool = ("+aiosqlite" in DB_URL) or ("+asyncpg" in DB_URL)
IS_SQLITE: bool = DB_URL.startswith("sqlite")

# -----------------------------------------------------------------------------
# Declarative base
# -----------------------------------------------------------------------------
Base = declarative_base()
metadata = Base.metadata  # for migrations if needed

# -----------------------------------------------------------------------------
# Engines & Session factories (async OR sync, selected by URL)
# -----------------------------------------------------------------------------
engine: Optional[AsyncEngine] | Optional[object] = None  # type: ignore

if IS_ASYNC:
    # Async engine (sqlite+aiosqlite / postgresql+asyncpg)
    engine = create_async_engine(
        DB_URL,
        echo=DEBUG,
        pool_pre_ping=True,
        pool_recycle=3600,
        future=True,
    )
    AsyncSessionLocal = async_sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)

    async def get_db() -> AsyncGenerator[AsyncSession, None]:
        """FastAPI dependency for async DB session."""
        async with AsyncSessionLocal() as session:
            try:
                yield session
            except Exception as e:
                logger.error(f"Async DB session error: {e}")
                await session.rollback()
                raise

else:
    # Sync engine (sqlite:/// / postgresql+psycopg2://)
    engine = create_engine(
        DB_URL,
        poolclass=QueuePool,
        pool_size=20,
        max_overflow=30,
        pool_pre_ping=True,
        pool_recycle=3600,
        echo=DEBUG,
        future=True,
    )
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

    def get_db() -> Generator:
        """FastAPI dependency for sync DB session."""
        db = SessionLocal()
        try:
            yield db
        except Exception as e:
            logger.error(f"DB session error: {e}")
            db.rollback()
            raise
        finally:
            db.close()

# -----------------------------------------------------------------------------
# SQLite PRAGMAs (performance) — works for both async & sync engines
# -----------------------------------------------------------------------------
def _attach_sqlite_pragmas(target_engine):
    # For async engines, attach to the underlying sync_engine
    target = getattr(target_engine, "sync_engine", target_engine)

    @event.listens_for(target, "connect")
    def _set_sqlite_pragmas(dbapi_connection, connection_record):
        # Only if using SQLite (any driver)
        if DB_URL.startswith("sqlite"):
            cursor = dbapi_connection.cursor()
            try:
                cursor.execute("PRAGMA journal_mode=WAL")
                cursor.execute("PRAGMA synchronous=NORMAL")
                cursor.execute("PRAGMA cache_size=10000")
                cursor.execute("PRAGMA temp_store=MEMORY")
            finally:
                cursor.close()

    @event.listens_for(target, "checkout")
    def _receive_checkout(dbapi_connection, connection_record, connection_proxy):
        if DEBUG:
            logger.debug("Database connection checked out")

    @event.listens_for(target, "checkin")
    def _receive_checkin(dbapi_connection, connection_record):
        if DEBUG:
            logger.debug("Database connection checked in")

_attach_sqlite_pragmas(engine)

# -----------------------------------------------------------------------------
# Initialization & Health checks (async vs sync)
# -----------------------------------------------------------------------------
async def init_db() -> None:
    """
    Create tables at startup.
    Call this with `await init_db()` if using async engine; if you're using
    a sync engine, you can still `await init_db()` safely (it runs sync via run_sync).
    """
    try:
        # Import your models so they are registered on Base.metadata
        # Adjust these imports to your real model module paths
        from app.models import user, clothing, social, analytics  # noqa: F401

        if IS_ASYNC:
            assert isinstance(engine, AsyncEngine)
            async with engine.begin() as conn:
                await conn.run_sync(Base.metadata.create_all)
        else:
            # sync engine path
            Base.metadata.create_all(bind=engine)  # type: ignore[arg-type]
        logger.info("Database tables created successfully")
    except Exception as e:
        logger.error(f"Database initialization error: {e}")
        raise

async def check_db_connection() -> bool:
    """Return True if DB is reachable."""
    try:
        if IS_ASYNC:
            assert isinstance(engine, AsyncEngine)
            async with engine.connect() as conn:
                await conn.execute(text("SELECT 1"))
        else:
            # sync engine path
            with engine.connect() as conn:  # type: ignore[union-attr]
                conn.execute(text("SELECT 1"))
        return True
    except Exception as e:
        logger.error(f"Database connection check failed: {e}")
        return False
