import cv2
import numpy as np
from PIL import Image
import io
import base64
from typing import Tuple, Optional

class ImageProcessor:
    @staticmethod
    def process_upload(image_data: bytes) -> np.ndarray:
        """Convert uploaded image to OpenCV format"""
        image = Image.open(io.BytesIO(image_data))
        image = image.convert('RGB')
        return cv2.cvtColor(np.array(image), cv2.COLOR_RGB2BGR)
    
    @staticmethod
    def resize_image(image: np.ndarray, max_size: int = 800) -> np.ndarray:
        """Resize image while maintaining aspect ratio"""
        height, width = image.shape[:2]
        
        if max(height, width) <= max_size:
            return image
        
        scale = max_size / max(height, width)
        new_width = int(width * scale)
        new_height = int(height * scale)
        
        return cv2.resize(image, (new_width, new_height))
    
    @staticmethod
    def extract_dominant_colors(image: np.ndarray, k: int = 5) -> list:
        """Extract dominant colors using K-means"""
        from sklearn.cluster import KMeans
        
        # Reshape image to 2D array of pixels
        data = image.reshape((-1, 3))
        data = np.float32(data)
        
        # Apply K-means
        kmeans = KMeans(n_clusters=k, random_state=42)
        kmeans.fit(data)
        
        colors = kmeans.cluster_centers_.astype(int)
        return [tuple(color) for color in colors]