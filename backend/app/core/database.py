from supabase import create_client, Client
from app.core.config import settings
import asyncpg
from typing import Optional

class Database:
    def __init__(self):
        self.client: Optional[Client] = None
        self.pool: Optional[asyncpg.Pool] = None

    async def connect(self):
        try:
            self.client = create_client(settings.SUPABASE_URL, settings.SUPABASE_SERVICE_ROLE_KEY)
        except Exception:
            self.client = None

        try:
            if settings.SUPABASE_DB_URL:
                dsn = settings.SUPABASE_DB_URL
            else:
                host = settings.SUPABASE_URL.replace("https://", "").strip("/")
                dsn = f"postgresql://postgres:{settings.SUPABASE_SERVICE_ROLE_KEY}@db.{host}:5432/postgres"
            self.pool = await asyncpg.create_pool(dsn, min_size=1, max_size=5)
        except Exception:
            self.pool = None

    async def disconnect(self):
        if self.pool:
            await self.pool.close()

    def get_client(self) -> Client:
        if not self.client:
            raise Exception("Database not connected")
        return self.client

    async def get_pool(self) -> asyncpg.Pool:
        if not self.pool:
            raise Exception("Database not connected")
        return self.pool

db = Database()

async def init_db():
    await db.connect()

async def get_db() -> Client:
    return db.get_client()
