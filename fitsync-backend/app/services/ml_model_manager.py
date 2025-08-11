# app/services/ml_model_manager.py
from __future__ import annotations

import logging
from typing import Dict, Any

from app.config import settings
from app.models.detection.clothing_detector import ClothingDetector

logger = logging.getLogger(__name__)

class MLModelManager:
    def __init__(self) -> None:
        self.models: Dict[str, Any] = {}
        self.status: Dict[str, Dict[str, Any]] = {}

    async def initialize(self) -> None:
        logger.info("Initializing ML Model Manager...")

        # Resolve device
        device = None
        try:
            if getattr(settings, "ENABLE_GPU", False):
                device = getattr(settings, "GPU_DEVICE", "cuda:0")
            else:
                device = "cpu"
        except Exception:
            device = "cpu"

        # Clothing detector
        try:
            model_path = getattr(settings, "CLOTHING_DETECTION_MODEL", "yolov8n.pt")
            cd = ClothingDetector(model_path=model_path, device=device)
            await cd.load()
            self.models["clothing_detector"] = cd
            self.status["clothing_detector"] = {
                "status": "ready" if cd.available else "disabled",
                "device": device,
                "model_path": model_path,
            }
            if not cd.available:
                logger.warning("clothing_detector not available (Ultralytics missing or load failed).")
        except Exception as e:
            logger.exception(f"Error loading clothing_detector: {e}")
            self.status["clothing_detector"] = {"status": "error", "error": str(e)}

        logger.info("ML Model Manager initialization complete.")

    async def cleanup(self) -> None:
        # Add any GPU memory cleanup if needed
        logger.info("ML Model Manager cleanup complete.")

    async def get_model_status(self) -> Dict[str, Dict[str, Any]]:
        # Ensure keys exist even if initialize() never ran
        if "clothing_detector" not in self.status:
            self.status["clothing_detector"] = {"status": "not_initialized"}
        return self.status
    
    async def is_model_ready(self, model_name: str) -> bool:
        """Check if a specific model is ready for use"""
        if model_name not in self.models:
            return False
        if model_name not in self.status:
            return False
        return self.status[model_name].get("status") == "ready"

# Singleton
ml_model_manager = MLModelManager()

async def get_ml_model(model_name: str):
    """Async context manager to get a specific ML model"""
    if model_name not in ml_model_manager.models:
        raise ValueError(f"Model '{model_name}' not found or not initialized")
    
    model = ml_model_manager.models[model_name]
    
    class ModelContextManager:
        def __init__(self, model):
            self.model = model
        
        async def __aenter__(self):
            return self.model
        
        async def __aexit__(self, exc_type, exc_val, exc_tb):
            # No cleanup needed for now
            pass
    
    return ModelContextManager(model)
