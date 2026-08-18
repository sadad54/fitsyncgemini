from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from app.core.database import db


def _to_trend(row: Dict[str, Any]) -> Dict[str, Any]:
    return {
        "id": row["id"],
        "name": row["title"],
        "description": row.get("description") or "",
        "category": row.get("category") or "general",
        "confidence_score": float(row.get("trend_score") or 0),
        "popularity_percentage": float(row.get("popularity_percentage") or 0),
        "season": row.get("season"),
        "color_palette": row.get("color_palette") or [],
        "style_tags": row.get("style_tags") or [],
        "image_url": row.get("image_url"),
        "created_at": row["created_at"],
        "updated_at": row["updated_at"],
    }


class TrendService:
    async def get_current_trends(self, category: Optional[str] = None, limit: int = 20) -> List[Dict[str, Any]]:
        query = (
            db.get_client()
            .table("fashion_insights")
            .select("*")
            .eq("is_active", True)
            .order("trend_score", desc=True)
            .limit(limit)
        )
        if category:
            query = query.eq("category", category)
        result = query.execute()
        return [_to_trend(row) for row in (result.data or [])]

    async def get_trend(self, trend_id: str) -> Optional[Dict[str, Any]]:
        result = db.get_client().table("fashion_insights").select("*").eq("id", trend_id).execute()
        if not result.data:
            return None
        return _to_trend(result.data[0])

    async def analyze_trends(self) -> Dict[str, Any]:
        result = (
            db.get_client()
            .table("fashion_insights")
            .select("*")
            .eq("is_active", True)
            .order("trend_score", desc=True)
            .execute()
        )
        rows = result.data or []
        trends = [_to_trend(row) for row in rows]

        category_breakdown: Dict[str, int] = {}
        for t in trends:
            category_breakdown[t["category"]] = category_breakdown.get(t["category"], 0) + 1

        confidence_distribution = {
            "high": len([t for t in trends if t["confidence_score"] >= 0.7]),
            "medium": len([t for t in trends if 0.4 <= t["confidence_score"] < 0.7]),
            "low": len([t for t in trends if t["confidence_score"] < 0.4]),
        }

        return {
            "top_trends": trends[:10],
            "category_breakdown": category_breakdown,
            "confidence_distribution": confidence_distribution,
            "analysis_date": datetime.now(timezone.utc),
        }


trend_service = TrendService()
