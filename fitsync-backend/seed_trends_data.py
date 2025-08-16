#!/usr/bin/env python3
"""
Seed script for trends and social data
Run this from the fitsync-backend directory with: python seed_trends_data.py
"""

import asyncio
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.models.trends import (
    FashionTrend, StyleInfluencer, ExploreContent, 
    NearbyLocation, TrendInsight, TrendDirection
)

def seed_fashion_trends(db: Session):
    """Seed fashion trends data"""
    trends = [
        {
            "trend_name": "Quiet Luxury",
            "trend_description": "Understated premium staples gaining popularity",
            "category": "style",
            "popularity_score": 0.85,
            "growth_rate": 0.21,
            "direction": TrendDirection.UP.value,
            "engagement": 14230,
            "posts_count": 980,
            "social_mentions": 5600,
            "hashtag_count": 2340,
            "tags": ["elegant", "minimalist", "luxury"],
            "image_url": "https://example.com/trend1.jpg",
            "confidence_level": 0.9
        },
        {
            "trend_name": "Tech Wear",
            "trend_description": "Functional fashion meets futuristic design",
            "category": "style",
            "popularity_score": 0.78,
            "growth_rate": 0.18,
            "direction": TrendDirection.UP.value,
            "engagement": 12100,
            "posts_count": 756,
            "social_mentions": 4200,
            "hashtag_count": 1890,
            "tags": ["streetwear", "functional", "futuristic"],
            "image_url": "https://example.com/trend2.jpg",
            "confidence_level": 0.85
        },
        {
            "trend_name": "Cottage Core",
            "trend_description": "Romantic, rural-inspired aesthetic",
            "category": "style",
            "popularity_score": 0.72,
            "growth_rate": 0.13,
            "direction": TrendDirection.UP.value,
            "engagement": 9840,
            "posts_count": 623,
            "social_mentions": 3100,
            "hashtag_count": 1456,
            "tags": ["bohemian", "romantic", "rural"],
            "image_url": "https://example.com/trend3.jpg",
            "confidence_level": 0.82
        },
        {
            "trend_name": "Minimalist",
            "trend_description": "Clean lines and neutral colors",
            "category": "style",
            "popularity_score": 0.88,
            "growth_rate": 0.12,
            "direction": TrendDirection.UP.value,
            "engagement": 18500,
            "posts_count": 1200,
            "social_mentions": 7800,
            "hashtag_count": 3200,
            "tags": ["minimalist", "clean", "neutral"],
            "image_url": "https://example.com/trend4.jpg",
            "confidence_level": 0.92
        }
    ]
    
    for trend_data in trends:
        existing = db.query(FashionTrend).filter(
            FashionTrend.trend_name == trend_data["trend_name"]
        ).first()
        
        if not existing:
            trend = FashionTrend(**trend_data)
            db.add(trend)
    
    db.commit()
    print(f"✅ Seeded {len(trends)} fashion trends")

def seed_style_influencers(db: Session):
    """Seed style influencers data"""
    influencers = [
        {
            "name": "Rina Tan",
            "handle": "@rinatan",
            "bio": "Fashion stylist and sustainable style advocate",
            "profile_image_url": "https://example.com/influencer1.jpg",
            "followers_count": 1200000,
            "engagement_rate": 0.048,
            "influence_score": 0.92,
            "trend_setter_type": "Soft tailoring",
            "recent_trend": "Muted palettes",
            "location": "New York, USA",
            "scope": "global"
        },
        {
            "name": "Alex Chen",
            "handle": "@alexstyle",
            "bio": "Sustainable fashion pioneer and vintage collector",
            "profile_image_url": "https://example.com/influencer2.jpg",
            "followers_count": 890000,
            "engagement_rate": 0.062,
            "influence_score": 0.88,
            "trend_setter_type": "Sustainable fashion",
            "recent_trend": "Vintage mixing",
            "location": "Los Angeles, USA",
            "scope": "global"
        },
        {
            "name": "Maya Johnson",
            "handle": "@maya_fashion",
            "bio": "Street couture and high-low fashion mixing expert",
            "profile_image_url": "https://example.com/influencer3.jpg",
            "followers_count": 2100000,
            "engagement_rate": 0.039,
            "influence_score": 0.85,
            "trend_setter_type": "Street couture",
            "recent_trend": "Deconstructed blazers",
            "location": "London, UK",
            "scope": "global"
        }
    ]
    
    for inf_data in influencers:
        existing = db.query(StyleInfluencer).filter(
            StyleInfluencer.handle == inf_data["handle"]
        ).first()
        
        if not existing:
            influencer = StyleInfluencer(**inf_data)
            db.add(influencer)
    
    db.commit()
    print(f"✅ Seeded {len(influencers)} style influencers")

def seed_explore_content(db: Session):
    """Seed explore content data"""
    content = [
        {
            "title": "Monochrome Layering",
            "content_type": "style_post",
            "author_name": "Ava M.",
            "author_avatar_url": "https://example.com/avatar1.jpg",
            "description": "Mastering the art of black and white layering",
            "image_url": "https://example.com/outfit1.jpg",
            "tags": ["minimalist", "winter", "layering"],
            "likes_count": 245,
            "views_count": 5190,
            "shares_count": 23,
            "comments_count": 18,
            "category": "tops",
            "style_archetype": "minimalist",
            "is_trending": True,
            "trending_score": 0.89,
            "is_public": True,
            "is_featured": False
        },
        {
            "title": "Street Style Vibes",
            "content_type": "outfit",
            "author_name": "Marcus K.",
            "author_avatar_url": "https://example.com/avatar2.jpg",
            "description": "Urban street style with a twist",
            "image_url": "https://example.com/outfit2.jpg",
            "tags": ["streetwear", "casual", "urban"],
            "likes_count": 189,
            "views_count": 3420,
            "shares_count": 31,
            "comments_count": 12,
            "category": "bottoms",
            "style_archetype": "streetwear",
            "is_trending": True,
            "trending_score": 0.76,
            "is_public": True,
            "is_featured": True
        },
        {
            "title": "Business Chic",
            "content_type": "lookbook",
            "author_name": "Sofia R.",
            "author_avatar_url": "https://example.com/avatar3.jpg",
            "description": "Professional looks that don't compromise on style",
            "image_url": "https://example.com/outfit3.jpg",
            "tags": ["business", "elegant", "professional"],
            "likes_count": 312,
            "views_count": 6780,
            "shares_count": 45,
            "comments_count": 28,
            "category": "outerwear",
            "style_archetype": "elegant",
            "is_trending": False,
            "trending_score": 0.65,
            "is_public": True,
            "is_featured": False
        }
    ]
    
    for content_data in content:
        existing = db.query(ExploreContent).filter(
            ExploreContent.title == content_data["title"],
            ExploreContent.author_name == content_data["author_name"]
        ).first()
        
        if not existing:
            explore_item = ExploreContent(**content_data)
            db.add(explore_item)
    
    db.commit()
    print(f"✅ Seeded {len(content)} explore content items")

def seed_nearby_locations(db: Session):
    """Seed nearby locations data"""
    # San Francisco coordinates for example
    base_lat = 37.7749
    base_lng = -122.4194
    
    locations = [
        {
            "location_type": "person",
            "name": "Leo",
            "image_url": "https://example.com/avatar1.jpg",
            "latitude": base_lat + 0.005,
            "longitude": base_lng + 0.003,
            "address": "Mission District",
            "city": "San Francisco",
            "country": "USA",
            "location_metadata": {
                "style": "streetwear",
                "mutualConnections": 3,
                "recentOutfit": "Oversized hoodie + cargos",
                "isOnline": True
            },
            "is_active": True,
            "is_public": True
        },
        {
            "location_type": "event",
            "name": "Fashion Pop-up",
            "description": "Local designer showcase",
            "image_url": "https://example.com/event1.jpg",
            "latitude": base_lat + 0.009,
            "longitude": base_lng - 0.005,
            "address": "Market St.",
            "city": "San Francisco",
            "country": "USA",
            "location_metadata": {
                "date": (datetime.utcnow() + timedelta(days=3)).isoformat() + "Z",
                "attendees": 120,
                "category": "streetwear"
            },
            "is_active": True,
            "is_public": True,
            "expires_at": datetime.utcnow() + timedelta(days=7)
        },
        {
            "location_type": "hotspot",
            "name": "SoMa Style Hub",
            "description": "Trendy boutique in SoMa",
            "image_url": "https://example.com/hotspot1.jpg",
            "latitude": base_lat + 0.007,
            "longitude": base_lng - 0.004,
            "address": "SoMa District",
            "city": "San Francisco",
            "country": "USA",
            "location_metadata": {
                "type": "boutique",
                "popularStyles": ["minimalist", "techwear"],
                "rating": 4.6,
                "checkIns": 312
            },
            "is_active": True,
            "is_public": True
        }
    ]
    
    for loc_data in locations:
        existing = db.query(NearbyLocation).filter(
            NearbyLocation.name == loc_data["name"],
            NearbyLocation.location_type == loc_data["location_type"]
        ).first()
        
        if not existing:
            location = NearbyLocation(**loc_data)
            db.add(location)
    
    db.commit()
    print(f"✅ Seeded {len(locations)} nearby locations")

def seed_trend_insights(db: Session):
    """Seed trend insights data"""
    insights = [
        {
            "category": "colors",
            "trending_items": ["navy", "cream", "sage green", "terracotta"],
            "declining_items": ["neon", "lime", "hot pink"],
            "scope": "global",
            "timeframe": "week",
            "confidence_score": 0.87,
            "data_points": 15000,
            "valid_until": datetime.utcnow() + timedelta(days=7)
        },
        {
            "category": "patterns",
            "trending_items": ["pinstripe", "small florals", "geometric"],
            "declining_items": ["animal print", "large logos"],
            "scope": "global",
            "timeframe": "week",
            "confidence_score": 0.82,
            "data_points": 12000,
            "valid_until": datetime.utcnow() + timedelta(days=7)
        },
        {
            "category": "silhouettes",
            "trending_items": ["oversized blazers", "wide-leg pants", "cropped tops"],
            "declining_items": ["skinny jeans", "bodycon dresses"],
            "scope": "global",
            "timeframe": "week",
            "confidence_score": 0.89,
            "data_points": 18000,
            "valid_until": datetime.utcnow() + timedelta(days=7)
        }
    ]
    
    for insight_data in insights:
        existing = db.query(TrendInsight).filter(
            TrendInsight.category == insight_data["category"],
            TrendInsight.scope == insight_data["scope"],
            TrendInsight.timeframe == insight_data["timeframe"],
            TrendInsight.valid_until > datetime.utcnow()
        ).first()
        
        if not existing:
            insight = TrendInsight(**insight_data)
            db.add(insight)
    
    db.commit()
    print(f"✅ Seeded {len(insights)} trend insights")

def main():
    """Main seeding function"""
    print("🌱 Seeding trends and social data...")
    
    db = SessionLocal()
    try:
        seed_fashion_trends(db)
        seed_style_influencers(db)
        seed_explore_content(db)
        seed_nearby_locations(db)
        seed_trend_insights(db)
        
        print("\n🎉 All trends data seeded successfully!")
        print("\nYou can now test the ML endpoints with real data.")
        
    except Exception as e:
        print(f"❌ Error seeding data: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    main()
