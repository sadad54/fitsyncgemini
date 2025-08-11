# app/models/detection/clothing_detector.py
from __future__ import annotations

from typing import List, Dict, Any, Optional
import logging

# Try to import ultralytics at module level
try:
    from ultralytics import YOLO  # type: ignore
    ULTRALYTICS_AVAILABLE = True
except ImportError:
    ULTRALYTICS_AVAILABLE = False
    YOLO = None

logger = logging.getLogger(__name__)

class ClothingDetector:
    """
    YOLOv8 wrapper that:
      - Works even if Ultralytics isn't installed (it returns empty results)
      - Accepts optional `model_path` and `device` ("cpu" | "cuda:0" …)
    """

    def __init__(self, model_path: Optional[str] = "yolov8n.pt", device: Optional[str] = None):
        self.model_path = model_path
        self.device = device  # "cpu" or "cuda:0"
        self.model = None
        self.available = False

    async def load(self) -> None:
        if not ULTRALYTICS_AVAILABLE:
            logger.warning("Ultralytics not available; detection disabled")
            self.available = False
            return

        try:
            self.model = YOLO(self.model_path or "yolov8n.pt")
            # Move model to device if provided
            if self.device:
                try:
                    self.model.to(self.device)
                except Exception as e:
                    logger.warning(f"Could not move YOLO to device '{self.device}': {e}")
            self.available = True
            logger.info("ClothingDetector loaded.")
        except Exception as e:
            logger.error(f"Failed to load ClothingDetector: {e}")
            self.available = False

    async def detect(self, image_path: str) -> List[Dict[str, Any]]:
        if not self.available or self.model is None:
            return []

        try:
            results = self.model(image_path, verbose=False)
        except Exception as e:
            logger.error(f"YOLO inference error: {e}")
            return []

        boxes: List[Dict[str, Any]] = []
        try:
            for r in results:
                # r.boxes may be empty
                for b in getattr(r, "boxes", []) or []:
                    xyxy = b.xyxy.cpu().numpy().astype(float)[0]
                    boxes.append({
                        "x1": float(xyxy[0]),
                        "y1": float(xyxy[1]),
                        "x2": float(xyxy[2]),
                        "y2": float(xyxy[3]),
                        "confidence": float(b.conf.cpu().numpy()[0]),
                        "label": str(int(b.cls.cpu().numpy()[0])),
                    })
        except Exception as e:
            logger.error(f"Failed to parse YOLO results: {e}")
        return boxes
