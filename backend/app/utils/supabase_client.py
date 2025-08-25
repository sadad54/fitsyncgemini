from supabase import create_client, Client
from app.core.config import settings

# Check environment variables
if not settings.SUPABASE_URL or not settings.SUPABASE_SERVICE_ROLE_KEY:
    raise RuntimeError("❌ Supabase credentials are missing from environment variables.")

# Initialize Supabase client
supabase: Client = create_client(
    settings.SUPABASE_URL,
    settings.SUPABASE_SERVICE_ROLE_KEY
)
