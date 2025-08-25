from typing import Dict, List, Optional
import uuid
from app.external_apis.google_vision import google_vision_client
from app.external_apis.groq_client import groq_client
from app.core.database import db
from app.utils.image_utils import process_and_upload_image
from fastapi import HTTPException

class ClothingService:
    def __init__(self):
        self.vision_client = google_vision_client
        self.ai_client = groq_client
    
    async def create_clothing_item(
        self,
        user_id: str,
        name: str,
        image_data: bytes,
        additional_info: Dict = None
    ) -> Dict:
        """Create clothing item with AI analysis"""
        
        try:
            # Step 1: Analyze image with Google Vision
            vision_analysis = await self.vision_client.analyze_clothing_item(image_data, user_id)
            
            # Step 2: Upload image to storage
            image_filename = f"clothing-items/{user_id}/{uuid.uuid4()}.jpg"
            image_url = await process_and_upload_image(image_data, image_filename)
            
            # Step 3: Get user preferences for AI analysis
            user_profile = await db.get_user_profile(user_id)
            user_preferences = user_profile.data[0] if user_profile.data else {}
            
            # Step 4: Enhanced AI analysis with Groq
            ai_analysis = await self.ai_client.analyze_style_and_outfit(
                image_data,
                user_preferences,
                analysis_type="comprehensive",
                user_id=user_id
            )
            
            # Step 5: Combine analyses
            combined_analysis = self._combine_analyses(vision_analysis, ai_analysis)
            
            # Step 6: Create clothing item record
            clothing_data = {
                "user_id": user_id,
                "name": name,
                "category": vision_analysis.get("category", "unknown"),
                "sub_category": vision_analysis.get("sub_category", "general"),
                "image_url": image_url,
                "colors": vision_analysis.get("colors", []),
                "ml_confidence": vision_analysis.get("confidence", 0.0),
                "ml_analysis": combined_analysis,
                **(additional_info or {})  # ✅ valid syntax
            }
            
            result = await db.create_clothing_item(clothing_data)
            
            return {
                "success": True,
                "clothing_item": result.data[0],
                "ai_insights": combined_analysis.get("style_insights", {}),
                "styling_suggestions": combined_analysis.get("styling_suggestions", [])
            }
            
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to create clothing item: {str(e)}"
            )
    
    async def analyze_wardrobe_compatibility(
        self,
        user_id: str,
        item_id: str = None
    ) -> Dict:
        """Analyze wardrobe compatibility and suggest combinations"""
        
        try:
            # Get user's clothing items
            clothing_items = await db.get_clothing_items(user_id)
            
            if not clothing_items.data:
                return {"message": "No clothing items found"}
            
            # Get user style profile
            user_profile = await db.get_user_profile(user_id)
            user_preferences = user_profile.data[0] if user_profile.data else {}
            
            # Analyze compatibility between items
            compatibility_matrix = await self._build_compatibility_matrix(
                clothing_items.data,
                user_preferences,
                user_id
            )
            
            # Generate outfit suggestions
            outfit_suggestions = await self._generate_outfit_combinations(
                clothing_items.data,
                compatibility_matrix,
                user_preferences
            )
            
            return {
                "success": True,
                "compatibility_analysis": compatibility_matrix,
                "outfit_suggestions": outfit_suggestions,
                "wardrobe_insights": {
                    "total_items": len(clothing_items.data),
                    "categories": self._analyze_wardrobe_distribution(clothing_items.data),
                    "color_palette": self._analyze_color_distribution(clothing_items.data),
                    "style_consistency": self._calculate_style_consistency(clothing_items.data),
                    "missing_essentials": self._identify_missing_essentials(clothing_items.data)
                }
            }
            
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Wardrobe analysis failed: {str(e)}"
            )
    
    async def get_smart_clothing_recommendations(
        self,
        user_id: str,
        occasion: str = None,
        weather: Dict = None,
        budget_range: str = None
    ) -> Dict:
        """Get AI-powered clothing recommendations"""
        
        try:
            # Get user's current wardrobe
            clothing_items = await db.get_clothing_items(user_id)
            user_profile = await db.get_user_profile(user_id)
            
            wardrobe_data = clothing_items.data if clothing_items.data else []
            user_preferences = user_profile.data[0] if user_profile.data else {}
            
            # Analyze wardrobe gaps
            wardrobe_analysis = self._analyze_wardrobe_gaps(wardrobe_data)
            
            # Generate recommendations using AI
            recommendations = await self.ai_client.generate_outfit_recommendations(
                wardrobe_data,
                occasion or "casual",
                weather or {},
                user_preferences,
                user_id
            )
            
            # Enhance with shopping suggestions
            enhanced_recommendations = await self._enhance_with_shopping_suggestions(
                recommendations,
                wardrobe_analysis,
                budget_range,
                user_preferences
            )
            
            return enhanced_recommendations
            
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Recommendation generation failed: {str(e)}"
            )
    
    def _combine_analyses(self, vision_analysis: Dict, ai_analysis: Dict) -> Dict:
        """Combine Google Vision and Groq analyses"""
        
        return {
            "vision_analysis": vision_analysis,
            "ai_analysis": ai_analysis.get("analysis", {}),
            "combined_confidence": (
                vision_analysis.get("confidence", 0) + 
                ai_analysis.get("analysis", {}).get("overall_score", 0)
            ) / 2,
            "style_insights": ai_analysis.get("analysis", {}).get("style_analysis", {}),
            "styling_suggestions": ai_analysis.get("analysis", {}).get("coordination", {}),
            "trend_relevance": ai_analysis.get("analysis", {}).get("trend_analysis", {}),
            "personalization": ai_analysis.get("analysis", {}).get("personalization", {})
        }
    
    async def _build_compatibility_matrix(
        self,
        clothing_items: List[Dict],
        user_preferences: Dict,
        user_id: str
    ) -> Dict:
        """Build compatibility matrix between clothing items"""
        
        compatibility = {}
        
        for i, item1 in enumerate(clothing_items):
            item1_id = item1["id"]
            compatibility[item1_id] = {}
            
            for j, item2 in enumerate(clothing_items):
                if i >= j:  # Skip same item and duplicates
                    continue
                    
                item2_id = item2["id"]
                
                # Calculate compatibility score
                score = self._calculate_item_compatibility(item1, item2, user_preferences)
                compatibility[item1_id][item2_id] = score
        
        return compatibility
    
    def _calculate_item_compatibility(
        self,
        item1: Dict,
        item2: Dict,
        user_preferences: Dict
    ) -> float:
        """Calculate compatibility score between two items"""
        
        score = 0.0
        
        # Category compatibility
        if self._categories_compatible(item1["category"], item2["category"]):
            score += 0.3
        
        # Color compatibility
        color_score = self._calculate_color_compatibility(
            item1.get("colors", []),
            item2.get("colors", [])
        )
        score += color_score * 0.4
        
        # Style compatibility (from ML analysis)
        style_score = self._calculate_style_compatibility(item1, item2)
        score += style_score * 0.3
        
        return min(score, 1.0)
    
    def _categories_compatible(self, cat1: str, cat2: str) -> bool:
        """Check if categories are compatible for outfit combinations"""
        
        compatible_combinations = {
            "tops": ["bottoms", "outerwear", "accessories"],
            "bottoms": ["tops", "outerwear", "footwear", "accessories"],
            "dresses": ["outerwear", "footwear", "accessories"],
            "outerwear": ["tops", "bottoms", "dresses", "accessories"],
            "footwear": ["bottoms", "dresses", "accessories"],
            "accessories": ["tops", "bottoms", "dresses", "outerwear", "footwear"]
        }
        
        return cat2 in compatible_combinations.get(cat1, [])
    
    def _calculate_color_compatibility(self, colors1: List[str], colors2: List[str]) -> float:
        """Calculate color compatibility between two items"""
        
        if not colors1 or not colors2:
            return 0.5  # Neutral score if no color info
        
        # Color harmony rules
        harmony_rules = {
            "complementary": ["red-green", "blue-orange", "yellow-purple"],
            "analogous": ["red-orange", "orange-yellow", "yellow-green", "green-blue", "blue-purple", "purple-red"],
            "neutral": ["black", "white", "gray", "beige", "brown", "navy"]
        }
        
        # Check for neutral colors (always compatible)
        neutral_colors = harmony_rules["neutral"]
        if any(c in neutral_colors for c in colors1) or any(c in neutral_colors for c in colors2):
            return 0.8
        
        # Check for direct color matches
        if any(c in colors2 for c in colors1):
            return 0.9
        
        # Check for complementary colors
        for color1 in colors1:
            for color2 in colors2:
                if f"{color1}-{color2}" in harmony_rules["complementary"] or f"{color2}-{color1}" in harmony_rules["complementary"]:
                    return 0.8
        
        # Check for analogous colors
        for color1 in colors1:
            for color2 in colors2:
                if f"{color1}-{color2}" in harmony_rules["analogous"] or f"{color2}-{color1}" in harmony_rules["analogous"]:
                    return 0.7
        
        return 0.5  # Neutral compatibility
    
    def _calculate_style_compatibility(self, item1: Dict, item2: Dict) -> float:
        """Calculate style compatibility between items"""
        
        # Extract style information from ML analysis
        item1_style = item1.get("ml_analysis", {}).get("style_insights", {})
        item2_style = item2.get("ml_analysis", {}).get("style_insights", {})
        
        if not item1_style or not item2_style:
            return 0.5
        
        # Compare style attributes
        compatibility_factors = []
        
        # Formality level
        formality1 = item1_style.get("formality_level", 0.5)
        formality2 = item2_style.get("formality_level", 0.5)
        formality_compat = 1 - abs(formality1 - formality2)
        compatibility_factors.append(formality_compat)
        
        # Style category
        style1 = item1_style.get("style_category", "")
        style2 = item2_style.get("style_category", "")
        if style1 == style2:
            compatibility_factors.append(0.9)
        elif style1 and style2:
            compatibility_factors.append(0.6)  # Different but compatible
        
        return sum(compatibility_factors) / len(compatibility_factors) if compatibility_factors else 0.5
    
    async def _generate_outfit_combinations(
        self,
        clothing_items: List[Dict],
        compatibility_matrix: Dict,
        user_preferences: Dict
    ) -> List[Dict]:
        """Generate outfit combinations based on compatibility"""
        
        outfit_combinations = []
        
        # Group items by category
        items_by_category = {}
        for item in clothing_items:
            category = item["category"]
            if category not in items_by_category:
                items_by_category[category] = []
            items_by_category[category].append(item)
        
        # Generate combinations for different outfit types
        if "tops" in items_by_category and "bottoms" in items_by_category:
            outfit_combinations.extend(
                self._generate_top_bottom_combinations(
                    items_by_category["tops"],
                    items_by_category["bottoms"],
                    compatibility_matrix,
                    items_by_category.get("outerwear", []),
                    items_by_category.get("accessories", [])
                )
            )
        
        if "dresses" in items_by_category:
            outfit_combinations.extend(
                self._generate_dress_combinations(
                    items_by_category["dresses"],
                    items_by_category.get("outerwear", []),
                    items_by_category.get("accessories", []),
                    compatibility_matrix
                )
            )
        
        # Sort by compatibility score and return top combinations
        sorted_combinations = sorted(
            outfit_combinations,
            key=lambda x: x.get("compatibility_score", 0),
            reverse=True
        )
        
        return sorted_combinations[:10]  # Return top 10 combinations
    
    def _generate_top_bottom_combinations(
        self,
        tops: List[Dict],
        bottoms: List[Dict],
        compatibility_matrix: Dict,
        outerwear: List[Dict] = None,
        accessories: List[Dict] = None
    ) -> List[Dict]:
        """Generate top + bottom outfit combinations"""
        
        combinations = []
        
        for top in tops:
            for bottom in bottoms:
                # Calculate base compatibility
                compat_score = compatibility_matrix.get(top["id"], {}).get(bottom["id"], 0.5)
                
                combination = {
                    "type": "casual",
                    "items": [top, bottom],
                    "item_ids": [top["id"], bottom["id"]],
                    "compatibility_score": compat_score,
                    "style_description": f"{top['name']} with {bottom['name']}",
                    "color_palette": list(set(top.get("colors", []) + bottom.get("colors", []))),
                    "occasions": self._determine_occasions(top, bottom)
                }
                
                # Add outerwear if compatible
                if outerwear:
                    best_outerwear = self._find_best_matching_item(
                        [top, bottom], outerwear, compatibility_matrix
                    )
                    if best_outerwear:
                        combination["items"].append(best_outerwear)
                        combination["item_ids"].append(best_outerwear["id"])
                
                # Add accessories if compatible
                if accessories:
                    compatible_accessories = self._find_compatible_accessories(
                        combination["items"], accessories, compatibility_matrix
                    )
                    combination["items"].extend(compatible_accessories[:2])  # Max 2 accessories
                    combination["item_ids"].extend([acc["id"] for acc in compatible_accessories[:2]])
                
                combinations.append(combination)
        
        return combinations
    
    def _generate_dress_combinations(
        self,
        dresses: List[Dict],
        outerwear: List[Dict] = None,
        accessories: List[Dict] = None,
        compatibility_matrix: Dict = None
    ) -> List[Dict]:
        """Generate dress-based outfit combinations"""
        
        combinations = []
        
        for dress in dresses:
            combination = {
                "type": "dress",
                "items": [dress],
                "item_ids": [dress["id"]],
                "compatibility_score": 0.8,  # Base score for dress outfits
                "style_description": f"Dress outfit featuring {dress['name']}",
                "color_palette": dress.get("colors", []),
                "occasions": self._determine_dress_occasions(dress)
            }
            
            # Add complementary outerwear
            if outerwear:
                best_outerwear = self._find_best_matching_item(
                    [dress], outerwear, compatibility_matrix
                )
                if best_outerwear:
                    combination["items"].append(best_outerwear)
                    combination["item_ids"].append(best_outerwear["id"])
            
            # Add accessories
            if accessories:
                compatible_accessories = self._find_compatible_accessories(
                    [dress], accessories, compatibility_matrix
                )
                combination["items"].extend(compatible_accessories[:3])  # Max 3 accessories for dresses
                combination["item_ids"].extend([acc["id"] for acc in compatible_accessories[:3]])
            
            combinations.append(combination)
        
        return combinations
    
    def _find_best_matching_item(
        self,
        base_items: List[Dict],
        candidate_items: List[Dict],
        compatibility_matrix: Dict
    ) -> Optional[Dict]:
        """Find the best matching item from candidates"""
        
        best_item = None
        best_score = 0
        
        for candidate in candidate_items:
            total_score = 0
            for base_item in base_items:
                score = compatibility_matrix.get(base_item["id"], {}).get(candidate["id"], 0)
                total_score += score
            
            avg_score = total_score / len(base_items)
            if avg_score > best_score:
                best_score = avg_score
                best_item = candidate
        
        return best_item if best_score > 0.6 else None
    
    def _find_compatible_accessories(
        self,
        base_items: List[Dict],
        accessories: List[Dict],
        compatibility_matrix: Dict
    ) -> List[Dict]:
        """Find compatible accessories for the outfit"""
        
        compatible = []
        
        for accessory in accessories:
            total_score = 0
            for base_item in base_items:
                score = compatibility_matrix.get(base_item["id"], {}).get(accessory["id"], 0.5)
                total_score += score
            
            avg_score = total_score / len(base_items)
            if avg_score > 0.6:
                compatible.append(accessory)
        
        # Sort by compatibility and return
        return sorted(compatible, key=lambda x: x.get("ml_confidence", 0), reverse=True)
    
    def _determine_occasions(self, top: Dict, bottom: Dict) -> List[str]:
        """Determine suitable occasions for the outfit"""
        
        occasions = []
        
        # Analyze formality levels from ML analysis
        top_analysis = top.get("ml_analysis", {}).get("style_insights", {})
        bottom_analysis = bottom.get("ml_analysis", {}).get("style_insights", {})
        
        top_formality = top_analysis.get("formality_level", 0.5)
        bottom_formality = bottom_analysis.get("formality_level", 0.5)
        
        avg_formality = (top_formality + bottom_formality) / 2
        
        if avg_formality > 0.8:
            occasions.extend(["business", "formal", "interview"])
        elif avg_formality > 0.6:
            occasions.extend(["business casual", "date night", "dinner"])
        elif avg_formality > 0.4:
            occasions.extend(["casual", "weekend", "social"])
        else:
            occasions.extend(["casual", "home", "errands", "workout"])
        
        return occasions
    
    def _determine_dress_occasions(self, dress: Dict) -> List[str]:
        """Determine suitable occasions for a dress"""
        
        dress_analysis = dress.get("ml_analysis", {}).get("style_insights", {})
        formality = dress_analysis.get("formality_level", 0.5)
        
        if formality > 0.9:
            return ["formal", "gala", "wedding", "special event"]
        elif formality > 0.7:
            return ["cocktail", "date night", "dinner", "party"]
        elif formality > 0.5:
            return ["brunch", "social", "casual dinner", "weekend"]
        else:
            return ["casual", "beach", "vacation", "home"]
    
    def _analyze_wardrobe_distribution(self, clothing_items: List[Dict]) -> Dict:
        """Analyze distribution of categories in wardrobe"""
        
        distribution = {}
        total_items = len(clothing_items)
        
        for item in clothing_items:
            category = item.get("category", "unknown")
            distribution[category] = distribution.get(category, 0) + 1
        
        # Convert to percentages
        for category in distribution:
            distribution[category] = {
                "count": distribution[category],
                "percentage": round((distribution[category] / total_items) * 100, 1)
            }
        
        return distribution
    
    def _analyze_color_distribution(self, clothing_items: List[Dict]) -> Dict:
        """Analyze color distribution in wardrobe"""
        
        color_count = {}
        
        for item in clothing_items:
            colors = item.get("colors", [])
            for color in colors:
                color_count[color] = color_count.get(color, 0) + 1
        
        # Sort by frequency
        sorted_colors = sorted(color_count.items(), key=lambda x: x[1], reverse=True)
        
        return {
            "dominant_colors": sorted_colors[:5],  # Top 5 colors
            "color_diversity": len(color_count),
            "most_common": sorted_colors[0][0] if sorted_colors else "none"
        }
    
    def _calculate_style_consistency(self, clothing_items: List[Dict]) -> float:
        """Calculate style consistency across wardrobe"""
        
        if not clothing_items:
            return 0.0
        
        style_categories = []
        formality_levels = []
        
        for item in clothing_items:
            ml_analysis = item.get("ml_analysis", {}).get("style_insights", {})
            
            style_cat = ml_analysis.get("style_category", "")
            if style_cat:
                style_categories.append(style_cat)
            
            formality = ml_analysis.get("formality_level", 0.5)
            formality_levels.append(formality)
        
        # Calculate style consistency
        if style_categories:
            most_common_style = max(set(style_categories), key=style_categories.count)
            style_consistency = style_categories.count(most_common_style) / len(style_categories)
        else:
            style_consistency = 0.5
        
        # Calculate formality consistency (lower standard deviation = more consistent)
        if formality_levels:
            import statistics
            formality_std = statistics.stdev(formality_levels) if len(formality_levels) > 1 else 0
            formality_consistency = 1 - min(formality_std, 1)  # Convert to 0-1 scale
        else:
            formality_consistency = 0.5
        
        return (style_consistency + formality_consistency) / 2
    
    def _identify_missing_essentials(self, clothing_items: List[Dict]) -> List[str]:
        """Identify essential wardrobe pieces that are missing"""
        
        # Define wardrobe essentials
        essentials = {
            "tops": ["white shirt", "black t-shirt", "blouse"],
            "bottoms": ["jeans", "black pants", "dress pants"],
            "dresses": ["little black dress", "casual dress"],
            "outerwear": ["blazer", "jacket", "coat"],
            "footwear": ["sneakers", "dress shoes", "boots"]
        }
        
        # Count existing items by category
        existing_categories = {}
        for item in clothing_items:
            category = item.get("category", "unknown")
            existing_categories[category] = existing_categories.get(category, 0) + 1
        
        # Identify missing essentials
        missing = []
        for category, essential_items in essentials.items():
            if existing_categories.get(category, 0) < 2:  # Less than 2 items in category
                missing.extend(essential_items[:2])  # Add first 2 essentials
        
        return missing
    
    def _analyze_wardrobe_gaps(self, wardrobe_data: List[Dict]) -> Dict:
        """Analyze gaps in the user's wardrobe"""
        
        gaps = {
            "missing_categories": [],
            "underrepresented_colors": [],
            "style_gaps": [],
            "occasion_gaps": [],
            "seasonal_gaps": []
        }
        
        if not wardrobe_data:
            return {
                "missing_categories": ["tops", "bottoms", "outerwear", "footwear"],
                "priority": "build_basic_wardrobe"
            }
        
        # Analyze category distribution
        categories = {}
        colors = {}
        occasions = set()
        
        for item in wardrobe_data:
            # Categories
            cat = item.get("category", "unknown")
            categories[cat] = categories.get(cat, 0) + 1
            
            # Colors
            for color in item.get("colors", []):
                colors[color] = colors.get(color, 0) + 1
            
            # Extract occasions from ML analysis
            item_occasions = item.get("ml_analysis", {}).get("occasions", [])
            occasions.update(item_occasions)
        
        # Identify missing essential categories
        essential_categories = ["tops", "bottoms", "outerwear", "footwear"]
        for cat in essential_categories:
            if categories.get(cat, 0) < 3:  # Less than 3 items
                gaps["missing_categories"].append(cat)
        
        # Identify underrepresented colors
        neutral_colors = ["black", "white", "gray", "navy", "beige"]
        for color in neutral_colors:
            if colors.get(color, 0) < 2:
                gaps["underrepresented_colors"].append(color)
        
        # Identify occasion gaps
        essential_occasions = ["casual", "business", "formal", "weekend"]
        for occasion in essential_occasions:
            if occasion not in occasions:
                gaps["occasion_gaps"].append(occasion)
        
        return gaps
    
    async def _enhance_with_shopping_suggestions(
        self,
        recommendations: Dict,
        wardrobe_analysis: Dict,
        budget_range: str,
        user_preferences: Dict
    ) -> Dict:
        """Enhance recommendations with shopping suggestions"""
        
        shopping_suggestions = []
        
        # Based on missing categories
        for missing_cat in wardrobe_analysis.get("missing_categories", []):
            suggestion = {
                "category": missing_cat,
                "priority": "high",
                "suggested_items": self._get_category_essentials(missing_cat),
                "budget_range": budget_range or "medium",
                "shopping_tips": self._get_category_shopping_tips(missing_cat)
            }
            shopping_suggestions.append(suggestion)
        
        # Based on color gaps
        for missing_color in wardrobe_analysis.get("underrepresented_colors", []):
            suggestion = {
                "type": "color_addition",
                "color": missing_color,
                "priority": "medium",
                "suggested_items": [f"{missing_color} top", f"{missing_color} bottom"],
                "rationale": f"Adding {missing_color} will increase outfit versatility"
            }
            shopping_suggestions.append(suggestion)
        
        # Enhance original recommendations
        enhanced = recommendations.copy()
        enhanced["shopping_suggestions"] = shopping_suggestions[:5]  # Top 5 suggestions
        enhanced["wardrobe_gaps"] = wardrobe_analysis
        
        return enhanced
    
    def _get_category_essentials(self, category: str) -> List[str]:
        """Get essential items for a category"""
        
        essentials_map = {
            "tops": ["white button-down shirt", "black t-shirt", "casual blouse", "sweater"],
            "bottoms": ["dark jeans", "black dress pants", "casual chinos", "leggings"],
            "outerwear": ["blazer", "denim jacket", "wool coat", "cardigan"],
            "footwear": ["white sneakers", "black dress shoes", "ankle boots", "comfortable flats"],
            "dresses": ["little black dress", "casual midi dress", "wrap dress"],
            "accessories": ["leather belt", "statement necklace", "watch", "scarf"]
        }
        
        return essentials_map.get(category, ["basic item", "versatile piece"])
    
    def _get_category_shopping_tips(self, category: str) -> List[str]:
        """Get shopping tips for a category"""
        
        tips_map = {
            "tops": [
                "Invest in quality basics that can be dressed up or down",
                "Choose versatile colors like white, black, and navy",
                "Consider fabric quality for longevity"
            ],
            "bottoms": [
                "Focus on fit - well-fitting pants are worth the investment",
                "Start with neutral colors for maximum versatility",
                "Consider your lifestyle when choosing styles"
            ],
            "outerwear": [
                "Choose pieces that work with multiple outfits",
                "Invest in quality - outerwear gets heavy use",
                "Consider your climate and seasonal needs"
            ],
            "footwear": [
                "Prioritize comfort and quality",
                "Start with neutral colors that match everything",
                "Invest in versatile styles you'll wear often"
            ]
        }
        
        return tips_map.get(category, ["Focus on quality and versatility", "Choose neutral colors first"])

clothing_service = ClothingService()