from typing import Dict, List, Optional
import uuid
from datetime import datetime, timedelta
from app.core.database import db
from app.utils.image_utils import process_and_upload_image
from fastapi import HTTPException
import json

class CommunityService:
    def __init__(self):
        pass
    
    async def create_outfit_post(
        self,
        user_id: str,
        outfit_data: Dict,
        image_data: bytes = None,
        caption: str = "",
        tags: List[str] = None,
        occasion: str = None
    ) -> Dict:
        """Create a new outfit post in the community"""
        
        try:
            # Upload image if provided
            image_url = None
            if image_data:
                image_filename = f"community-posts/{user_id}/{uuid.uuid4()}.jpg"
                image_url = await process_and_upload_image(image_data, image_filename)
            
            # Create post data
            post_data = {
                "user_id": user_id,
                "outfit_data": outfit_data,
                "image_url": image_url,
                "caption": caption,
                "tags": tags or [],
                "occasion": occasion,
                "likes_count": 0,
                "comments_count": 0,
                "shares_count": 0,
                "visibility": "public",
                "is_featured": False
            }
            
            result = await db.create_outfit_post(post_data)
            
            if result.data:
                # Update user's community stats
                await self._update_user_community_stats(user_id, "post_created")
                
                return {
                    "success": True,
                    "post": result.data[0],
                    "message": "Outfit post created successfully"
                }
            else:
                raise HTTPException(status_code=500, detail="Failed to create post")
                
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to create outfit post: {str(e)}"
            )
    
    async def get_community_feed(
        self,
        user_id: str,
        feed_type: str = "following",
        limit: int = 20,
        offset: int = 0,
        filters: Dict = None
    ) -> Dict:
        """Get personalized community feed"""
        
        try:
            # Get user's following list and preferences
            following_result = await db.get_user_following(user_id)
            following_ids = [f["followed_id"] for f in following_result.data] if following_result.data else []
            
            # Add user's own posts
            following_ids.append(user_id)
            
            if feed_type == "following" and not following_ids:
                # Fallback to discover feed if not following anyone
                feed_type = "discover"
            
            # Get feed posts based on type
            if feed_type == "following":
                posts_result = await db.get_posts_by_users(
                    following_ids,
                    limit=limit,
                    offset=offset,
                    filters=filters
                )
            elif feed_type == "discover":
                posts_result = await db.get_trending_posts(
                    limit=limit,
                    offset=offset,
                    filters=filters,
                    exclude_user=user_id
                )
            elif feed_type == "trending":
                posts_result = await db.get_trending_posts(
                    limit=limit,
                    offset=offset,
                    time_range="24h"
                )
            else:
                posts_result = await db.get_all_posts(
                    limit=limit,
                    offset=offset,
                    filters=filters
                )
            
            posts = posts_result.data if posts_result.data else []
            
            # Enhance posts with user interaction data
            enhanced_posts = await self._enhance_posts_with_interactions(posts, user_id)
            
            # Personalize feed order
            if feed_type in ["following", "discover"]:
                enhanced_posts = await self._personalize_feed_order(enhanced_posts, user_id)
            
            return {
                "success": True,
                "feed_type": feed_type,
                "posts": enhanced_posts,
                "has_more": len(enhanced_posts) == limit,
                "next_offset": offset + len(enhanced_posts)
            }
            
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to get community feed: {str(e)}"
            )
    
    async def interact_with_post(
        self,
        user_id: str,
        post_id: str,
        interaction_type: str,
        data: Dict = None
    ) -> Dict:
        """Handle post interactions (like, comment, share, save)"""
        
        try:
            if interaction_type == "like":
                return await self._handle_like(user_id, post_id)
            elif interaction_type == "unlike":
                return await self._handle_unlike(user_id, post_id)
            elif interaction_type == "comment":
                return await self._handle_comment(user_id, post_id, data.get("comment", ""))
            elif interaction_type == "share":
                return await self._handle_share(user_id, post_id, data)
            elif interaction_type == "save":
                return await self._handle_save(user_id, post_id)
            elif interaction_type == "report":
                return await self._handle_report(user_id, post_id, data.get("reason", ""))
            else:
                raise HTTPException(status_code=400, detail="Invalid interaction type")
                
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to interact with post: {str(e)}"
            )
    
    async def follow_user(self, follower_id: str, followed_id: str) -> Dict:
        """Follow another user"""
        
        try:
            if follower_id == followed_id:
                raise HTTPException(status_code=400, detail="Cannot follow yourself")
            
            # Check if already following
            existing = await db.check_user_following(follower_id, followed_id)
            if existing.data:
                return {
                    "success": False,
                    "message": "Already following this user"
                }
            
            # Create follow relationship
            follow_data = {
                "follower_id": follower_id,
                "followed_id": followed_id
            }
            
            result = await db.create_follow_relationship(follow_data)
            
            if result.data:
                # Update stats
                await self._update_user_community_stats(follower_id, "followed_user")
                await self._update_user_community_stats(followed_id, "gained_follower")
                
                return {
                    "success": True,
                    "message": "Successfully followed user"
                }
            else:
                raise HTTPException(status_code=500, detail="Failed to follow user")
                
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to follow user: {str(e)}"
            )
    
    async def unfollow_user(self, follower_id: str, followed_id: str) -> Dict:
        """Unfollow a user"""
        
        try:
            result = await db.delete_follow_relationship(follower_id, followed_id)
            
            if result:
                # Update stats
                await self._update_user_community_stats(follower_id, "unfollowed_user")
                await self._update_user_community_stats(followed_id, "lost_follower")
                
                return {
                    "success": True,
                    "message": "Successfully unfollowed user"
                }
            else:
                return {
                    "success": False,
                    "message": "Not following this user"
                }
                
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to unfollow user: {str(e)}"
            )
    
    async def get_user_profile(self, user_id: str, viewer_id: str = None) -> Dict:
        """Get user's community profile"""
        
        try:
            # Get user basic info
            user_result = await db.get_user_profile(user_id)
            if not user_result.data:
                raise HTTPException(status_code=404, detail="User not found")
            
            user_profile = user_result.data[0]
            
            # Get community stats
            stats_result = await db.get_user_community_stats(user_id)
            community_stats = stats_result.data[0] if stats_result.data else {}
            
            # Get user's posts
            posts_result = await db.get_user_posts(user_id, limit=12)  # Recent 12 posts
            posts = posts_result.data if posts_result.data else []
            
            # Check if viewer is following this user (if viewer provided)
            is_following = False
            if viewer_id and viewer_id != user_id:
                following_check = await db.check_user_following(viewer_id, user_id)
                is_following = bool(following_check.data)
            
            return {
                "success": True,
                "user_profile": {
                    "id": user_profile.get("id"),
                    "username": user_profile.get("username"),
                    "display_name": user_profile.get("display_name"),
                    "profile_picture": user_profile.get("profile_picture"),
                    "bio": user_profile.get("bio", ""),
                    "style_archetype": user_profile.get("style_archetype"),
                    "location": user_profile.get("location"),
                    "joined_date": user_profile.get("created_at")
                },
                "community_stats": {
                    "followers_count": community_stats.get("followers_count", 0),
                    "following_count": community_stats.get("following_count", 0),
                    "posts_count": community_stats.get("posts_count", 0),
                    "total_likes": community_stats.get("total_likes", 0),
                    "community_level": self._calculate_community_level(community_stats)
                },
                "recent_posts": posts,
                "is_following": is_following,
                "is_own_profile": viewer_id == user_id if viewer_id else False
            }
            
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to get user profile: {str(e)}"
            )
    
    async def get_style_challenges(
        self,
        user_id: str = None,
        status: str = "active",
        difficulty: str = None
    ) -> Dict:
        """Get available style challenges"""
        
        try:
            challenges_result = await db.get_style_challenges(
                status=status,
                difficulty=difficulty
            )
            
            challenges = challenges_result.data if challenges_result.data else []
            
            # If user provided, check their participation
            if user_id:
                for challenge in challenges:
                    participation = await db.get_user_challenge_participation(
                        user_id, 
                        challenge["id"]
                    )
                    challenge["user_participated"] = bool(participation.data)
                    challenge["user_progress"] = participation.data[0] if participation.data else None
            
            # Categorize challenges
            categorized = {
                "beginner": [c for c in challenges if c.get("difficulty") == "beginner"],
                "intermediate": [c for c in challenges if c.get("difficulty") == "intermediate"],
                "advanced": [c for c in challenges if c.get("difficulty") == "advanced"],
                "community": [c for c in challenges if c.get("type") == "community"],
                "seasonal": [c for c in challenges if c.get("type") == "seasonal"]
            }
            
            return {
                "success": True,
                "challenges": challenges,
                "categorized_challenges": categorized,
                "total_active_challenges": len([c for c in challenges if c.get("status") == "active"])
            }
            
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to get style challenges: {str(e)}"
            )
    
    async def participate_in_challenge(
        self,
        user_id: str,
        challenge_id: str,
        outfit_data: Dict,
        image_data: bytes = None
    ) -> Dict:
        """Participate in a style challenge"""
        
        try:
            # Check if challenge exists and is active
            challenge_result = await db.get_challenge_by_id(challenge_id)
            if not challenge_result.data:
                raise HTTPException(status_code=404, detail="Challenge not found")
            
            challenge = challenge_result.data[0]
            if challenge.get("status") != "active":
                raise HTTPException(status_code=400, detail="Challenge is not active")
            
            # Upload challenge image
            image_url = None
            if image_data:
                image_filename = f"challenge-entries/{challenge_id}/{user_id}/{uuid.uuid4()}.jpg"
                image_url = await process_and_upload_image(image_data, image_filename)
            
            # Create challenge participation
            participation_data = {
                "user_id": user_id,
                "challenge_id": challenge_id,
                "outfit_data": outfit_data,
                "image_url": image_url,
                "submission_date": datetime.utcnow(),
                "votes_count": 0,
                "status": "submitted"
            }
            
            result = await db.create_challenge_participation(participation_data)
            
            if result.data:
                # Update user stats
                await self._update_user_community_stats(user_id, "challenge_participated")
                
                # Create community post for the challenge entry
                post_data = {
                    "user_id": user_id,
                    "outfit_data": outfit_data,
                    "image_url": image_url,
                    "caption": f"My entry for {challenge.get('title', 'Style Challenge')}",
                    "tags": ["challenge", challenge.get("theme", "")],
                    "challenge_id": challenge_id,
                    "post_type": "challenge_entry"
                }
                
                await db.create_outfit_post(post_data)
                
                return {
                    "success": True,
                    "participation": result.data[0],
                    "message": "Successfully joined the challenge!"
                }
            else:
                raise HTTPException(status_code=500, detail="Failed to join challenge")
                
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to participate in challenge: {str(e)}"
            )
    
    async def get_leaderboard(
        self,
        leaderboard_type: str = "overall",
        timeframe: str = "monthly",
        limit: int = 50
    ) -> Dict:
        """Get community leaderboards"""
        
        try:
            if leaderboard_type == "overall":
                leaderboard = await self._get_overall_leaderboard(timeframe, limit)
            elif leaderboard_type == "style_challenges":
                leaderboard = await self._get_challenges_leaderboard(timeframe, limit)
            elif leaderboard_type == "most_liked":
                leaderboard = await self._get_most_liked_leaderboard(timeframe, limit)
            elif leaderboard_type == "most_followed":
                leaderboard = await self._get_most_followed_leaderboard(limit)
            else:
                raise HTTPException(status_code=400, detail="Invalid leaderboard type")
            
            return {
                "success": True,
                "leaderboard_type": leaderboard_type,
                "timeframe": timeframe,
                "leaderboard": leaderboard,
                "last_updated": datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to get leaderboard: {str(e)}"
            )
    
    # Helper methods
    
    async def _enhance_posts_with_interactions(
        self,
        posts: List[Dict],
        user_id: str
    ) -> List[Dict]:
        """Enhance posts with user interaction data"""
        
        enhanced_posts = []
        
        for post in posts:
            post_id = post.get("id")
            
            # Check if user liked this post
            like_check = await db.check_user_liked_post(user_id, post_id)
            post["user_liked"] = bool(like_check.data)
            
            # Check if user saved this post
            save_check = await db.check_user_saved_post(user_id, post_id)
            post["user_saved"] = bool(save_check.data)
            
            # Get post author info
            author_result = await db.get_user_profile(post.get("user_id"))
            if author_result.data:
                post["author"] = {
                    "id": author_result.data[0].get("id"),
                    "username": author_result.data[0].get("username"),
                    "display_name": author_result.data[0].get("display_name"),
                    "profile_picture": author_result.data[0].get("profile_picture")
                }
            
            # Add engagement metrics
            post["engagement_rate"] = self._calculate_engagement_rate(post)
            
            enhanced_posts.append(post)
        
        return enhanced_posts
    
    async def _personalize_feed_order(
        self,
        posts: List[Dict],
        user_id: str
    ) -> List[Dict]:
        """Personalize feed order based on user preferences and behavior"""
        
        # Get user preferences
        user_profile_result = await db.get_user_profile(user_id)
        user_preferences = user_profile_result.data[0] if user_profile_result.data else {}
        
        # Get user's interaction history
        interactions_result = await db.get_user_interactions_summary(user_id)
        interaction_patterns = interactions_result.data[0] if interactions_result.data else {}
        
        # Score each post based on personalization factors
        for post in posts:
            score = 0
            
            # Recency score (more recent = higher score)
            post_age = (datetime.utcnow() - datetime.fromisoformat(post.get("created_at", ""))).days
            recency_score = max(0, 1 - (post_age / 7))  # Declines over 7 days
            score += recency_score * 0.3
            
            # Engagement score
            engagement_rate = post.get("engagement_rate", 0)
            score += engagement_rate * 0.4
            
            # Style preference match
            post_style = post.get("outfit_data", {}).get("style_category", "")
            user_style = user_preferences.get("style_archetype", "")
            if post_style == user_style:
                score += 0.2
            
            # Author relationship (following, interaction history)
            if post.get("user_id") in interaction_patterns.get("frequently_interacted", []):
                score += 0.1
            
            post["personalization_score"] = score
        
        # Sort by personalization score
        return sorted(posts, key=lambda x: x.get("personalization_score", 0), reverse=True)
    
    async def _handle_like(self, user_id: str, post_id: str) -> Dict:
        """Handle post like"""
        
        # Check if already liked
        existing_like = await db.check_user_liked_post(user_id, post_id)
        if existing_like.data:
            return {"success": False, "message": "Post already liked"}
        
        # Create like
        like_data = {"user_id": user_id, "post_id": post_id}
        result = await db.create_post_like(like_data)
        
        if result.data:
            # Update post likes count
            await db.increment_post_likes(post_id)
            
            # Update post author's stats
            post_result = await db.get_post_by_id(post_id)
            if post_result.data:
                post_author_id = post_result.data[0].get("user_id")
                await self._update_user_community_stats(post_author_id, "received_like")
            
            return {"success": True, "message": "Post liked successfully"}
        
        return {"success": False, "message": "Failed to like post"}
    
    async def _handle_unlike(self, user_id: str, post_id: str) -> Dict:
        """Handle post unlike"""
        
        result = await db.delete_post_like(user_id, post_id)
        
        if result:
            # Decrease post likes count
            await db.decrement_post_likes(post_id)
            return {"success": True, "message": "Post unliked successfully"}
        
        return {"success": False, "message": "Post was not liked"}
    
    async def _handle_comment(self, user_id: str, post_id: str, comment_text: str) -> Dict:
        """Handle post comment"""
        
        if not comment_text.strip():
            raise HTTPException(status_code=400, detail="Comment cannot be empty")
        
        comment_data = {
            "user_id": user_id,
            "post_id": post_id,
            "comment_text": comment_text.strip(),
            "likes_count": 0
        }
        
        result = await db.create_post_comment(comment_data)
        
        if result.data:
            # Update post comments count
            await db.increment_post_comments(post_id)
            
            # Update post author's stats
            post_result = await db.get_post_by_id(post_id)
            if post_result.data:
                post_author_id = post_result.data[0].get("user_id")
                await self._update_user_community_stats(post_author_id, "received_comment")
            
            return {
                "success": True,
                "comment": result.data[0],
                "message": "Comment added successfully"
            }
        
        return {"success": False, "message": "Failed to add comment"}
    
    async def _handle_share(self, user_id: str, post_id: str, share_data: Dict) -> Dict:
        """Handle post share"""
        
        share_type = share_data.get("type", "repost")  # repost, external, etc.
        share_message = share_data.get("message", "")
        
        share_record = {
            "user_id": user_id,
            "post_id": post_id,
            "share_type": share_type,
            "share_message": share_message
        }
        
        result = await db.create_post_share(share_record)
        
        if result.data:
            # Update post shares count
            await db.increment_post_shares(post_id)
            
            # Update post author's stats
            post_result = await db.get_post_by_id(post_id)
            if post_result.data:
                post_author_id = post_result.data[0].get("user_id")
                await self._update_user_community_stats(post_author_id, "received_share")
            
            return {"success": True, "message": "Post shared successfully"}
        
        return {"success": False, "message": "Failed to share post"}
    
    async def _handle_save(self, user_id: str, post_id: str) -> Dict:
        """Handle post save"""
        
        # Check if already saved
        existing_save = await db.check_user_saved_post(user_id, post_id)
        if existing_save.data:
            # Unsave
            await db.delete_post_save(user_id, post_id)
            return {"success": True, "message": "Post removed from saved", "action": "unsaved"}
        else:
            # Save
            save_data = {"user_id": user_id, "post_id": post_id}
            result = await db.create_post_save(save_data)
            
            if result.data:
                return {"success": True, "message": "Post saved successfully", "action": "saved"}
            
            return {"success": False, "message": "Failed to save post"}
    
    async def _handle_report(self, user_id: str, post_id: str, reason: str) -> Dict:
        """Handle post report"""
        
        if not reason.strip():
            raise HTTPException(status_code=400, detail="Report reason is required")
        
        report_data = {
            "reporter_id": user_id,
            "post_id": post_id,
            "reason": reason,
            "status": "pending"
        }
        
        result = await db.create_post_report(report_data)
        
        if result.data:
            return {"success": True, "message": "Post reported successfully"}
        
        return {"success": False, "message": "Failed to report post"}
    
    async def _update_user_community_stats(self, user_id: str, action: str):
        """Update user's community statistics"""
        
        stats_updates = {
            "post_created": {"posts_count": 1},
            "followed_user": {"following_count": 1},
            "gained_follower": {"followers_count": 1},
            "unfollowed_user": {"following_count": -1},
            "lost_follower": {"followers_count": -1},
            "received_like": {"total_likes": 1},
            "received_comment": {"total_comments": 1},
            "received_share": {"total_shares": 1},
            "challenge_participated": {"challenges_participated": 1}
        }
        
        update_data = stats_updates.get(action, {})
        if update_data:
            await db.update_user_community_stats(user_id, update_data)
    
    def _calculate_engagement_rate(self, post: Dict) -> float:
        """Calculate post engagement rate"""
        
        likes = post.get("likes_count", 0)
        comments = post.get("comments_count", 0)
        shares = post.get("shares_count", 0)
        
        total_engagement = likes + (comments * 2) + (shares * 3)  # Weighted engagement
        
        # Simple engagement rate (would need follower count for true rate)
        return min(total_engagement / 100, 1.0)  # Normalize to 0-1 scale
    
    def _calculate_community_level(self, stats: Dict) -> str:
        """Calculate user's community level"""
        
        posts = stats.get("posts_count", 0)
        followers = stats.get("followers_count", 0)
        likes = stats.get("total_likes", 0)
        
        score = posts * 5 + followers * 2 + likes
        
        if score >= 1000:
            return "Style Influencer"
        elif score >= 500:
            return "Fashion Expert"
        elif score >= 200:
            return "Style Enthusiast"
        elif score >= 50:
            return "Fashion Explorer"
        else:
            return "Style Newcomer"
    
    async def _get_overall_leaderboard(self, timeframe: str, limit: int) -> List[Dict]:
        """Get overall community leaderboard"""
        
        # Calculate date range based on timeframe
        if timeframe == "weekly":
            since_date = datetime.utcnow() - timedelta(days=7)
        elif timeframe == "monthly":
            since_date = datetime.utcnow() - timedelta(days=30)
        elif timeframe == "yearly":
            since_date = datetime.utcnow() - timedelta(days=365)
        else:
            since_date = None  # All time
        
        result = await db.get_community_leaderboard(
            order_by="community_score",
            since_date=since_date,
            limit=limit
        )
        
        return result.data if result.data else []
    
    async def _get_challenges_leaderboard(self, timeframe: str, limit: int) -> List[Dict]:
        """Get style challenges leaderboard"""
        
        since_date = None
        if timeframe == "monthly":
            since_date = datetime.utcnow() - timedelta(days=30)
        
        result = await db.get_challenges_leaderboard(
            since_date=since_date,
            limit=limit
        )
        
        return result.data if result.data else []
    
    async def _get_most_liked_leaderboard(self, timeframe: str, limit: int) -> List[Dict]:
        """Get most liked posts leaderboard"""
        
        since_date = None
        if timeframe == "weekly":
            since_date = datetime.utcnow() - timedelta(days=7)
        elif timeframe == "monthly":
            since_date = datetime.utcnow() - timedelta(days=30)
        
        result = await db.get_most_liked_posts_leaderboard(
            since_date=since_date,
            limit=limit
        )
        
        return result.data if result.data else []
    
    async def _get_most_followed_leaderboard(self, limit: int) -> List[Dict]:
        """Get most followed users leaderboard"""
        
        result = await db.get_most_followed_users(limit=limit)
        return result.data if result.data else []

community_service = CommunityService()