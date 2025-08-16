"""
Cache Service - Redis-based caching for frequently accessed data
"""

import json
import logging
from typing import Any, Optional, Dict, List
from datetime import datetime, timedelta
import hashlib

# For development, we'll use a simple in-memory cache
# In production, replace with Redis
class InMemoryCache:
    def __init__(self):
        self._cache: Dict[str, Dict[str, Any]] = {}
    
    def get(self, key: str) -> Optional[Any]:
        if key in self._cache:
            item = self._cache[key]
            if datetime.utcnow() < item['expires_at']:
                return item['value']
            else:
                del self._cache[key]
        return None
    
    def set(self, key: str, value: Any, ttl_seconds: int = 300):
        self._cache[key] = {
            'value': value,
            'expires_at': datetime.utcnow() + timedelta(seconds=ttl_seconds)
        }
    
    def delete(self, key: str):
        if key in self._cache:
            del self._cache[key]
    
    def clear(self):
        self._cache.clear()

# Global cache instance
_cache = InMemoryCache()

logger = logging.getLogger(__name__)

class CacheService:
    """Service for caching frequently accessed data"""
    
    # Cache TTL values (in seconds)
    CACHE_TTL = {
        'categories': 3600,  # 1 hour - rarely changes
        'trending_styles': 900,  # 15 minutes - updates frequently
        'fashion_insights': 1800,  # 30 minutes - moderate update frequency
        'influencer_spotlight': 1800,  # 30 minutes
        'explore_items': 300,  # 5 minutes - dynamic content
        'trending_now': 600,  # 10 minutes
        'outfit_recommendations': 60,  # 1 minute - personalized, short cache
        'nearby_data': 180,  # 3 minutes - location-based, needs freshness
    }
    
    @staticmethod
    def _generate_cache_key(prefix: str, **kwargs) -> str:
        """Generate a cache key from prefix and parameters"""
        # Sort kwargs for consistent key generation
        key_parts = [prefix]
        for k, v in sorted(kwargs.items()):
            if v is not None:
                key_parts.append(f"{k}:{v}")
        
        key_string = ":".join(key_parts)
        
        # Hash long keys to avoid key length issues
        if len(key_string) > 100:
            hash_obj = hashlib.md5(key_string.encode())
            return f"{prefix}:hash:{hash_obj.hexdigest()}"
        
        return key_string
    
    @staticmethod
    def get_categories() -> Optional[List[str]]:
        """Get cached categories"""
        try:
            key = CacheService._generate_cache_key("categories")
            return _cache.get(key)
        except Exception as e:
            logger.error(f"Cache get error for categories: {e}")
            return None
    
    @staticmethod
    def set_categories(categories: List[str]):
        """Cache categories"""
        try:
            key = CacheService._generate_cache_key("categories")
            _cache.set(key, categories, CacheService.CACHE_TTL['categories'])
        except Exception as e:
            logger.error(f"Cache set error for categories: {e}")
    
    @staticmethod
    def get_trending_styles(limit: int = 10) -> Optional[List[Dict[str, Any]]]:
        """Get cached trending styles"""
        try:
            key = CacheService._generate_cache_key("trending_styles", limit=limit)
            return _cache.get(key)
        except Exception as e:
            logger.error(f"Cache get error for trending styles: {e}")
            return None
    
    @staticmethod
    def set_trending_styles(styles: List[Dict[str, Any]], limit: int = 10):
        """Cache trending styles"""
        try:
            key = CacheService._generate_cache_key("trending_styles", limit=limit)
            _cache.set(key, styles, CacheService.CACHE_TTL['trending_styles'])
        except Exception as e:
            logger.error(f"Cache set error for trending styles: {e}")
    
    @staticmethod
    def get_explore_items(
        category: Optional[str] = None,
        trending: Optional[bool] = None,
        limit: int = 20,
        offset: int = 0
    ) -> Optional[Dict[str, Any]]:
        """Get cached explore items"""
        try:
            key = CacheService._generate_cache_key(
                "explore_items", 
                category=category, 
                trending=trending, 
                limit=limit, 
                offset=offset
            )
            return _cache.get(key)
        except Exception as e:
            logger.error(f"Cache get error for explore items: {e}")
            return None
    
    @staticmethod
    def set_explore_items(
        data: Dict[str, Any],
        category: Optional[str] = None,
        trending: Optional[bool] = None,
        limit: int = 20,
        offset: int = 0
    ):
        """Cache explore items"""
        try:
            key = CacheService._generate_cache_key(
                "explore_items", 
                category=category, 
                trending=trending, 
                limit=limit, 
                offset=offset
            )
            _cache.set(key, data, CacheService.CACHE_TTL['explore_items'])
        except Exception as e:
            logger.error(f"Cache set error for explore items: {e}")
    
    @staticmethod
    def get_trending_now(
        scope: str = "global",
        timeframe: str = "week",
        limit: int = 10
    ) -> Optional[List[Dict[str, Any]]]:
        """Get cached trending now data"""
        try:
            key = CacheService._generate_cache_key(
                "trending_now", 
                scope=scope, 
                timeframe=timeframe, 
                limit=limit
            )
            return _cache.get(key)
        except Exception as e:
            logger.error(f"Cache get error for trending now: {e}")
            return None
    
    @staticmethod
    def set_trending_now(
        data: List[Dict[str, Any]],
        scope: str = "global",
        timeframe: str = "week",
        limit: int = 10
    ):
        """Cache trending now data"""
        try:
            key = CacheService._generate_cache_key(
                "trending_now", 
                scope=scope, 
                timeframe=timeframe, 
                limit=limit
            )
            _cache.set(key, data, CacheService.CACHE_TTL['trending_now'])
        except Exception as e:
            logger.error(f"Cache set error for trending now: {e}")
    
    @staticmethod
    def get_fashion_insights(
        scope: str = "global",
        timeframe: str = "week"
    ) -> Optional[List[Dict[str, Any]]]:
        """Get cached fashion insights"""
        try:
            key = CacheService._generate_cache_key(
                "fashion_insights", 
                scope=scope, 
                timeframe=timeframe
            )
            return _cache.get(key)
        except Exception as e:
            logger.error(f"Cache get error for fashion insights: {e}")
            return None
    
    @staticmethod
    def set_fashion_insights(
        data: List[Dict[str, Any]],
        scope: str = "global",
        timeframe: str = "week"
    ):
        """Cache fashion insights"""
        try:
            key = CacheService._generate_cache_key(
                "fashion_insights", 
                scope=scope, 
                timeframe=timeframe
            )
            _cache.set(key, data, CacheService.CACHE_TTL['fashion_insights'])
        except Exception as e:
            logger.error(f"Cache set error for fashion insights: {e}")
    
    @staticmethod
    def get_influencer_spotlight(
        scope: str = "global",
        limit: int = 10
    ) -> Optional[List[Dict[str, Any]]]:
        """Get cached influencer spotlight"""
        try:
            key = CacheService._generate_cache_key(
                "influencer_spotlight", 
                scope=scope, 
                limit=limit
            )
            return _cache.get(key)
        except Exception as e:
            logger.error(f"Cache get error for influencer spotlight: {e}")
            return None
    
    @staticmethod
    def set_influencer_spotlight(
        data: List[Dict[str, Any]],
        scope: str = "global",
        limit: int = 10
    ):
        """Cache influencer spotlight"""
        try:
            key = CacheService._generate_cache_key(
                "influencer_spotlight", 
                scope=scope, 
                limit=limit
            )
            _cache.set(key, data, CacheService.CACHE_TTL['influencer_spotlight'])
        except Exception as e:
            logger.error(f"Cache set error for influencer spotlight: {e}")
    
    @staticmethod
    def get_outfit_recommendations(
        user_id: int,
        context_hash: Optional[str] = None,
        limit: int = 10
    ) -> Optional[Dict[str, Any]]:
        """Get cached outfit recommendations for user"""
        try:
            key = CacheService._generate_cache_key(
                "outfit_recommendations", 
                user_id=user_id, 
                context=context_hash,
                limit=limit
            )
            return _cache.get(key)
        except Exception as e:
            logger.error(f"Cache get error for outfit recommendations: {e}")
            return None
    
    @staticmethod
    def set_outfit_recommendations(
        user_id: int,
        data: Dict[str, Any],
        context_hash: Optional[str] = None,
        limit: int = 10
    ):
        """Cache outfit recommendations for user"""
        try:
            key = CacheService._generate_cache_key(
                "outfit_recommendations", 
                user_id=user_id, 
                context=context_hash,
                limit=limit
            )
            _cache.set(key, data, CacheService.CACHE_TTL['outfit_recommendations'])
        except Exception as e:
            logger.error(f"Cache set error for outfit recommendations: {e}")
    
    @staticmethod
    def get_nearby_data(
        data_type: str,  # people, events, hotspots, map
        lat: float,
        lng: float,
        radius_km: float = 5.0,
        limit: int = 20,
        **kwargs
    ) -> Optional[Any]:
        """Get cached nearby data"""
        try:
            # Round coordinates to reduce cache key variations
            lat_rounded = round(lat, 3)  # ~100m precision
            lng_rounded = round(lng, 3)
            
            key = CacheService._generate_cache_key(
                f"nearby_{data_type}",
                lat=lat_rounded,
                lng=lng_rounded,
                radius=radius_km,
                limit=limit,
                **kwargs
            )
            return _cache.get(key)
        except Exception as e:
            logger.error(f"Cache get error for nearby {data_type}: {e}")
            return None
    
    @staticmethod
    def set_nearby_data(
        data_type: str,
        data: Any,
        lat: float,
        lng: float,
        radius_km: float = 5.0,
        limit: int = 20,
        **kwargs
    ):
        """Cache nearby data"""
        try:
            # Round coordinates to reduce cache key variations
            lat_rounded = round(lat, 3)
            lng_rounded = round(lng, 3)
            
            key = CacheService._generate_cache_key(
                f"nearby_{data_type}",
                lat=lat_rounded,
                lng=lng_rounded,
                radius=radius_km,
                limit=limit,
                **kwargs
            )
            _cache.set(key, data, CacheService.CACHE_TTL['nearby_data'])
        except Exception as e:
            logger.error(f"Cache set error for nearby {data_type}: {e}")
    
    @staticmethod
    def invalidate_user_cache(user_id: int):
        """Invalidate all cache entries for a specific user"""
        try:
            # This is a simplified version for in-memory cache
            # In Redis, you'd use pattern matching to delete keys
            keys_to_delete = []
            for key in _cache._cache.keys():
                if f"user_id:{user_id}" in key:
                    keys_to_delete.append(key)
            
            for key in keys_to_delete:
                _cache.delete(key)
                
            logger.info(f"Invalidated {len(keys_to_delete)} cache entries for user {user_id}")
        except Exception as e:
            logger.error(f"Error invalidating user cache: {e}")
    
    @staticmethod
    def invalidate_location_cache(lat: float, lng: float, radius_km: float = 10.0):
        """Invalidate location-based cache entries near the given coordinates"""
        try:
            # Simplified for in-memory cache
            keys_to_delete = []
            lat_rounded = round(lat, 3)
            lng_rounded = round(lng, 3)
            
            for key in _cache._cache.keys():
                if key.startswith("nearby_") and f"lat:{lat_rounded}" in key and f"lng:{lng_rounded}" in key:
                    keys_to_delete.append(key)
            
            for key in keys_to_delete:
                _cache.delete(key)
                
            logger.info(f"Invalidated {len(keys_to_delete)} location cache entries")
        except Exception as e:
            logger.error(f"Error invalidating location cache: {e}")
    
    @staticmethod
    def clear_all_cache():
        """Clear all cache entries (use with caution)"""
        try:
            _cache.clear()
            logger.info("Cleared all cache entries")
        except Exception as e:
            logger.error(f"Error clearing cache: {e}")
    
    @staticmethod
    def get_cache_stats() -> Dict[str, Any]:
        """Get cache statistics"""
        try:
            total_keys = len(_cache._cache)
            expired_keys = 0
            now = datetime.utcnow()
            
            for item in _cache._cache.values():
                if now >= item['expires_at']:
                    expired_keys += 1
            
            return {
                "total_keys": total_keys,
                "active_keys": total_keys - expired_keys,
                "expired_keys": expired_keys,
                "cache_type": "in_memory"
            }
        except Exception as e:
            logger.error(f"Error getting cache stats: {e}")
            return {"error": str(e)}

# Utility function to generate context hash
def hash_context(context: Dict[str, Any]) -> str:
    """Generate a hash for context data to use in cache keys"""
    try:
        context_str = json.dumps(context, sort_keys=True)
        return hashlib.md5(context_str.encode()).hexdigest()[:8]
    except Exception:
        return "default"
