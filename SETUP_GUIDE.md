# FitSync Setup Guide

This guide will help you set up the FitSync Flutter app with all required dependencies, permissions, and API keys.

## 📋 Prerequisites

### 1. Flutter Environment
- Flutter SDK 3.7.2 or higher
- Dart SDK 3.7.2 or higher
- Android Studio / VS Code with Flutter extensions
- iOS development environment (for iOS builds)

### 2. API Keys Required

#### Google Maps API Key
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create or select a project
3. Enable the following APIs:
   - **Maps SDK for Android**
   - **Maps SDK for iOS**
   - **Places API** (optional, for enhanced location features)
4. Create API credentials (API Key)
5. Restrict the key to your app's package name for security

#### Backend API
- The app connects to the FastAPI backend running on `http://127.0.0.1:8000`
- Ensure the backend is running before testing the app

## 🔧 Setup Instructions

### Step 1: Clone and Install Dependencies

```bash
# Navigate to the Flutter project
cd fitsyncgemini

# Install Flutter dependencies
flutter pub get

# For iOS, install pod dependencies
cd ios && pod install && cd ..
```

### Step 2: Configure Google Maps API Keys

#### Android Configuration
1. Open `android/app/src/main/AndroidManifest.xml`
2. Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual API key:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ACTUAL_API_KEY_HERE" />
```

#### iOS Configuration
1. Open `ios/Runner/AppDelegate.swift`
2. Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual API key:

```swift
GMSServices.provideAPIKey("YOUR_ACTUAL_API_KEY_HERE")
```

### Step 3: Backend Setup

#### Start the Backend Server
```bash
# Navigate to backend directory
cd fitsync-backend

# Install Python dependencies (if not already done)
pip install -r requirements.txt

# Run database migrations
alembic upgrade head

# Start the server
uvicorn app.main:app --reload
```

The backend will be available at `http://127.0.0.1:8000`

#### Test Backend Connectivity
```bash
# Test virtual try-on endpoints
python test_virtual_tryon.py
```

### Step 4: Run the Flutter App

```bash
# For Android
flutter run

# For iOS
flutter run -d ios

# For web (limited functionality)
flutter run -d chrome
```

## 📱 Features Available

### ✅ Working Features

#### Virtual Try-On Screen
- **Camera Integration**: Front camera for selfie-style try-on
- **AR/Mirror Modes**: Switch between AR simulation and live camera
- **Smart Features**: Configurable AI features (lighting, fit analysis, movement)
- **Outfit Selection**: Interactive outfit cards with confidence scores
- **Real-time Processing**: Progress indicators and status updates
- **Settings Management**: User preferences and quality settings

#### Nearby Screen with Google Maps
- **Live Location**: GPS-based location detection
- **Interactive Map**: Google Maps with custom markers
- **Mock Data**: Fallback data when backend is unavailable
- **Permission Handling**: Proper location and camera permission requests
- **Marker Types**: Different markers for people, events, and hotspots
- **Info Windows**: Detailed information on marker tap

#### API Integration
- **Authentication**: JWT-based authentication system
- **ML Endpoints**: Complete virtual try-on API
- **Cache System**: Performance optimization with caching
- **Error Handling**: Comprehensive error handling and fallbacks

### 🔄 Development Features (Mock Data)

When the backend is not available, the app uses mock data for:
- Nearby people, events, and hotspots
- Outfit suggestions
- Try-on features and preferences
- Processing simulations

## 🚨 Troubleshooting

### Common Issues

#### 1. Google Maps Not Loading
**Problem**: Maps show blank or gray screen
**Solutions**:
- Verify API key is correctly placed in both Android and iOS configs
- Ensure Maps SDK is enabled in Google Cloud Console
- Check API key restrictions and billing account
- For Android: Clean and rebuild the project

#### 2. Camera Permission Denied
**Problem**: Camera not working in try-on screen
**Solutions**:
- Check permissions in `AndroidManifest.xml` and `Info.plist`
- Manually grant camera permission in device settings
- Restart the app after granting permissions

#### 3. Location Services Unavailable
**Problem**: Location not detected on nearby screen
**Solutions**:
- Grant location permissions in device settings
- Enable GPS/location services on device
- Use the "Demo Location" fallback option
- Check location permissions in app settings

#### 4. Backend Connection Issues
**Problem**: API calls failing, no data loading
**Solutions**:
- Ensure backend server is running on `http://127.0.0.1:8000`
- Check network connectivity
- App automatically falls back to mock data
- Verify backend health at `http://127.0.0.1:8000/health`

#### 5. Build Issues
**Problem**: App fails to build or run
**Solutions**:
```bash
# Clean and rebuild
flutter clean
flutter pub get

# For iOS
cd ios && pod install && cd ..

# For Android, clean project
flutter clean
flutter pub get
cd android && ./gradlew clean && cd ..
```

### Performance Optimization

#### Android
- Enable proguard for release builds
- Optimize image assets
- Use release build configuration

#### iOS
- Use release mode for better performance
- Optimize for device-specific features
- Test on actual devices for camera functionality

## 🔐 Security Considerations

### API Key Security
- **Never commit API keys to version control**
- Use environment variables or secure key management
- Restrict API keys to specific package names/bundle IDs
- Monitor API usage in Google Cloud Console

### Location Privacy
- Only request location when needed
- Explain location usage to users clearly
- Allow users to opt-out of location sharing
- Provide demo/mock location options

### Camera Privacy
- Request camera permission only when needed
- Explain camera usage for try-on features
- Provide alternative options without camera

## 📚 Additional Resources

### Documentation
- [Google Maps Flutter Plugin](https://pub.dev/packages/google_maps_flutter)
- [Camera Plugin](https://pub.dev/packages/camera)
- [Permission Handler](https://pub.dev/packages/permission_handler)
- [Location Plugin](https://pub.dev/packages/location)

### Development Tools
- **Flutter Inspector**: For debugging UI layout
- **Performance Profiler**: For optimizing app performance
- **Network Inspector**: For debugging API calls

### Testing
- Use Android emulator with location simulation
- iOS simulator with custom location
- Test on real devices for camera functionality
- Test with various permission states

## 🎯 Next Steps

1. **Production Setup**:
   - Set up proper API key management
   - Configure app signing and distribution
   - Set up CI/CD pipelines

2. **Advanced Features**:
   - Implement real ML processing
   - Add social features integration
   - Enhanced camera features (filters, effects)
   - Offline mode capabilities

3. **Testing**:
   - Unit tests for business logic
   - Integration tests for API calls
   - UI tests for user flows
   - Performance testing

This setup guide ensures you have a fully functional FitSync app with all features working correctly. The app is designed to gracefully handle missing API keys or backend connectivity with appropriate fallbacks and mock data.
