from datetime import datetime, timezone
from typing import Any, Dict, List, Tuple

from fastapi import HTTPException, status

from app.core.database import db
from app.external_apis.tryon_compositor import composite_tryon
from app.models.tryon import TryOnResult
from app.utils.image_utils import process_and_upload_image

BUCKET = "try-on-results"


def _to_tryon(row: Dict[str, Any]) -> TryOnResult:
    return TryOnResult(
        id=row["id"],
        user_id=row["user_id"],
        item_ids=row.get("item_ids") or [],
        person_image_url=row.get("person_image_url"),
        result_image_url=row.get("result_image_url"),
        status=row.get("status") or "failed",
        confidence_score=row.get("confidence_score"),
        error_message=row.get("error_message"),
        created_at=row["created_at"],
        updated_at=row["updated_at"],
    )


class TryOnService:
    async def create_tryon(self, user_id: str, person_image_bytes: bytes, item_ids: List[str]) -> TryOnResult:
        garments: List[Dict[str, Any]] = []
        if item_ids:
            result = (
                db.get_client()
                .table("clothing_items")
                .select("id, image_url, category")
                .eq("user_id", user_id)
                .in_("id", item_ids)
                .execute()
            )
            garments = result.data or []
            if not garments:
                raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="None of the selected items were found in your closet")

        person_url, _ = process_and_upload_image(person_image_bytes, user_id, bucket=BUCKET, resize=False)

        now = datetime.now(timezone.utc).isoformat()
        row: Dict[str, Any] = {
            "user_id": user_id,
            "item_ids": [g["id"] for g in garments],
            "person_image_url": person_url,
            "status": "processing",
            "view_mode": "preview",
            "created_at": now,
            "updated_at": now,
        }

        try:
            result_bytes, confidence = await composite_tryon(person_image_bytes, garments)
            result_url, _ = process_and_upload_image(result_bytes, user_id, bucket=BUCKET, resize=False)
            row["status"] = "completed"
            row["result_image_url"] = result_url
            row["confidence_score"] = confidence
            row["completed_at"] = datetime.now(timezone.utc).isoformat()
        except Exception as exc:
            row["status"] = "failed"
            row["error_message"] = str(exc)

        result = db.get_client().table("try_on_sessions").insert(row).execute()
        return _to_tryon(result.data[0])

    async def list_tryons(self, user_id: str) -> Tuple[List[TryOnResult], int]:
        result = (
            db.get_client()
            .table("try_on_sessions")
            .select("*")
            .eq("user_id", user_id)
            .order("created_at", desc=True)
            .execute()
        )
        results = [_to_tryon(row) for row in result.data]
        return results, len(results)

    async def get_tryon(self, user_id: str, tryon_id: str) -> TryOnResult:
        result = (
            db.get_client()
            .table("try_on_sessions")
            .select("*")
            .eq("id", tryon_id)
            .eq("user_id", user_id)
            .execute()
        )
        if not result.data:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Try-on result not found")
        return _to_tryon(result.data[0])

    async def delete_tryon(self, user_id: str, tryon_id: str) -> None:
        result = (
            db.get_client()
            .table("try_on_sessions")
            .delete()
            .eq("id", tryon_id)
            .eq("user_id", user_id)
            .execute()
        )
        if not result.data:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Try-on result not found")


tryon_service = TryOnService()
