#!/usr/bin/env python3
"""
Script to download pre-trained ML models
"""

import os
import urllib.request
import logging
from pathlib import Path

from app.config import settings

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def download_models():
    """Download all required ML models"""
    
    # Create models directory
    os.makedirs(settings.model_cache_dir, exist_ok=True)
    
    # Model URLs (replace with actual URLs)
    models = {
        "clothing_detector": {
            "url": "https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8n.pt",
            "path": settings.clothing_detection_model
        },
        "pose_estimator": {
            "url": "https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_lite/float16/1/pose_landmarker_lite.task",
            "path": settings.pose_estimation_model
        },
        # Add more models as needed
    }
    
    for model_name, config in models.items():
        model_path = config["path"]
        
        if os.path.exists(model_path):
            logger.info(f"✅ {model_name} already exists at {model_path}")
            continue
        
        try:
            logger.info(f"�� Downloading {model_name}...")
            
            # Create directory if needed
            os.makedirs(os.path.dirname(model_path), exist_ok=True)
            
            # Download file
            urllib.request.urlretrieve(config["url"], model_path)
            
            logger.info(f"✅ Downloaded {model_name} to {model_path}")
            
        except Exception as e:
            logger.error(f"❌ Failed to download {model_name}: {e}")

if __name__ == "__main__":
    download_models()
