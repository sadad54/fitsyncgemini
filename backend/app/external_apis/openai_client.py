import openai
import aiohttp
import base64
import json
from typing import Dict, List, Optional, Union
from app.core.config import settings
from app.utils.rate_limiter import rate_limiter
from fastapi import HTTPException

class OpenAIClient:
    def __init__(self):
        self.api_key = settings.OPENAI_API_KEY
        self.base_url = "https://api.openai.com/v1"
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
        Analyze style and outfit using GPT-4 Vision
        
        Args:
            image_data: Image as bytes
            user_preferences: User's style preferences and context
            analysis_type: "comprehensive", "compatibility", "recommendation"
            user_id: User ID for rate limiting
        """
        
        # Rate limiting
        allowed, reset_time = await rate_limiter.check_rate_limit(
            "openai_vision",
            60,  # 60 requests per hour
            3600,
            user_id
        )
        
        if not allowed:
            raise HTTPException(
                status_code=429,
                detail=f"OpenAI Vision rate limit exceeded. Reset at {reset_time}"
            )
        
        # Encode image to base64
        image_b64 = base64.b64encode(image_data).decode('utf-8')
        
        # Create analysis prompt based on type
        prompt = self._create_analysis_prompt(analysis_type, user_preferences)
        
        payload = {
            "model": "gpt-4-vision-preview",
            "messages": [
                {
                    "role": "system",
                    "content": "You are an expert fashion stylist and trend analyst with deep knowledge of fashion history, current trends, color theory, and personal styling."
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
            async with aiohttp.ClientSession() as session:
                async with session.post(
                    f"{self.base_url}/chat/completions",
                    headers=self.headers,
                    json=payload,
                    timeout=aiohttp.ClientTimeout(total=60)
                ) as response:
                    
                    if response.status == 200:
                        result = await response.json()
                        content = result["choices"][0]["message"]["content"]
                        
                        try:
                            # Parse JSON response
                            recommendations = json.loads(content)
                            return {
                                "success": True,
                                "recommendations": recommendations.get("recommendations", []),
                                "style_insights": recommendations.get("style_insights", {}),
                                "tokens_used": result["usage"]["total_tokens"]
                            }
                        except json.JSONDecodeError:
                            # Fallback if JSON parsing fails
                            return {
                                "success": False,
                                "error": "Failed to parse recommendations",
                                "raw_response": content
                            }
                    else:
                        raise HTTPException(
                            status_code=response.status,
                            detail="OpenAI recommendations API error"
                        )
                        
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"OpenAI recommendations error: {str(e)}"
            )
    
    async def analyze_celebrity_outfit(
        self,
        celebrity_image: bytes,
        user_id: str
    ) -> Dict:
        """Analyze celebrity outfit and provide breakdown"""
        
        # Rate limiting
        allowed, _ = await rate_limiter.check_rate_limit(
            "openai_celebrity",
            30,  # 30 requests per hour
            3600,
            user_id
        )
        
        if not allowed:
            raise HTTPException(
                status_code=429,
                detail="Celebrity analysis rate limit exceeded"
            )
        
        image_b64 = base64.b64encode(celebrity_image).decode('utf-8')
        
        prompt = """
        Analyze this celebrity outfit and provide a detailed breakdown. Focus on:
        1. Individual clothing items and accessories
        2. Style category and aesthetic
        3. Color palette and coordination
        4. Occasion appropriateness
        5. How to recreate this look with accessible alternatives
        6. Key styling elements that make this outfit work

        Provide the response in JSON format:
        {
            "outfit_breakdown": {
                "top": {"description": "", "style": "", "color": "", "alternatives": []},
                "bottom": {"description": "", "style": "", "color": "", "alternatives": []},
                "outerwear": {"description": "", "style": "", "color": "", "alternatives": []},
                "footwear": {"description": "", "style": "", "color": "", "alternatives": []},
                "accessories": [{"item": "", "description": "", "alternatives": []}]
            },
            "overall_style": {
                "category": "",
                "aesthetic": "",
                "occasion": "",
                "season": "",
                "color_palette": [],
                "key_elements": []
            },
            "recreation_guide": {
                "budget_friendly_alternatives": [],
                "key_pieces_to_invest_in": [],
                "styling_tips": [],
                "where_to_shop": []
            },
            "difficulty_level": "Easy/Medium/Hard",
            "estimated_budget": "Low/Medium/High"
        }
        """
        
        payload = {
            "model": "gpt-4-vision-preview",
            "messages": [
                {
                    "role": "system",
                    "content": "You are a celebrity fashion analyst who can break down outfits and provide practical styling advice for everyday people."
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
            "max_tokens": 2000,
            "temperature": 0.3
        }
        
        try:
            async with aiohttp.ClientSession() as session:
                async with session.post(
                    f"{self.base_url}/chat/completions",
                    headers=self.headers,
                    json=payload,
                    timeout=aiohttp.ClientTimeout(total=60)
                ) as response:
                    
                    if response.status == 200:
                        result = await response.json()
                        content = result["choices"][0]["message"]["content"]
                        
                        try:
                            analysis = json.loads(content)
                            return {
                                "success": True,
                                "celebrity_analysis": analysis,
                                "tokens_used": result["usage"]["total_tokens"]
                            }
                        except json.JSONDecodeError:
                            return {
                                "success": False,
                                "error": "Failed to parse celebrity analysis",
                                "raw_response": content
                            }
                    else:
                        raise HTTPException(
                            status_code=response.status,
                            detail="Celebrity analysis API error"
                        )
                        
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Celebrity analysis error: {str(e)}"
            )
    
    def _create_analysis_prompt(self, analysis_type: str, user_preferences: Dict) -> str:
        """Create analysis prompt based on type and user preferences"""
        
        base_context = f"""
        User Style Profile:
        - Style Archetype: {user_preferences.get('style_archetype', 'Not specified')}
        - Preferred Colors: {user_preferences.get('preferred_colors', [])}
        - Body Type: {user_preferences.get('body_type', 'Not specified')}
        - Lifestyle: {user_preferences.get('lifestyle', 'Not specified')}
        - Budget Range: {user_preferences.get('budget_range', 'Not specified')}
        """
        
        if analysis_type == "comprehensive":
            return f"""
            {base_context}
            
            Please analyze this outfit/clothing item comprehensively and provide:
            
            1. STYLE ANALYSIS:
            - Overall style category and aesthetic
            - Color palette analysis and harmony
            - Fit and silhouette assessment
            - Season and occasion appropriateness
            
            2. PERSONALIZATION:
            - How well this aligns with the user's style profile
            - Suggested modifications for user's preferences
            - Body type considerations and adjustments
            
            3. COORDINATION:
            - What pieces would work well with this
            - Color combinations to try
            - Styling variations possible
            
            4. TREND ANALYSIS:
            - Current trend relevance
            - Timeless vs trendy elements
            - Future styling potential
            
            Provide response in structured JSON format with scores (0-1) for each aspect.
            """
        
        elif analysis_type == "compatibility":
            return f"""
            {base_context}
            
            Analyze the compatibility and styling potential of this outfit/item:
            
            1. VERSATILITY SCORE (0-1)
            2. COMPATIBILITY with user's existing style
            3. COORDINATION suggestions
            4. OCCASION appropriateness
            5. INVESTMENT VALUE assessment
            
            Provide specific, actionable styling advice in JSON format.
            """
        
        elif analysis_type == "recommendation":
            return f"""
            {base_context}
            
            Based on this image, provide personalized recommendations:
            
            1. IMPROVEMENT SUGGESTIONS
            2. ALTERNATIVE STYLING OPTIONS
            3. COMPLEMENTARY PIECES to add
            4. BUDGET-FRIENDLY ALTERNATIVES
            5. SHOPPING RECOMMENDATIONS
            
            Focus on practical, actionable advice in JSON format.
            """
        
        return "Provide a general fashion analysis of this image in JSON format."
    
    def _parse_analysis_response(self, content: str, analysis_type: str) -> Dict:
        """Parse and structure the OpenAI response"""
        
        try:
            # Try to parse as JSON first
            return json.loads(content)
        except json.JSONDecodeError:
            # If JSON parsing fails, create structured response from text
            return {
                "analysis_type": analysis_type,
                "raw_analysis": content,
                "parsed": False,
                "summary": content[:500] + "..." if len(content) > 500 else content
            }

openai_client = OpenAIClient()