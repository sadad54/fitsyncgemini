# 🚀 FitSync Backend: Complete Setup Guide

## Overview
This guide will help you set up all the required APIs to make your FitSync backend fully functional. We've chosen the best free and affordable options for each service.

## 📋 Required APIs

### 1. ✅ **Groq API** (Already Set Up)
- **Purpose**: AI outfit suggestions and style analysis
- **Status**: ✅ Configured with your key
- **Cost**: Free tier available

### 2. ✅ **Google Vision API** (Already Set Up)
- **Purpose**: Clothing detection and analysis
- **Status**: ✅ Configured with your key
- **Cost**: Free tier available

### 3. 🔧 **Replicate AI** (Virtual Try-On)
- **Purpose**: Virtual try-on functionality
- **Cost**: Free tier available
- **Setup Required**: Yes

### 4. 🔧 **OpenWeather API** (Weather Integration)
- **Purpose**: Weather-based outfit recommendations
- **Cost**: Free tier available
- **Setup Required**: Yes

### 5. 🔧 **Google Places API** (Location Services)
- **Purpose**: Find nearby fashion stores
- **Cost**: Free tier available
- **Setup Required**: Yes

---

## 🎯 **Step-by-Step API Setup**

### **Step 1: Replicate AI (Virtual Try-On)**

#### **1.1 Sign Up for Replicate**
1. Go to [replicate.com](https://replicate.com)
2. Click "Sign Up" (use GitHub or Google)
3. **No credit card required** for free tier

#### **1.2 Get Your API Key**
1. After signing up, go to [Account Settings](https://replicate.com/account/api-tokens)
2. Click "Create API token"
3. Name it "FitSync Virtual Try-On"
4. Copy the API key (starts with `r8_`)

#### **1.3 Update Your Environment**
```bash
# Replace the placeholder in your .env file
REPLICATE_API_KEY=r8_your_actual_api_key_here
```

---

### **Step 2: OpenWeather API (Weather Integration)**

#### **2.1 Sign Up for OpenWeather**
1. Go to [openweathermap.org/api](https://openweathermap.org/api)
2. Click "Get API Key"
3. Create a free account
4. **No credit card required**

#### **2.2 Get Your API Key**
1. After signing up, go to your [API keys page](https://home.openweathermap.org/api_keys)
2. Copy your API key
3. Wait 2 hours for activation (free tier requirement)

#### **2.3 Update Your Environment**
```bash
# Add to your .env file
OPENWEATHER_API_KEY=your_openweather_api_key_here
```

---

### **Step 3: Google Places API (Location Services)**

#### **3.1 Enable Google Places API**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable the "Places API" from the API Library
4. Go to "Credentials" and create an API key

#### **3.2 Get Your API Key**
1. In Google Cloud Console, go to "Credentials"
2. Click "Create Credentials" → "API Key"
3. Copy the API key
4. **Important**: Restrict the key to "Places API" only

#### **3.3 Update Your Environment**
```bash
# Add to your .env file
GOOGLE_PLACES_API_KEY=your_google_places_api_key_here
```

---

## 🔧 **Complete Environment File**

Update your `.env` file with all the API keys:

```env
# API Settings
SECRET_KEY=fitsync-secret-key-2024-make-it-long-and-random-for-production
ACCESS_TOKEN_EXPIRE_MINUTES=11520

# Supabase Settings (You'll need to set up Supabase)
SUPABASE_URL=your-supabase-url
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
SUPABASE_ANON_KEY=your-anon-key

# External APIs
GOOGLE_CLOUD_VISION_API_KEY=AIzaSyC6w992SBRb4M5srA3zITMVofogG2wv0UY
GOOGLE_CLOUD_PROJECT_ID=your-google-project-id
REPLICATE_API_KEY=r8_your_replicate_api_key_here
OPENWEATHER_API_KEY=your_openweather_api_key_here
OPENWEATHER_BASE_URL=https://api.openweathermap.org/data/2.5
GOOGLE_PLACES_API_KEY=your_google_places_api_key_here
GOOGLE_PLACES_BASE_URL=https://maps.googleapis.com/maps/api/place
GROQ_API_KEY=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
GROQ_BASE_URL=https://api.groq.com/openai/v1

# Redis Settings
REDIS_URL=redis://localhost:6379

# Rate Limiting
GOOGLE_VISION_RATE_LIMIT=1000
REPLICATE_RATE_LIMIT=50
OPENWEATHER_RATE_LIMIT=1000
GOOGLE_PLACES_RATE_LIMIT=100

# Image Processing
MAX_IMAGE_SIZE=10485760
ALLOWED_IMAGE_TYPES=["image/jpeg", "image/png", "image/webp"]

# Cache Settings
CACHE_TTL_WEATHER=3600
CACHE_TTL_PLACES=86400
CACHE_TTL_TRENDS=3600
```

---

## 🗄️ **Database Setup (Supabase)**

### **Step 1: Create Supabase Account**
1. Go to [supabase.com](https://supabase.com)
2. Sign up with GitHub
3. Create a new project

### **Step 2: Get Your Credentials**
1. Go to Project Settings → API
2. Copy:
   - Project URL
   - Anon Key
   - Service Role Key

### **Step 3: Update Environment**
```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

---

## 🚀 **Testing Your Setup**

### **Step 1: Install Dependencies**
```bash
cd backend
pip install -r requirements.txt
```

### **Step 2: Start Redis**
```bash
# Option 1: Docker (Recommended)
docker run -d -p 6379:6379 redis:7-alpine

# Option 2: Windows (if you have Redis installed)
redis-server
```

### **Step 3: Test Individual APIs**
```bash
# Test Groq API
python test_groq.py

# Test the full backend
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### **Step 4: Verify API Endpoints**
1. Open [http://localhost:8000/docs](http://localhost:8000/docs)
2. Test the health endpoint: [http://localhost:8000/health](http://localhost:8000/health)
3. Try uploading a clothing item image
4. Test virtual try-on functionality

---

## 🔍 **API Testing Checklist**

### ✅ **Groq API**
- [ ] Test fashion analysis: `python test_groq.py`
- [ ] Verify response contains fashion insights

### ✅ **Google Vision API**
- [ ] Upload clothing image via API
- [ ] Verify clothing detection works
- [ ] Check color and category detection

### ✅ **Replicate AI**
- [ ] Test virtual try-on endpoint
- [ ] Upload person + clothing images
- [ ] Verify try-on result generation

### ✅ **OpenWeather API**
- [ ] Test weather endpoint with coordinates
- [ ] Verify weather data retrieval
- [ ] Check weather-based recommendations

### ✅ **Google Places API**
- [ ] Test nearby stores endpoint
- [ ] Verify location-based results
- [ ] Check store information retrieval

---

## 🛠️ **Troubleshooting**

### **Common Issues**

#### **1. API Key Errors**
- Ensure API keys are correctly copied
- Check for extra spaces or characters
- Verify API keys are activated (some require waiting)

#### **2. Rate Limiting**
- Check your API usage limits
- Implement proper rate limiting in your app
- Consider upgrading to paid tiers if needed

#### **3. Redis Connection**
- Ensure Redis is running on port 6379
- Check firewall settings
- Verify Redis URL in environment

#### **4. Image Upload Issues**
- Check file size limits
- Verify supported image formats
- Ensure proper image encoding

---

## 📊 **Cost Breakdown**

### **Free Tier Limits**
- **Groq**: 100 requests/hour
- **Google Vision**: 1000 requests/month
- **Replicate**: 50 requests/hour
- **OpenWeather**: 1000 requests/day
- **Google Places**: 100 requests/day

### **Estimated Monthly Costs (if you exceed free limits)**
- **Groq**: $0.10 per 1000 requests
- **Google Vision**: $1.50 per 1000 requests
- **Replicate**: $0.20 per request
- **OpenWeather**: $40/month for unlimited
- **Google Places**: $17 per 1000 requests

---

## 🎉 **You're Ready!**

Once you've completed all the steps above, your FitSync backend will be fully functional with:

- ✅ AI-powered outfit recommendations
- ✅ Virtual try-on capabilities
- ✅ Weather-based styling suggestions
- ✅ Location-based store discovery
- ✅ Clothing detection and analysis
- ✅ Trend analysis and insights

### **Next Steps**
1. Test all endpoints thoroughly
2. Integrate with your Flutter frontend
3. Deploy to production
4. Monitor API usage and costs

---

## 📞 **Need Help?**

If you encounter any issues:
1. Check the troubleshooting section above
2. Verify all API keys are correctly set
3. Test individual APIs separately
4. Check the backend logs for detailed error messages

Your FitSync backend is now ready to power an amazing fashion recommendation app! 🚀
