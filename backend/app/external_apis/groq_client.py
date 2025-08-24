import httpx
import asyncio
import base64
import json
from typing import Dict, List, Optional, Union
from app.core.config import settings
from app.utils.rate_limiter import rate_limiter
from fastapi import HTTPException

class GroqClient:
    def __init__(self):
        self.api_key = settings.GROQ_API_KEY
        self.base_url = settings.GROQ_BASE_URL
        self.headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
    
    async def analyze_style_and_outfit(
        self, 
        image_data: bytes, 
        user_preferences: Dict,
        analysis_type: str = "comprehensive",
        user_id: str = "default"
    ) -> Dict:
        """
        Analyze style and outfit using Groq's LLaMA 3 Vision model
        
        Args:
            image_data: Image as bytes
            user_preferences: User's style preferences and context
            analysis_type: "comprehensive", "compatibility", "recommendation"
            user_id: User ID for rate limiting
        """
        
        # Rate limiting
        allowed, reset_time = await rate_limiter.check_rate_limit(
            "groq_vision",
            100,  # 100 requests per hour (Groq has higher limits)
            3600,
            user_id
        )
        
        if not allowed:
            raise HTTPException(
                status_code=429,
                detail=f"Groq Vision rate limit exceeded. Reset at {reset_time}"
            )
        
        # Encode image to base64
        image_b64 = base64.b64encode(image_data).decode('utf-8')
        
        # Create analysis prompt based on type
        prompt = self._create_analysis_prompt(analysis_type, user_preferences)
        
        payload = {
            "model": "llama-3.1-8b-instant",  # Groq's fast LLaMA model
            "messages": [
                {
                    "role": "system",
                    "content": "You are an expert fashion stylist and trend analyst with deep knowledge of fashion history, current trends, color theory, and personal styling. Provide detailed, actionable fashion advice."
                },
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": prompt
                        },
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/jpeg;base64,{image_b64}"
                            }
                        }
                    ]
                }
            ],
            "max_tokens": 1500,
            "temperature": 0.3
        }
        
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{self.base_url}/chat/completions",
                    headers=self.headers,
                    json=payload,
                    timeout=60.0
                )
                
                if response.status_code == 200:
                    result = response.json()
                    content = result["choices"][0]["message"]["content"]
                    
                    try:
                        # Parse JSON response
                        recommendations = json.loads(content)
                        return {
                            "success": True,
                            "style_analysis": recommendations.get("style_analysis", {}),
                            "outfit_suggestions": recommendations.get("outfit_suggestions", []),
                            "color_recommendations": recommendations.get("color_recommendations", []),
                            "occasion_recommendations": recommendations.get("occasion_recommendations", []),
                            "trend_insights": recommendations.get("trend_insights", {}),
                            "confidence_score": recommendations.get("confidence_score", 0.8)
                        }
                    except json.JSONDecodeError:
                        # Fallback: parse text response
                        return {
                            "success": True,
                            "style_analysis": {"description": content},
                            "outfit_suggestions": [],
                            "color_recommendations": [],
                            "occasion_recommendations": [],
                            "trend_insights": {},
                            "confidence_score": 0.7
                        }
                        
                elif response.status_code == 429:
                    raise HTTPException(status_code=429, detail="Groq service rate limited")
                else:
                    error_detail = response.text
                    raise HTTPException(
                        status_code=response.status_code,
                        detail=f"Groq API error: {error_detail}"
                    )
                    
        except httpx.TimeoutException:
            raise HTTPException(
                status_code=504,
                detail="Groq service timeout"
            )
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Groq API error: {str(e)}"
            )
    
    async def generate_outfit_recommendations(
        self,
        wardrobe_data: List[Dict],
        occasion: str,
        weather: Dict,
        user_preferences: Dict,
        user_id: str = "default"
    ) -> Dict:
        """Generate outfit recommendations using Groq"""
        
        # Rate limiting
        allowed, reset_time = await rate_limiter.check_rate_limit(
            "groq_recommendations",
            50,  # 50 requests per hour
            3600,
            user_id
        )
        
        if not allowed:
            raise HTTPException(
                status_code=429,
                detail=f"Groq recommendations rate limit exceeded. Reset at {reset_time}"
            )
        
        # Create wardrobe summary
        wardrobe_summary = self._create_wardrobe_summary(wardrobe_data)
        
        prompt = f"""
        As a fashion expert, analyze this wardrobe and provide outfit recommendations:
        
        Wardrobe Summary: {wardrobe_summary}
        Occasion: {occasion}
        Weather: {weather}
        User Preferences: {user_preferences}
        
        Provide recommendations in this JSON format:
        {{
            "outfit_recommendations": [
                {{
                    "name": "Outfit name",
                    "items": ["item1_id", "item2_id"],
                    "description": "Why this works",
                    "confidence": 0.9
                }}
            ],
            "missing_items": ["item_type1", "item_type2"],
            "style_advice": "General styling advice"
        }}
        """
        
        payload = {
            "model": "llama-3.1-8b-instant",
            "messages": [
                {
                    "role": "system",
                    "content": "You are an expert fashion stylist. Provide practical, personalized outfit recommendations based on the user's wardrobe, occasion, and preferences."
                },
                {
                    "role": "user",
                    "content": prompt
                }
            ],
            "max_tokens": 1000,
            "temperature": 0.4
        }
        
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{self.base_url}/chat/completions",
                    headers=self.headers,
                    json=payload,
                    timeout=30.0
                )
                
                if response.status_code == 200:
                    result = response.json()
                    content = result["choices"][0]["message"]["content"]
                    
                    try:
                        recommendations = json.loads(content)
                        return {
                            "success": True,
                            "recommendations": recommendations
                        }
                    except json.JSONDecodeError:
                        return {
                            "success": True,
                            "recommendations": {
                                "outfit_recommendations": [],
                                "missing_items": [],
                                "style_advice": content
                            }
                        }
                else:
                    raise HTTPException(
                        status_code=response.status_code,
                        detail=f"Groq API error: {response.text}"
                    )
                    
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to generate recommendations: {str(e)}"
            )
    
    async def generate_trend_analysis(
        self,
        category: str,
        user_preferences: Dict,
        user_id: str = "default"
    ) -> Dict:
        """Generate fashion trend analysis using Groq"""
        
        prompt = f"""
        Analyze current fashion trends for {category} category.
        User preferences: {user_preferences}
        
        Provide analysis in JSON format:
        {{
            "current_trends": ["trend1", "trend2"],
            "seasonal_recommendations": ["rec1", "rec2"],
            "personalized_suggestions": ["suggestion1", "suggestion2"],
            "confidence": 0.8
        }}
        """
        
        payload = {
            "model": "llama-3.1-8b-instant",
            "messages": [
                {
                    "role": "system",
                    "content": "You are a fashion trend analyst with expertise in current fashion trends and seasonal styling."
                },
                {
                    "role": "user",
                    "content": prompt
                }
            ],
            "max_tokens": 800,
            "temperature": 0.3
        }
        
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{self.base_url}/chat/completions",
                    headers=self.headers,
                    json=payload,
                    timeout=30.0
                )
                
                if response.status_code == 200:
                    result = response.json()
                    content = result["choices"][0]["message"]["content"]
                    
                    try:
                        analysis = json.loads(content)
                        return {
                            "success": True,
                            "trend_analysis": analysis
                        }
                    except json.JSONDecodeError:
                        return {
                            "success": True,
                            "trend_analysis": {
                                "current_trends": [],
                                "seasonal_recommendations": [],
                                "personalized_suggestions": [],
                                "confidence": 0.7
                            }
                        }
                else:
                    raise HTTPException(
                        status_code=response.status_code,
                        detail=f"Groq API error: {response.text}"
                    )
                    
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to generate trend analysis: {str(e)}"
            )
    
    def _create_analysis_prompt(self, analysis_type: str, user_preferences: Dict) -> str:
        """Create analysis prompt based on type"""
        
        base_prompt = f"""
        Analyze this clothing item and provide detailed fashion insights.
        
        User Preferences: {user_preferences}
        Analysis Type: {analysis_type}
        
        Provide response in this JSON format:
        {{
            "style_analysis": {{
                "category": "clothing_category",
                "style": "style_description",
                "seasonality": "seasonal_analysis",
                "formality": "formal/casual/party"
            }},
            "outfit_suggestions": [
                {{
                    "description": "outfit_description",
                    "items": ["item1", "item2"],
                    "occasion": "occasion_type"
                }}
            ],
            "color_recommendations": ["color1", "color2"],
            "occasion_recommendations": ["occasion1", "occasion2"],
            "trend_insights": {{
                "current_trend": "trend_description",
                "timeless": true/false
            }},
            "confidence_score": 0.8
        }}
        """
        
        if analysis_type == "comprehensive":
            return base_prompt + "\nProvide comprehensive analysis including style, trends, and recommendations."
        elif analysis_type == "compatibility":
            return base_prompt + "\nFocus on compatibility with user's existing wardrobe and style preferences."
        elif analysis_type == "recommendation":
            return base_prompt + "\nFocus on specific outfit and styling recommendations."
        else:
            return base_prompt
    
    def _create_wardrobe_summary(self, wardrobe_data: List[Dict]) -> str:
        """Create a summary of the user's wardrobe"""
        
        categories = {}
        colors = []
        
        for item in wardrobe_data:
            category = item.get("category", "unknown")
            categories[category] = categories.get(category, 0) + 1
            
            item_colors = item.get("colors", [])
            colors.extend(item_colors)
        
        return f"Categories: {categories}, Colors: {list(set(colors))}"

# Create global instance
groq_client = GroqClient()
