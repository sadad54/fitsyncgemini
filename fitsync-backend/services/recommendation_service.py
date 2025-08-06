from typing import List, Dict, Any, Optional
import structlog
import asyncio
from sklearn.metrics.pairwise import cosine_similarity
import numpy as np

from app.services.ml_service import MLService
from app.utils.weather import WeatherService
from app.models.recommendation.style_matcher import StyleMatcher
from app.schemas.recommendation import OutfitRecommendation

logger = structlog.get_logger()

class RecommendationService:
    """Advanced outfit recommendation engine"""
    
    def __init__(self, ml_service: MLService):
        self.ml_service = ml_service
        self.style_matcher = StyleMatcher()
        self.weather_service = WeatherService()
        
    async def generate_outfit_recommendations(self, user_id: str, wardrobe_items: List[str],
                                            occasion: Optional[str] = None,
                                            weather_condition: Optional[str] = None,
                                            style_preference: Optional[str] = None,
                                            color_preference: Optional[List[str]] = None,
                                            limit: int = 5) -> List[OutfitRecommendation]:
        """Generate personalized outfit recommendations"""
        
        try:
            # Get user profile and preferences
            user_profile = await self._get_user_style_profile(user_id)
            
            # Generate outfit combinations
            outfit_combinations = await self._generate_combinations(
                wardrobe_items, user_profile, occasion, weather_condition
            )
            
            # Score and rank combinations
            scored_outfits = await self._score_outfits(
                outfit_combinations, user_profile, style_preference, color_preference
            )
            
            # Apply filters and sorting
            filtered_outfits = self._apply_filters(scored_outfits, occasion, weather_condition)
            
            # Return top recommendations
            return filtered_outfits[:limit]
            
        except Exception as e:
            logger.error(f"Outfit recommendation generation failed: {str(e)}")
            return []
    
    async def get_trending_outfits(self, style: Optional[str] = None, 
                                 season: Optional[str] = None, 
                                 limit: int = 10) -> List[OutfitRecommendation]:
        """Get trending outfit recommendations"""
        
        # Placeholder for trend analysis
        # In production, this would analyze social media trends, fashion shows, etc.
        trending_outfits = [
            {
                "id": f"trend_{i}",
                "name": f"Trending Look {i}",
                "style_tags": ["trendy", "modern"],
                "items": ["item1", "item2", "item3"],
                "trend_score": 0.9 - (i * 0.1),
                "popularity": 1000 - (i * 100)
            }
            for i in range(limit)
        ]
        
        return trending_outfits
    
    async def get_weather_based_recommendations(self, user_id: str, location: str, 
                                              days_ahead: int = 0) -> Dict[str, Any]:
        """Get weather-appropriate outfit recommendations"""
        
        try:
            # Get weather forecast
            weather_data = await self.weather_service.get_weather_forecast(location, days_ahead)
            
            # Get user wardrobe
            user_wardrobe = await self._get_user_wardrobe(user_id)
            
            # Generate weather-appropriate combinations
            recommendations = await self._generate_weather_outfits(
                weather_data, user_wardrobe
            )
            
            return {
                "location": location,
                "weather_forecast": weather_data,
                "outfit_recommendations": recommendations,
                "weather_tips": self._generate_weather_tips(weather_data)
            }
            
        except Exception as e:
            logger.error(f"Weather-based recommendations failed: {str(e)}")
            return {}
    
    async def _get_user_style_profile(self, user_id: str) -> Dict[str, Any]:
        """Get user's style profile and preferences"""
        # Placeholder - in production, query user database
        return {
            "style_archetype": "minimalist",
            "preferred_colors": ["black", "white", "grey", "navy"],
            "body_type": "pear",
            "lifestyle": "professional",
            "fashion_goals": ["versatile", "timeless", "comfortable"]
        }
    
    async def _generate_combinations(self, wardrobe_items: List[str], user_profile: Dict,
                                   occasion: Optional[str], weather_condition: Optional[str]) -> List[Dict]:
        """Generate potential outfit combinations"""
        
        combinations = []
        
        # Simplified combination generation
        # In production, use advanced algorithms for optimal combinations
        for i in range(len(wardrobe_items)):
            for j in range(i+1, len(wardrobe_items)):
                for k in range(j+1, len(wardrobe_items)):
                    combination = {
                        "items": [wardrobe_items[i], wardrobe_items[j], wardrobe_items[k]],
                        "category_balance": self._check_category_balance([
                            wardrobe_items[i], wardrobe_items[j], wardrobe_items[k]
                        ])
                    }
                    
                    if combination["category_balance"]:
                        combinations.append(combination)
        
        return combinations
    
    def _check_category_balance(self, items: List[str]) -> bool:
        """Check if combination has proper category balance"""
        # Simplified category balance check
        # In production, analyze actual item categories
        return len(items) >= 3
    
    async def _score_outfits(self, combinations: List[Dict], user_profile: Dict,
                           style_preference: Optional[str], 
                           color_preference: Optional[List[str]]) -> List[Dict]:
        """Score outfit combinations based on various factors"""
        
        scored_combinations = []
        
        for combination in combinations:
            scores = {
                "style_compatibility": await self._calculate_style_compatibility(
                    combination, user_profile, style_preference
                ),
                "color_harmony": await self._calculate_color_harmony(
                    combination, color_preference
                ),
                "occasion_appropriateness": await self._calculate_occasion_score(
                    combination, user_profile
                ),
                "personal_preference": await self._calculate_personal_preference_score(
                    combination, user_profile
                )
            }
            
            # Calculate weighted total score
            total_score = (
                scores["style_compatibility"] * 0.3 +
                scores["color_harmony"] * 0.25 +
                scores["occasion_appropriateness"] * 0.25 +
                scores["personal_preference"] * 0.2
            )
            
            combination["scores"] = scores
            combination["total_score"] = total_score
            scored_combinations.append(combination)
        
        return sorted(scored_combinations, key=lambda x: x["total_score"], reverse=True)
    
    async def _calculate_style_compatibility(self, combination: Dict, user_profile: Dict,
                                           style_preference: Optional[str]) -> float:
        """Calculate style compatibility score"""
        # Placeholder for sophisticated style matching
        return np.random.uniform(0.6, 0.95)
    
    async def _calculate_color_harmony(self, combination: Dict, 
                                     color_preference: Optional[List[str]]) -> float:
        """Calculate color harmony score"""
        # Placeholder for color theory analysis
        return np.random.uniform(0.7, 0.9)
    
    async def _calculate_occasion_score(self, combination: Dict, user_profile: Dict) -> float:
        """Calculate occasion appropriateness score"""
        # Placeholder for occasion matching
        return np.random.uniform(0.6, 0.9)
    
    async def _calculate_personal_preference_score(self, combination: Dict, 
                                                 user_profile: Dict) -> float:
        """Calculate personal preference score"""
        # Placeholder for personal preference analysis
        return np.random.uniform(0.5, 0.95)
    
    def _apply_filters(self, scored_outfits: List[Dict], occasion: Optional[str],
                      weather_condition: Optional[str]) -> List[OutfitRecommendation]:
        """Apply filters and convert to response format"""
        
        filtered_outfits = []
        
        for outfit in scored_outfits:
            recommendation = OutfitRecommendation(
                id=f"outfit_{len(filtered_outfits)}",
                name=f"Outfit Combination {len(filtered_outfits) + 1}",
                items=outfit["items"],
                style_scores=outfit["scores"],
                total_score=outfit["total_score"],
                description=self._generate_outfit_description(outfit),
                tags=self._generate_outfit_tags(outfit, occasion)
            )
            
            filtered_outfits.append(recommendation)
        
        return filtered_outfits
    
    def _generate_outfit_description(self, outfit: Dict) -> str:
        """Generate descriptive text for outfit"""
        return f"A stylish combination featuring {', '.join(outfit['items'][:3])}"
    
    def _generate_outfit_tags(self, outfit: Dict, occasion: Optional[str]) -> List[str]:
        """Generate relevant tags for outfit"""
        tags = ["recommended", "ai-generated"]
        if occasion:
            tags.append(occasion)
        return tags

def get_recommendation_service() -> RecommendationService:
    return RecommendationService(ml_service=get_ml_service())
