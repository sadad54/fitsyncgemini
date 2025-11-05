# FitSync Production Environment
# Copy this to your deployment platform's environment variables

# ===== CORE SETTINGS =====
ENV=production
DEBUG=false
SECRET_KEY=your-super-secure-secret-key-for-production-make-it-long-and-random
ACCESS_TOKEN_EXPIRE_MINUTES=11520
API_V1_STR=/api/v1

# ===== SUPABASE SETTINGS =====
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
SUPABASE_ANON_KEY=your-anon-key

# ===== EXTERNAL APIs =====
GROQ_API_KEY=your_groq_api_key
GROQ_BASE_URL=https://api.groq.com/openai/v1
GOOGLE_CLOUD_VISION_API_KEY=your_google_vision_api_key
GOOGLE_CLOUD_PROJECT_ID=your-google-project-id
HUGGINGFACE_TOKEN=your_huggingface_token
OPENWEATHER_API_KEY=your_openweather_api_key
OPENWEATHER_BASE_URL=https://api.openweathermap.org/data/2.5
GOOGLE_PLACES_API_KEY=your_google_places_api_key
GOOGLE_PLACES_BASE_URL=https://maps.googleapis.com/maps/api/place

# ===== REDIS SETTINGS =====
# For Railway: Use Railway's Redis addon
# For other platforms: Use Upstash free tier
REDIS_URL=redis://default:password@host:port

# ===== RATE LIMITING =====
GOOGLE_VISION_RATE_LIMIT=1000
OPENWEATHER_RATE_LIMIT=1000
GOOGLE_PLACES_RATE_LIMIT=100

# ===== CACHE SETTINGS =====
CACHE_TTL_WEATHER=3600
CACHE_TTL_PLACES=86400
CACHE_TTL_TRENDS=3600