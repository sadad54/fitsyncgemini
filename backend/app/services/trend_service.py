import aiohttp
import json
from typing import Dict, List, Optional
from datetime import datetime, timedelta
from app.external_apis.google_trends import GoogleTrendsClient
from app.core.config import settings
from app.utils.rate_limiter import rate_limiter
from fastapi import HTTPException
import redis.asyncio as redis

class TrendService:
    def __init__(self):
        self.redis = redis.from_url(settings.REDIS_URL)
        self.trends_client = GoogleTrendsClient()
    
    async def get_fashion_trends(
        self,
        category: str = "general",
        timeframe: str = "now 7-d",
        geo: str = "US",
        user_id: str = "system"
    ) -> Dict:
        """Get current fashion trends"""
        
        # Check cache first
        cache_key = f"trends:fashion:{category}:{timeframe}:{geo}"
        cached = await self.redis.get(cache_key)
        if cached:
            return json.loads(cached)
        
        # Rate limiting
        allowed, _ = await rate_limiter.check_rate_limit(
            "trends_api",
            50,  # 50 requests per hour
            3600,
            user_id
        )
        
        if not allowed:
            return {"error": "Rate limit exceeded", "success": False}
        
        try:
            # Fashion trend keywords by category
            trend_keywords = {
                "general": [
                    "fashion trends 2024", "style inspiration", "outfit ideas",
                    "fashion week", "designer collections", "sustainable fashion"
                ],
                "seasonal": [
                    "spring fashion", "summer style", "fall trends", "winter outfits",
                    "seasonal wardrobe", "transitional pieces"
                ],
                "demographics": [
                    "gen z fashion", "millennial style", "professional women fashion",
                    "sustainable fashion", "inclusive fashion", "plus size fashion"
                ],
                "accessories": [
                    "handbag trends", "jewelry trends", "shoe trends",
                    "hat fashion", "belt styles", "watch trends"
                ],
                "colors": [
                    "pantone color year", "trending colors", "color palette fashion",
                    "neutral colors", "bold colors fashion", "pastel trends"
                ]
            }
            
            keywords = trend_keywords.get(category, trend_keywords["general"])
            
            # Get trends data
            trends_data = await self.trends_client.get_trending_searches(
                keywords=keywords[:5],  # Top 5 keywords
                timeframe=timeframe,
                geo=geo
            )
            
            if trends_data.get("success"):
                # Process and enhance trends data
                processed_trends = await self._process_trends_data(
                    trends_data["trends"],
                    category
                )
                
                result = {
                    "success": True,
                    "category": category,
                    "timeframe": timeframe,
                    "geo": geo,
                    "trends": processed_trends,
                    "trend_insights": await self._generate_trend_insights(processed_trends),
                    "updated_at": datetime.utcnow().isoformat()
                }
                
                # Cache for 1 hour
                await self.redis.setex(cache_key, 3600, json.dumps(result))
                return result
            else:
                return {"success": False, "error": "Failed to fetch trends data"}
                
        except Exception as e:
            return {"success": False, "error": f"Trend analysis error: {str(e)}"}
    
    async def get_personalized_trends(
        self,
        user_id: str,
        style_preferences: Dict,
        location: str = "US"
    ) -> Dict:
        """Get personalized fashion trends based on user preferences"""
        
        try:
            # Get user's style archetype and preferences
            style_archetype = style_preferences.get("archetype", "casual")
            preferred_colors = style_preferences.get("colors", [])
            preferred_categories = style_preferences.get("categories", [])
            
            # Get relevant trend categories
            relevant_categories = self._map_style_to_trend_categories(
                style_archetype,
                preferred_categories
            )
            
            # Fetch trends for each relevant category
            personalized_trends = []
            
            for category in relevant_categories:
                category_trends = await self.get_fashion_trends(
                    category=category,
                    geo=location,
                    user_id=user_id
                )
                
                if category_trends.get("success"):
                    # Filter trends based on user preferences
                    filtered_trends = self._filter_trends_by_preferences(
                        category_trends["trends"],
                        style_preferences
                    )
                    personalized_trends.extend(filtered_trends)
            
            # Rank trends by relevance to user
            ranked_trends = self._rank_trends_by_relevance(
                personalized_trends,
                style_preferences
            )
            
            return {
                "success": True,
                "user_style_archetype": style_archetype,
                "personalized_trends": ranked_trends[:10],  # Top 10
                "trend_recommendations": await self._generate_trend_recommendations(
                    ranked_trends,
                    style_preferences
                ),
                "shopping_suggestions": self._generate_trend_shopping_suggestions(
                    ranked_trends[:5]  # Top 5 trends
                )
            }
            
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Personalized trends error: {str(e)}"
            )
    
    async def get_social_fashion_trends(
        self,
        platforms: List[str] = ["instagram", "tiktok", "pinterest"],
        user_id: str = "system"
    ) -> Dict:
        """Get trending fashion from social media platforms"""
        
        cache_key = f"trends:social:{':'.join(platforms)}"
        cached = await self.redis.get(cache_key)
        if cached:
            return json.loads(cached)
        
        try:
            social_trends = {}
            
            # Instagram trends (using hashtag analysis)
            if "instagram" in platforms:
                instagram_trends = await self._get_instagram_trends(user_id)
                social_trends["instagram"] = instagram_trends
            
            # TikTok trends (using trending hashtags)
            if "tiktok" in platforms:
                tiktok_trends = await self._get_tiktok_trends(user_id)
                social_trends["tiktok"] = tiktok_trends
            
            # Pinterest trends (using search trends)
            if "pinterest" in platforms:
                pinterest_trends = await self._get_pinterest_trends(user_id)
                social_trends["pinterest"] = pinterest_trends
            
            # Aggregate and analyze cross-platform trends
            aggregated_trends = self._aggregate_social_trends(social_trends)
            
            result = {
                "success": True,
                "platforms": platforms,
                "social_trends": social_trends,
                "cross_platform_trends": aggregated_trends,
                "trending_hashtags": self._extract_trending_hashtags(social_trends),
                "viral_styles": self._identify_viral_styles(aggregated_trends),
                "updated_at": datetime.utcnow().isoformat()
            }
            
            # Cache for 30 minutes (social trends change quickly)
            await self.redis.setex(cache_key, 1800, json.dumps(result))
            return result
            
        except Exception as e:
            return {"success": False, "error": f"Social trends error: {str(e)}"}
    
    async def analyze_trend_lifecycle(
        self,
        trend_keyword: str,
        timeframe: str = "now 12-m"
    ) -> Dict:
        """Analyze the lifecycle of a specific fashion trend"""
        
        try:
            # Get historical trend data
            trend_history = await self.trends_client.get_trend_over_time(
                keyword=trend_keyword,
                timeframe=timeframe
            )
            
            if not trend_history.get("success"):
                return {"success": False, "error": "Failed to get trend history"}
            
            # Analyze trend phases
            lifecycle_analysis = self._analyze_trend_phases(
                trend_history["data"]
            )
            
            # Predict trend future
            trend_prediction = self._predict_trend_future(
                trend_history["data"],
                lifecycle_analysis
            )
            
            return {
                "success": True,
                "trend": trend_keyword,
                "timeframe": timeframe,
                "lifecycle_phase": lifecycle_analysis["current_phase"],
                "trend_strength": lifecycle_analysis["strength"],
                "peak_period": lifecycle_analysis["peak_period"],
                "predicted_direction": trend_prediction["direction"],
                "adoption_rate": lifecycle_analysis["adoption_rate"],
                "longevity_score": lifecycle_analysis["longevity_score"],
                "recommendations": self._generate_lifecycle_recommendations(
                    lifecycle_analysis,
                    trend_prediction
                )
            }
            
        except Exception as e:
            return {"success": False, "error": f"Lifecycle analysis error: {str(e)}"}
    
    # Helper methods
    
    async def _process_trends_data(self, trends_data: List[Dict], category: str) -> List[Dict]:
        """Process and enhance raw trends data"""
        
        processed = []
        
        for trend in trends_data:
            enhanced_trend = {
                "keyword": trend.get("title", ""),
                "search_volume": trend.get("value", 0),
                "growth_rate": trend.get("growth", 0),
                "category": category,
                "relevance_score": self._calculate_relevance_score(trend),
                "style_tags": self._extract_style_tags(trend.get("title", "")),
                "target_demographic": self._identify_target_demographic(trend),
                "seasonality": self._analyze_seasonality(trend),
                "commercial_potential": self._assess_commercial_potential(trend)
            }
            processed.append(enhanced_trend)
        
        return processed
    
    async def _generate_trend_insights(self, trends: List[Dict]) -> Dict:
        """Generate insights from trends data"""
        
        if not trends:
            return {"message": "No trends data available"}
        
        # Calculate average metrics
        avg_growth = sum(t.get("growth_rate", 0) for t in trends) / len(trends)
        top_categories = {}
        emerging_styles = []
        
        for trend in trends:
            # Category popularity
            category = trend.get("category", "unknown")
            top_categories[category] = top_categories.get(category, 0) + 1
            
            # Emerging styles (high growth, lower volume)
            if (trend.get("growth_rate", 0) > avg_growth * 1.5 and 
                trend.get("search_volume", 0) < 50):
                emerging_styles.append(trend)
        
        return {
            "total_trends_analyzed": len(trends),
            "average_growth_rate": round(avg_growth, 2),
            "top_categories": sorted(top_categories.items(), key=lambda x: x[1], reverse=True)[:3],
            "emerging_styles": emerging_styles[:5],
            "trend_velocity": "high" if avg_growth > 20 else "medium" if avg_growth > 5 else "low",
            "market_sentiment": self._analyze_market_sentiment(trends)
        }
    
    def _map_style_to_trend_categories(
        self,
        style_archetype: str,
        preferred_categories: List[str]
    ) -> List[str]:
        """Map user style to relevant trend categories"""
        
        archetype_mapping = {
            "minimalist": ["colors", "sustainable"],
            "bohemian": ["accessories", "seasonal"],
            "classic": ["general", "professional"],
            "trendy": ["social", "demographics"],
            "edgy": ["street_style", "alternative"],
            "romantic": ["feminine", "accessories"],
            "sporty": ["athleisure", "functional"],
            "casual": ["general", "everyday"]
        }
        
        base_categories = archetype_mapping.get(style_archetype, ["general"])
        
        # Add categories based on user preferences
        if "accessories" in preferred_categories:
            base_categories.append("accessories")
        if "seasonal" in preferred_categories:
            base_categories.append("seasonal")
        
        return list(set(base_categories))  # Remove duplicates
    
    def _filter_trends_by_preferences(
        self,
        trends: List[Dict],
        preferences: Dict
    ) -> List[Dict]:
        """Filter trends based on user preferences"""
        
        filtered = []
        preferred_colors = preferences.get("colors", [])
        style_archetype = preferences.get("archetype", "")
        
        for trend in trends:
            # Filter by color preferences
            trend_colors = self._extract_colors_from_trend(trend.get("keyword", ""))
            if preferred_colors and trend_colors:
                if not any(color in preferred_colors for color in trend_colors):
                    continue
            
            # Filter by style compatibility
            trend_styles = trend.get("style_tags", [])
            archetype_styles = self._get_archetype_styles(style_archetype)
            
            if archetype_styles and trend_styles:
                style_match = any(style in archetype_styles for style in trend_styles)
                if style_match:
                    trend["preference_match_score"] = 0.8
                else:
                    trend["preference_match_score"] = 0.3
            else:
                trend["preference_match_score"] = 0.5
            
            filtered.append(trend)
        
        return filtered
    
    def _rank_trends_by_relevance(
        self,
        trends: List[Dict],
        preferences: Dict
    ) -> List[Dict]:
        """Rank trends by relevance to user"""
        
        for trend in trends:
            relevance_score = (
                trend.get("relevance_score", 0) * 0.3 +
                trend.get("preference_match_score", 0) * 0.4 +
                trend.get("growth_rate", 0) / 100 * 0.3  # Normalize growth rate
            )
            trend["user_relevance_score"] = min(relevance_score, 1.0)
        
        return sorted(trends, key=lambda x: x.get("user_relevance_score", 0), reverse=True)
    
    async def _generate_trend_recommendations(
        self,
        trends: List[Dict],
        preferences: Dict
    ) -> List[Dict]:
        """Generate actionable trend recommendations"""
        
        recommendations = []
        
        for trend in trends[:5]:  # Top 5 trends
            recommendation = {
                "trend": trend.get("keyword", ""),
                "adoption_difficulty": self._assess_adoption_difficulty(trend, preferences),
                "integration_suggestions": self._generate_integration_suggestions(trend),
                "shopping_priorities": self._prioritize_trend_shopping(trend),
                "styling_tips": self._generate_trend_styling_tips(trend),
                "budget_impact": self._estimate_budget_impact(trend),
                "timeline": self._suggest_adoption_timeline(trend)
            }
            recommendations.append(recommendation)
        
        return recommendations
    
    def _generate_trend_shopping_suggestions(self, trends: List[Dict]) -> List[Dict]:
        """Generate shopping suggestions based on trends"""
        
        suggestions = []
        
        for trend in trends:
            suggestion = {
                "trend_keyword": trend.get("keyword", ""),
                "key_pieces": self._identify_key_trend_pieces(trend),
                "price_range": self._estimate_trend_price_range(trend),
                "where_to_shop": self._suggest_shopping_venues(trend),
                "timing": self._suggest_purchase_timing(trend),
                "investment_level": trend.get("commercial_potential", "medium")
            }
            suggestions.append(suggestion)
        
        return suggestions
    
    async def _get_instagram_trends(self, user_id: str) -> Dict:
        """Get Instagram fashion trends (simplified - would use Instagram API)"""
        
        # Simulate Instagram trending hashtags analysis
        trending_hashtags = [
            {"tag": "#OOTD", "posts": 150000000, "growth": 15},
            {"tag": "#Fashion", "posts": 500000000, "growth": 8},
            {"tag": "#Style", "posts": 200000000, "growth": 12},
            {"tag": "#Minimalist", "posts": 25000000, "growth": 25},
            {"tag": "#Sustainable", "posts": 15000000, "growth": 35}
        ]
        
        return {
            "platform": "instagram",
            "trending_hashtags": trending_hashtags,
            "top_styles": ["minimalist", "sustainable", "y2k", "cottagecore"],
            "emerging_aesthetics": ["dark academia", "light academia", "indie sleaze"]
        }
    
    async def _get_tiktok_trends(self, user_id: str) -> Dict:
        """Get TikTok fashion trends (simplified)"""
        
        return {
            "platform": "tiktok",
            "viral_styles": ["coquette", "clean girl", "mob wife", "old money"],
            "trending_challenges": ["#GetReady", "#StyleChallenge", "#ThriftFlip"],
            "popular_creators": ["@fashiontok1", "@styletok2"]  # Anonymized
        }
    
    async def _get_pinterest_trends(self, user_id: str) -> Dict:
        """Get Pinterest fashion trends (simplified)"""
        
        return {
            "platform": "pinterest",
            "trending_searches": [
                {"query": "capsule wardrobe", "growth": 45},
                {"query": "maximalist fashion", "growth": 30},
                {"query": "gender neutral style", "growth": 55}
            ],
            "popular_boards": ["minimalist wardrobe", "sustainable fashion", "vintage style"]
        }
    
    def _aggregate_social_trends(self, social_trends: Dict) -> List[Dict]:
        """Aggregate trends across social platforms"""
        
        aggregated = []
        
        # Find cross-platform trends
        all_styles = []
        for platform, data in social_trends.items():
            styles = data.get("top_styles", []) + data.get("viral_styles", [])
            all_styles.extend(styles)
        
        # Count style frequency across platforms
        style_counts = {}
        for style in all_styles:
            style_counts[style] = style_counts.get(style, 0) + 1
        
        # Create aggregated trend objects
        for style, count in style_counts.items():
            if count > 1:  # Appeared on multiple platforms
                aggregated.append({
                    "style": style,
                    "cross_platform_presence": count,
                    "trend_strength": "strong" if count >= 3 else "moderate",
                    "virality_score": count / len(social_trends)
                })
        
        return sorted(aggregated, key=lambda x: x["cross_platform_presence"], reverse=True)
    
    def _extract_trending_hashtags(self, social_trends: Dict) -> List[str]:
        """Extract all trending hashtags from social data"""
        
        hashtags = []
        
        for platform, data in social_trends.items():
            if platform == "instagram" and "trending_hashtags" in data:
                hashtags.extend([tag["tag"] for tag in data["trending_hashtags"][:5]])
            elif platform == "tiktok" and "trending_challenges" in data:
                hashtags.extend(data["trending_challenges"])
        
        return list(set(hashtags))  # Remove duplicates
    
    def _identify_viral_styles(self, aggregated_trends: List[Dict]) -> List[str]:
        """Identify viral styles across platforms"""
        
        return [
            trend["style"] for trend in aggregated_trends 
            if trend.get("trend_strength") == "strong"
        ][:5]  # Top 5
    
    def _analyze_trend_phases(self, trend_data: List[Dict]) -> Dict:
        """Analyze trend lifecycle phases"""
        
        if not trend_data:
            return {"current_phase": "unknown", "strength": 0}
        
        # Simple trend analysis (would be more sophisticated in real implementation)
        values = [point.get("value", 0) for point in trend_data]
        
        if not values:
            return {"current_phase": "unknown", "strength": 0}
        
        # Calculate trend metrics
        max_value = max(values)
        current_value = values[-1] if values else 0
        avg_value = sum(values) / len(values)
        
        # Determine phase
        if current_value > avg_value * 1.5:
            phase = "growth"
        elif current_value > avg_value * 0.8:
            phase = "peak"
        elif current_value > avg_value * 0.5:
            phase = "decline"
        else:
            phase = "dormant"
        
        return {
            "current_phase": phase,
            "strength": current_value / max_value if max_value > 0 else 0,
            "peak_period": self._find_peak_period(trend_data),
            "adoption_rate": self._calculate_adoption_rate(values),
            "longevity_score": len([v for v in values if v > avg_value]) / len(values)
        }
    
    def _predict_trend_future(
        self,
        trend_data: List[Dict],
        lifecycle_analysis: Dict
    ) -> Dict:
        """Predict future trend direction"""
        
        current_phase = lifecycle_analysis.get("current_phase", "unknown")
        strength = lifecycle_analysis.get("strength", 0)
        
        if current_phase == "growth" and strength > 0.7:
            direction = "continuing_up"
            confidence = 0.8
        elif current_phase == "peak":
            direction = "stabilizing"
            confidence = 0.6
        elif current_phase == "decline":
            direction = "declining"
            confidence = 0.7
        else:
            direction = "uncertain"
            confidence = 0.3
        
        return {
            "direction": direction,
            "confidence": confidence,
            "recommended_action": self._recommend_action_based_on_prediction(direction, strength)
        }
    
    def _generate_lifecycle_recommendations(
        self,
        lifecycle_analysis: Dict,
        prediction: Dict
    ) -> List[str]:
        """Generate recommendations based on trend lifecycle"""
        
        phase = lifecycle_analysis.get("current_phase", "unknown")
        direction = prediction.get("direction", "uncertain")
        
        recommendations = []
        
        if phase == "growth":
            recommendations.extend([
                "Consider adopting this trend early for maximum impact",
                "Start with small, reversible changes",
                "Monitor trend development closely"
            ])
        elif phase == "peak":
            recommendations.extend([
                "Perfect time to fully embrace this trend",
                "Invest in key pieces while widely available",
                "Consider how to make the trend your own"
            ])
        elif phase == "decline":
            recommendations.extend([
                "Look for discounted items from this trend",
                "Focus on timeless elements that will last",
                "Prepare to transition to emerging trends"
            ])
        
        return recommendations

trend_service = TrendService()