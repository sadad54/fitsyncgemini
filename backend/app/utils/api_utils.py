import httpx
from typing import Dict, Any, Optional
import json
from loguru import logger

class APIUtils:
    @staticmethod
    async def make_request(
        url: str,
        method: str = "GET",
        headers: Optional[Dict[str, str]] = None,
        data: Optional[Dict[str, Any]] = None,
        timeout: int = 30
    ) -> Dict[str, Any]:
        """Make HTTP request with error handling"""
        try:
            async with httpx.AsyncClient(timeout=timeout) as client:
                if method.upper() == "GET":
                    response = await client.get(url, headers=headers)
                elif method.upper() == "POST":
                    response = await client.post(url, headers=headers, json=data)
                elif method.upper() == "PUT":
                    response = await client.put(url, headers=headers, json=data)
                elif method.upper() == "DELETE":
                    response = await client.delete(url, headers=headers)
                else:
                    raise ValueError(f"Unsupported HTTP method: {method}")
                
                response.raise_for_status()
                return response.json()
                
        except httpx.HTTPStatusError as e:
            logger.error(f"HTTP error occurred: {e.response.status_code} - {e.response.text}")
            raise
        except httpx.RequestError as e:
            logger.error(f"Request error occurred: {e}")
            raise
        except Exception as e:
            logger.error(f"Unexpected error: {e}")
            raise

    @staticmethod
    def validate_api_response(response: Dict[str, Any], required_fields: list) -> bool:
        """Validate API response contains required fields"""
        return all(field in response for field in required_fields)

    @staticmethod
    def format_error_response(error: str, status_code: int = 400) -> Dict[str, Any]:
        """Format error response"""
        return {
            "error": error,
            "status_code": status_code,
            "success": False
        }
