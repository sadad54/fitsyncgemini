import redis.asyncio as redis
from app.core.config import settings
from typing import Optional

class Cache:
    def __init__(self):
        self.redis: Optional[redis.Redis] = None

    async def connect(self):
        try:
            self.redis = redis.from_url(settings.REDIS_URL, decode_responses=True)
            # Attempt a ping to validate
            await self.redis.ping()
        except Exception:
            self.redis = None

    async def disconnect(self):
        if self.redis:
            await self.redis.close()

    async def get(self, key: str):
        if self.redis:
            return await self.redis.get(key)
        return None

    async def set(self, key: str, value: str, ttl: int = None):
        if self.redis:
            await self.redis.set(key, value, ex=ttl)

    async def delete(self, key: str):
        if self.redis:
            await self.redis.delete(key)

cache = Cache()

async def init_cache():
    await cache.connect()

async def get_cache() -> Cache:
    return cache
