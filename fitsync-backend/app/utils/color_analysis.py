"""
Color Analysis Utility for Extracting and Analyzing Color Palettes from Images
"""

import cv2
import numpy as np
from typing import List, Tuple, Dict, Any
import logging
from dataclasses import dataclass
from sklearn.cluster import KMeans
from collections import Counter
import colorsys

logger = logging.getLogger(__name__)

@dataclass
class ColorPalette:
    """Color palette data structure"""
    colors: List[Tuple[int, int, int]]  # RGB values
    percentages: List[float]  # Percentage of each color
    hex_colors: List[str]  # Hex color codes
    dominant_color: Tuple[int, int, int]  # Most dominant color
    color_names: List[str]  # Human-readable color names

@dataclass
class ColorHarmony:
    """Color harmony analysis result"""
    harmony_score: float  # 0-1 score
    harmony_type: str  # Type of harmony (complementary, analogous, etc.)
    suggestions: List[str]  # Color combination suggestions

class ColorAnalyzer:
    """Color analysis and palette extraction from images"""
    
    def __init__(self, n_colors: int = 8):
        """
        Initialize color analyzer
        
        Args:
            n_colors: Number of colors to extract from image
        """
        self.n_colors = n_colors
        self.color_names = {
            'red': (255, 0, 0),
            'orange': (255, 165, 0),
            'yellow': (255, 255, 0),
            'green': (0, 255, 0),
            'blue': (0, 0, 255),
            'purple': (128, 0, 128),
            'pink': (255, 192, 203),
            'brown': (165, 42, 42),
            'black': (0, 0, 0),
            'white': (255, 255, 255),
            'gray': (128, 128, 128),
            'navy': (0, 0, 128),
            'maroon': (128, 0, 0),
            'olive': (128, 128, 0),
            'teal': (0, 128, 128),
            'lime': (0, 255, 0),
            'aqua': (0, 255, 255),
            'fuchsia': (255, 0, 255),
            'silver': (192, 192, 192),
            'gold': (255, 215, 0)
        }
    
    def extract_palette(self, image: np.ndarray) -> ColorPalette:
        """
        Extract color palette from image
        
        Args:
            image: Input image (BGR format)
            
        Returns:
            ColorPalette object
        """
        try:
            # Convert BGR to RGB
            rgb_image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
            
            # Reshape image for clustering
            pixels = rgb_image.reshape(-1, 3)
            
            # Apply K-means clustering
            kmeans = KMeans(n_clusters=self.n_colors, random_state=42, n_init=10)
            kmeans.fit(pixels)
            
            # Get cluster centers (colors)
            colors = kmeans.cluster_centers_.astype(int)
            
            # Get cluster labels and count occurrences
            labels = kmeans.labels_
            color_counts = Counter(labels)
            
            # Calculate percentages
            total_pixels = len(labels)
            percentages = [color_counts[i] / total_pixels * 100 for i in range(self.n_colors)]
            
            # Convert to hex colors
            hex_colors = [self._rgb_to_hex(color) for color in colors]
            
            # Find dominant color
            dominant_idx = max(range(self.n_colors), key=lambda i: color_counts[i])
            dominant_color = tuple(colors[dominant_idx])
            
            # Get color names
            color_names = [self._get_color_name(color) for color in colors]
            
            return ColorPalette(
                colors=[tuple(color) for color in colors],
                percentages=percentages,
                hex_colors=hex_colors,
                dominant_color=dominant_color,
                color_names=color_names
            )
            
        except Exception as e:
            logger.error(f"Error extracting color palette: {e}")
            raise
    
    def analyze_color_harmony(self, colors: List[Tuple[int, int, int]]) -> ColorHarmony:
        """
        Analyze color harmony between colors
        
        Args:
            colors: List of RGB colors
            
        Returns:
            ColorHarmony object
        """
        try:
            if len(colors) < 2:
                return ColorHarmony(
                    harmony_score=0.5,
                    harmony_type="single_color",
                    suggestions=["Add more colors for better harmony analysis"]
                )
            
            # Convert RGB to HSV for better color analysis
            hsv_colors = [self._rgb_to_hsv(color) for color in colors]
            
            # Calculate hue differences
            hues = [hsv[0] for hsv in hsv_colors]
            hue_differences = []
            
            for i in range(len(hues)):
                for j in range(i + 1, len(hues)):
                    diff = abs(hues[i] - hues[j])
                    # Handle circular nature of hue
                    if diff > 180:
                        diff = 360 - diff
                    hue_differences.append(diff)
            
            # Determine harmony type based on hue differences
            avg_hue_diff = np.mean(hue_differences)
            
            if avg_hue_diff < 30:
                harmony_type = "analogous"
                harmony_score = 0.8
                suggestions = ["Analogous colors create a harmonious, cohesive look"]
            elif 150 < avg_hue_diff < 210:
                harmony_type = "complementary"
                harmony_score = 0.9
                suggestions = ["Complementary colors create high contrast and visual interest"]
            elif 60 < avg_hue_diff < 120:
                harmony_type = "triadic"
                harmony_score = 0.85
                suggestions = ["Triadic colors offer good balance and variety"]
            elif 80 < avg_hue_diff < 140:
                harmony_type = "split_complementary"
                harmony_score = 0.8
                suggestions = ["Split-complementary offers contrast without tension"]
            else:
                harmony_type = "other"
                harmony_score = 0.6
                suggestions = ["Consider using established color harmony rules"]
            
            # Adjust score based on saturation and value
            saturations = [hsv[1] for hsv in hsv_colors]
            values = [hsv[2] for hsv in hsv_colors]
            
            avg_saturation = np.mean(saturations)
            avg_value = np.mean(values)
            
            # Boost score for good saturation and value balance
            if 0.3 < avg_saturation < 0.8 and 0.3 < avg_value < 0.8:
                harmony_score = min(harmony_score + 0.1, 1.0)
            
            return ColorHarmony(
                harmony_score=harmony_score,
                harmony_type=harmony_type,
                suggestions=suggestions
            )
            
        except Exception as e:
            logger.error(f"Error analyzing color harmony: {e}")
            return ColorHarmony(
                harmony_score=0.5,
                harmony_type="error",
                suggestions=["Error in color harmony analysis"]
            )
    
    def get_color_suggestions(self, base_color: Tuple[int, int, int], 
                            suggestion_type: str = "complementary") -> List[Tuple[int, int, int]]:
        """
        Get color suggestions based on a base color
        
        Args:
            base_color: Base RGB color
            suggestion_type: Type of suggestion (complementary, analogous, triadic)
            
        Returns:
            List of suggested RGB colors
        """
        try:
            # Convert to HSV
            h, s, v = self._rgb_to_hsv(base_color)
            
            suggestions = []
            
            if suggestion_type == "complementary":
                # Complementary color (opposite on color wheel)
                comp_h = (h + 180) % 360
                suggestions.append(self._hsv_to_rgb(comp_h, s, v))
                
            elif suggestion_type == "analogous":
                # Analogous colors (adjacent on color wheel)
                for offset in [-30, 30]:
                    analog_h = (h + offset) % 360
                    suggestions.append(self._hsv_to_rgb(analog_h, s, v))
                    
            elif suggestion_type == "triadic":
                # Triadic colors (equidistant on color wheel)
                for offset in [120, 240]:
                    triadic_h = (h + offset) % 360
                    suggestions.append(self._hsv_to_rgb(triadic_h, s, v))
                    
            elif suggestion_type == "split_complementary":
                # Split-complementary (colors adjacent to complementary)
                comp_h = (h + 180) % 360
                for offset in [-30, 30]:
                    split_h = (comp_h + offset) % 360
                    suggestions.append(self._hsv_to_rgb(split_h, s, v))
            
            return suggestions
            
        except Exception as e:
            logger.error(f"Error getting color suggestions: {e}")
            return []
    
    def calculate_color_similarity(self, color1: Tuple[int, int, int], 
                                 color2: Tuple[int, int, int]) -> float:
        """
        Calculate similarity between two colors (0-1, where 1 is identical)
        
        Args:
            color1: First RGB color
            color2: Second RGB color
            
        Returns:
            Similarity score (0-1)
        """
        try:
            # Convert to HSV for better similarity calculation
            hsv1 = self._rgb_to_hsv(color1)
            hsv2 = self._rgb_to_hsv(color2)
            
            # Calculate differences
            h_diff = min(abs(hsv1[0] - hsv2[0]), 360 - abs(hsv1[0] - hsv2[0])) / 180.0
            s_diff = abs(hsv1[1] - hsv2[1])
            v_diff = abs(hsv1[2] - hsv2[2])
            
            # Weighted similarity (hue is most important)
            similarity = 1.0 - (0.5 * h_diff + 0.25 * s_diff + 0.25 * v_diff)
            
            return max(0.0, min(1.0, similarity))
            
        except Exception as e:
            logger.error(f"Error calculating color similarity: {e}")
            return 0.0
    
    def _rgb_to_hex(self, rgb: Tuple[int, int, int]) -> str:
        """Convert RGB to hex color code"""
        return f"#{rgb[0]:02x}{rgb[1]:02x}{rgb[2]:02x}"
    
    def _rgb_to_hsv(self, rgb: Tuple[int, int, int]) -> Tuple[float, float, float]:
        """Convert RGB to HSV"""
        r, g, b = [x / 255.0 for x in rgb]
        h, s, v = colorsys.rgb_to_hsv(r, g, b)
        return (h * 360, s, v)  # Convert hue to degrees
    
    def _hsv_to_rgb(self, h: float, s: float, v: float) -> Tuple[int, int, int]:
        """Convert HSV to RGB"""
        h = h / 360.0  # Convert hue to 0-1
        r, g, b = colorsys.hsv_to_rgb(h, s, v)
        return (int(r * 255), int(g * 255), int(b * 255))
    
    def _get_color_name(self, rgb: Tuple[int, int, int]) -> str:
        """Get human-readable color name"""
        try:
            min_distance = float('inf')
            closest_color = "unknown"
            
            for name, color_rgb in self.color_names.items():
                distance = np.sqrt(sum((a - b) ** 2 for a, b in zip(rgb, color_rgb)))
                if distance < min_distance:
                    min_distance = distance
                    closest_color = name
            
            return closest_color
            
        except Exception as e:
            logger.error(f"Error getting color name: {e}")
            return "unknown"
    
    def analyze_seasonal_colors(self, colors: List[Tuple[int, int, int]]) -> Dict[str, float]:
        """
        Analyze how well colors fit different seasons
        
        Args:
            colors: List of RGB colors
            
        Returns:
            Dictionary with seasonal scores
        """
        try:
            seasonal_palettes = {
                "spring": [(255, 182, 193), (255, 218, 185), (255, 255, 224), (144, 238, 144)],
                "summer": [(176, 196, 222), (255, 192, 203), (221, 160, 221), (152, 251, 152)],
                "autumn": [(210, 105, 30), (255, 140, 0), (255, 215, 0), (139, 69, 19)],
                "winter": [(25, 25, 112), (128, 0, 128), (220, 20, 60), (255, 255, 255)]
            }
            
            seasonal_scores = {}
            
            for season, palette in seasonal_palettes.items():
                total_similarity = 0
                for color in colors:
                    max_similarity = max(
                        self.calculate_color_similarity(color, palette_color)
                        for palette_color in palette
                    )
                    total_similarity += max_similarity
                
                seasonal_scores[season] = total_similarity / len(colors)
            
            return seasonal_scores
            
        except Exception as e:
            logger.error(f"Error analyzing seasonal colors: {e}")
            return {"spring": 0.5, "summer": 0.5, "autumn": 0.5, "winter": 0.5}
