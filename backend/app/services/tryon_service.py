from typing import Dict, List, Optional, BinaryIO
import uuid
import asyncio
from datetime import datetime
from app.external_apis.free_virtual_tryon import free_virtual_tryon_client
from app.core.database import db
from app.utils.image_utils import process_and_upload_image
from fastapi import HTTPException
import base64

class VirtualTryOnService:
    def __init__(self):
        self.fashion_ai = free_virtual_tryon_client
    
    async def create_tryon_session(
        self,
        user_id: str,
        session_name: str = None,
        view_mode: str = "ar"
    ) -> Dict:
        """Create a new virtual try-on session"""
        
        try:
            session_data = {
                "user_id": user_id,
                "session_name": session_name or f"Try-On {datetime.utcnow().strftime('%Y-%m-%d %H:%M')}",
                "view_mode": view_mode,
                "status": "pending",
                "processing_progress": 0.0
            }
            
            result = await db.create_tryon_session(session_data)
            return {
                "success": True,
                "session": result.data[0],
                "message": "Try-on session created successfully"
            }
            
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to create try-on session: {str(e)}"
            )
    
    async def perform_virtual_tryon(
        self,
        session_id: str,
        user_image: bytes,
        clothing_items: List[str],  # List of clothing item IDs
        user_id: str
    ) -> Dict:
        """Perform virtual try-on with multiple clothing items"""
        
        try:
            # Update session status
            await db.update_tryon_session(session_id, {
                "status": "processing",
                "processing_progress": 0.1
            })
            
            # Get clothing item details
            clothing_data = []
            for item_id in clothing_items:
                item_result = await db.get_clothing_item(item_id, user_id)
                if item_result.data:
                    clothing_data.append(item_result.data[0])
            
            if not clothing_data:
                raise HTTPException(status_code=404, detail="No valid clothing items found")
            
            # Update progress
            await db.update_tryon_session(session_id, {"processing_progress": 0.3})
            
            # Perform individual try-ons for each item
            tryon_results = []
            total_items = len(clothing_data)
            
            for i, clothing_item in enumerate(clothing_data):
                # Download clothing item image
                clothing_image_data = await self._download_image(clothing_item["image_url"])
                
                # Determine try-on type based on clothing category
                tryon_type = self._determine_tryon_type(clothing_item["category"])
                
                # Perform try-on with Fashion AI
                tryon_result = await self.fashion_ai.virtual_tryon(
                    user_image,
                    clothing_image_data,
                    user_id,
                    tryon_type
                )
                
                if tryon_result["success"]:
                    # Save individual try-on result
                    attempt_data = {
                        "session_id": session_id,
                        "outfit_name": f"Try-on with {clothing_item['name']}",
                        "clothing_items": [clothing_item],
                        "confidence_score": tryon_result["confidence_score"],
                        "fit_analysis": tryon_result.get("quality_metrics", {}),
                        "processing_time_ms": tryon_result["processing_time_ms"],
                        "result_image_url": await self._save_tryon_result_image(
                            tryon_result["result_image"], 
                            session_id, 
                            i
                        )
                    }
                    
                    attempt_result = await db.create_tryon_attempt(attempt_data)
                    tryon_results.append(attempt_result.data[0])
                
                # Update progress
                progress = 0.3 + (0.6 * (i + 1) / total_items)
                await db.update_tryon_session(session_id, {"processing_progress": progress})
            
            # Generate outfit combinations if multiple items
            outfit_combinations = []
            if len(clothing_data) > 1:
                outfit_combinations = await self._generate_outfit_combinations(
                    session_id,
                    user_image,
                    clothing_data,
                    user_id
                )
            
            # Finalize session
            final_session_data = {
                "status": "completed",
                "processing_progress": 1.0,
                "completed_at": datetime.utcnow(),
                "confidence_score": sum(r.get("confidence_score", 0) for r in tryon_results) / len(tryon_results) if tryon_results else 0
            }
            
            await db.update_tryon_session(session_id, final_session_data)
            
            return {
                "success": True,
                "session_id": session_id,
                "individual_results": tryon_results,
                "outfit_combinations": outfit_combinations,
                "summary": {
                    "total_attempts": len(tryon_results),
                    "successful_attempts": len([r for r in tryon_results if r.get("confidence_score", 0) > 0.7]),
                    "average_confidence": sum(r.get("confidence_score", 0) for r in tryon_results) / len(tryon_results) if tryon_results else 0
                }
            }
            
        except Exception as e:
            # Update session with error
            await db.update_tryon_session(session_id, {
                "status": "failed",
                "error_message": str(e)
            })
            raise HTTPException(
                status_code=500,
                detail=f"Virtual try-on failed: {str(e)}"
            )
    
    async def get_tryon_session(self, session_id: str, user_id: str) -> Dict:
        """Get try-on session details with all attempts"""
        
        try:
            # Get session
            session_result = await db.get_tryon_session(session_id, user_id)
            if not session_result.data:
                raise HTTPException(status_code=404, detail="Session not found")
            
            session = session_result.data[0]
            
            # Get all attempts for this session
            attempts_result = await db.get_tryon_attempts(session_id)
            attempts = attempts_result.data if attempts_result.data else []
            
            return {
                "success": True,
                "session": session,
                "attempts": attempts,
                "total_attempts": len(attempts)
            }
            
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to get session: {str(e)}"
            )
    
    async def get_user_tryon_history(
        self,
        user_id: str,
        limit: int = 20,
        status_filter: str = None
    ) -> Dict:
        """Get user's virtual try-on history"""
        
        try:
            sessions_result = await db.get_user_tryon_sessions(
                user_id, 
                limit=limit, 
                status_filter=status_filter
            )
            
            sessions = sessions_result.data if sessions_result.data else []
            
            # Get stats
            total_sessions = len(sessions)
            completed_sessions = len([s for s in sessions if s.get("status") == "completed"])
            avg_confidence = 0
            
            if completed_sessions > 0:
                confidence_scores = [s.get("confidence_score", 0) for s in sessions if s.get("confidence_score")]
                avg_confidence = sum(confidence_scores) / len(confidence_scores) if confidence_scores else 0
            
            return {
                "success": True,
                "sessions": sessions,
                "statistics": {
                    "total_sessions": total_sessions,
                    "completed_sessions": completed_sessions,
                    "success_rate": (completed_sessions / total_sessions * 100) if total_sessions > 0 else 0,
                    "average_confidence": round(avg_confidence, 2)
                }
            }
            
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to get try-on history: {str(e)}"
            )
    
    async def save_tryon_result(
        self,
        session_id: str,
        attempt_id: str,
        user_id: str,
        is_favorite: bool = False,
        user_rating: int = None,
        notes: str = None
    ) -> Dict:
        """Save/update try-on result with user preferences"""
        
        try:
            update_data = {
                "is_favorite": is_favorite,
                "updated_at": datetime.utcnow()
            }
            
            if user_rating is not None:
                update_data["user_rating"] = user_rating
            
            if notes:
                update_data["notes"] = notes
            
            result = await db.update_tryon_attempt(attempt_id, user_id, update_data)
            
            return {
                "success": True,
                "message": "Try-on result saved successfully",
                "updated_attempt": result.data[0] if result.data else None
            }
            
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to save try-on result: {str(e)}"
            )
    
    async def get_tryon_analytics(self, user_id: str) -> Dict:
        """Get analytics for user's virtual try-on usage"""
        
        try:
            # Get all user sessions
            all_sessions_result = await db.get_user_tryon_sessions(user_id, limit=1000)
            sessions = all_sessions_result.data if all_sessions_result.data else []
            
            if not sessions:
                return {
                    "success": True,
                    "analytics": {
                        "total_sessions": 0,
                        "message": "No try-on history found"
                    }
                }
            
            # Calculate analytics
            total_sessions = len(sessions)
            completed_sessions = [s for s in sessions if s.get("status") == "completed"]
            failed_sessions = [s for s in sessions if s.get("status") == "failed"]
            
            # Most tried categories
            category_counts = {}
            confidence_scores = []
            processing_times = []
            
            for session in completed_sessions:
                if session.get("confidence_score"):
                    confidence_scores.append(session["confidence_score"])
                if session.get("processing_time_ms"):
                    processing_times.append(session["processing_time_ms"])
            
            # Get attempt details for more insights
            all_attempts = []
            for session in completed_sessions[:50]:  # Limit to recent sessions
                attempts_result = await db.get_tryon_attempts(session["id"])
                if attempts_result.data:
                    all_attempts.extend(attempts_result.data)
            
            # Analyze clothing categories
            for attempt in all_attempts:
                clothing_items = attempt.get("clothing_items", [])
                for item in clothing_items:
                    category = item.get("category", "unknown")
                    category_counts[category] = category_counts.get(category, 0) + 1
            
            # Calculate success metrics
            avg_confidence = sum(confidence_scores) / len(confidence_scores) if confidence_scores else 0
            avg_processing_time = sum(processing_times) / len(processing_times) if processing_times else 0
            
            # Favorite analysis
            favorite_attempts = [a for a in all_attempts if a.get("is_favorite", False)]
            
            analytics = {
                "total_sessions": total_sessions,
                "completed_sessions": len(completed_sessions),
                "failed_sessions": len(failed_sessions),
                "success_rate": (len(completed_sessions) / total_sessions * 100) if total_sessions > 0 else 0,
                "average_confidence_score": round(avg_confidence, 2),
                "average_processing_time_seconds": round(avg_processing_time / 1000, 2) if avg_processing_time > 0 else 0,
                "most_tried_categories": sorted(category_counts.items(), key=lambda x: x[1], reverse=True)[:5],
                "total_attempts": len(all_attempts),
                "favorite_attempts": len(favorite_attempts),
                "usage_patterns": {
                    "sessions_this_week": len([s for s in sessions if self._is_recent(s.get("created_at"), days=7)]),
                    "sessions_this_month": len([s for s in sessions if self._is_recent(s.get("created_at"), days=30)]),
                    "most_active_day": self._get_most_active_day(sessions),
                    "preferred_view_mode": self._get_preferred_view_mode(sessions)
                },
                "quality_insights": {
                    "high_confidence_rate": len([s for s in confidence_scores if s > 0.8]) / len(confidence_scores) * 100 if confidence_scores else 0,
                    "avg_user_rating": self._calculate_avg_user_rating(all_attempts),
                    "most_successful_category": max(category_counts.items(), key=lambda x: x[1])[0] if category_counts else "none"
                }
            }
            
            return {
                "success": True,
                "analytics": analytics
            }
            
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to get analytics: {str(e)}"
            )
    
    def _determine_tryon_type(self, category: str) -> str:
        """Determine appropriate try-on type based on clothing category"""
        
        tryon_mapping = {
            "tops": "upper_body",
            "dresses": "full_body",
            "bottoms": "lower_body",
            "outerwear": "upper_body",
            "footwear": "lower_body"
        }
        
        return tryon_mapping.get(category, "full_body")
    
    async def _download_image(self, image_url: str) -> bytes:
        """Download image from URL"""
        
        import aiohttp
        
        try:
            async with aiohttp.ClientSession() as session:
                async with session.get(image_url) as response:
                    if response.status == 200:
                        return await response.read()
                    else:
                        raise HTTPException(
                            status_code=400,
                            detail=f"Failed to download image: {response.status}"
                        )
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Image download error: {str(e)}"
            )
    
    async def _save_tryon_result_image(self, image_b64: str, session_id: str, attempt_index: int) -> str:
        """Save try-on result image to storage"""
        
        try:
            # Decode base64 image
            image_data = base64.b64decode(image_b64)
            
            # Generate filename
            filename = f"try-on-results/{session_id}/result_{attempt_index}_{uuid.uuid4().hex[:8]}.jpg"
            
            # Upload to storage
            image_url = await process_and_upload_image(image_data, filename)
            return image_url
            
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to save result image: {str(e)}"
            )
    
    async def _generate_outfit_combinations(
        self,
        session_id: str,
        user_image: bytes,
        clothing_items: List[Dict],
        user_id: str
    ) -> List[Dict]:
        """Generate outfit combinations from multiple clothing items"""
        
        try:
            combinations = []
            
            # Generate combinations of 2-3 items
            from itertools import combinations as iter_combinations
            
            for r in [2, 3]:  # Try combinations of 2 and 3 items
                for combo in iter_combinations(clothing_items, r):
                    # Check if combination makes sense (e.g., top + bottom)
                    categories = [item["category"] for item in combo]
                    
                    if self._is_valid_outfit_combination(categories):
                        # Create outfit name
                        outfit_name = " + ".join([item["name"] for item in combo])
                        
                        # For now, create a placeholder - in real implementation,
                        # you'd need to composite multiple items or use advanced AI
                        combination_data = {
                            "session_id": session_id,
                            "outfit_name": outfit_name,
                            "clothing_items": list(combo),
                            "confidence_score": 0.75,  # Placeholder
                            "is_combination": True,
                            "combination_type": "multi_item"
                        }
                        
                        combination_result = await db.create_tryon_attempt(combination_data)
                        combinations.append(combination_result.data[0])
                        
                        if len(combinations) >= 5:  # Limit combinations
                            break
                
                if len(combinations) >= 5:
                    break
            
            return combinations
            
        except Exception as e:
            # Don't fail the whole process if combinations fail
            print(f"Combination generation error: {str(e)}")
            return []
    
    def _is_valid_outfit_combination(self, categories: List[str]) -> bool:
        """Check if clothing categories make a valid outfit combination"""
        
        valid_combinations = [
            {"tops", "bottoms"},
            {"tops", "bottoms", "outerwear"},
            {"tops", "outerwear"},
            {"dresses", "outerwear"},
            {"dresses", "accessories"}
        ]
        
        category_set = set(categories)
        
        return any(
            category_set.issubset(valid_combo) or valid_combo.issubset(category_set)
            for valid_combo in valid_combinations
        )
    
    def _is_recent(self, date_str: str, days: int) -> bool:
        """Check if date is within recent days"""
        
        if not date_str:
            return False
        
        try:
            from datetime import datetime, timedelta
            date = datetime.fromisoformat(date_str.replace('Z', '+00:00'))
            cutoff = datetime.utcnow() - timedelta(days=days)
            return date > cutoff
        except:
            return False
    
    def _get_most_active_day(self, sessions: List[Dict]) -> str:
        """Get the most active day of the week"""
        
        if not sessions:
            return "none"
        
        day_counts = {}
        
        for session in sessions:
            created_at = session.get("created_at")
            if created_at:
                try:
                    date = datetime.fromisoformat(created_at.replace('Z', '+00:00'))
                    day_name = date.strftime('%A')
                    day_counts[day_name] = day_counts.get(day_name, 0) + 1
                except:
                    continue
        
        if not day_counts:
            return "none"
        
        return max(day_counts.items(), key=lambda x: x[1])[0]
    
    def _get_preferred_view_mode(self, sessions: List[Dict]) -> str:
        """Get user's preferred view mode"""
        
        mode_counts = {}
        
        for session in sessions:
            mode = session.get("view_mode", "ar")
            mode_counts[mode] = mode_counts.get(mode, 0) + 1
        
        if not mode_counts:
            return "ar"
        
        return max(mode_counts.items(), key=lambda x: x[1])[0]
    
    def _calculate_avg_user_rating(self, attempts: List[Dict]) -> float:
        """Calculate average user rating from attempts"""
        
        ratings = [a.get("user_rating") for a in attempts if a.get("user_rating")]
        
        if not ratings:
            return 0.0
        
        return round(sum(ratings) / len(ratings), 2)

tryon_service = VirtualTryOnService()