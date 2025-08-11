from fastapi import HTTPException, status
from typing import Any, Dict, Optional

class FitSyncException(Exception):
    """Base exception for FitSync application"""
    
    def __init__(
        self, 
        message: str, 
        error_code: str = None, 
        status_code: int = 500,
        details: Dict[str, Any] = None
    ):
        self.message = message
        self.error_code = error_code
        self.status_code = status_code
        self.details = details or {}
        super().__init__(self.message)

class ValidationError(FitSyncException):
    """Raised when input validation fails"""
    
    def __init__(self, message: str, field: str = None, details: Dict[str, Any] = None):
        super().__init__(
            message=message,
            error_code="VALIDATION_ERROR",
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            details={"field": field, **(details or {})}
        )

class AuthenticationError(FitSyncException):
    """Raised when authentication fails"""
    
    def __init__(self, message: str = "Authentication failed", details: Dict[str, Any] = None):
        super().__init__(
            message=message,
            error_code="AUTHENTICATION_ERROR",
            status_code=status.HTTP_401_UNAUTHORIZED,
            details=details
        )

class AuthorizationError(FitSyncException):
    """Raised when user lacks permission"""
    
    def __init__(self, message: str = "Insufficient permissions", details: Dict[str, Any] = None):
        super().__init__(
            message=message,
            error_code="AUTHORIZATION_ERROR",
            status_code=status.HTTP_403_FORBIDDEN,
            details=details
        )

class ResourceNotFoundError(FitSyncException):
    """Raised when a requested resource is not found"""
    
    def __init__(self, resource_type: str, resource_id: str, details: Dict[str, Any] = None):
        super().__init__(
            message=f"{resource_type} with id {resource_id} not found",
            error_code="RESOURCE_NOT_FOUND",
            status_code=status.HTTP_404_NOT_FOUND,
            details={"resource_type": resource_type, "resource_id": resource_id, **(details or {})}
        )

class DuplicateResourceError(FitSyncException):
    """Raised when trying to create a duplicate resource"""
    
    def __init__(self, resource_type: str, field: str, value: str, details: Dict[str, Any] = None):
        super().__init__(
            message=f"{resource_type} with {field} '{value}' already exists",
            error_code="DUPLICATE_RESOURCE",
            status_code=status.HTTP_409_CONFLICT,
            details={"resource_type": resource_type, "field": field, "value": value, **(details or {})}
        )

class MLModelError(FitSyncException):
    """Raised when ML model operations fail"""
    
    def __init__(self, model_type: str, operation: str, details: Dict[str, Any] = None):
        super().__init__(
            message=f"ML model {model_type} failed during {operation}",
            error_code="ML_MODEL_ERROR",
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            details={"model_type": model_type, "operation": operation, **(details or {})}
        )

class ImageProcessingError(FitSyncException):
    """Raised when image processing fails"""
    
    def __init__(self, operation: str, details: Dict[str, Any] = None):
        super().__init__(
            message=f"Image processing failed during {operation}",
            error_code="IMAGE_PROCESSING_ERROR",
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            details={"operation": operation, **(details or {})}
        )

class DatabaseError(FitSyncException):
    """Raised when database operations fail"""
    
    def __init__(self, operation: str, details: Dict[str, Any] = None):
        super().__init__(
            message=f"Database operation failed: {operation}",
            error_code="DATABASE_ERROR",
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            details={"operation": operation, **(details or {})}
        )

class CacheError(FitSyncException):
    """Raised when cache operations fail"""
    
    def __init__(self, operation: str, details: Dict[str, Any] = None):
        super().__init__(
            message=f"Cache operation failed: {operation}",
            error_code="CACHE_ERROR",
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            details={"operation": operation, **(details or {})}
        )

class ExternalServiceError(FitSyncException):
    """Raised when external service calls fail"""
    
    def __init__(self, service_name: str, operation: str, details: Dict[str, Any] = None):
        super().__init__(
            message=f"External service {service_name} failed during {operation}",
            error_code="EXTERNAL_SERVICE_ERROR",
            status_code=status.HTTP_502_BAD_GATEWAY,
            details={"service_name": service_name, "operation": operation, **(details or {})}
        )

class RateLimitError(FitSyncException):
    """Raised when rate limit is exceeded"""
    
    def __init__(self, limit: int, window: str, details: Dict[str, Any] = None):
        super().__init__(
            message=f"Rate limit exceeded: {limit} requests per {window}",
            error_code="RATE_LIMIT_ERROR",
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            details={"limit": limit, "window": window, **(details or {})}
        )

class FileUploadError(FitSyncException):
    """Raised when file upload fails"""
    
    def __init__(self, file_name: str, reason: str, details: Dict[str, Any] = None):
        super().__init__(
            message=f"File upload failed for {file_name}: {reason}",
            error_code="FILE_UPLOAD_ERROR",
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            details={"file_name": file_name, "reason": reason, **(details or {})}
        )

class RecommendationError(FitSyncException):
    """Raised when recommendation generation fails"""
    
    def __init__(self, recommendation_type: str, details: Dict[str, Any] = None):
        super().__init__(
            message=f"Failed to generate {recommendation_type} recommendations",
            error_code="RECOMMENDATION_ERROR",
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            details={"recommendation_type": recommendation_type, **(details or {})}
        )

class VirtualTryOnError(FitSyncException):
    """Raised when virtual try-on fails"""
    
    def __init__(self, reason: str, details: Dict[str, Any] = None):
        super().__init__(
            message=f"Virtual try-on failed: {reason}",
            error_code="VIRTUAL_TRYON_ERROR",
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            details={"reason": reason, **(details or {})}
        )

def handle_fitsync_exception(exc: FitSyncException) -> Dict[str, Any]:
    """Convert FitSyncException to HTTP response format"""
    return {
        "error": {
            "code": exc.error_code,
            "message": exc.message,
            "details": exc.details
        }
    }

def raise_validation_error(message: str, field: str = None, details: Dict[str, Any] = None):
    """Helper function to raise validation error"""
    raise ValidationError(message, field, details)

def raise_not_found_error(resource_type: str, resource_id: str, details: Dict[str, Any] = None):
    """Helper function to raise not found error"""
    raise ResourceNotFoundError(resource_type, resource_id, details)

def raise_duplicate_error(resource_type: str, field: str, value: str, details: Dict[str, Any] = None):
    """Helper function to raise duplicate resource error"""
    raise DuplicateResourceError(resource_type, field, value, details)

def raise_ml_error(model_type: str, operation: str, details: Dict[str, Any] = None):
    """Helper function to raise ML model error"""
    raise MLModelError(model_type, operation, details)
