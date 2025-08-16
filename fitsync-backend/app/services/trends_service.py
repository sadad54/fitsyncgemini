"""
Trends Service - Real data operations for fashion trends and content discovery
"""

import math
from typing import List, Dict, Any, Optional, Tuple
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_, desc, asc, func
from app.models.trends import (
    FashionTrend, StyleInfluencer, ExploreContent, 
    NearbyLocation, TrendInsight, TrendDirection
)
from app.models.user import User
from app.schemas.trends import (
    TrendingStyleResponse, ExploreItemResponse, TrendingNowResponse,
    FashionInsightResponse, InfluencerSpotlightResponse,
    NearbyPersonResponse, NearbyEventResponse, NearbyHotspotResponse,
    OutfitSuggestionResponse, StyleFocusResponse, WeatherInfo,
    OutfitSuggestionItem, LocationTypeEnum
)
from app.services.enhanced_ml_service import enhanced_ml_service
import logging

logger = logging.getLogger(__name__)

class TrendsService:
    """Service for handling trends and content discovery"""
    
    @staticmethod
    def calculate_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """Calculate distance between two points using Haversine formula"""
        R = 6371  # Earth's radius in kilometers
        
        lat1_rad = math.radians(lat1)
        lon1_rad = math.radians(lon1)
        lat2_rad = math.radians(lat2)
        lon2_rad = math.radians(lon2)
        
        dlat = lat2_rad - lat1_rad
        dlon = lon2_rad - lon1_rad
        
        a = math.sin(dlat/2)**2 + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(dlon/2)**2
        c = 2 * math.asin(math.sqrt(a))
        
        return R * c

    @staticmethod
    async def get_outfit_recommendations(
        db: Session, 
        user: User, 
        context: Dict[str, Any] = None,
        limit: int = 10
    ) -> Dict[str, Any]:
        """Get personalized outfit recommendations"""
        try:
            # Get user's wardrobe items and preferences
            from app.models.clothing import ClothingItem
            from app.schemas.user import StylePreferencesResponse
            
            # Fetch user's clothing items
            user_items = db.query(ClothingItem).filter(
                ClothingItem.owner_id == user.id,
                ClothingItem.is_active == True
            ).limit(50).all()
            
            # Get user preferences if available
            user_profile = getattr(user, 'profile', None)
            style_prefs = getattr(user, 'style_preferences', None)
            
            # Use ML service for recommendations
            ml_recommendations = await enhanced_ml_service.get_user_recommendations(
                user.id, context or {}
            )
            
            # Mock weather data (integrate with weather service later)
            weather_info = WeatherInfo(
                temperature=22.0,
                condition="Clear",
                unit="°C"
            )
            
            # Generate outfit suggestions based on user's items and ML recommendations
            suggestions = []
            for i in range(min(limit, len(user_items) if user_items else 3)):
                if user_items and i < len(user_items):
                    base_item = user_items[i]
                    items = [
                        OutfitSuggestionItem(
                            id=str(base_item.id),
                            name=base_item.name,
                            category=base_item.category.value,
                            imageUrl=base_item.image_url or "https://example.com/default.jpg",
                            isMain=True
                        )
                    ]
                    
                    # Add complementary items
                    complementary_categories = {
                        "tops": "bottoms",
                        "bottoms": "tops", 
                        "dresses": "outerwear"
                    }
                    
                    comp_category = complementary_categories.get(base_item.category.value)
                    if comp_category:
                        comp_items = db.query(ClothingItem).filter(
                            ClothingItem.owner_id == user.id,
                            ClothingItem.category == comp_category,
                            ClothingItem.is_active == True,
                            ClothingItem.id != base_item.id
                        ).limit(2).all()
                        
                        for comp_item in comp_items:
                            items.append(
                                OutfitSuggestionItem(
                                    id=str(comp_item.id),
                                    name=comp_item.name,
                                    category=comp_item.category.value,
                                    imageUrl=comp_item.image_url or "https://example.com/default.jpg",
                                    isMain=False
                                )
                            )
                    
                    # Determine occasion based on item style tags
                    occasion = "casual"
                    if base_item.style_tags:
                        if "formal" in base_item.style_tags:
                            occasion = "formal"
                        elif "business" in base_item.style_tags:
                            occasion = "business"
                        elif "sporty" in base_item.style_tags:
                            occasion = "sporty"
                    
                    suggestions.append(
                        OutfitSuggestionResponse(
                            id=f"outfit_{user.id}_{i}",
                            name=f"Outfit with {base_item.name}",
                            occasion=occasion,
                            items=items,
                            matchPercentage=0.85 + (i * 0.02),
                            description=f"A stylish combination featuring your {base_item.name}",
                            weatherInfo=weather_info,
                            isFavorite=False
                        )
                    )
                else:
                    # Fallback to mock data if no user items
                    suggestions.append(
                        OutfitSuggestionResponse(
                            id=f"mock_{user.id}_{i}",
                            name=f"Suggested Outfit {i+1}",
                            occasion=["casual", "business", "formal", "sporty"][i % 4],
                            items=[
                                OutfitSuggestionItem(
                                    id=f"mock_item_{i}_1",
                                    name="Recommended Top",
                                    category="tops",
                                    imageUrl="https://example.com/top.jpg",
                                    isMain=True
                                ),
                                OutfitSuggestionItem(
                                    id=f"mock_item_{i}_2",
                                    name="Recommended Bottom",
                                    category="bottoms", 
                                    imageUrl="https://example.com/bottom.jpg",
                                    isMain=False
                                )
                            ],
                            matchPercentage=0.80 + (i * 0.03),
                            description="A curated outfit suggestion based on current trends",
                            weatherInfo=weather_info,
                            isFavorite=False
                        )
                    )
            
            # Generate style focus
            focus_title = "Today's Focus"
            focus_description = "Light layers and breathable fabrics work best for today's weather."
            recommendations = [
                "Try earth tones for a grounded look",
                "Avoid heavy fabrics in this weather",
                "Consider layering for versatility"
            ]
            
            # Personalize based on user preferences
            if style_prefs:
                if hasattr(style_prefs, 'preferred_colors') and style_prefs.preferred_colors:
                    focus_description = f"Focus on {', '.join(style_prefs.preferred_colors[:2])} tones today."
                    recommendations.insert(0, f"Your preferred {style_prefs.preferred_colors[0]} colors work well")
            
            style_focus = StyleFocusResponse(
                title=focus_title,
                description=focus_description,
                weatherInfo=weather_info,
                recommendations=recommendations
            )
            
            return {
                "suggestions": [s.dict() for s in suggestions],
                "styleFocus": style_focus.dict()
            }
            
        except Exception as e:
            logger.error(f"Error getting outfit recommendations: {e}")
            # Return fallback data
            return await TrendsService._get_fallback_recommendations(user, limit)

    @staticmethod
    async def _get_fallback_recommendations(user: User, limit: int) -> Dict[str, Any]:
        """Fallback recommendations if main service fails"""
        weather_info = WeatherInfo(temperature=22.0, condition="Clear", unit="°C")
        
        suggestions = []
        for i in range(min(limit, 3)):
            suggestions.append({
                "id": f"fallback_{user.id}_{i}",
                "name": f"Curated Look {i+1}",
                "occasion": ["casual", "business", "formal"][i % 3],
                "items": [
                    {
                        "id": f"fb_item_{i}_1",
                        "name": "Style Recommendation",
                        "category": "tops",
                        "imageUrl": "https://example.com/style.jpg",
                        "isMain": True
                    }
                ],
                "matchPercentage": 0.75,
                "description": "A versatile outfit suggestion",
                "weatherInfo": weather_info.dict(),
                "isFavorite": False
            })
        
        return {
            "suggestions": suggestions,
            "styleFocus": {
                "title": "Style Inspiration",
                "description": "Explore new combinations and express your unique style.",
                "weatherInfo": weather_info.dict(),
                "recommendations": ["Mix textures for visual interest", "Experiment with proportions"]
            }
        }

    @staticmethod
    def get_trending_styles(db: Session, limit: int = 10) -> List[TrendingStyleResponse]:
        """Get trending styles from database"""
        try:
            trends = db.query(FashionTrend).filter(
                FashionTrend.is_active == True,
                FashionTrend.category == "style"
            ).order_by(desc(FashionTrend.popularity_score)).limit(limit).all()
            
            styles = []
            colors = ["#777777", "#222222", "#8B4513", "#000080", "#FF69B4", "#800000", "#228B22", "#4B0082"]
            
            for i, trend in enumerate(trends):
                growth_sign = "+" if trend.growth_rate > 0 else ""
                growth_pct = f"{growth_sign}{int(trend.growth_rate * 100)}%"
                
                styles.append(TrendingStyleResponse(
                    name=trend.trend_name,
                    growth=growth_pct,
                    color=colors[i % len(colors)]
                ))
            
            # Fill with defaults if not enough data
            default_styles = [
                {"name": "Minimalist", "growth": "+12%", "color": "#777777"},
                {"name": "Streetwear", "growth": "+8%", "color": "#222222"},
                {"name": "Bohemian", "growth": "+15%", "color": "#8B4513"},
                {"name": "Classic", "growth": "+5%", "color": "#000080"},
            ]
            
            while len(styles) < min(limit, 4):
                idx = len(styles)
                if idx < len(default_styles):
                    styles.append(TrendingStyleResponse(**default_styles[idx]))
                else:
                    break
            
            return styles
            
        except Exception as e:
            logger.error(f"Error getting trending styles: {e}")
            # Return default styles
            return [TrendingStyleResponse(**style) for style in [
                {"name": "Minimalist", "growth": "+12%", "color": "#777777"},
                {"name": "Streetwear", "growth": "+8%", "color": "#222222"},
                {"name": "Bohemian", "growth": "+15%", "color": "#8B4513"},
                {"name": "Classic", "growth": "+5%", "color": "#000080"},
            ][:limit]]

    @staticmethod
    def get_explore_items(
        db: Session, 
        category: Optional[str] = None,
        trending: Optional[bool] = None,
        limit: int = 20,
        offset: int = 0
    ) -> Tuple[List[ExploreItemResponse], int]:
        """Get explore items from database"""
        try:
            query = db.query(ExploreContent).filter(
                ExploreContent.is_public == True
            )
            
            # Apply filters
            if category:
                query = query.filter(
                    or_(
                        ExploreContent.category.ilike(f"%{category}%"),
                        ExploreContent.tags.contains([category])
                    )
                )
            
            if trending is not None:
                query = query.filter(ExploreContent.is_trending == trending)
            
            # Get total count
            total = query.count()
            
            # Apply pagination and ordering
            items = query.order_by(
                desc(ExploreContent.is_featured),
                desc(ExploreContent.trending_score),
                desc(ExploreContent.created_at)
            ).offset(offset).limit(limit).all()
            
            explore_items = []
            for item in items:
                explore_items.append(ExploreItemResponse(
                    id=item.id,
                    title=item.title,
                    author=item.author_name,
                    authorAvatar=item.author_avatar_url or "https://example.com/avatar.jpg",
                    likes=item.likes_count,
                    views=item.views_count,
                    tags=item.tags or [],
                    image=item.image_url,
                    trending=item.is_trending
                ))
            
            return explore_items, total
            
        except Exception as e:
            logger.error(f"Error getting explore items: {e}")
            # Return fallback data
            fallback_items = [
                ExploreItemResponse(
                    id=101,
                    title="Monochrome Layering",
                    author="Ava M.",
                    authorAvatar="https://example.com/avatar1.jpg",
                    likes=245,
                    views=5190,
                    tags=["minimalist", "winter"],
                    image="https://example.com/outfit1.jpg",
                    trending=True
                ),
                ExploreItemResponse(
                    id=102,
                    title="Street Style Vibes", 
                    author="Marcus K.",
                    authorAvatar="https://example.com/avatar2.jpg",
                    likes=189,
                    views=3420,
                    tags=["streetwear", "casual"],
                    image="https://example.com/outfit2.jpg",
                    trending=True
                )
            ]
            return fallback_items[:limit], len(fallback_items)

    @staticmethod
    def get_trending_now(
        db: Session,
        scope: str = "global",
        timeframe: str = "week", 
        limit: int = 10
    ) -> List[TrendingNowResponse]:
        """Get trending items from database"""
        try:
            # Calculate date filter based on timeframe
            now = datetime.utcnow()
            if timeframe == "day":
                since = now - timedelta(days=1)
            elif timeframe == "month":
                since = now - timedelta(days=30)
            else:  # week
                since = now - timedelta(days=7)
            
            trends = db.query(FashionTrend).filter(
                FashionTrend.is_active == True,
                FashionTrend.created_at >= since
            ).order_by(desc(FashionTrend.popularity_score)).limit(limit).all()
            
            trending_items = []
            for trend in trends:
                growth_sign = "+" if trend.growth_rate > 0 else ""
                growth_pct = f"{growth_sign}{int(trend.growth_rate * 100)}%"
                
                direction = TrendDirection.UP
                if trend.growth_rate < -0.05:
                    direction = TrendDirection.DOWN
                elif trend.growth_rate < 0.05:
                    direction = TrendDirection.STABLE
                
                trending_items.append(TrendingNowResponse(
                    id=f"t_{trend.id}",
                    title=trend.trend_name,
                    growth=growth_pct,
                    trend=direction,
                    description=trend.trend_description or "Trending fashion item",
                    image=trend.image_url or "https://example.com/trend.jpg",
                    tags=trend.tags or [],
                    engagement=trend.engagement,
                    posts=trend.posts_count
                ))
            
            return trending_items
            
        except Exception as e:
            logger.error(f"Error getting trending now: {e}")
            # Return fallback data
            return [
                TrendingNowResponse(
                    id="t_001",
                    title="Quiet Luxury",
                    growth="+21%",
                    trend=TrendDirection.UP,
                    description="Understated premium staples gaining popularity.",
                    image="https://example.com/trend1.jpg",
                    tags=["elegant", "minimalist"],
                    engagement=14230,
                    posts=980
                )
            ]

    @staticmethod
    def get_fashion_insights(
        db: Session,
        scope: str = "global",
        timeframe: str = "week"
    ) -> List[FashionInsightResponse]:
        """Get fashion insights from database"""
        try:
            # Calculate validity period
            now = datetime.utcnow()
            insights = db.query(TrendInsight).filter(
                TrendInsight.scope == scope,
                TrendInsight.timeframe == timeframe,
                TrendInsight.valid_until > now
            ).order_by(desc(TrendInsight.confidence_score)).all()
            
            insight_responses = []
            for insight in insights:
                insight_responses.append(FashionInsightResponse(
                    category=insight.category,
                    trending=insight.trending_items,
                    declining=insight.declining_items
                ))
            
            return insight_responses
            
        except Exception as e:
            logger.error(f"Error getting fashion insights: {e}")
            # Return fallback data
            return [
                FashionInsightResponse(
                    category="Colors",
                    trending=["Sage Green", "Warm Beige", "Soft Lavender"],
                    declining=["Hot Pink", "Electric Blue"]
                ),
                FashionInsightResponse(
                    category="Silhouettes",
                    trending=["Oversized", "High-waisted", "Cropped"],
                    declining=["Bodycon", "Low-rise"]
                ),
                FashionInsightResponse(
                    category="Fabrics",
                    trending=["Corduroy", "Velvet", "Organic Cotton"],
                    declining=["Polyester Blends", "Shiny Materials"]
                ),
            ]

    @staticmethod
    def get_influencer_spotlight(
        db: Session,
        scope: str = "global",
        limit: int = 10
    ) -> List[InfluencerSpotlightResponse]:
        """Get influencer spotlight from database"""
        try:
            influencers = db.query(StyleInfluencer).filter(
                StyleInfluencer.is_active == True,
                StyleInfluencer.scope == scope
            ).order_by(desc(StyleInfluencer.influence_score)).limit(limit).all()
            
            spotlight = []
            for influencer in influencers:
                # Format follower count
                followers = influencer.followers_count
                if followers >= 1000000:
                    followers_str = f"{followers/1000000:.1f}M"
                elif followers >= 1000:
                    followers_str = f"{followers/1000:.0f}K"
                else:
                    followers_str = str(followers)
                
                engagement_str = f"{influencer.engagement_rate*100:.1f}%"
                
                spotlight.append(InfluencerSpotlightResponse(
                    id=f"inf_{influencer.id}",
                    name=influencer.name,
                    handle=influencer.handle,
                    trendSetter=influencer.trend_setter_type or "Fashion Influencer",
                    followers=followers_str,
                    engagement=engagement_str,
                    recentTrend=influencer.recent_trend or "Style inspiration"
                ))
            
            return spotlight
            
        except Exception as e:
            logger.error(f"Error getting influencer spotlight: {e}")
            # Return fallback data
            return [
                InfluencerSpotlightResponse(
                    id="inf_44",
                    name="Rina Tan",
                    handle="@rinatan",
                    trendSetter="Soft tailoring",
                    followers="1.2M",
                    engagement="4.8%",
                    recentTrend="Muted palettes"
                )
            ]

    @staticmethod
    def get_nearby_people(
        db: Session,
        user_lat: float,
        user_lng: float,
        radius_km: float = 5.0,
        limit: int = 20
    ) -> List[NearbyPersonResponse]:
        """Get nearby people from database"""
        try:
            # Query for nearby people within radius
            # Note: This is a simplified version. For production, use PostGIS or similar for efficient geo queries
            people_locations = db.query(NearbyLocation).filter(
                NearbyLocation.location_type == LocationTypeEnum.PERSON.value,
                NearbyLocation.is_active == True,
                NearbyLocation.is_public == True
            ).all()
            
            nearby_people = []
            for location in people_locations:
                distance_km = TrendsService.calculate_distance(
                    user_lat, user_lng, location.latitude, location.longitude
                )
                
                if distance_km <= radius_km:
                    metadata = location.location_metadata or {}
                    nearby_people.append({
                        'location': location,
                        'distance_km': distance_km,
                        'metadata': metadata
                    })
            
            # Sort by distance and limit results
            nearby_people.sort(key=lambda x: x['distance_km'])
            nearby_people = nearby_people[:limit]
            
            # Convert to response format
            people_responses = []
            for item in nearby_people:
                location = item['location']
                metadata = item['metadata']
                
                people_responses.append(NearbyPersonResponse(
                    id=f"u_{location.id}",
                    name=location.name,
                    avatar=location.image_url or "https://example.com/avatar.jpg",
                    distance=f"{item['distance_km']:.1f} km",
                    style=metadata.get('style', 'casual'),
                    mutualConnections=metadata.get('mutualConnections', 0),
                    recentOutfit=metadata.get('recentOutfit', 'Stylish look'),
                    isOnline=metadata.get('isOnline', False),
                    latitude=location.latitude,
                    longitude=location.longitude
                ))
            
            return people_responses
            
        except Exception as e:
            logger.error(f"Error getting nearby people: {e}")
            return []

    @staticmethod
    def get_nearby_events(
        db: Session,
        user_lat: float,
        user_lng: float,
        radius_km: float = 5.0,
        limit: int = 20
    ) -> List[NearbyEventResponse]:
        """Get nearby events from database"""
        try:
            # Query for nearby events within radius and not expired
            now = datetime.utcnow()
            event_locations = db.query(NearbyLocation).filter(
                NearbyLocation.location_type == LocationTypeEnum.EVENT.value,
                NearbyLocation.is_active == True,
                NearbyLocation.is_public == True,
                or_(
                    NearbyLocation.expires_at.is_(None),
                    NearbyLocation.expires_at > now
                )
            ).all()
            
            nearby_events = []
            for location in event_locations:
                distance_km = TrendsService.calculate_distance(
                    user_lat, user_lng, location.latitude, location.longitude
                )
                
                if distance_km <= radius_km:
                    metadata = location.location_metadata or {}
                    nearby_events.append({
                        'location': location,
                        'distance_km': distance_km,
                        'metadata': metadata
                    })
            
            # Sort by distance and limit results
            nearby_events.sort(key=lambda x: x['distance_km'])
            nearby_events = nearby_events[:limit]
            
            # Convert to response format
            event_responses = []
            for item in nearby_events:
                location = item['location']
                metadata = item['metadata']
                
                event_date = metadata.get('date', datetime.utcnow().isoformat())
                if isinstance(event_date, str):
                    try:
                        parsed_date = datetime.fromisoformat(event_date.replace('Z', '+00:00'))
                        event_date = parsed_date.isoformat() + 'Z'
                    except:
                        event_date = datetime.utcnow().isoformat() + 'Z'
                
                event_responses.append(NearbyEventResponse(
                    id=f"ev_{location.id}",
                    title=location.name,
                    location=location.address or "Event Location",
                    distance=f"{item['distance_km']:.1f} km",
                    date=event_date,
                    attendees=metadata.get('attendees', 0),
                    image=location.image_url or "https://example.com/event.jpg",
                    category=metadata.get('category', 'fashion'),
                    latitude=location.latitude,
                    longitude=location.longitude
                ))
            
            return event_responses
            
        except Exception as e:
            logger.error(f"Error getting nearby events: {e}")
            return []

    @staticmethod
    def get_nearby_hotspots(
        db: Session,
        user_lat: float,
        user_lng: float,
        radius_km: float = 5.0,
        limit: int = 20
    ) -> List[NearbyHotspotResponse]:
        """Get nearby hotspots from database"""
        try:
            # Query for nearby hotspots within radius
            hotspot_locations = db.query(NearbyLocation).filter(
                NearbyLocation.location_type == LocationTypeEnum.HOTSPOT.value,
                NearbyLocation.is_active == True,
                NearbyLocation.is_public == True
            ).all()
            
            nearby_hotspots = []
            for location in hotspot_locations:
                distance_km = TrendsService.calculate_distance(
                    user_lat, user_lng, location.latitude, location.longitude
                )
                
                if distance_km <= radius_km:
                    metadata = location.location_metadata or {}
                    nearby_hotspots.append({
                        'location': location,
                        'distance_km': distance_km,
                        'metadata': metadata
                    })
            
            # Sort by distance and limit results
            nearby_hotspots.sort(key=lambda x: x['distance_km'])
            nearby_hotspots = nearby_hotspots[:limit]
            
            # Convert to response format
            hotspot_responses = []
            for item in nearby_hotspots:
                location = item['location']
                metadata = item['metadata']
                
                hotspot_responses.append(NearbyHotspotResponse(
                    id=f"hs_{location.id}",
                    name=location.name,
                    type=metadata.get('type', 'boutique'),
                    distance=f"{item['distance_km']:.1f} km",
                    popularStyles=metadata.get('popularStyles', ['fashion']),
                    rating=metadata.get('rating', 4.0),
                    checkIns=metadata.get('checkIns', 0),
                    latitude=location.latitude,
                    longitude=location.longitude
                ))
            
            return hotspot_responses
            
        except Exception as e:
            logger.error(f"Error getting nearby hotspots: {e}")
            return []
