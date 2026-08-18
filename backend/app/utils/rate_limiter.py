# app/utils/rate_limiter.py
import time
from collections import defaultdict
from typing import Tuple

from app.core.cache import cache


class InMemoryRateLimiter:
    """Per-process fallback. Used only when Redis is unreachable, so limits
    aren't shared across worker processes/replicas in that degraded mode."""

    def __init__(self):
        self.requests = defaultdict(list)  # {user_key: [timestamps]}

    async def check_rate_limit(self, endpoint: str, limit: int, window: int, user_id: str) -> Tuple[bool, int]:
        current_time = time.time()
        key = f"{endpoint}:{user_id}"
        self.requests[key] = [t for t in self.requests[key] if t > current_time - window]
        if len(self.requests[key]) < limit:
            self.requests[key].append(current_time)
            return True, int(current_time + window)
        return False, int(current_time + window)


class RedisRateLimiter:
    """Fixed-window counter backed by Redis so limits are shared across all
    worker processes and replicas, not just the process handling the request."""

    def __init__(self):
        self._fallback = InMemoryRateLimiter()

    async def check_rate_limit(self, endpoint: str, limit: int, window: int, user_id: str) -> Tuple[bool, int]:
        if cache.redis is None:
            return await self._fallback.check_rate_limit(endpoint, limit, window, user_id)

        current_time = time.time()
        window_start = int(current_time // window) * window
        key = f"ratelimit:{endpoint}:{user_id}:{window_start}"
        reset_time = window_start + window

        try:
            count = await cache.redis.incr(key)
            if count == 1:
                await cache.redis.expire(key, window)
            return count <= limit, reset_time
        except Exception:
            return await self._fallback.check_rate_limit(endpoint, limit, window, user_id)


rate_limiter = RedisRateLimiter()
