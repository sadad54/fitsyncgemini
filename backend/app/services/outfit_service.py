from app.models.outfit import Outfit, OutfitCreate, OutfitUpdate
from app.core.database import get_db
from app.services.recommendation_service import RecommendationService
from typing import List, Optional
import uuid
from datetime import datetime

class OutfitService:
    def __init__(self):
        self.db = get_db()
        self.recommendation_service = RecommendationService()

    async def create_outfit(self, outfit_data: OutfitCreate, user_id: str) -> Outfit:
        outfit_dict = outfit_data.dict()
        outfit_dict["id"] = str(uuid.uuid4())
        outfit_dict["user_id"] = user_id
        outfit_dict["created_at"] = datetime.utcnow().isoformat()
        outfit_dict["updated_at"] = datetime.utcnow().isoformat()
        
        result = self.db.table("outfits").insert(outfit_dict).execute()
        return Outfit(**result.data[0])

    async def get_user_outfits(self, user_id: str) -> List[Outfit]:
        result = self.db.table("outfits").select("*").eq("user_id", user_id).execute()
        return [Outfit(**outfit) for outfit in result.data]

    async def get_outfit(self, outfit_id: str, user_id: str) -> Optional[Outfit]:
        result = self.db.table("outfits").select("*").eq("id", outfit_id).eq("user_id", user_id).execute()
        if result.data:
            return Outfit(**result.data[0])
        return None

    async def update_outfit(self, outfit_id: str, outfit_data: OutfitUpdate, user_id: str) -> Optional[Outfit]:
        update_data = outfit_data.dict(exclude_unset=True)
        update_data["updated_at"] = datetime.utcnow().isoformat()
        
        result = self.db.table("outfits").update(update_data).eq("id", outfit_id).eq("user_id", user_id).execute()
        if result.data:
            return Outfit(**result.data[0])
        return None

    async def delete_outfit(self, outfit_id: str, user_id: str) -> bool:
        result = self.db.table("outfits").delete().eq("id", outfit_id).eq("user_id", user_id).execute()
        return len(result.data) > 0

    async def share_outfit(self, outfit_id: str, user_id: str) -> dict:
        outfit = await self.get_outfit(outfit_id, user_id)
        if not outfit:
            raise ValueError("Outfit not found")
        
        # Create a shared version of the outfit
        shared_outfit = outfit.dict()
        shared_outfit["id"] = str(uuid.uuid4())
        shared_outfit["original_outfit_id"] = outfit_id
        shared_outfit["is_shared"] = True
        shared_outfit["created_at"] = datetime.utcnow().isoformat()
        
        result = self.db.table("shared_outfits").insert(shared_outfit).execute()
        return {"shared_outfit_id": result.data[0]["id"]}