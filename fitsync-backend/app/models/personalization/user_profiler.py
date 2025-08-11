"""
User Profiling Model for Learning User Preferences and Style Patterns
"""

import numpy as np
import pandas as pd
from typing import Dict, List, Tuple, Optional, Any
import logging
from dataclasses import dataclass
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler
from sklearn.decomposition import PCA
import joblib
import os
from datetime import datetime, timedelta

logger = logging.getLogger(__name__)

@dataclass
class UserProfile:
    """User profile data structure"""
    user_id: int
    style_archetype: str
    color_preferences: List[str]
    brand_preferences: List[str]
    price_range: Tuple[float, float]
    size_preferences: Dict[str, str]
    occasion_preferences: Dict[str, float]
    seasonal_preferences: Dict[str, float]
    confidence_score: float
    last_updated: datetime

@dataclass
class StyleInsight:
    """Style insight data structure"""
    insight_type: str
    value: Any
    confidence: float
    description: str
    timestamp: datetime

class UserProfiler:
    """Machine learning model for user profiling and preference learning"""
    
    def __init__(self, model_path: Optional[str] = None):
        """
        Initialize user profiler
        
        Args:
            model_path: Path to pre-trained model
        """
        self.model_path = model_path
        self.scaler = StandardScaler()
        self.pca = PCA(n_components=10)
        self.kmeans = KMeans(n_clusters=8, random_state=42)  # 8 style archetypes
        self.is_trained = False
        
        # Load pre-trained model if provided
        if model_path and os.path.exists(model_path):
            self.load_model(model_path)
    
    def extract_user_features(self, user_data: Dict[str, Any]) -> np.ndarray:
        """
        Extract features from user data
        
        Args:
            user_data: Dictionary containing user interaction data
            
        Returns:
            Feature vector
        """
        try:
            features = []
            
            # Basic user features
            features.extend([
                user_data.get('age', 25),
                user_data.get('height', 170),
                user_data.get('weight', 70),
                user_data.get('body_type_encoded', 0),
                user_data.get('gender_encoded', 0)
            ])
            
            # Style preference features
            style_prefs = user_data.get('style_preferences', {})
            features.extend([
                style_prefs.get('casual', 0.5),
                style_prefs.get('formal', 0.5),
                style_prefs.get('streetwear', 0.5),
                style_prefs.get('vintage', 0.5),
                style_prefs.get('minimalist', 0.5),
                style_prefs.get('bohemian', 0.5),
                style_prefs.get('sporty', 0.5),
                style_prefs.get('elegant', 0.5)
            ])
            
            # Color preference features
            color_prefs = user_data.get('color_preferences', {})
            features.extend([
                color_prefs.get('black', 0.5),
                color_prefs.get('white', 0.5),
                color_prefs.get('blue', 0.5),
                color_prefs.get('red', 0.5),
                color_prefs.get('green', 0.5),
                color_prefs.get('yellow', 0.5),
                color_prefs.get('purple', 0.5),
                color_prefs.get('pink', 0.5),
                color_prefs.get('brown', 0.5),
                color_prefs.get('gray', 0.5)
            ])
            
            # Interaction features
            interactions = user_data.get('interactions', {})
            features.extend([
                interactions.get('likes_count', 0),
                interactions.get('dislikes_count', 0),
                interactions.get('purchases_count', 0),
                interactions.get('shares_count', 0),
                interactions.get('avg_rating', 3.0),
                interactions.get('session_duration_avg', 300),
                interactions.get('items_viewed_per_session', 10)
            ])
            
            # Brand and price features
            features.extend([
                len(user_data.get('brand_preferences', [])),
                user_data.get('avg_price_preference', 100),
                user_data.get('price_range_min', 20),
                user_data.get('price_range_max', 200)
            ])
            
            # Seasonal and occasion features
            seasonal_prefs = user_data.get('seasonal_preferences', {})
            features.extend([
                seasonal_prefs.get('spring', 0.25),
                seasonal_prefs.get('summer', 0.25),
                seasonal_prefs.get('autumn', 0.25),
                seasonal_prefs.get('winter', 0.25)
            ])
            
            occasion_prefs = user_data.get('occasion_preferences', {})
            features.extend([
                occasion_prefs.get('casual', 0.5),
                occasion_prefs.get('work', 0.5),
                occasion_prefs.get('formal', 0.5),
                occasion_prefs.get('party', 0.5),
                occasion_prefs.get('sport', 0.5)
            ])
            
            return np.array(features, dtype=np.float32)
            
        except Exception as e:
            logger.error(f"Error extracting user features: {e}")
            return np.zeros(50, dtype=np.float32)  # Default feature vector
    
    def train_model(self, training_data: List[Dict[str, Any]]):
        """
        Train the user profiling model
        
        Args:
            training_data: List of user data dictionaries
        """
        try:
            if not training_data:
                logger.warning("No training data provided")
                return
            
            # Extract features from all users
            feature_vectors = []
            for user_data in training_data:
                features = self.extract_user_features(user_data)
                feature_vectors.append(features)
            
            feature_matrix = np.array(feature_vectors)
            
            # Scale features
            feature_matrix_scaled = self.scaler.fit_transform(feature_matrix)
            
            # Apply PCA for dimensionality reduction
            feature_matrix_pca = self.pca.fit_transform(feature_matrix_scaled)
            
            # Train K-means clustering
            self.kmeans.fit(feature_matrix_pca)
            
            self.is_trained = True
            logger.info(f"User profiling model trained on {len(training_data)} users")
            
        except Exception as e:
            logger.error(f"Error training user profiling model: {e}")
            raise
    
    def predict_user_profile(self, user_data: Dict[str, Any]) -> UserProfile:
        """
        Predict user profile and preferences
        
        Args:
            user_data: User interaction data
            
        Returns:
            UserProfile object
        """
        try:
            if not self.is_trained:
                logger.warning("Model not trained, returning default profile")
                return self._create_default_profile(user_data.get('user_id', 0))
            
            # Extract features
            features = self.extract_user_features(user_data)
            features_scaled = self.scaler.transform(features.reshape(1, -1))
            features_pca = self.pca.transform(features_scaled)
            
            # Predict cluster (style archetype)
            cluster = self.kmeans.predict(features_pca)[0]
            style_archetype = self._get_style_archetype(cluster)
            
            # Extract preferences from user data
            color_preferences = self._extract_color_preferences(user_data)
            brand_preferences = user_data.get('brand_preferences', [])
            price_range = (
                user_data.get('price_range_min', 20),
                user_data.get('price_range_max', 200)
            )
            size_preferences = user_data.get('size_preferences', {})
            occasion_preferences = user_data.get('occasion_preferences', {})
            seasonal_preferences = user_data.get('seasonal_preferences', {})
            
            # Calculate confidence score
            confidence_score = self._calculate_confidence_score(user_data)
            
            return UserProfile(
                user_id=user_data.get('user_id', 0),
                style_archetype=style_archetype,
                color_preferences=color_preferences,
                brand_preferences=brand_preferences,
                price_range=price_range,
                size_preferences=size_preferences,
                occasion_preferences=occasion_preferences,
                seasonal_preferences=seasonal_preferences,
                confidence_score=confidence_score,
                last_updated=datetime.now()
            )
            
        except Exception as e:
            logger.error(f"Error predicting user profile: {e}")
            return self._create_default_profile(user_data.get('user_id', 0))
    
    def _get_style_archetype(self, cluster: int) -> str:
        """Map cluster to style archetype"""
        archetypes = [
            "minimalist", "bohemian", "streetwear", "elegant",
            "casual", "vintage", "sporty", "formal"
        ]
        return archetypes[cluster % len(archetypes)]
    
    def _extract_color_preferences(self, user_data: Dict[str, Any]) -> List[str]:
        """Extract top color preferences"""
        try:
            color_prefs = user_data.get('color_preferences', {})
            if not color_prefs:
                return ['black', 'white', 'blue']  # Default colors
            
            # Sort colors by preference score
            sorted_colors = sorted(color_prefs.items(), key=lambda x: x[1], reverse=True)
            return [color for color, score in sorted_colors[:5]]  # Top 5 colors
            
        except Exception as e:
            logger.error(f"Error extracting color preferences: {e}")
            return ['black', 'white', 'blue']
    
    def _calculate_confidence_score(self, user_data: Dict[str, Any]) -> float:
        """Calculate confidence score based on data quality and quantity"""
        try:
            confidence = 0.5  # Base confidence
            
            # Increase confidence based on data quantity
            interactions = user_data.get('interactions', {})
            total_interactions = sum([
                interactions.get('likes_count', 0),
                interactions.get('dislikes_count', 0),
                interactions.get('purchases_count', 0),
                interactions.get('shares_count', 0)
            ])
            
            if total_interactions > 100:
                confidence += 0.3
            elif total_interactions > 50:
                confidence += 0.2
            elif total_interactions > 10:
                confidence += 0.1
            
            # Increase confidence based on data completeness
            required_fields = ['style_preferences', 'color_preferences', 'brand_preferences']
            for field in required_fields:
                if field in user_data and user_data[field]:
                    confidence += 0.05
            
            return min(confidence, 1.0)
            
        except Exception as e:
            logger.error(f"Error calculating confidence score: {e}")
            return 0.5
    
    def _create_default_profile(self, user_id: int) -> UserProfile:
        """Create default user profile"""
        return UserProfile(
            user_id=user_id,
            style_archetype="casual",
            color_preferences=["black", "white", "blue"],
            brand_preferences=[],
            price_range=(20, 200),
            size_preferences={},
            occasion_preferences={"casual": 1.0},
            seasonal_preferences={"spring": 0.25, "summer": 0.25, "autumn": 0.25, "winter": 0.25},
            confidence_score=0.3,
            last_updated=datetime.now()
        )
    
    def generate_style_insights(self, user_data: Dict[str, Any]) -> List[StyleInsight]:
        """
        Generate style insights for user
        
        Args:
            user_data: User interaction data
            
        Returns:
            List of StyleInsight objects
        """
        try:
            insights = []
            
            # Analyze color preferences
            color_prefs = user_data.get('color_preferences', {})
            if color_prefs:
                top_color = max(color_prefs.items(), key=lambda x: x[1])
                insights.append(StyleInsight(
                    insight_type="color_preference",
                    value=top_color[0],
                    confidence=top_color[1],
                    description=f"You prefer {top_color[0]} colors",
                    timestamp=datetime.now()
                ))
            
            # Analyze style consistency
            style_prefs = user_data.get('style_preferences', {})
            if style_prefs:
                dominant_style = max(style_prefs.items(), key=lambda x: x[1])
                insights.append(StyleInsight(
                    insight_type="style_archetype",
                    value=dominant_style[0],
                    confidence=dominant_style[1],
                    description=f"Your dominant style is {dominant_style[0]}",
                    timestamp=datetime.now()
                ))
            
            # Analyze interaction patterns
            interactions = user_data.get('interactions', {})
            if interactions.get('likes_count', 0) > interactions.get('dislikes_count', 0):
                insights.append(StyleInsight(
                    insight_type="engagement_pattern",
                    value="positive",
                    confidence=0.8,
                    description="You tend to like more items than dislike",
                    timestamp=datetime.now()
                ))
            
            # Analyze seasonal preferences
            seasonal_prefs = user_data.get('seasonal_preferences', {})
            if seasonal_prefs:
                favorite_season = max(seasonal_prefs.items(), key=lambda x: x[1])
                insights.append(StyleInsight(
                    insight_type="seasonal_preference",
                    value=favorite_season[0],
                    confidence=favorite_season[1],
                    description=f"You prefer {favorite_season[0]} fashion",
                    timestamp=datetime.now()
                ))
            
            return insights
            
        except Exception as e:
            logger.error(f"Error generating style insights: {e}")
            return []
    
    def update_user_profile(self, user_profile: UserProfile, 
                          new_data: Dict[str, Any]) -> UserProfile:
        """
        Update user profile with new data
        
        Args:
            user_profile: Current user profile
            new_data: New interaction data
            
        Returns:
            Updated UserProfile
        """
        try:
            # Update color preferences
            new_color_prefs = new_data.get('color_preferences', {})
            if new_color_prefs:
                current_colors = {color: 0.5 for color in user_profile.color_preferences}
                for color, score in new_color_prefs.items():
                    current_colors[color] = current_colors.get(color, 0.5) * 0.7 + score * 0.3
                
                # Update top colors
                sorted_colors = sorted(current_colors.items(), key=lambda x: x[1], reverse=True)
                user_profile.color_preferences = [color for color, _ in sorted_colors[:5]]
            
            # Update style preferences
            new_style_prefs = new_data.get('style_preferences', {})
            if new_style_prefs:
                for style, score in new_style_prefs.items():
                    current_score = user_profile.occasion_preferences.get(style, 0.5)
                    user_profile.occasion_preferences[style] = current_score * 0.7 + score * 0.3
            
            # Update price range
            new_price_min = new_data.get('price_range_min')
            new_price_max = new_data.get('price_range_max')
            if new_price_min and new_price_max:
                current_min, current_max = user_profile.price_range
                user_profile.price_range = (
                    current_min * 0.7 + new_price_min * 0.3,
                    current_max * 0.7 + new_price_max * 0.3
                )
            
            # Update confidence score
            user_profile.confidence_score = min(
                user_profile.confidence_score + 0.1, 1.0
            )
            
            user_profile.last_updated = datetime.now()
            
            return user_profile
            
        except Exception as e:
            logger.error(f"Error updating user profile: {e}")
            return user_profile
    
    def save_model(self, model_path: str):
        """Save trained model"""
        try:
            model_data = {
                'scaler': self.scaler,
                'pca': self.pca,
                'kmeans': self.kmeans,
                'is_trained': self.is_trained
            }
            joblib.dump(model_data, model_path)
            logger.info(f"User profiling model saved to {model_path}")
        except Exception as e:
            logger.error(f"Error saving user profiling model: {e}")
    
    def load_model(self, model_path: str):
        """Load trained model"""
        try:
            if os.path.exists(model_path):
                model_data = joblib.load(model_path)
                self.scaler = model_data['scaler']
                self.pca = model_data['pca']
                self.kmeans = model_data['kmeans']
                self.is_trained = model_data['is_trained']
                logger.info(f"User profiling model loaded from {model_path}")
            else:
                logger.warning(f"Model path {model_path} does not exist")
        except Exception as e:
            logger.error(f"Error loading user profiling model: {e}")
    
    def cleanup(self):
        """Clean up resources"""
        pass  # No specific cleanup needed for this model
