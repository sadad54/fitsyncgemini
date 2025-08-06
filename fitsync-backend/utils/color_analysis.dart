import cv2
import numpy as np
from sklearn.cluster import KMeans
from typing import Dict, List, Tuple, Any
import colorsys
import webcolors

class ColorAnalyzer:
    """Advanced color analysis with fashion-specific algorithms"""
    
    def __init__(self):
        self.seasonal_palettes = self._load_seasonal_palettes()
        self.color_harmony_rules = self._load_color_harmony_rules()
    
    def analyze_personal_palette(self, image_path: str) -> Dict[str, Any]:
        """Comprehensive personal color palette analysis"""
        
        image = cv2.imread(image_path)
        if image is None:
            raise ValueError("Could not load image")
        
        # Extract dominant colors
        dominant_colors = self._extract_dominant_colors(image, n_colors=8)
        
        # Analyze color temperature
        color_temperature = self._analyze_color_temperature(dominant_colors)
        
        # Determine seasonal palette
        seasonal_analysis = self._determine_seasonal_palette(dominant_colors)
        
        # Generate color recommendations
        recommendations = self._generate_color_recommendations(
            dominant_colors, seasonal_analysis, color_temperature
        )
        
        return {
            "colors": [self._rgb_to_hex(color) for color in dominant_colors],
            "color_names": [self._get_color_name(color) for color in dominant_colors],
            "harmony_score": self._calculate_harmony_score(dominant_colors),
            "seasonal_compatibility": seasonal_analysis,
            "color_temperature": color_temperature,
            "recommendations": recommendations,
            "complementary_colors": self._find_complementary_colors(dominant_colors),
            "analogous_colors": self._find_analogous_colors(dominant_colors)
        }
    
    def _extract_dominant_colors(self, image: np.ndarray, n_colors: int = 5) -> List[Tuple[int, int, int]]:
        """Extract dominant colors using advanced clustering"""
        
        # Resize image for faster processing
        image = cv2.resize(image, (150, 150))
        
        # Convert to RGB
        image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        
        # Reshape for clustering
        pixels = image_rgb.reshape(-1, 3)
        
        # Remove very dark and very bright pixels (likely shadows/highlights)
        brightness = np.mean(pixels, axis=1)
        pixels = pixels[(brightness > 30) & (brightness < 225)]
        
        # Perform clustering
        kmeans = KMeans(n_clusters=n_colors, random_state=42, n_init=10)
        kmeans.fit(pixels)
        
        colors = kmeans.cluster_centers_.astype(int)
        
        # Sort by frequency (cluster size)
        labels = kmeans.labels_
        frequencies = np.bincount(labels)
        sorted_indices = np.argsort(frequencies)[::-1]
        
        return [tuple(colors[i]) for i in sorted_indices]
    
    def _analyze_color_temperature(self, colors: List[Tuple[int, int, int]]) -> str:
        """Analyze overall color temperature"""
        
        warm_score = 0
        cool_score = 0
        
        for r, g, b in colors:
            # Convert to HSV for better analysis
            h, s, v = colorsys.rgb_to_hsv(r/255, g/255, b/255)
            h_degrees = h * 360
            
            # Warm colors: reds, oranges, yellows (0-60, 300-360)
            if (h_degrees <= 60) or (h_degrees >= 300):
                warm_score += s * v  # Weight by saturation and brightness
            # Cool colors: greens, blues, purples (120-270)
            elif 120 <= h_degrees <= 270:
                cool_score += s * v
        
        if warm_score > cool_score:
            return "warm"
        elif cool_score > warm_score:
            return "cool"
        else:
            return "neutral"
    
    def _determine_seasonal_palette(self, colors: List[Tuple[int, int, int]]) -> Dict[str, float]:
        """Determine seasonal color palette compatibility"""
        
        seasonal_scores = {"spring": 0, "summer": 0, "autumn": 0, "winter": 0}
        
        for color in colors:
            for season, palette in self.seasonal_palettes.items():
                # Calculate similarity to seasonal palette
                similarity = self._calculate_color_similarity_to_palette(color, palette)
                seasonal_scores[season] += similarity
        
        # Normalize scores
        total_score = sum(seasonal_scores.values())
        if total_score > 0:
            seasonal_scores = {k: v/total_score for k, v in seasonal_scores.items()}
        
        return seasonal_scores
    
    def _generate_color_recommendations(self, dominant_colors: List[Tuple[int, int, int]], 
                                      seasonal_analysis: Dict[str, float],
                                      color_temperature: str) -> Dict[str, List[str]]:
        """Generate personalized color recommendations"""
        
        # Find best seasonal match
        best_season = max(seasonal_analysis.items(), key=lambda x: x[1])[0]
        
        recommendations = {
            "signature_colors": [self._rgb_to_hex(color) for color in dominant_colors[:3]],
            "accent_colors": self._recommend_accent_colors(dominant_colors, color_temperature),
            "neutral_bases": self._recommend_neutral_bases(best_season, color_temperature),
            "avoid_colors": self._get_colors_to_avoid(best_season, color_temperature),
            "seasonal_highlights": self.seasonal_palettes[best_season][:5]
        }
        
        return recommendations
    
    def _calculate_harmony_score(self, colors: List[Tuple[int, int, int]]) -> float:
        """Calculate overall color harmony score"""
        
        if len(colors) < 2:
            return 1.0
        
        harmony_scores = []
        
        # Check various color harmony rules
        for i in range(len(colors)):
            for j in range(i + 1, len(colors)):
                color1 = colors[i]
                color2 = colors[j]
                
                # Complementary harmony
                comp_score = self._check_complementary_harmony(color1, color2)
                
                # Analogous harmony  
                analog_score = self._check_analogous_harmony(color1, color2)
                
                # Triadic harmony
                triadic_score = self._check_triadic_harmony(color1, color2)
                
                # Take the best harmony score for this pair
                best_score = max(comp_score, analog_score, triadic_score)
                harmony_scores.append(best_score)
        
        return np.mean(harmony_scores) if harmony_scores else 0.5
    
    def _rgb_to_hex(self, rgb: Tuple[int, int, int]) -> str:
        """Convert RGB tuple to hex string"""
        return f"#{rgb[0]:02x}{rgb[1]:02x}{rgb[2]:02x}"
    
    def _get_color_name(self, rgb: Tuple[int, int, int]) -> str:
        """Get closest CSS color name"""
        try:
            return webcolors.rgb_to_name(rgb)
        except ValueError:
            # Find closest named color
            min_colors = {}
            for hex_color, name in webcolors.CSS3_HEX_TO_NAMES.items():
                r, g, b = webcolors.hex_to_rgb(hex_color)
                rd = (r - rgb[0]) ** 2
                gd = (g - rgb[1]) ** 2
                bd = (b - rgb[2]) ** 2
                min_colors[(rd + gd + bd)] = name
            
            return min_colors[min(min_colors.keys())]
    
    def _load_seasonal_palettes(self) -> Dict[str, List[str]]:
        """Load seasonal color palettes"""
        return {
            "spring": ["#FFB6C1", "#98FB98", "#F0E68C", "#87CEEB", "#DDA0DD"],
            "summer": ["#B0C4DE", "#F0F8FF", "#E6E6FA", "#D8BFD8", "#AFEEEE"],
            "autumn": ["#CD853F", "#A0522D", "#8B4513", "#D2691E", "#B22222"],
            "winter": ["#000000", "#FFFFFF", "#FF0000", "#0000FF", "#800080"]
        }
    
    def _load_color_harmony_rules(self) -> Dict[str, Any]:
        """Load color harmony calculation rules"""
        return {
            "complementary_tolerance": 30,  # degrees
            "analogous_range": (30, 60),   # degrees
            "triadic_tolerance": 15        # degrees from 120°
        }
    
    # Additional helper methods for color analysis...
    def _calculate_color_similarity_to_palette(self, color: Tuple[int, int, int], 
                                             palette: List[str]) -> float:
        """Calculate similarity of color to a palette"""
        # Simplified similarity calculation
        return 0.5  # Placeholder
    
    def _recommend_accent_colors(self, colors: List[Tuple[int, int, int]], 
                               temperature: str) -> List[str]:
        """Recommend accent colors"""
        # Placeholder for accent color recommendations
        return ["#FF6B6B", "#4ECDC4", "#45B7D1"]
    
    def _recommend_neutral_bases(self, season: str, temperature: str) -> List[str]:
        """Recommend neutral base colors"""
        neutrals = {
            "spring": ["#F5F5DC", "#DCDCDC", "#C0C0C0"],
            "summer": ["#F8F8FF", "#E0E0E0", "#D3D3D3"],
            "autumn": ["#F5DEB3", "#D2B48C", "#BC8F8F"],
            "winter": ["#FFFFFF", "#000000", "#696969"]
        }
        return neutrals.get(season, neutrals["spring"])
    
    def _get_colors_to_avoid(self, season: str, temperature: str) -> List[str]:
        """Get colors to avoid for the season/temperature"""
        # Placeholder for colors to avoid
        return ["#FF1493", "#00FF00"]  # Placeholder
    
    def _check_complementary_harmony(self, color1: Tuple[int, int, int], 
                                   color2: Tuple[int, int, int]) -> float:
        """Check complementary color harmony"""
        # Convert to HSV and check if hues are ~180° apart
        h1, _, _ = colorsys.rgb_to_hsv(color1[0]/255, color1[1]/255, color1[2]/255)
        h2, _, _ = colorsys.rgb_to_hsv(color2[0]/255, color2[1]/255, color2[2]/255)
        
        hue_diff = abs((h1 - h2) * 360)
        if hue_diff > 180:
            hue_diff = 360 - hue_diff
            
        tolerance = self.color_harmony_rules["complementary_tolerance"]
        
        if abs(hue_diff - 180) <= tolerance:
            return 1.0 - (abs(hue_diff - 180) / tolerance)
        
        return 0.0
    
    def _check_analogous_harmony(self, color1: Tuple[int, int, int], 
                               color2: Tuple[int, int, int]) -> float:
        """Check analogous color harmony"""
        h1, _, _ = colorsys.rgb_to_hsv(color1[0]/255, color1[1]/255, color1[2]/255)
        h2, _, _ = colorsys.rgb_to_hsv(color2[0]/255, color2[1]/255, color2[2]/255)
        
        hue_diff = abs((h1 - h2) * 360)
        if hue_diff > 180:
            hue_diff = 360 - hue_diff
        
        min_range, max_range = self.color_harmony_rules["analogous_range"]
        
        if min_range <= hue_diff <= max_range:
            # Score based on how close to ideal analogous range
            ideal_diff = (min_range + max_range) / 2
            return 1.0 - abs(hue_diff - ideal_diff) / (max_range - min_range)
        
        return 0.0
    
    def _check_triadic_harmony(self, color1: Tuple[int, int, int], 
                             color2: Tuple[int, int, int]) -> float:
        """Check triadic color harmony"""
        h1, _, _ = colorsys.rgb_to_hsv(color1[0]/255, color1[1]/255, color1[2]/255)
        h2, _, _ = colorsys.rgb_to_hsv(color2[0]/255, color2[1]/255, color2[2]/255)
        
        hue_diff = abs((h1 - h2) * 360)
        if hue_diff > 180:
            hue_diff = 360 - hue_diff
            
        tolerance = self.color_harmony_rules["triadic_tolerance"]
        
        if abs(hue_diff - 120) <= tolerance:
            return 1.0 - (abs(hue_diff - 120) / tolerance)
        
        return 0.0
    
    def _find_complementary_colors(self, colors: List[Tuple[int, int, int]]) -> List[str]:
        """Find complementary colors for the palette"""
        complementary = []
        
        for r, g, b in colors:
            h, s, v = colorsys.rgb_to_hsv(r/255, g/255, b/255)
            # Add 180 degrees (0.5 in HSV) for complementary
            comp_h = (h + 0.5) % 1.0
            comp_r, comp_g, comp_b = colorsys.hsv_to_rgb(comp_h, s, v)
            comp_rgb = (int(comp_r * 255), int(comp_g * 255), int(comp_b * 255))
            complementary.append(self._rgb_to_hex(comp_rgb))
        
        return complementary[:3]  # Return top 3
    
    def _find_analogous_colors(self, colors: List[Tuple[int, int, int]]) -> List[str]:
        """Find analogous colors for the palette"""
        analogous = []
        
        for r, g, b in colors:
            h, s, v = colorsys.rgb_to_hsv(r/255, g/255, b/255)
            
            # Add ±30 degrees for analogous colors
            for offset in [-30/360, 30/360]:
                analog_h = (h + offset) % 1.0
                analog_r, analog_g, analog_b = colorsys.hsv_to_rgb(analog_h, s, v)
                analog_rgb = (int(analog_r * 255), int(analog_g * 255), int(analog_b * 255))
                analogous.append(self._rgb_to_hex(analog_rgb))
        
        return analogous[:4]  # Return top 4
