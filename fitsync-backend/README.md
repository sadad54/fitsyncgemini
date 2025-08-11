# FitSync Backend 🚀

A comprehensive, AI-powered fashion assistant backend built with FastAPI, featuring ML-driven recommendations, virtual try-on, social features, and advanced analytics.

## 🌟 Features

### 🤖 AI & Machine Learning
- **Clothing Detection**: Advanced computer vision for identifying clothing items
- **Style Classification**: ML-powered style archetype recognition
- **Color Analysis**: Intelligent color palette extraction and harmony scoring
- **Body Type Analysis**: Personalized body type compatibility assessment
- **Virtual Try-On**: GAN-based virtual outfit visualization
- **Recommendation Engine**: Hybrid collaborative + content-based recommendations

### 👥 User Management
- **Comprehensive Profiles**: Detailed user profiles with style preferences
- **Body Measurements**: Precise body measurements for perfect fit
- **Style Preferences**: AI-learned style preferences and patterns
- **Social Connections**: Follow/unfollow system with style discovery

### 👗 Wardrobe Management
- **Smart Wardrobe**: AI-powered clothing categorization and tagging
- **Outfit Creation**: Intelligent outfit combination suggestions
- **Style Analysis**: Detailed style compatibility and improvement suggestions
- **Virtual Try-On**: See how outfits look on you before buying

### 🎯 Recommendations
- **Personalized Outfits**: AI-generated outfit recommendations
- **Similar Items**: Find similar clothing items and styles
- **Trend-Based**: Current fashion trend integration
- **Occasion-Specific**: Event and weather-based suggestions
- **Sustainability**: Eco-friendly fashion recommendations

### 🌍 Social Features
- **Fashion Challenges**: Community-driven style challenges
- **Style Posts**: Share and discover outfit combinations
- **Inspiration Feed**: Curated fashion inspiration
- **Location-Based**: Discover nearby fashion enthusiasts
- **Rating System**: Community-driven outfit ratings

### 📊 Analytics & Insights
- **Style Analytics**: Deep insights into personal style patterns
- **Trend Analysis**: Real-time fashion trend detection
- **Performance Metrics**: Comprehensive system monitoring
- **User Behavior**: Advanced user interaction analytics

## 🏗️ Architecture

```
fitsync-backend/
├── app/
│   ├── api/                    # API layer
│   │   └── v1/
│   │       ├── endpoints/      # API endpoints
│   │       └── api_router.py   # Main router
│   ├── models/                 # Database & ML Models
│   │   ├── user.py             # User-related database models
│   │   ├── clothing.py         # Clothing & outfit database models
│   │   ├── social.py           # Social features database models
│   │   ├── analytics.py        # Analytics & tracking database models
│   │   ├── detection/          # Computer vision models
│   │   ├── recommendation/     # Recommendation algorithms
│   │   ├── generation/         # Virtual try-on models
│   │   └── personalization/    # User profiling models
│   ├── schemas/                # Pydantic models
│   ├── services/               # Business logic
│   ├── utils/                  # Utilities
│   └── core/                   # Core functionality
├── tests/                      # Test suite
├── docker/                     # Docker configuration
└── docs/                       # API documentation
```

## 🚀 Quick Start

### Prerequisites

- Python 3.8+
- PostgreSQL 12+
- Redis 6+
- Docker (optional)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/fitsync-backend.git
   cd fitsync-backend
   ```

2. **Create virtual environment**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Set up environment variables**
   ```bash
   cp env.example .env
   # Edit .env with your configuration
   ```

5. **Set up database**
   ```bash
   # Create PostgreSQL database
   createdb fitsync_db
   
   # Run migrations
   alembic upgrade head
   ```

6. **Start Redis**
   ```bash
   redis-server
   ```

7. **Run the application**
   ```bash
   python -m app.main
   ```

The API will be available at `http://localhost:8000`

## 📚 API Documentation

Once the server is running, you can access:

- **Interactive API Docs**: http://localhost:8000/docs
- **ReDoc Documentation**: http://localhost:8000/redoc
- **OpenAPI Schema**: http://localhost:8000/openapi.json

## 🔧 Configuration

### Environment Variables

Copy `env.example` to `.env` and configure:

```bash
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/fitsync_db
REDIS_URL=redis://localhost:6379

# Security
SECRET_KEY=your-secret-key-here

# ML Models
MODEL_CACHE_DIR=./models
ENABLE_GPU=false

# External APIs
WEATHER_API_KEY=your-weather-api-key
OPENAI_API_KEY=your-openai-api-key
```

### Database Setup

1. **Install PostgreSQL**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install postgresql postgresql-contrib
   
   # macOS
   brew install postgresql
   ```

2. **Create database and user**
   ```sql
   CREATE DATABASE fitsync_db;
   CREATE USER fitsync_user WITH PASSWORD 'fitsync_password';
   GRANT ALL PRIVILEGES ON DATABASE fitsync_db TO fitsync_user;
   ```

3. **Run migrations**
   ```bash
   alembic upgrade head
   ```

## 🧪 Testing

### Run tests
```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=app

# Run specific test file
pytest tests/test_user.py
```

### Test database setup
```bash
# Create test database
createdb fitsync_test_db

# Set test environment
export TEST_DATABASE_URL=postgresql://user:password@localhost:5432/fitsync_test_db
```

## 🐳 Docker Deployment

### Using Docker Compose

1. **Build and run**
   ```bash
   docker-compose up --build
   ```

2. **Run in background**
   ```bash
   docker-compose up -d
   ```

3. **View logs**
   ```bash
   docker-compose logs -f
   ```

### Manual Docker

1. **Build image**
   ```bash
   docker build -t fitsync-backend .
   ```

2. **Run container**
   ```bash
   docker run -p 8000:8000 --env-file .env fitsync-backend
   ```

## 📊 Monitoring

### Health Checks
- **Basic Health**: `GET /health`
- **Detailed Health**: `GET /health/detailed`
- **Metrics**: `GET /metrics`

### Logging
- **Structured Logging**: JSON format with correlation IDs
- **Log Levels**: DEBUG, INFO, WARNING, ERROR, CRITICAL
- **Log Files**: `fitsync.log` (production)

### Metrics
- **Prometheus**: Built-in metrics collection
- **Custom Metrics**: Request counts, latency, ML model performance
- **Grafana**: Dashboard templates available

## 🔒 Security

### Authentication
- **JWT Tokens**: Secure token-based authentication
- **Password Hashing**: bcrypt with salt
- **Rate Limiting**: Configurable per-user limits
- **CORS**: Configurable cross-origin policies

### Data Protection
- **Input Validation**: Comprehensive Pydantic validation
- **SQL Injection Protection**: SQLAlchemy ORM
- **XSS Protection**: Input sanitization
- **HTTPS**: Required in production

## 🚀 Production Deployment

### Environment Setup
```bash
# Set production environment
export ENVIRONMENT=production
export DEBUG=false
export WORKERS=4

# Use production database
export DATABASE_URL=postgresql://prod_user:prod_password@prod_host:5432/prod_db

# Set secure secret key
export SECRET_KEY=$(python -c "import secrets; print(secrets.token_urlsafe(32))")
```

### Using Gunicorn
```bash
gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```

### Using Nginx
```nginx
server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## 🤝 Contributing

1. **Fork the repository**
2. **Create feature branch**: `git checkout -b feature/amazing-feature`
3. **Commit changes**: `git commit -m 'Add amazing feature'`
4. **Push to branch**: `git push origin feature/amazing-feature`
5. **Open Pull Request**

### Development Guidelines
- Follow PEP 8 style guide
- Write comprehensive tests
- Update documentation
- Use conventional commit messages

## 📝 API Endpoints

### Core Endpoints
```
POST   /api/v1/auth/register          # User registration
POST   /api/v1/auth/login             # User login
POST   /api/v1/auth/refresh           # Refresh token
GET    /api/v1/users/profile          # Get user profile
PUT    /api/v1/users/profile          # Update user profile
```

### Clothing & Wardrobe
```
POST   /api/v1/clothing/upload        # Upload clothing item
GET    /api/v1/clothing/items         # Get user's wardrobe
POST   /api/v1/outfits/create         # Create outfit
GET    /api/v1/outfits/recommendations # Get outfit recommendations
```

### Analysis & ML
```
POST   /api/v1/analyze/clothing       # Analyze clothing image
POST   /api/v1/analyze/style          # Analyze style
POST   /api/v1/tryon/generate         # Generate virtual try-on
```

### Social Features
```
GET    /api/v1/social/challenges      # Get fashion challenges
POST   /api/v1/social/posts           # Create style post
GET    /api/v1/social/feed            # Get social feed
```

## 🛠️ Development

### Project Structure
```
app/
├── api/                    # API endpoints
├── models/                 # Database models
├── schemas/                # Pydantic schemas
├── services/               # Business logic
├── utils/                  # Utilities
└── core/                   # Core functionality
```

### Adding New Features

1. **Create database model** in `app/models/`
2. **Create Pydantic schemas** in `app/schemas/`
3. **Implement business logic** in `app/services/`
4. **Create API endpoints** in `app/api/v1/endpoints/`
5. **Add tests** in `tests/`

### Database Migrations
```bash
# Create new migration
alembic revision --autogenerate -m "Add new feature"

# Apply migrations
alembic upgrade head

# Rollback migration
alembic downgrade -1
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- FastAPI for the excellent web framework
- SQLAlchemy for database ORM
- Pydantic for data validation
- Ultralytics for YOLO models
- PyTorch for deep learning capabilities

## 📞 Support

- **Documentation**: [docs/](docs/)
- **Issues**: [GitHub Issues](https://github.com/yourusername/fitsync-backend/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/fitsync-backend/discussions)

---

**Made with ❤️ for the fashion community**
