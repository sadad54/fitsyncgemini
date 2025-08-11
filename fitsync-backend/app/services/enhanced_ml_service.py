"""
Enhanced ML Service with model manager integration
"""

import asyncio
import logging
from typing import Dict, Any, List, Optional
import numpy as np
from PIL import Image
import io

from app.services.ml_model_manager import ml_model_manager, get_ml_model
from app.utils.image_processing import ImageProcessor
from app.utils.color_analysis import ColorAnalyzer
from app.core.exceptions import MLModelError

logger = logging.getLogger(__name__)

class EnhancedMLService:
    """Enhanced ML service with comprehensive model integration"""
    
    def __init__(self):
        self.image_processor = ImageProcessor()
        self.color_analyzer = ColorAnalyzer()
        self._initialized = False
    
    async def initialize(self):
        """Initialize the ML service and model manager"""
        if not self._initialized:
            await ml_model_manager.initialize()
            self._initialized = True
            logger.info("Enhanced ML Service initialized")
    
    async def analyze_clothing_image(self, image_data: bytes, user_id: Optional[int] = None) -> Dict[str, Any]:
        """Complete clothing analysis pipeline"""
        await self.initialize()
        
        try:
            # Process image
            image = self.image_processor.process_upload(image_data)
            image = self.image_processor.resize_image(image)
            
            # Detect clothing items
            async with get_ml_model("clothing_detector") as detector:
                detections = detector.detect_clothing(image)
            
            # Analyze each detection
            analyzed_items = []
            for detection in detections:
                item_analysis = await self._analyze_clothing_item(image, detection)
                analyzed_items.append(item_analysis)
            
            # Generate overall analysis
            overall_analysis = self._generate_overall_analysis(analyzed_items)
            
            return {
                'items': analyzed_items,
                'item_count': len(analyzed_items),
                'overall_analysis': overall_analysis,
                'status': 'success'
            }
            
        except Exception as e:
            logger.error(f"Clothing analysis failed: {e}")
            raise MLModelError("clothing_analysis", "analysis_failed", {"error": str(e)})
    
    async def _analyze_clothing_item(self, image: np.ndarray, detection: Dict[str, Any]) -> Dict[str, Any]:
        """Analyze a single clothing item"""
        try:
            # Extract clothing region
            bbox = detection['bbox']
            clothing_region = image[bbox[1]:bbox[3], bbox[0]:bbox[2]]
            
            # Color analysis
            color_palette = self.color_analyzer.extract_palette(clothing_region)
            color_harmony = self.color_analyzer.analyze_color_harmony(color_palette.colors)
            
            # Style classification (if model is available)
            style_classification = None
            if await ml_model_manager.is_model_ready("style_matcher"):
                async with get_ml_model("style_matcher") as style_model:
                    style_classification = style_model.classify_style(clothing_region)
            
            return {
                'type': detection['class'],
                'confidence': detection['confidence'],
                'bbox': detection['bbox'],
                'color_palette': color_palette.dict(),
                'color_harmony': color_harmony.dict(),
                'style_classification': style_classification,
                'features': detection.get('features', {})
            }
            
        except Exception as e:
            logger.error(f"Item analysis failed: {e}")
            return {
                'type': detection['class'],
                'confidence': detection['confidence'],
                'bbox': detection['bbox'],
                'error': str(e)
            }
    
    def _generate_overall_analysis(self, items: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Generate overall analysis from individual items"""
        if not items:
            return {}
        
        # Aggregate colors
        all_colors = []
        for item in items:
            if 'color_palette' in item:
                all_colors.extend(item['color_palette']['colors'])
        
        # Overall color harmony
        overall_harmony = self.color_analyzer.analyze_color_harmony(all_colors) if all_colors else None
        
        # Style distribution
        style_distribution = {}
        for item in items:
            if item.get('style_classification'):
                style = item['style_classification']['style']
                style_distribution[style] = style_distribution.get(style, 0) + 1
        
        return {
            'overall_color_harmony': overall_harmony.dict() if overall_harmony else None,
            'style_distribution': style_distribution,
            'total_items': len(items),
            'confidence_avg': sum(item.get('confidence', 0) for item in items) / len(items)
        }
    
    async def estimate_body_pose(self, image_data: bytes) -> Dict[str, Any]:
        """Estimate body pose and measurements"""
        await self.initialize()
        
        try:
            image = self.image_processor.process_upload(image_data)
            
            async with get_ml_model("pose_estimator") as pose_model:
                pose_landmarks = pose_model.estimate_pose(image)
                
                if pose_landmarks:
                    measurements = pose_model.calculate_body_measurements(
                        pose_landmarks, image.shape[0], image.shape[1]
                    )
                    body_type = pose_model.get_body_type(measurements)
                    
                    return {
                        'pose_landmarks': pose_landmarks,
                        'measurements': measurements.dict(),
                        'body_type': body_type,
                        'status': 'success'
                    }
                else:
                    return {
                        'status': 'error',
                        'message': 'No pose detected in image'
                    }
                    
        except Exception as e:
            logger.error(f"Pose estimation failed: {e}")
            raise MLModelError("pose_estimation", "estimation_failed", {"error": str(e)})
    
    async def generate_virtual_tryon(self, person_image: bytes, clothing_image: bytes) -> Dict[str, Any]:
        """Generate virtual try-on visualization"""
        await self.initialize()
        
        try:
            person_img = self.image_processor.process_upload(person_image)
            clothing_img = self.image_processor.process_upload(clothing_image)
            
            async with get_ml_model("virtual_tryon") as tryon_model:
                result = tryon_model.generate_tryon(person_img, clothing_img)
                
                return {
                    'tryon_image': result.tryon_image.tolist(),
                    'confidence': result.confidence,
                    'status': 'success'
                }
                
        except Exception as e:
            logger.error(f"Virtual try-on failed: {e}")
            raise MLModelError("virtual_tryon", "generation_failed", {"error": str(e)})
    
    async def get_user_recommendations(self, user_id: int, context: Dict[str, Any] = None) -> Dict[str, Any]:
        """Get personalized recommendations for user"""
        await self.initialize()
        
        try:
            recommendations = {}
            
            # Style recommendations
            if await ml_model_manager.is_model_ready("style_matcher"):
                async with get_ml_model("style_matcher") as style_model:
                    style_recs = style_model.get_style_recommendations(user_id, context)
                    recommendations['style'] = style_recs
            
            # User profiling recommendations
            if await ml_model_manager.is_model_ready("user_profiler"):
                async with get_ml_model("user_profiler") as profiler:
                    profile_recs = profiler.generate_recommendations(user_id, context)
                    recommendations['profile'] = profile_recs
            
            return {
                'recommendations': recommendations,
                'status': 'success'
            }
            
        except Exception as e:
            logger.error(f"Recommendation generation failed: {e}")
            raise MLModelError("recommendations", "generation_failed", {"error": str(e)})
    
    async def get_model_status(self) -> Dict[str, Any]:
        """Get status of all ML models"""
        return await ml_model_manager.get_model_status()

# Global instance
enhanced_ml_service = EnhancedMLService()
