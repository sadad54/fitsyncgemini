import numpy as np
from typing import List, Dict, Any, Tuple
from sklearn.metrics.pairwise import cosine_similarity

class StyleMatcher:
    def __init__(self):
        # Define style archetypes with color and feature preferences
        self.style_profiles = {
            'classic': {
                'colors': ['navy', 'white', 'black', 'gray', 'beige'],
                'patterns': ['solid', 'subtle_stripe'],
                'fits': ['tailored', 'regular'],
                'formality': 0.8
            },
            'casual': {
                'colors': ['blue', 'green', 'red', 'yellow'],
                'patterns': ['solid', 'graphic', 'plaid'],
                'fits': ['relaxed', 'regular'],
                'formality': 0.3
            },
            'bohemian': {
                'colors': ['earth_tones', 'burnt_orange', 'deep_purple'],
                'patterns': ['floral', 'paisley', 'ethnic'],
                'fits': ['flowy', 'loose'],
                'formality': 0.4
            },
            'minimalist': {
                'colors': ['white', 'black', 'gray', 'nude'],
                'patterns': ['solid'],
                'fits': ['clean', 'structured'],
                'formality': 0.6
            }
        }
    
    def analyze_user_style(self, clothing_history: List[Dict]) -> Dict[str, float]:
        """Analyze user's style preferences from clothing history"""
        style_scores = {style: 0.0 for style in self.style_profiles}
        
        for item in clothing_history:
            for style_name, style_profile in self.style_profiles.items():
                score = self._calculate_item_style_match(item, style_profile)
                style_scores[style_name] += score
        
        # Normalize scores
        total_items = len(clothing_history)
        if total_items > 0:
            style_scores = {k: v / total_items for k, v in style_scores.items()}
        
        return style_scores
    
    def _calculate_item_style_match(self, item: Dict, style_profile: Dict) -> float:
        """Calculate how well an item matches a style profile"""
        score = 0.0
        
        # Color matching
        if 'color_primary' in item:
            if item['color_primary'].lower() in [c.lower() for c in style_profile['colors']]:
                score += 0.4
        
        # Pattern matching (if available)
        if 'pattern' in item:
            if item['pattern'] in style_profile['patterns']:
                score += 0.3
        
        # Fit matching (if available)
        if 'fit_type' in item:
            if item['fit_type'] in style_profile['fits']:
                score += 0.3
        
        return score
    
    def recommend_compatible_items(self, base_item: Dict, available_items: List[Dict]) -> List[Dict]:
        """Recommend items that go well with the base item"""
        recommendations = []
        
        base_features = self._extract_item_features(base_item)
        
        for item in available_items:
            if item['id'] == base_item['id']:
                continue
                
            item_features = self._extract_item_features(item)
            compatibility_score = self._calculate_compatibility(base_features, item_features)
            
            recommendations.append({
                'item': item,
                'compatibility_score': compatibility_score
            })
        
        # Sort by compatibility score
        recommendations.sort(key=lambda x: x['compatibility_score'], reverse=True)
        return recommendations[:10]  # Top 10 recommendations
    
    def _extract_item_features(self, item: Dict) -> np.ndarray:
        """Convert item attributes to feature vector"""
        features = []
        
        # Color features (simplified RGB representation)
        if 'color_primary' in item:
            color_vector = self._color_to_vector(item['color_primary'])
            features.extend(color_vector)
        else:
            features.extend([0, 0, 0])  # Default
        
        # Category one-hot encoding
        categories = ['shirt', 'pants', 'dress', 'jacket', 'skirt', 'shoes']
        category_vector = [1 if item.get('category') == cat else 0 for cat in categories]
        features.extend(category_vector)
        
        # Formality score (0-1)
        formality_map = {'casual': 0.2, 'smart_casual': 0.5, 'formal': 0.8, 'business': 0.9}
        formality = formality_map.get(item.get('style', 'casual'), 0.5)
        features.append(formality)
        
        return np.array(features)
    
    def _color_to_vector(self, color_name: str) -> List[float]:
        """Convert color name to RGB-like vector (simplified)"""
        color_map = {
            'red': [1.0, 0.0, 0.0],
            'blue': [0.0, 0.0, 1.0],
            'green': [0.0, 1.0, 0.0],
            'black': [0.0, 0.0, 0.0],
            'white': [1.0, 1.0, 1.0],
            'gray': [0.5, 0.5, 0.5],
            'navy': [0.0, 0.0, 0.5],
            'brown': [0.5, 0.25, 0.0]
        }
        return color_map.get(color_name.lower(), [0.5, 0.5, 0.5])
    
    def _calculate_compatibility(self, features1: np.ndarray, features2: np.ndarray) -> float:
        """Calculate compatibility between two items"""
        # Use cosine similarity for basic compatibility
        similarity = cosine_similarity([features1], [features2])[0][0]
        
        # Add color harmony rules
        color1 = features1[:3]
        color2 = features2[:3]
        color_harmony = self._calculate_color_harmony(color1, color2)
        
        # Combine similarity and color harmony
        return 0.6 * similarity + 0.4 * color_harmony
    
    def _calculate_color_harmony(self, color1: np.ndarray, color2: np.ndarray) -> float:
        """Calculate color harmony score"""
        # Simplified color harmony rules
        # Complementary colors, analogous colors, etc.
        
        # For now, use inverse of color distance as harmony
        distance = np.linalg.norm(color1 - color2)
        max_distance = np.sqrt(3)  # Maximum possible RGB distance
        
        # Convert to harmony score (closer colors = higher harmony for basics)
        harmony = 1.0 - (distance / max_distance)
        
        # Adjust for high contrast combinations (black/white, etc.)
        if distance > 0.8 * max_distance:
            harmony = 0.8  # High contrast can work well
        
        return harmony