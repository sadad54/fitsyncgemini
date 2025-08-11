"""
Pose Estimation Model for Body Type Analysis and Virtual Try-On
"""

import cv2
import numpy as np
import mediapipe as mp
from typing import Dict, List, Tuple, Optional
import logging
from dataclasses import dataclass

logger = logging.getLogger(__name__)

@dataclass
class PoseLandmarks:
    """Pose landmarks data structure"""
    landmarks: List[Tuple[float, float, float]]
    visibility: List[float]
    pose_world_landmarks: Optional[List[Tuple[float, float, float]]] = None

@dataclass
class BodyMeasurements:
    """Body measurements from pose estimation"""
    height: float
    shoulder_width: float
    chest_circumference: float
    waist_circumference: float
    hip_circumference: float
    inseam_length: float
    arm_length: float
    confidence: float

class PoseEstimator:
    """MediaPipe-based pose estimation for body measurements"""
    
    def __init__(self, static_mode: bool = False, model_complexity: int = 1):
        """
        Initialize pose estimator
        
        Args:
            static_mode: Whether to use static mode for better accuracy
            model_complexity: Model complexity (0, 1, or 2)
        """
        self.mp_pose = mp.solutions.pose
        self.pose = self.mp_pose.Pose(
            static_image_mode=static_mode,
            model_complexity=model_complexity,
            enable_segmentation=True,
            min_detection_confidence=0.5
        )
        self.mp_drawing = mp.solutions.drawing_utils
        
    def estimate_pose(self, image: np.ndarray) -> Optional[PoseLandmarks]:
        """
        Estimate pose from image
        
        Args:
            image: Input image (BGR format)
            
        Returns:
            PoseLandmarks object or None if no pose detected
        """
        try:
            # Convert BGR to RGB
            rgb_image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
            
            # Process image
            results = self.pose.process(rgb_image)
            
            if results.pose_landmarks:
                landmarks = []
                visibility = []
                
                for landmark in results.pose_landmarks.landmark:
                    landmarks.append((landmark.x, landmark.y, landmark.z))
                    visibility.append(landmark.visibility)
                
                pose_world_landmarks = None
                if results.pose_world_landmarks:
                    pose_world_landmarks = [
                        (lm.x, lm.y, lm.z) for lm in results.pose_world_landmarks.landmark
                    ]
                
                return PoseLandmarks(
                    landmarks=landmarks,
                    visibility=visibility,
                    pose_world_landmarks=pose_world_landmarks
                )
            
            return None
            
        except Exception as e:
            logger.error(f"Error in pose estimation: {e}")
            return None
    
    def calculate_body_measurements(self, pose_landmarks: PoseLandmarks, 
                                  image_height: int, image_width: int) -> BodyMeasurements:
        """
        Calculate body measurements from pose landmarks
        
        Args:
            pose_landmarks: Detected pose landmarks
            image_height: Image height in pixels
            image_width: Image width in pixels
            
        Returns:
            BodyMeasurements object
        """
        try:
            landmarks = pose_landmarks.landmarks
            visibility = pose_landmarks.visibility
            
            # MediaPipe pose landmarks indices
            LEFT_SHOULDER = 11
            RIGHT_SHOULDER = 12
            LEFT_HIP = 23
            RIGHT_HIP = 24
            LEFT_KNEE = 25
            RIGHT_KNEE = 26
            LEFT_ANKLE = 27
            RIGHT_ANKLE = 28
            LEFT_WRIST = 15
            RIGHT_WRIST = 16
            LEFT_ELBOW = 13
            RIGHT_ELBOW = 14
            
            # Calculate measurements in pixels
            shoulder_width = self._calculate_distance(
                landmarks[LEFT_SHOULDER], landmarks[RIGHT_SHOULDER], 
                image_width, image_height
            )
            
            # Estimate other measurements based on shoulder width
            # These are rough estimates - in production, you'd use more sophisticated algorithms
            chest_circumference = shoulder_width * 2.5
            waist_circumference = shoulder_width * 2.2
            hip_circumference = shoulder_width * 2.8
            
            # Calculate height
            height = self._calculate_distance(
                landmarks[LEFT_SHOULDER], landmarks[LEFT_ANKLE],
                image_width, image_height
            )
            
            # Calculate inseam
            inseam_length = self._calculate_distance(
                landmarks[LEFT_HIP], landmarks[LEFT_ANKLE],
                image_width, image_height
            )
            
            # Calculate arm length
            arm_length = self._calculate_distance(
                landmarks[LEFT_SHOULDER], landmarks[LEFT_WRIST],
                image_width, image_height
            )
            
            # Calculate confidence based on landmark visibility
            avg_visibility = np.mean(visibility)
            confidence = min(avg_visibility * 1.2, 1.0)  # Boost confidence slightly
            
            return BodyMeasurements(
                height=height,
                shoulder_width=shoulder_width,
                chest_circumference=chest_circumference,
                waist_circumference=waist_circumference,
                hip_circumference=hip_circumference,
                inseam_length=inseam_length,
                arm_length=arm_length,
                confidence=confidence
            )
            
        except Exception as e:
            logger.error(f"Error calculating body measurements: {e}")
            return BodyMeasurements(
                height=0.0, shoulder_width=0.0, chest_circumference=0.0,
                waist_circumference=0.0, hip_circumference=0.0,
                inseam_length=0.0, arm_length=0.0, confidence=0.0
            )
    
    def _calculate_distance(self, point1: Tuple[float, float, float], 
                          point2: Tuple[float, float, float],
                          image_width: int, image_height: int) -> float:
        """Calculate Euclidean distance between two points in pixels"""
        x1, y1, _ = point1
        x2, y2, _ = point2
        
        # Convert normalized coordinates to pixels
        x1_px = x1 * image_width
        y1_px = y1 * image_height
        x2_px = x2 * image_width
        y2_px = y2 * image_height
        
        return np.sqrt((x2_px - x1_px)**2 + (y2_px - y1_px)**2)
    
    def draw_pose(self, image: np.ndarray, pose_landmarks: PoseLandmarks) -> np.ndarray:
        """
        Draw pose landmarks on image
        
        Args:
            image: Input image
            pose_landmarks: Detected pose landmarks
            
        Returns:
            Image with pose landmarks drawn
        """
        try:
            # Convert landmarks back to MediaPipe format
            mp_landmarks = self.mp_pose.PoseLandmark
            landmarks_list = []
            
            for i, (x, y, z) in enumerate(pose_landmarks.landmarks):
                landmark = mp_landmarks(x=x, y=y, z=z, visibility=pose_landmarks.visibility[i])
                landmarks_list.append(landmark)
            
            # Draw landmarks
            annotated_image = image.copy()
            self.mp_drawing.draw_landmarks(
                annotated_image,
                landmarks_list,
                self.mp_pose.POSE_CONNECTIONS
            )
            
            return annotated_image
            
        except Exception as e:
            logger.error(f"Error drawing pose: {e}")
            return image
    
    def get_body_type(self, measurements: BodyMeasurements) -> str:
        """
        Determine body type based on measurements
        
        Args:
            measurements: Body measurements
            
        Returns:
            Body type classification
        """
        try:
            # Calculate body proportions
            shoulder_to_hip_ratio = measurements.shoulder_width / measurements.hip_circumference
            waist_to_hip_ratio = measurements.waist_circumference / measurements.hip_circumference
            
            # Body type classification based on proportions
            if shoulder_to_hip_ratio > 1.1:
                return "inverted_triangle"
            elif shoulder_to_hip_ratio < 0.9:
                return "triangle"
            elif waist_to_hip_ratio < 0.8:
                return "hourglass"
            elif waist_to_hip_ratio > 0.9:
                return "rectangle"
            else:
                return "oval"
                
        except Exception as e:
            logger.error(f"Error determining body type: {e}")
            return "unknown"
    
    def cleanup(self):
        """Clean up resources"""
        if hasattr(self, 'pose'):
            self.pose.close()
