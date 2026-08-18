from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel


class TryOnResult(BaseModel):
    id: str
    user_id: str
    item_ids: List[str] = []
    person_image_url: Optional[str] = None
    result_image_url: Optional[str] = None
    status: str
    confidence_score: Optional[float] = None
    error_message: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
