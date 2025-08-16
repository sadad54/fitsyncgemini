# FitSync ML Endpoints Deployment Guide

This guide covers deploying the new ML endpoints with real data, caching, and map integration.

## Prerequisites

1. **Backend Environment**:
   - Python 3.8+
   - PostgreSQL or SQLite
   - Redis (for production caching)

2. **Flutter Environment**:
   - Flutter 3.0+
   - Google Maps API key

## Backend Setup

### 1. Database Migration

Run the new database migration to create trends tables:

```bash
cd fitsync-backend

# Run the migration
alembic upgrade head

# If you need to create the migration first:
# alembic revision --autogenerate -m "Add trends tables"
```

### 2. Seed Sample Data

Populate the database with sample data:

```bash
# Make sure your virtual environment is activated
source venv/bin/activate  # Linux/Mac
# or
venv\Scripts\activate     # Windows

# Install dependencies if needed
pip install -r requirements.txt

# Run the seed script
python seed_trends_data.py
```

### 3. Update Models Registration

Ensure new models are imported in your main models `__init__.py`:

```python
# app/models/__init__.py
from .user import User
from .clothing import ClothingItem, OutfitCombination
from .trends import (
    FashionTrend, StyleInfluencer, ExploreContent, 
    NearbyLocation, TrendInsight
)
```

### 4. Production Caching Setup

For production, replace the in-memory cache with Redis:

```bash
# Install Redis
# Ubuntu/Debian:
sudo apt-get install redis-server

# macOS:
brew install redis

# Windows: Download from https://github.com/microsoftarchive/redis/releases
```

Update cache service for Redis (optional for production):

```python
# app/services/cache_service.py
import redis
import json
from typing import Any, Optional
import logging

# Redis configuration
REDIS_HOST = os.getenv('REDIS_HOST', 'localhost')
REDIS_PORT = int(os.getenv('REDIS_PORT', 6379))
REDIS_DB = int(os.getenv('REDIS_DB', 0))

# Create Redis client
redis_client = redis.Redis(
    host=REDIS_HOST,
    port=REDIS_PORT,
    db=REDIS_DB,
    decode_responses=True
)

class CacheService:
    @staticmethod
    def get(key: str) -> Optional[Any]:
        try:
            value = redis_client.get(key)
            return json.loads(value) if value else None
        except Exception as e:
            logger.error(f"Cache get error: {e}")
            return None
    
    @staticmethod
    def set(key: str, value: Any, ttl_seconds: int = 300):
        try:
            redis_client.setex(key, ttl_seconds, json.dumps(value))
        except Exception as e:
            logger.error(f"Cache set error: {e}")
```

### 5. Environment Variables

Update your `.env` file:

```env
# Database
DATABASE_URL=sqlite:///./fitsync.db  # or PostgreSQL URL

# Redis (for production)
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_DB=0

# Cache settings
CACHE_TTL_CATEGORIES=3600
CACHE_TTL_TRENDING=900
CACHE_TTL_NEARBY=180

# Google Maps (for geocoding - optional)
GOOGLE_MAPS_API_KEY=your_server_side_api_key_here
```

## Flutter Setup

### 1. Update Dependencies

Add new dependencies to `pubspec.yaml`:

```yaml
dependencies:
  google_maps_flutter: ^2.5.0
  location: ^5.0.3
  permission_handler: ^11.0.1
  cached_network_image: ^3.3.0  # For image caching
```

### 2. Google Maps Configuration

Follow the [MAP_INTEGRATION_GUIDE.md](MAP_INTEGRATION_GUIDE.md) for complete setup.

### 3. Add Location Service

Create the location service:

```bash
# Create the location service file
touch lib/services/location_service.dart
```

Copy the location service implementation from the map integration guide.

### 4. Update Nearby Screen

Replace the existing nearby screen with the map-based implementation:

```dart
// lib/screens/nearby/nearby_screen.dart
// Replace with the implementation from MAP_INTEGRATION_GUIDE.md
```

## Testing the Implementation

### 1. Backend Testing

Test the new endpoints:

```bash
cd fitsync-backend

# Start the backend server
uvicorn app.main:app --reload

# In another terminal, test the endpoints
python test_new_ml_endpoints.py
```

Expected results:
- All endpoints should return 403 (authentication required) ✅
- No 404 errors (endpoints exist) ✅
- No 500 errors (no implementation bugs) ✅

### 2. Test with Authentication

Create a test user and get an auth token:

```bash
# Run the authentication test
python test_auth.py
```

Update the test script with the auth token:

```python
# In test_new_ml_endpoints.py
AUTH_TOKEN = "your_auth_token_here"
```

Run tests again - should now return 200 responses with data.

### 3. Flutter Testing

Test the Flutter integration:

```bash
cd ..  # Back to project root
flutter run
```

Test functionality:
- ✅ Categories load in explore screen
- ✅ Trending styles display with growth percentages
- ✅ Explore items show with real data
- ✅ Trends screen shows fashion insights
- ✅ Nearby screen requests location permission
- ✅ Map displays with user location
- ✅ Nearby markers appear on map

## Performance Monitoring

### 1. Cache Performance

Monitor cache hit rates:

```bash
# Check cache stats (requires admin access)
curl -X GET "http://localhost:8000/api/v1/cache/stats" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

### 2. Database Performance

Monitor database queries:

```python
# Add to your main.py for development
import logging
logging.basicConfig()
logging.getLogger('sqlalchemy.engine').setLevel(logging.INFO)
```

### 3. API Response Times

Monitor endpoint performance:

```python
# Add middleware to track response times
from fastapi import Request, Response
import time

@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    response.headers["X-Process-Time"] = str(process_time)
    return response
```

## Production Deployment

### 1. Backend Deployment

Using Docker:

```dockerfile
# Dockerfile
FROM python:3.9-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Run migrations
RUN alembic upgrade head

# Seed data (for initial deployment)
RUN python seed_trends_data.py

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

```yaml
# docker-compose.yml
version: '3.8'
services:
  backend:
    build: .
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://user:pass@db:5432/fitsync
      - REDIS_HOST=redis
    depends_on:
      - db
      - redis
  
  db:
    image: postgres:13
    environment:
      POSTGRES_DB: fitsync
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
    volumes:
      - postgres_data:/var/lib/postgresql/data
  
  redis:
    image: redis:6-alpine
    
volumes:
  postgres_data:
```

### 2. Flutter Deployment

Build for production:

```bash
# Android
flutter build apk --release
# or
flutter build appbundle --release

# iOS
flutter build ios --release
```

### 3. Environment-Specific Configuration

Create environment-specific config:

```dart
// lib/config/environment.dart
enum Environment { development, staging, production }

class EnvironmentConfig {
  static Environment get current {
    const env = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
    switch (env) {
      case 'staging':
        return Environment.staging;
      case 'production':
        return Environment.production;
      default:
        return Environment.development;
    }
  }
  
  static String get apiBaseUrl {
    switch (current) {
      case Environment.development:
        return 'http://127.0.0.1:8000';
      case Environment.staging:
        return 'https://api-staging.fitsync.com';
      case Environment.production:
        return 'https://api.fitsync.com';
    }
  }
}
```

## Security Considerations

### 1. API Rate Limiting

Add rate limiting to prevent abuse:

```python
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# Apply to endpoints
@router.get("/recommendations/outfits")
@limiter.limit("10/minute")
async def get_outfit_recommendations(request: Request, ...):
```

### 2. Input Validation

Ensure all query parameters are validated:

```python
from pydantic import validator

class NearbyQueryParams(BaseModel):
    lat: float
    lng: float
    radius_km: float = Field(5.0, ge=0.1, le=50.0)
    
    @validator('lat')
    def validate_latitude(cls, v):
        if not -90 <= v <= 90:
            raise ValueError('Invalid latitude')
        return v
    
    @validator('lng')
    def validate_longitude(cls, v):
        if not -180 <= v <= 180:
            raise ValueError('Invalid longitude')
        return v
```

### 3. Data Privacy

Implement privacy controls:

```python
# Filter sensitive data based on user privacy settings
def filter_nearby_people(people: List[NearbyPerson], requesting_user: User):
    filtered = []
    for person in people:
        # Check privacy settings
        if person.is_public or person.user_id == requesting_user.id:
            filtered.append(person)
    return filtered
```

## Monitoring and Logging

### 1. Application Monitoring

Set up monitoring with tools like:
- **Sentry** for error tracking
- **DataDog** or **New Relic** for performance monitoring
- **Prometheus + Grafana** for metrics

### 2. Logging

Configure structured logging:

```python
import structlog

logger = structlog.get_logger(__name__)

# In your endpoints
logger.info("Recommendation request", 
           user_id=current_user.id, 
           context=context_data,
           cache_hit=cached_result is not None)
```

## Troubleshooting

### Common Issues

1. **Cache Connection Errors**:
   ```bash
   # Check Redis connection
   redis-cli ping
   ```

2. **Database Migration Issues**:
   ```bash
   # Reset migration (development only)
   alembic downgrade base
   alembic upgrade head
   ```

3. **Location Permission Issues**:
   ```dart
   // Check permission status
   final status = await Permission.location.status;
   print('Location permission: $status');
   ```

4. **Map Rendering Issues**:
   ```bash
   # Clear Flutter cache
   flutter clean
   flutter pub get
   ```

This deployment guide ensures a smooth transition from mock data to a production-ready system with real data, caching, and map integration.
