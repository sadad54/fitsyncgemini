import aiohttp
import json
from typing import Dict, List, Optional
from app.core.config import settings
from app.utils.rate_limiter import rate_limiter
from fastapi import HTTPException
import redis.asyncio as redis

class GooglePlacesClient:
    def __init__(self):
        self.base_url = settings.GOOGLE_PLACES_BASE_URL
        self.api_key = settings.GOOGLE_PLACES_API_KEY
        self.redis = redis.from_url(settings.REDIS_URL)
    
    async def find_nearby_fashion_stores(
        self, 
        lat: float, 
        lon: float, 
        radius: int = 5000,
        user_id: str = "default"
    ) -> Dict:
        """Find nearby fashion stores and boutiques"""
        
        # Check cache
        cache_key = f"places:fashion:{lat}:{lon}:{radius}"
        cached = await self.redis.get(cache_key)
        if cached:
            return json.loads(cached)
        
        # Rate limiting
        allowed, reset_time = await rate_limiter.check_rate_limit(
            "google_places",
            settings.GOOGLE_PLACES_RATE_LIMIT,
            86400,
            user_id
        )
        
        if not allowed:
            raise HTTPException(
                status_code=429,
                detail="Google Places rate limit exceeded"
            )
        
        fashion_types = [
            "clothing_store",
            "shoe_store", 
            "jewelry_store",
            "department_store"
        ]
        
        all_places = []
        
        try:
            async with aiohttp.ClientSession() as session:
                for place_type in fashion_types:
                    async with session.get(
                        f"{self.base_url}/nearbysearch/json",
                        params={
                            "location": f"{lat},{lon}",
                            "radius": radius,
                            "type": place_type,
                            "key": self.api_key
                        }
                    ) as response:
                        
                        if response.status == 200:
                            data = await response.json()
                            if data["status"] == "OK":
                                for place in data.get("results", []):
                                    place_info = self._process_place_data(place, place_type)
                                    all_places.append(place_info)
                        else:
                            continue  # Skip this type if error
            
            # Remove duplicates and sort by rating
            unique_places = self._deduplicate_places(all_places)
            sorted_places = sorted(unique_places, key=lambda x: x.get("rating", 0), reverse=True)
            
            result = {
                "places": sorted_places[:20],  # Top 20 places
                "total_found": len(sorted_places),
                "search_center": {"lat": lat, "lon": lon},
                "search_radius": radius
            }
            
            # Cache for 24 hours
            await self.redis.setex(
                cache_key,
                settings.CACHE_TTL_PLACES,
                json.dumps(result)
            )
            
            return result
            
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Google Places API error: {str(e)}"
            )
    
    async def get_trending_fashion_locations(
        self, 
        lat: float, 
        lon: float,
        user_id: str = "default"
    ) -> Dict:
        """Get trending fashion locations and hotspots"""
        
        cache_key = f"places:trending:{lat}:{lon}"
        cached = await self.redis.get(cache_key)
        if cached:
            return json.loads(cached)
        
        # Rate limiting
        allowed, _ = await rate_limiter.check_rate_limit(
            "google_places_trending",
            settings.GOOGLE_PLACES_RATE_LIMIT // 2,
            86400,
            user_id
        )
        
        if not allowed:
            raise HTTPException(
                status_code=429,
                detail="Places trending API rate limit exceeded"
            )
        
        try:
            # Search for high-end fashion areas
            trending_keywords = [
                "fashion district",
                "designer boutique", 
                "luxury shopping",
                "fashion mall",
                "trendy shopping area"
            ]
            
            trending_places = []
            
            async with aiohttp.ClientSession() as session:
                for keyword in trending_keywords:
                    async with session.get(
                        f"{self.base_url}/textsearch/json",
                        params={
                            "query": f"{keyword} near {lat},{lon}",
                            "radius": 10000,  # 10km
                            "key": self.api_key
                        }
                    ) as response:
                        
                        if response.status == 200:
                            data = await response.json()
                            if data["status"] == "OK":
                                for place in data.get("results", [])[:5]:  # Top 5 per keyword
                                    place_info = self._process_trending_place(place, keyword)
                                    trending_places.append(place_info)
            
            # Deduplicate and sort by popularity score
            unique_trending = self._deduplicate_places(trending_places)
            sorted_trending = sorted(
                unique_trending, 
                key=lambda x: x.get("popularity_score", 0), 
                reverse=True
            )
            
            result = {
                "trending_locations": sorted_trending[:10],
                "fashion_districts": self._identify_fashion_districts(sorted_trending),
                "hotspots": self._identify_hotspots(sorted_trending)
            }
            
            # Cache for 12 hours
            await self.redis.setex(cache_key, 43200, json.dumps(result))
            return result
            
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Trending locations error: {str(e)}"
            )
    
    async def text_search(
        self,
        query: str,
        lat: Optional[float] = None,
        lon: Optional[float] = None,
        user_id: str = "default"
    ) -> Dict:
        """Free-text place search, optionally biased toward a location"""

        cache_key = f"places:textsearch:{query}:{lat}:{lon}"
        cached = await self.redis.get(cache_key)
        if cached:
            return json.loads(cached)

        allowed, _ = await rate_limiter.check_rate_limit(
            "google_places_search",
            settings.GOOGLE_PLACES_RATE_LIMIT,
            86400,
            user_id
        )

        if not allowed:
            raise HTTPException(
                status_code=429,
                detail="Google Places rate limit exceeded"
            )

        params = {"query": query, "key": self.api_key}
        if lat is not None and lon is not None:
            params["location"] = f"{lat},{lon}"
            params["radius"] = 20000

        try:
            async with aiohttp.ClientSession() as session:
                async with session.get(f"{self.base_url}/textsearch/json", params=params) as response:
                    if response.status != 200:
                        return {"places": [], "total_found": 0}
                    data = await response.json()
                    if data.get("status") != "OK":
                        return {"places": [], "total_found": 0}
                    places = [self._process_place_data(place, "search") for place in data.get("results", [])[:20]]

            result = {"places": places, "total_found": len(places)}
            await self.redis.setex(cache_key, settings.CACHE_TTL_PLACES, json.dumps(result))
            return result

        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Google Places search error: {str(e)}")

    async def get_place_details(self, place_id: str, user_id: str) -> Dict:
        """Get detailed information about a specific place"""
        
        cache_key = f"places:details:{place_id}"
        cached = await self.redis.get(cache_key)
        if cached:
            return json.loads(cached)
        
        # Rate limiting
        allowed, _ = await rate_limiter.check_rate_limit(
            "google_places_details",
            settings.GOOGLE_PLACES_RATE_LIMIT // 4,
            86400,
            user_id
        )
        
        if not allowed:
            return {"error": "Rate limit exceeded"}
        
        try:
            async with aiohttp.ClientSession() as session:
                async with session.get(
                    f"{self.base_url}/details/json",
                    params={
                        "place_id": place_id,
                        "fields": "name,rating,reviews,photos,opening_hours,website,formatted_phone_number,price_level,types",
                        "key": self.api_key
                    }
                ) as response:
                    
                    if response.status == 200:
                        data = await response.json()
                        if data["status"] == "OK":
                            place_details = self._process_place_details(data["result"])
                            
                            # Cache for 48 hours
                            await self.redis.setex(cache_key, 172800, json.dumps(place_details))
                            return place_details
                    
                    return {"error": "Place details not found"}
                    
        except Exception as e:
            return {"error": f"Place details error: {str(e)}"}
    
    def _process_place_data(self, place: Dict, place_type: str) -> Dict:
        """Process place data from Google Places API"""
        return {
            "id": place.get("place_id"),
            "name": place.get("name"),
            "rating": place.get("rating", 0),
            "price_level": place.get("price_level", 0),
            "types": place.get("types", []),
            "category": self._categorize_fashion_store(place.get("types", []), place_type),
            "location": {
                "lat": place["geometry"]["location"]["lat"],
                "lng": place["geometry"]["location"]["lng"]
            },
            "address": place.get("vicinity"),
            "is_open": place.get("opening_hours", {}).get("open_now", None),
            "photos": [photo.get("photo_reference") for photo in place.get("photos", [])[:3]]
        }
    
    def _process_trending_place(self, place: Dict, keyword: str) -> Dict:
        """Process trending place data"""
        base_info = self._process_place_data(place, "trending")
        
        # Calculate popularity score based on rating, reviews, and search relevance
        popularity_score = (
            (place.get("rating", 0) * 20) +  # Rating impact
            (min(place.get("user_ratings_total", 0), 1000) / 10) +  # Review count impact
            (50 if "luxury" in keyword.lower() else 0) +  # Luxury bonus
            (30 if "designer" in keyword.lower() else 0)   # Designer bonus
        )
        
        base_info.update({
            "popularity_score": popularity_score,
            "trending_keyword": keyword,
            "review_count": place.get("user_ratings_total", 0)
        })
        
        return base_info
    
    def _process_place_details(self, place: Dict) -> Dict:
        """Process detailed place information"""
        return {
            "name": place.get("name"),
            "rating": place.get("rating"),
            "review_count": place.get("user_ratings_total", 0),
            "price_level": place.get("price_level"),
            "website": place.get("website"),
            "phone": place.get("formatted_phone_number"),
            "opening_hours": place.get("opening_hours", {}).get("weekday_text", []),
            "reviews": [
                {
                    "author": review.get("author_name"),
                    "rating": review.get("rating"),
                    "text": review.get("text"),
                    "time": review.get("relative_time_description")
                }
                for review in place.get("reviews", [])[:5]
            ],
            "photos": [
                f"https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference={photo['photo_reference']}&key={self.api_key}"
                for photo in place.get("photos", [])[:5]
            ]
        }
    
    def _categorize_fashion_store(self, types: List[str], place_type: str) -> str:
        """Categorize fashion store type"""
        category_map = {
            "clothing_store": "Clothing",
            "shoe_store": "Footwear", 
            "jewelry_store": "Jewelry & Accessories",
            "department_store": "Department Store"
        }
        
        # Check for luxury indicators
        luxury_keywords = ["luxury", "designer", "boutique", "high_end"]
        if any(keyword in " ".join(types).lower() for keyword in luxury_keywords):
            return f"Luxury {category_map.get(place_type, 'Fashion')}"
        
        return category_map.get(place_type, "Fashion Store")
    
    def _deduplicate_places(self, places: List[Dict]) -> List[Dict]:
        """Remove duplicate places based on name and location"""
        seen = set()
        unique_places = []
        
        for place in places:
            # Create a unique key based on name and approximate location
            key = (
                place.get("name", "").lower(),
                round(place.get("location", {}).get("lat", 0), 4),
                round(place.get("location", {}).get("lng", 0), 4)
            )
            
            if key not in seen:
                seen.add(key)
                unique_places.append(place)
        
        return unique_places
    
    def _identify_fashion_districts(self, places: List[Dict]) -> List[Dict]:
        """Identify fashion districts based on place clustering"""
        # Simple clustering logic - group places within 1km of each other
        districts = []
        processed = set()
        
        for i, place in enumerate(places):
            if i in processed:
                continue
                
            district_places = [place]
            place_lat = place.get("location", {}).get("lat", 0)
            place_lng = place.get("location", {}).get("lng", 0)
            
            for j, other_place in enumerate(places[i+1:], i+1):
                if j in processed:
                    continue
                    
                other_lat = other_place.get("location", {}).get("lat", 0)
                other_lng = other_place.get("location", {}).get("lng", 0)
                
                # Simple distance calculation (approximately 1km = 0.01 degrees)
                if abs(place_lat - other_lat) < 0.01 and abs(place_lng - other_lng) < 0.01:
                    district_places.append(other_place)
                    processed.add(j)
            
            if len(district_places) >= 3:  # At least 3 places to form a district
                district = {
                    "name": f"Fashion District {len(districts) + 1}",
                    "center": {
                        "lat": sum(p.get("location", {}).get("lat", 0) for p in district_places) / len(district_places),
                        "lng": sum(p.get("location", {}).get("lng", 0) for p in district_places) / len(district_places)
                    },
                    "places": district_places,
                    "store_count": len(district_places),
                    "avg_rating": sum(p.get("rating", 0) for p in district_places) / len(district_places)
                }
                districts.append(district)
            
            processed.add(i)
        
        return districts
    
    def _identify_hotspots(self, places: List[Dict]) -> List[Dict]:
        """Identify fashion hotspots (highly rated clusters)"""
        hotspots = []
        
        for place in places:
            if place.get("rating", 0) >= 4.5 and place.get("popularity_score", 0) > 100:
                hotspot = {
                    "name": place.get("name"),
                    "type": "Fashion Hotspot",
                    "location": place.get("location"),
                    "rating": place.get("rating"),
                    "category": place.get("category"),
                    "why_trending": self._generate_trending_reason(place)
                }
                hotspots.append(hotspot)
        
        return hotspots[:5]  # Top 5 hotspots
    
    def _generate_trending_reason(self, place: Dict) -> str:
        """Generate reason why a place is trending"""
        reasons = []
        
        if place.get("rating", 0) >= 4.8:
            reasons.append("Exceptional customer ratings")
        elif place.get("rating", 0) >= 4.5:
            reasons.append("High customer satisfaction")
        
        if place.get("review_count", 0) > 500:
            reasons.append("Popular destination")
        elif place.get("review_count", 0) > 100:
            reasons.append("Well-reviewed location")
        
        if "luxury" in place.get("category", "").lower():
            reasons.append("Premium fashion destination")
        
        return " • ".join(reasons) if reasons else "Trending in your area"

google_places_client = GooglePlacesClient()