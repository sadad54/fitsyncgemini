from typing import Optional, Dict, Any

class FitSyncException(Exception):
    """Base exception for FitSync application"""
    
    def __init__(self, detail: str, status_code: int = 500, error_code: str = "INTERNAL_ERROR"):
        self.detail = detail
        self.status_code = status_code
        self.error_code = error_code
        super().__init__(self.detail)

class ValidationError(FitSyncException):
    """Input validation error"""
    
    def __init__(self, detail: str, field: Optional[str] = None):
        super().__init__(detail, status_code=400, error_code="VALIDATION_ERROR")
        self.field = field

class ModelNotFoundError(FitSyncException):
    """ML model not found or not loaded"""
    
    def __init__(self, model_name: str):
        detail = f"ML model '{model_name}' not found or not initialized"
        super().__init__(detail, status_code=503, error_code="MODEL_NOT_FOUND")
        self.model_name = model_name

class ImageProcessingError(FitSyncException):
    """Image processing failed"""
    
    def __init__(self, detail: str, operation: str):
        super().__init__(detail, status_code=422, error_code="IMAGE_PROCESSING_ERROR")
        self.operation = operation

class RecommendationError(FitSyncException):
    """Recommendation generation failed"""
    
    def __init__(self, detail: str):
        super().__init__(detail, status_code=500, error_code="RECOMMENDATION_ERROR")

class TryOnError(FitSyncException):
    """Virtual try-on generation failed"""
    
    def __init__(self, detail: str, job_id: Optional[str] = None):
        super().__init__(detail, status_code=500, error_code="TRYON_ERROR")
        self.job_id = job_id

class RateLimitError(FitSyncException):
    """Rate limit exceeded"""
    
    def __init__(self, detail: str = "Rate limit exceeded"):
        super().__init__(detail, status_code=429, error_code="RATE_LIMIT_EXCEEDED")
