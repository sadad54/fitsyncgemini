from datetime import datetime, timezone
from fastapi import HTTPException, status
from supabase import create_client, Client
from app.core.config import settings
from app.models.user import User


class UnifiedAuthService:
    """Verifies Supabase-issued JWTs and keeps public.user_profiles in sync."""

    def __init__(self):
        self.supabase: Client = create_client(
            settings.SUPABASE_URL,
            settings.SUPABASE_SERVICE_ROLE_KEY,
        )

    def _verify_supabase_token(self, token: str) -> dict:
        try:
            user_response = self.supabase.auth.get_user(token)
        except Exception:
            user_response = None

        if not user_response or not user_response.user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication token",
            )

        return {"id": user_response.user.id, "email": user_response.user.email}

    def _get_or_create_profile(self, user_id: str, email: str) -> dict:
        existing = self.supabase.table("user_profiles").select("*").eq("user_id", user_id).execute()
        if existing.data:
            return existing.data[0]

        now = datetime.now(timezone.utc).isoformat()
        new_profile = {
            "user_id": user_id,
            "email": email,
            "display_name": None,
            "style_preferences": [],
            "favorite_colors": [],
            "sizes": {},
            "onboarding_complete": False,
            "created_at": now,
            "updated_at": now,
        }
        result = self.supabase.table("user_profiles").insert(new_profile).execute()
        return result.data[0]

    async def get_current_user_from_token(self, token: str) -> User:
        if token.startswith("Bearer "):
            token = token[7:]

        supabase_user = self._verify_supabase_token(token)
        profile = self._get_or_create_profile(supabase_user["id"], supabase_user["email"])
        return User(**profile)

    async def update_profile(self, user_id: str, updates: dict) -> User:
        updates["updated_at"] = datetime.now(timezone.utc).isoformat()
        result = self.supabase.table("user_profiles").update(updates).eq("user_id", user_id).execute()
        if not result.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Profile not found",
            )
        return User(**result.data[0])


auth_service = UnifiedAuthService()
