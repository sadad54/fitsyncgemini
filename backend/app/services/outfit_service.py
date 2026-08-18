import random
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Tuple

from fastapi import HTTPException, status

from app.core.database import db
from app.models.outfit import Outfit
from app.services.weather_service import WeatherService

ESSENTIAL_CATEGORIES = ["tops", "bottoms", "footwear"]

OCCASION_NAMES = {
    "casual": "Everyday Edit",
    "work": "Desk to Done",
    "date": "Easy Charm",
    "workout": "Move Ready",
    "travel": "Pack Light",
    "dinner": "Evening Out",
}


def _to_outfit(row: Dict[str, Any]) -> Outfit:
    # DB columns predate this contract in a couple of spots (ai_score,
    # is_favorite) — map them to the app-facing names here.
    return Outfit(
        id=row["id"],
        user_id=row["user_id"],
        name=row.get("name") or "Your look",
        item_ids=row.get("item_ids") or [],
        occasion=row.get("occasion") or "casual",
        weather_context=row.get("weather_context"),
        score=row.get("ai_score") or 0.0,
        explanation=row.get("explanation") or "",
        saved=bool(row.get("saved")),
        favorited=bool(row.get("is_favorite")),
        created_at=row["created_at"],
        updated_at=row["updated_at"],
    )


class OutfitService:
    def __init__(self):
        self.weather_service = WeatherService()

    async def generate_outfit(
        self,
        user_id: str,
        occasion: str,
        use_weather: bool = False,
        latitude: Optional[float] = None,
        longitude: Optional[float] = None,
    ) -> Outfit:
        items_result = db.get_client().table("clothing_items").select("*").eq("user_id", user_id).execute()
        items = items_result.data or []

        weather_context: Optional[Dict[str, Any]] = None
        if use_weather and latitude is not None and longitude is not None:
            try:
                weather_context = await self.weather_service.get_current_weather(latitude, longitude, user_id=user_id)
            except Exception:
                weather_context = None

        selected, categories_filled = self._select_items(items, occasion, weather_context)
        item_ids = [item["id"] for item in selected]
        score = self._score(categories_filled, weather_context is not None, len(item_ids))
        explanation = self._explain(selected, occasion, weather_context)

        now = datetime.now(timezone.utc).isoformat()
        row = {
            "user_id": user_id,
            "name": OCCASION_NAMES.get(occasion, occasion.replace("_", " ").title()),
            "occasion": occasion,
            "item_ids": item_ids,
            "weather_context": weather_context,
            "ai_score": score,
            "explanation": explanation,
            "saved": False,
            "is_favorite": False,
            "created_at": now,
            "updated_at": now,
        }
        result = db.get_client().table("outfits").insert(row).execute()
        return _to_outfit(result.data[0])

    async def list_outfits(self, user_id: str, saved_only: bool = False) -> Tuple[List[Outfit], int]:
        query = db.get_client().table("outfits").select("*").eq("user_id", user_id)
        if saved_only:
            query = query.eq("saved", True)
        result = query.order("created_at", desc=True).execute()
        outfits = [_to_outfit(row) for row in result.data]
        return outfits, len(outfits)

    async def save_outfit(self, user_id: str, outfit_id: str) -> Outfit:
        return await self._update(user_id, outfit_id, {"saved": True})

    async def favorite_outfit(self, user_id: str, outfit_id: str) -> Outfit:
        return await self._update(user_id, outfit_id, {"is_favorite": True})

    async def record_feedback(self, user_id: str, outfit_id: str, rating: int, reason: Optional[str] = None) -> None:
        updates: Dict[str, Any] = {"rating": rating, "updated_at": datetime.now(timezone.utc).isoformat()}
        if reason:
            updates["feedback_reason"] = reason
        result = (
            db.get_client()
            .table("outfits")
            .update(updates)
            .eq("id", outfit_id)
            .eq("user_id", user_id)
            .execute()
        )
        if not result.data:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Outfit not found")

    async def _update(self, user_id: str, outfit_id: str, updates: Dict[str, Any]) -> Outfit:
        updates = dict(updates)
        updates["updated_at"] = datetime.now(timezone.utc).isoformat()
        result = (
            db.get_client()
            .table("outfits")
            .update(updates)
            .eq("id", outfit_id)
            .eq("user_id", user_id)
            .execute()
        )
        if not result.data:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Outfit not found")
        return _to_outfit(result.data[0])

    def _select_items(
        self, items: List[Dict[str, Any]], occasion: str, weather_context: Optional[Dict[str, Any]]
    ) -> Tuple[List[Dict[str, Any]], int]:
        by_category: Dict[str, List[Dict[str, Any]]] = {}
        for item in items:
            by_category.setdefault(item.get("category") or "unknown", []).append(item)

        temperature = weather_context.get("temperature") if weather_context else None
        cold = isinstance(temperature, (int, float)) and temperature < 15
        hot = isinstance(temperature, (int, float)) and temperature > 26

        def pick(category: str) -> Optional[Dict[str, Any]]:
            pool = by_category.get(category)
            return random.choice(pool) if pool else None

        selected: List[Dict[str, Any]] = []
        filled = 0

        if occasion == "workout" and by_category.get("activewear"):
            for piece in (pick("activewear"), pick("footwear")):
                if piece:
                    selected.append(piece)
                    filled += 1
        elif occasion in ("dinner", "date") and by_category.get("dresses"):
            for piece in (pick("dresses"), pick("footwear")):
                if piece:
                    selected.append(piece)
                    filled += 1
        else:
            for piece in (pick("tops"), pick("bottoms"), pick("footwear")):
                if piece:
                    selected.append(piece)
                    filled += 1

        if (cold or occasion in ("travel", "work")) and not hot:
            outer = pick("outerwear")
            if outer and outer not in selected:
                selected.append(outer)

        if not hot and occasion in ("dinner", "date"):
            accessory = pick("accessories")
            if accessory:
                selected.append(accessory)

        return selected, filled

    def _score(self, categories_filled: int, has_weather: bool, item_count: int) -> float:
        if item_count == 0:
            return 0.0
        base = min(categories_filled / len(ESSENTIAL_CATEGORIES), 1.0) * 0.75
        if item_count > categories_filled:
            base += 0.15
        if has_weather:
            base += 0.10
        return round(min(base, 0.98), 2)

    def _explain(
        self, selected: List[Dict[str, Any]], occasion: str, weather_context: Optional[Dict[str, Any]]
    ) -> str:
        if not selected:
            return "Add a few more pieces to your closet and FitSync can start assembling full looks."
        names = [item.get("name") or "a piece" for item in selected]
        colors = sorted({c for item in selected for c in (item.get("colors") or [])})
        pairing = ", ".join(names[:-1]) + (f" and {names[-1]}" if len(names) > 1 else names[0])
        color_note = f" in {', '.join(colors)}" if colors else ""
        weather_note = ""
        temperature = weather_context.get("temperature") if weather_context else None
        if isinstance(temperature, (int, float)):
            weather_note = f" Built for about {round(temperature)}°C right now."
        return f"{pairing}{color_note} — a straightforward pairing for {occasion}.{weather_note}"


outfit_service = OutfitService()
