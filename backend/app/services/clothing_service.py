from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Tuple

from fastapi import HTTPException, status

from app.core.database import db
from app.external_apis.groq_client import groq_client
from app.ml.clothing_classifier import clothing_classifier
from app.models.clothing import ClothingItem
from app.utils.image_utils import process_and_upload_image

CORE_CATEGORIES = ["tops", "bottoms", "footwear", "outerwear"]

FALLBACK_VISION_RESULT: Dict[str, Any] = {
    "category": "unknown",
    "sub_category": None,
    "colors": [],
    "confidence": 0.0,
    "detected_objects": [],
    "detected_labels": [],
    "error": "vision_unavailable",
}


async def _safe_vision_analysis(image_bytes: bytes, user_id: str) -> Dict[str, Any]:
    """AI category detection is a nice-to-have, not a blocker — the local
    classifier has no external dependency to fail, but a fallback stays here
    in case the model can't load (e.g. disk space) so adding a closet item
    still works with manual category selection either way."""
    try:
        return await clothing_classifier.analyze(image_bytes)
    except Exception:
        return dict(FALLBACK_VISION_RESULT)


def _to_clothing_item(row: Dict[str, Any]) -> ClothingItem:
    return ClothingItem(
        id=row["id"],
        user_id=row["user_id"],
        name=row["name"],
        image_url=row.get("image_url"),
        category=row.get("category") or "unknown",
        subcategory=row.get("subcategory"),
        colors=row.get("colors") or [],
        tags=row.get("tags") or [],
        seasons=row.get("seasons") or [],
        occasions=row.get("occasions") or [],
        brand=row.get("brand"),
        notes=row.get("notes"),
        analysis=row.get("ml_analysis") or {},
        created_at=row["created_at"],
        updated_at=row["updated_at"],
    )


class ClothingService:
    async def detect_category(self, image_bytes: bytes, user_id: str) -> Dict[str, Any]:
        return await _safe_vision_analysis(image_bytes, user_id)

    async def create_clothing_item(
        self,
        user_id: str,
        name: str,
        image_bytes: bytes,
        category: Optional[str] = None,
        brand: Optional[str] = None,
        notes: Optional[str] = None,
        precomputed_vision: Optional[Dict[str, Any]] = None,
    ) -> ClothingItem:
        image_url, _ = process_and_upload_image(image_bytes, user_id)

        vision_result = precomputed_vision or await _safe_vision_analysis(image_bytes, user_id)

        analysis: Dict[str, Any] = {"vision": vision_result}
        tags: List[str] = list(vision_result.get("detected_labels") or [])

        try:
            groq_result = await groq_client.analyze_style_and_outfit(image_bytes, {}, user_id=user_id)
            analysis["groq"] = groq_result
            tags.extend(groq_result.get("occasion_recommendations") or [])
        except Exception:
            analysis["groq"] = {"success": False, "note": "style analysis unavailable"}

        now = datetime.now(timezone.utc).isoformat()
        row = {
            "user_id": user_id,
            "name": name,
            "image_url": image_url,
            "category": category or vision_result.get("category") or "unknown",
            "subcategory": vision_result.get("sub_category"),
            "colors": vision_result.get("colors") or [],
            "tags": tags,
            "seasons": [],
            "occasions": [],
            "brand": brand,
            "notes": notes,
            "ml_confidence": vision_result.get("confidence", 0.0),
            "ml_analysis": analysis,
            "created_at": now,
            "updated_at": now,
        }
        result = db.get_client().table("clothing_items").insert(row).execute()
        return _to_clothing_item(result.data[0])

    async def list_clothing_items(
        self, user_id: str, category: Optional[str] = None, search: Optional[str] = None
    ) -> Tuple[List[ClothingItem], int]:
        query = db.get_client().table("clothing_items").select("*").eq("user_id", user_id)
        if category:
            query = query.eq("category", category)
        if search:
            query = query.ilike("name", f"%{search}%")
        result = query.order("created_at", desc=True).execute()
        items = [_to_clothing_item(row) for row in result.data]
        return items, len(items)

    async def get_clothing_item(self, user_id: str, item_id: str) -> ClothingItem:
        result = (
            db.get_client()
            .table("clothing_items")
            .select("*")
            .eq("id", item_id)
            .eq("user_id", user_id)
            .execute()
        )
        if not result.data:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Clothing item not found")
        return _to_clothing_item(result.data[0])

    async def update_clothing_item(self, user_id: str, item_id: str, updates: Dict[str, Any]) -> ClothingItem:
        updates = dict(updates)
        updates["updated_at"] = datetime.now(timezone.utc).isoformat()
        result = (
            db.get_client()
            .table("clothing_items")
            .update(updates)
            .eq("id", item_id)
            .eq("user_id", user_id)
            .execute()
        )
        if not result.data:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Clothing item not found")
        return _to_clothing_item(result.data[0])

    async def delete_clothing_item(self, user_id: str, item_id: str) -> None:
        result = (
            db.get_client()
            .table("clothing_items")
            .delete()
            .eq("id", item_id)
            .eq("user_id", user_id)
            .execute()
        )
        if not result.data:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Clothing item not found")

    async def get_stats(self, user_id: str) -> Dict[str, Any]:
        result = db.get_client().table("clothing_items").select("category").eq("user_id", user_id).execute()
        rows = result.data or []
        by_category: Dict[str, int] = {}
        for row in rows:
            cat = row.get("category") or "unknown"
            by_category[cat] = by_category.get(cat, 0) + 1
        missing_essentials = [cat for cat in CORE_CATEGORIES if by_category.get(cat, 0) == 0]
        return {
            "total_items": len(rows),
            "by_category": by_category,
            "missing_essentials": missing_essentials,
        }


clothing_service = ClothingService()
