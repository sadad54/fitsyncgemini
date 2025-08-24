import aiohttp
import asyncio
from typing import Dict, List, Optional, BinaryIO
import base64
import json
from app.core.config import settings
from app.utils.rate_limiter import rate_limiter
from fastapi import HTTPException

class FashionAIClient:
    def __init__(self):
        self.base_url = settings.FASHION_AI_BASE_URL
        self.api_key = settings.FASHION_AI_API_KEY
        self.headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
    
    async def virtual_tryon(
        self, 
        person_image: bytes, 
        clothing_image: bytes, 
        user_id: str,
        tryon_type: str = "full_body"
    ) -> Dict:
        """
        Perform virtual try-on using Fashion AI API
        
        Args:
            person_image: User's photo as bytes
            clothing_image: Clothing item image as bytes
            user_id: User identifier for rate limiting
            tryon_type: "upper_body", "lower_body", or "full_body"
        """
        
        # Check rate limit
        allowed, reset_time = await rate_limiter.check_rate_limit(
            "fashion_ai", 
            settings.FASHION_AI_RATE_LIMIT,
            3600,  # 1 hour
            user_id
        )
        
        if not allowed:
            raise HTTPException(
                status_code=429,
                detail=f"Fashion AI rate limit exceeded. Reset at {reset_time}"
            )
        
        # Encode images to base64
        person_b64 = base64.b64encode(person_image).decode('utf-8')
        clothing_b64 = base64.b64encode(clothing_image).decode('utf-8')
        
        payload = {
            "person_image": person_b64,
            "clothing_image": clothing_b64,
            "tryon_type": tryon_type,
            "generate_mask": True,
            "preserve_background": True,
            "output_format": "jpg",
            "quality": "high"
        }
        
        try:
            async with aiohttp.ClientSession() as session:
                async with session.post(
                    f"{self.base_url}/virtual-tryon",
                    headers=self.headers,
                    json=payload,
                    timeout=aiohttp.ClientTimeout(total=60)
                ) as response:
                    
                    if response.status == 200:
                        result = await response.json()
                        return {
                            "success": True,
                            "result_image": result.get("result_image"),
                            "confidence_score": result.get("confidence_score", 0.8),
                            "processing_time_ms": result.get("processing_time", 0),
                            "tryon_type": tryon_type,
                            "quality_metrics": {
                                "fit_score": result.get("fit_score", 0.8),
                                "color_harmony": result.get("color_harmony", 0.8),
                                "style_compatibility": result.get("style_compatibility", 0.8)
                            }
                        }
                    elif response.status == 429:
                        raise HTTPException(status_code=429, detail="Fashion AI service rate limited")
                    else:
                        error_detail = await response.text()
                        raise HTTPException(
                            status_code=response.status,
                            detail=f"Fashion AI API error: {error_detail}"
                        )
                        
        except asyncio.TimeoutError:
            raise HTTPException(
                status_code=504,
                detail="Fashion AI service timeout"
            )
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Fashion AI integration error: {str(e)}"
            )
    
    async def generate_outfit_combinations(
        self, 
        clothing_items: List[Dict], 
        user_preferences: Dict,
        user_id: str
    ) -> Dict:
        """Generate outfit combinations from clothing items"""
        
        allowed, reset_time = await rate_limiter.check_rate_limit(
            "fashion_ai_outfits", 
            settings.FASHION_AI_RATE_LIMIT // 2,  # Lower limit for complex operations
            3600,
            user_id
        )
        
        if not allowed:
            raise HTTPException(
                status_code=429,
                detail=f"Outfit generation rate limit exceeded"
            )
        
        payload = {
            "clothing_items": clothing_items,
            "user_preferences": user_preferences,
            "max_combinations": 10,
            "include_style_analysis": True,
            "filter_weather_appropriate": user_preferences.get("weather_filter", False)
        }
        
        try:
            async with aiohttp.ClientSession() as session:
                async with session.post(
                    f"{self.base_url}/outfit-generation",
                    headers=self.headers,
                    json=payload,
                    timeout=aiohttp.ClientTimeout(total=45)
                ) as response:
                    
                    if response.status == 200:
                        result = await response.json()
                        return {
                            "success": True,
                            "outfit_combinations": result.get("combinations", []),
                            "style_insights": result.get("style_insights", {}),
                            "generated_count": len(result.get("combinations", []))
                        }
                    else:
                        raise HTTPException(
                            status_code=response.status,
                            detail="Outfit generation failed"
                        )
                        
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Outfit generation error: {str(e)}"
            )
    
    async def analyze_style_compatibility(
        self, 
        item1_image: bytes, 
        item2_image: bytes,
        user_id: str
    ) -> Dict:
        """Analyze style compatibility between two clothing items"""
        
        # Rate limiting
        allowed, _ = await rate_limiter.check_rate_limit(
            "fashion_ai_compatibility", 
            settings.FASHION_AI_RATE_LIMIT,
            3600,
            user_id
        )
        
        if not allowed:
            return {"success": False, "error": "Rate limit exceeded"}
        
        item1_b64 = base64.b64encode(item1_image).decode('utf-8')
        item2_b64 = base64.b64encode(item2_image).decode('utf-8')
        
        payload = {
            "item1_image": item1_b64,
            "item2_image": item2_b64,
            "analysis_type": "compatibility"
        }
        
        try:
            async with aiohttp.ClientSession() as session:
                async with session.post(
                    f"{self.base_url}/style-analysis",
                    headers=self.headers,
                    json=payload,
                    timeout=aiohttp.ClientTimeout(total=30)
                ) as response:
                    
                    if response.status == 200:
                        result = await response.json()
                        return {
                            "success": True,
                            "compatibility_score": result.get("compatibility_score", 0.5),
                            "style_harmony": result.get("style_harmony", 0.5),
                            "color_coordination": result.get("color_coordination", 0.5),
                            "recommendations": result.get("recommendations", [])
                        }
                    else:
                        return {"success": False, "error": "Analysis failed"}
                        
        except Exception as e:
            return {"success": False, "error": str(e)}

fashion_ai_client = FashionAIClient()