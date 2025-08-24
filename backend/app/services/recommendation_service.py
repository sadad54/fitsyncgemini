from typing import Dict, List, Optional, Tuple
import json
from datetime import datetime, timedelta
from app.external_apis.groq_client import groq_client
from app.external_apis.weather_client import weather_client
from app.services.clothing_service import clothing_service
from app.core.database import db
from fastapi import HTTPException

class RecommendationService:
    def __init__(self):
        self.ai_client = groq_client
        self.weather_client = weather_client
        self.clothing_service = clothing_service
    
    async def get_daily_outfit_recommendations(
        self,
        user_id: str,
        occasion: str = "casual",
        location: Tuple[float, float] = None,
        date: str = None
    ) -> Dict:
        """Get comprehensive daily outfit recommendations"""
        
        try:
            # Get user data
            user_profile = await db.get_user_profile(user_id)
            clothing_items = await db.get_clothing_items(user_id)
            user_preferences = user_profile.data[0] if user_profile.data else {}
            wardrobe = clothing_items.data if clothing_items.data else []
            
            if not wardrobe:
                return {
                    "success": False,
                    "message": "No clothing items found. Please add items to your closet first.",
                    "suggestions": {
                        "action": "add_clothing_items",
                        "recommended_categories": ["tops", "bottoms", "outerwear", "footwear"]
                    }
                }
            
            # Get weather data if location provided
            weather_data = None
            if location:
                lat, lon = location
                weather_data = await self.weather_client.get_current_weather(lat, lon, user_id)
            
            # Get outfit recommendations from AI
            ai_recommendations = await self.ai_client.generate_outfit_recommendations(
                wardrobe,
                occasion,
                weather_data or {},
                user_preferences,
                user_id
            )
            
            if not ai_recommendations.get("success"):
                # Fallback to rule-based recommendations
                fallback_recommendations = await self._generate_fallback_recommendations(
                    wardrobe,
                    occasion,
                    weather_data,
                    user_preferences
                )
                return fallback_recommendations
            
            # Enhance AI recommendations with additional insights
            enhanced_recommendations = await self._enhance_recommendations(
                ai_recommendations,
                weather_data,
                user_preferences,
                occasion
            )
            
            # Save recommendations for learning
            await self._save_recommendation_history(
                user_id,
                enhanced_recommendations,
                occasion,
                weather_data
            )
            
            return enhanced_recommendations
            
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to get outfit recommendations: {str(e)}"
            )
    
    async def get_occasion_specific_recommendations(
        self,
        user_id: str,
        occasion: str,
        additional_context: Dict = None
    ) -> Dict:
        """Get recommendations for specific occasions"""
        
        try:
            # Define occasion requirements
            occasion_requirements = {
                "business_meeting": {
                    "formality_level": 0.9,
                    "required_categories": ["tops", "bottoms", "footwear"],
                    "style_keywords": ["professional", "polished", "conservative"],
                    "color_preferences": ["navy", "black", "gray", "white"],
                    "avoid_categories": ["shorts", "sandals"]
                },
                "date_night": {
                    "formality_level": 0.7,
                    "required_categories": ["tops", "bottoms", "footwear"],
                    "style_keywords": ["elegant", "flattering", "stylish"],
                    "color_preferences": ["black", "burgundy", "navy", "jewel tones"],
                    "special_considerations": ["figure_flattering", "confidence_boosting"]
                },
                "workout": {
                    "formality_level": 0.1,
                    "required_categories": ["activewear"],
                    "style_keywords": ["comfortable", "breathable", "flexible"],
                    "material_preferences": ["moisture-wicking", "stretchy"],
                    "avoid_materials": ["cotton", "heavy fabrics"]
                },
                "casual_weekend": {
                    "formality_level": 0.3,
                    "required_categories": ["tops", "bottoms"],
                    "style_keywords": ["comfortable", "relaxed", "casual"],
                    "versatility": "high"
                },
                "party": {
                    "formality_level": 0.8,
                    "required_categories": ["statement_piece"],
                    "style_keywords": ["fun", "festive", "eye-catching"],
                    "special_considerations": ["photography_friendly", "dancing_appropriate"]
                }
            }
            
            requirements = occasion_requirements.get(occasion, {})
            if not requirements:
                # Generic recommendations
                return await self.get_daily_outfit_recommendations(user_id, occasion)
            
            # Get user's wardrobe
            clothing_items = await db.get_clothing_items(user_id)
            wardrobe = clothing_items.data if clothing_items.data else []
            
            # Filter items based on occasion requirements
            suitable_items = self._filter_items_by_occasion(wardrobe, requirements)
            
            if not suitable_items:
                return {
                    "success": False,
                    "message": f"No suitable items found for {occasion}",
                    "shopping_suggestions": self._generate_shopping_suggestions(requirements)
                }
            
            # Generate targeted recommendations
            recommendations = await self._generate_targeted_recommendations(
                suitable_items,
                requirements,
                additional_context or {}
            )
            
            return {
                "success": True,
                "occasion": occasion,
                "recommendations": recommendations,
                "occasion_insights": {
                    "key_requirements": requirements.get("style_keywords", []),
                    "formality_level": requirements.get("formality_level", 0.5),
                    "special_tips": self._get_occasion_tips(occasion)
                }
            }
            
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to get occasion-specific recommendations: {str(e)}"
            )
    
    async def get_personalized_style_insights(self, user_id: str) -> Dict:
        """Generate personalized style insights and improvement suggestions"""
        
        try:
            # Get user's outfit history and preferences
            outfit_history = await db.get_user_outfit_history(user_id, limit=50)
            favorite_outfits = await db.get_user_favorite_outfits(user_id)
            clothing_items = await db.get_clothing_items(user_id)
            user_profile = await db.get_user_profile(user_id)
            
            wardrobe_data = clothing_items.data if clothing_items.data else []
            outfit_data = outfit_history.data if outfit_history.data else []
            favorites_data = favorite_outfits.data if favorite_outfits.data else []
            profile_data = user_profile.data[0] if user_profile.data else {}
            
            # Analyze style patterns
            style_analysis = await self._analyze_style_patterns(
                wardrobe_data,
                outfit_data,
                favorites_data,
                profile_data
            )
            
            # Generate improvement suggestions
            improvement_suggestions = await self._generate_improvement_suggestions(
                style_analysis,
                wardrobe_data,
                profile_data
            )
            
            # Create style evolution roadmap
            style_roadmap = self._create_style_roadmap(
                style_analysis,
                improvement_suggestions,
                profile_data
            )
            
            return {
                "success": True,
                "style_profile": {
                    "dominant_style": style_analysis.get("dominant_style"),
                    "style_consistency": style_analysis.get("consistency_score"),
                    "color_palette": style_analysis.get("preferred_colors"),
                    "formality_preference": style_analysis.get("avg_formality"),
                    "style_evolution": style_analysis.get("style_evolution")
                },
                "wardrobe_insights": {
                    "total_pieces": len(wardrobe_data),
                    "category_distribution": style_analysis.get("category_distribution"),
                    "utilization_rate": style_analysis.get("utilization_rate"),
                    "versatility_score": style_analysis.get("versatility_score")
                },
                "improvement_suggestions": improvement_suggestions,
                "style_roadmap": style_roadmap,
                "next_actions": self._prioritize_next_actions(improvement_suggestions)
            }
            
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to generate style insights: {str(e)}"
            )
    
    async def get_seasonal_wardrobe_plan(
        self,
        user_id: str,
        season: str,
        budget_range: str = "medium"
    ) -> Dict:
        """Generate seasonal wardrobe planning recommendations"""
        
        try:
            # Get current wardrobe
            clothing_items = await db.get_clothing_items(user_id)
            user_profile = await db.get_user_profile(user_id)
            
            wardrobe = clothing_items.data if clothing_items.data else []
            profile = user_profile.data[0] if user_profile.data else {}
            
            # Analyze seasonal needs
            seasonal_analysis = self._analyze_seasonal_wardrobe(wardrobe, season)
            
            # Generate seasonal plan
            seasonal_plan = {
                "season": season,
                "current_coverage": seasonal_analysis["coverage_score"],
                "essential_gaps": seasonal_analysis["missing_essentials"],
                "shopping_priorities": self._prioritize_seasonal_shopping(
                    seasonal_analysis["gaps"],
                    budget_range
                ),
                "outfit_themes": self._generate_seasonal_outfit_themes(season, profile),
                "color_palette": self._get_seasonal_color_palette(season, profile),
                "storage_suggestions": self._generate_storage_suggestions(wardrobe, season),
                "budget_breakdown": self._create_budget_breakdown(
                    seasonal_analysis["gaps"],
                    budget_range
                )
            }
            
            return {
                "success": True,
                "seasonal_plan": seasonal_plan,
                "timeline": self._create_seasonal_timeline(seasonal_plan),
                "tips": self._get_seasonal_tips(season)
            }
            
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to generate seasonal plan: {str(e)}"
            )
    
    # Helper methods
    
    async def _generate_fallback_recommendations(
        self,
        wardrobe: List[Dict],
        occasion: str,
        weather_data: Dict = None,
        user_preferences: Dict = None
    ) -> Dict:
        """Generate rule-based recommendations when AI fails"""
        
        # Group items by category
        items_by_category = {}
        for item in wardrobe:
            category = item.get("category", "unknown")
            if category not in items_by_category:
                items_by_category[category] = []
            items_by_category[category].append(item)
        
        recommendations = []
        
        # Basic outfit structures
        outfit_templates = [
            {
                "name": "Classic Casual",
                "structure": ["tops", "bottoms", "footwear"],
                "style": "casual"
            },
            {
                "name": "Layered Look",
                "structure": ["tops", "outerwear", "bottoms", "footwear"],
                "style": "layered"
            },
            {
                "name": "Dress & Layer",
                "structure": ["dresses", "outerwear", "footwear"],
                "style": "feminine"
            }
        ]
        
        for template in outfit_templates:
            outfit_items = []
            missing_categories = []
            
            for category in template["structure"]:
                if category in items_by_category and items_by_category[category]:
                    # Pick highest rated or most recently added item
                    best_item = max(
                        items_by_category[category],
                        key=lambda x: x.get("user_rating", 0)
                    )
                    outfit_items.append(best_item)
                else:
                    missing_categories.append(category)
            
            if len(outfit_items) >= 2:  # At least 2 items for a valid outfit
                recommendation = {
                    "name": template["name"],
                    "items": [item["id"] for item in outfit_items],
                    "item_details": outfit_items,
                    "style_description": f"{template['style']} outfit",
                    "confidence_score": 0.7 - (len(missing_categories) * 0.1),
                    "missing_pieces": missing_categories,
                    "weather_appropriate": self._check_weather_appropriateness(
                        outfit_items, weather_data
                    )
                }
                recommendations.append(recommendation)
        
        return {
            "success": True,
            "recommendations": recommendations[:3],  # Top 3
            "method": "rule_based",
            "message": "Generated using fashion rules (AI unavailable)"
        }
    
    async def _enhance_recommendations(
        self,
        ai_recommendations: Dict,
        weather_data: Dict = None,
        user_preferences: Dict = None,
        occasion: str = "casual"
    ) -> Dict:
        """Enhance AI recommendations with additional context"""
        
        enhanced = ai_recommendations.copy()
        
        for recommendation in enhanced.get("recommendations", []):
            # Add weather context
            if weather_data:
                recommendation["weather_analysis"] = self._analyze_weather_fit(
                    recommendation,
                    weather_data
                )
            
            # Add styling alternatives
            recommendation["styling_alternatives"] = await self._generate_styling_alternatives(
                recommendation["items"]
            )
            
            # Add shopping suggestions for missing pieces
            if "missing_pieces" in recommendation:
                recommendation["shopping_suggestions"] = self._generate_item_shopping_suggestions(
                    recommendation["missing_pieces"],
                    user_preferences
                )
        
        # Add overall insights
        enhanced["enhanced_insights"] = {
            "weather_summary": self._create_weather_summary(weather_data) if weather_data else None,
            "occasion_fit": self._analyze_occasion_fit(enhanced["recommendations"], occasion),
            "style_consistency": self._calculate_recommendation_consistency(enhanced["recommendations"])
        }
        
        return enhanced
    
    def _filter_items_by_occasion(self, wardrobe: List[Dict], requirements: Dict) -> List[Dict]:
        """Filter wardrobe items suitable for specific occasion"""
        
        suitable_items = []
        
        for item in wardrobe:
            item_analysis = item.get("ml_analysis", {}).get("style_insights", {})
            
            # Check formality level
            item_formality = item_analysis.get("formality_level", 0.5)
            required_formality = requirements.get("formality_level", 0.5)
            formality_tolerance = 0.3
            
            if abs(item_formality - required_formality) > formality_tolerance:
                continue
            
            # Check category requirements
            required_categories = requirements.get("required_categories", [])
            avoid_categories = requirements.get("avoid_categories", [])
            item_category = item.get("category", "")
            
            if required_categories and item_category not in required_categories:
                continue
            
            if item_category in avoid_categories:
                continue
            
            # Check color preferences
            preferred_colors = requirements.get("color_preferences", [])
            item_colors = item.get("colors", [])
            
            if preferred_colors and not any(color in preferred_colors for color in item_colors):
                continue
            
            suitable_items.append(item)
        
        return suitable_items
    
    async def _generate_targeted_recommendations(
        self,
        suitable_items: List[Dict],
        requirements: Dict,
        context: Dict
    ) -> List[Dict]:
        """Generate recommendations for specific requirements"""
        
        recommendations = []
        
        # Group by category
        by_category = {}
        for item in suitable_items:
            category = item.get("category", "unknown")
            if category not in by_category:
                by_category[category] = []
            by_category[category].append(item)
        
        # Generate combinations
        required_cats = requirements.get("required_categories", [])
        
        if len(required_cats) >= 2:
            # Multi-item outfits
            from itertools import product
            
            category_items = []
            for cat in required_cats:
                if cat in by_category:
                    category_items.append(by_category[cat][:3])  # Top 3 per category
                else:
                    category_items.append([])  # Missing category
            
            if all(category_items):  # All categories have items
                for combination in product(*category_items):
                    if len(combination) >= 2:
                        recommendation = {
                            "name": f"Targeted {requirements.get('style_keywords', [''])[0]} Look",
                            "items": [item["id"] for item in combination],
                            "item_details": list(combination),
                            "confidence_score": 0.8,
                            "occasion_fit": "high",
                            "styling_notes": requirements.get("style_keywords", [])
                        }
                        recommendations.append(recommendation)
                        
                        if len(recommendations) >= 3:
                            break
        
        return recommendations[:5]  # Top 5
    
    def _generate_shopping_suggestions(self, requirements: Dict) -> List[Dict]:
        """Generate shopping suggestions based on requirements"""
        
        suggestions = []
        
        for category in requirements.get("required_categories", []):
            suggestion = {
                "category": category,
                "style_requirements": requirements.get("style_keywords", []),
                "color_preferences": requirements.get("color_preferences", []),
                "formality_level": requirements.get("formality_level", 0.5),
                "budget_range": "medium",
                "shopping_tips": self._get_category_shopping_tips(category)
            }
            suggestions.append(suggestion)
        
        return suggestions
    
    def _get_occasion_tips(self, occasion: str) -> List[str]:
        """Get styling tips for specific occasions"""
        
        tips_map = {
            "business_meeting": [
                "Ensure clothes are well-fitted and wrinkle-free",
                "Stick to classic, conservative styles",
                "Keep accessories minimal and professional",
                "Choose closed-toe shoes"
            ],
            "date_night": [
                "Wear something that makes you feel confident",
                "Consider the venue when choosing formality level",
                "Add one special or unique element",
                "Ensure comfort for the planned activities"
            ],
            "workout": [
                "Choose moisture-wicking fabrics",
                "Ensure freedom of movement",
                "Layer for temperature changes",
                "Don't forget supportive undergarments"
            ],
            "party": [
                "Consider the lighting and photography",
                "Choose fabrics that won't wrinkle easily",
                "Add fun accessories or statement pieces",
                "Ensure you can move and dance comfortably"
            ]
        }
        
        return tips_map.get(occasion, ["Choose pieces that make you feel confident"])
    
    async def _analyze_style_patterns(
        self,
        wardrobe: List[Dict],
        outfit_history: List[Dict],
        favorites: List[Dict],
        profile: Dict
    ) -> Dict:
        """Analyze user's style patterns and preferences"""
        
        analysis = {
            "dominant_style": "casual",
            "consistency_score": 0.7,
            "preferred_colors": [],
            "avg_formality": 0.5,
            "category_distribution": {},
            "utilization_rate": 0.6,
            "versatility_score": 0.7,
            "style_evolution": []
        }
        
        if not wardrobe:
            return analysis
        
        # Analyze color preferences
        color_counts = {}
        formality_levels = []
        
        for item in wardrobe:
            # Colors
            for color in item.get("colors", []):
                color_counts[color] = color_counts.get(color, 0) + 1
            
            # Formality
            ml_analysis = item.get("ml_analysis", {}).get("style_insights", {})
            formality = ml_analysis.get("formality_level", 0.5)
            formality_levels.append(formality)
        
        # Preferred colors (top 5)
        analysis["preferred_colors"] = sorted(
            color_counts.items(), 
            key=lambda x: x[1], 
            reverse=True
        )[:5]
        
        # Average formality
        if formality_levels:
            analysis["avg_formality"] = sum(formality_levels) / len(formality_levels)
        
        # Category distribution
        category_counts = {}
        for item in wardrobe:
            category = item.get("category", "unknown")
            category_counts[category] = category_counts.get(category, 0) + 1
        
        total_items = len(wardrobe)
        analysis["category_distribution"] = {
            cat: count / total_items for cat, count in category_counts.items()
        }
        
        # Analyze favorites for style insights
        if favorites:
            favorite_styles = []
            for fav in favorites:
                outfit_items = fav.get("items", [])
                for item in outfit_items:
                    item_style = item.get("ml_analysis", {}).get("style_insights", {}).get("style_category", "")
                    if item_style:
                        favorite_styles.append(item_style)
            
            if favorite_styles:
                analysis["dominant_style"] = max(set(favorite_styles), key=favorite_styles.count)
        
        return analysis
    
    async def _generate_improvement_suggestions(
        self,
        style_analysis: Dict,
        wardrobe: List[Dict],
        profile: Dict
    ) -> List[Dict]:
        """Generate personalized improvement suggestions"""
        
        suggestions = []
        
        # Color palette suggestions
        preferred_colors = [color[0] for color in style_analysis.get("preferred_colors", [])]
        if len(preferred_colors) < 3:
            suggestions.append({
                "type": "color_expansion",
                "priority": "medium",
                "title": "Expand Your Color Palette",
                "description": "Adding more colors will increase outfit versatility",
                "action_items": [
                    "Try incorporating neutral colors like navy or gray",
                    "Experiment with one new accent color",
                    "Consider colors that complement your skin tone"
                ]
            })
        
        # Category balance
        category_dist = style_analysis.get("category_distribution", {})
        if category_dist.get("tops", 0) < 0.3:
            suggestions.append({
                "type": "wardrobe_balance",
                "priority": "high",
                "title": "Build Your Tops Collection",
                "description": "More variety in tops will create more outfit options",
                "action_items": [
                    "Add 2-3 versatile blouses or shirts",
                    "Include both casual and dressier options",
                    "Consider different necklines and sleeves"
                ]
            })
        
        # Style consistency
        if style_analysis.get("consistency_score", 0) < 0.6:
            suggestions.append({
                "type": "style_consistency",
                "priority": "medium",
                "title": "Define Your Personal Style",
                "description": "Creating a more cohesive style will make getting dressed easier",
                "action_items": [
                    "Identify your style goals and preferences",
                    "Focus on pieces that work together",
                    "Consider creating a style mood board"
                ]
            })
        
        return suggestions
    
    def _create_style_roadmap(
        self,
        analysis: Dict,
        suggestions: List[Dict],
        profile: Dict
    ) -> Dict:
        """Create a personalized style evolution roadmap"""
        
        return {
            "current_level": self._assess_style_level(analysis),
            "target_level": profile.get("style_goals", "confident_casual"),
            "timeline": "3-6 months",
            "phases": [
                {
                    "phase": 1,
                    "title": "Foundation Building",
                    "duration": "Month 1-2",
                    "goals": ["Establish core wardrobe pieces", "Define color palette"],
                    "key_actions": [s for s in suggestions if s.get("priority") == "high"]
                },
                {
                    "phase": 2,
                    "title": "Style Refinement",
                    "duration": "Month 3-4",
                    "goals": ["Experiment with trends", "Develop signature style"],
                    "key_actions": [s for s in suggestions if s.get("priority") == "medium"]
                },
                {
                    "phase": 3,
                    "title": "Style Mastery",
                    "duration": "Month 5-6",
                    "goals": ["Personal style confidence", "Advanced styling skills"],
                    "key_actions": ["Experiment with accessories", "Try new combinations"]
                }
            ]
        }
    
    def _prioritize_next_actions(self, suggestions: List[Dict]) -> List[str]:
        """Prioritize immediate next actions"""
        
        high_priority = [s for s in suggestions if s.get("priority") == "high"]
        
        next_actions = []
        for suggestion in high_priority[:3]:  # Top 3 high priority
            next_actions.extend(suggestion.get("action_items", [])[:2])  # Top 2 actions each
        
        return next_actions[:5]  # Max 5 next actions
    
    async def _save_recommendation_history(
        self,
        user_id: str,
        recommendations: Dict,
        occasion: str,
        weather_data: Dict = None
    ):
        """Save recommendation history for learning"""
        
        try:
            history_data = {
                "user_id": user_id,
                "occasion": occasion,
                "weather_conditions": weather_data,
                "recommendations": recommendations,
                "timestamp": datetime.utcnow()
            }
            
            await db.create_recommendation_history(history_data)
            
        except Exception as e:
            # Don't fail the main request if history saving fails
            print(f"Failed to save recommendation history: {str(e)}")

recommendation_service = RecommendationService()