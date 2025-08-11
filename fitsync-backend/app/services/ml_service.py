from typing import List, Dict, Any
import numpy as np
from app.models.detection.clothing_detector import ClothingDetector
from app.utils.image_processing import ImageProcessor

class MLService:
    def __init__(self):
        self.clothing_detector = ClothingDetector()
        self.image_processor = ImageProcessor()
    
    async def analyze_clothing_image(self, image_data: bytes) -> Dict[str, Any]:
        """Complete clothing analysis pipeline"""
        try:
            # Process image
            image = self.image_processor.process_upload(image_data)
            image = self.image_processor.resize_image(image)
            
            # Detect clothing items
            detections = self.clothing_detector.detect_clothing(image)
            
            # Extract features for each detection
            analyzed_items = []
            for detection in detections:
                features = self.clothing_detector.extract_clothing_features(
                    image, detection['bbox']
                )
                
                item = {
                    'type': detection['class'],
                    'confidence': detection['confidence'],
                    'features': features
                }
                analyzed_items.append(item)
            
            return {
                'items': analyzed_items,
                'item_count': len(analyzed_items),
                'status': 'success'
            }
            
        except Exception as e:
            return {
                'items': [],
                'item_count': 0,
                'status': 'error',
                'message': str(e)
            }