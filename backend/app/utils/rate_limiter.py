import time
from typing import Dict, Optional
from app.core.cache import get_cache
import json

class RateLimiter:
    def __init__(self):
        self.cache = get_cache()

    async def check_rate_limit(self, key: str, limit: int, window: int) -> bool:
        """Check if request is within rate limit"""
        current_time = int(time.time())
        window_start = current_time - window
        
        # Get current requests in window
        requests_data = await self.cache.get(f"rate_limit:{key}")
        if requests_data:
            requests = json.loads(requests_data)
            # Remove old requests outside window
            requests = [req for req in requests if req > window_start]
        else:
            requests = []
        
        # Check if limit exceeded
        if len(requests) >= limit:
            return False
        
        # Add current request
        requests.append(current_time)
        await self.cache.set(f"rate_limit:{key}", json.dumps(requests), window)
        
        return True

    async def get_remaining_requests(self, key: str, limit: int, window: int) -> int:
        """Get remaining requests for rate limit"""
        current_time = int(time.time())
        window_start = current_time - window
        
        requests_data = await self.cache.get(f"rate_limit:{key}")
        if requests_data:
            requests = json.loads(requests_data)
            requests = [req for req in requests if req > window_start]
            return max(0, limit - len(requests))
        
        return limit