# app/utils/rate_limiter.py

import time
from collections import defaultdict
from typing import Tuple

# Simple in-memory fallback rate limiter (non-production safe)
class InMemoryRateLimiter:
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

rate_limiter = InMemoryRateLimiter()
