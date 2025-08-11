# FitSync Backend Integration Guide

## Overview

This document describes the complete integration of the FitSync Flutter frontend with the FastAPI backend. The integration includes authentication, clothing management, ML services, and virtual try-on functionality.

## 🚀 Quick Start

### Prerequisites

1. **Backend Setup**: Ensure the FitSync backend is running on `http://127.0.0.1:8000`
2. **Flutter Dependencies**: Make sure all Flutter packages are installed (`flutter pub get`)

### Testing the Integration

1. **Backend Status Check**: Go to Settings screen to see the backend connection status
2. **Authentication**: Try registering or logging in on the Auth screen
3. **Closet Management**: Upload clothing items and view your wardrobe
4. **Outfit Suggestions**: Get AI-powered outfit recommendations
5. **Virtual Try-On**: Upload photos and try on clothing virtually

## 📁 Files Modified

### Core Services

#### `lib/services/MLAPI_service.dart` - Main API Service
- **Complete rewrite** with full backend integration
- Authentication endpoints (`/auth/register`, `/auth/login`, `/auth/me`)
- Clothing management (`/clothing/upload`, `/clothing/items`, `/clothing/stats`)
- ML endpoints (`/ml/analyze/clothing`, `/ml/pose/estimate`, `/ml/virtual-tryon`)
- Outfit management (`/clothing/outfits`)
- Health checks (`/health`)

#### `lib/services/auth_service.dart` - Authentication Service
- Integrated with backend authentication
- Token management through MLAPI_service
- User session handling

### UI Screens

#### `lib/screens/auth/auth_screen.dart` - Authentication Screen
- **Added**: Real backend authentication calls
- **Added**: Loading states and error handling
- **Added**: Form validation
- **Added**: Success/error messaging

#### `lib/screens/closet/closet_screen.dart` - Closet Management
- **Added**: Backend wardrobe data loading
- **Added**: Real-time statistics from backend
- **Added**: Category filtering with backend queries
- **Added**: Error handling and fallback to sample data
- **Modified**: Item display to handle both backend and sample data

#### `lib/screens/outfit_suggestions/outfit_suggestions_screen.dart` - AI Recommendations
- **Added**: Backend recommendation loading
- **Added**: Context-aware recommendations (weather, time, category)
- **Added**: Loading states during AI processing
- **Added**: Error handling with fallback to sample data

#### `lib/screens/try_on/try_on_screen.dart` - Virtual Try-On
- **Added**: Real image capture and upload
- **Added**: Backend pose estimation
- **Added**: Virtual try-on processing
- **Added**: Real clothing item selection from user's wardrobe
- **Added**: Error handling and user feedback

#### `lib/screens/settings/settings_screen.dart` - Settings & Debug
- **Added**: Backend status widget for connection monitoring

### New Components

#### `lib/widgets/common/backend_status_widget.dart` - Backend Monitor
- Real-time backend connection status
- Health check integration
- Error message display
- Manual refresh capability

#### `lib/widgets/common/gradient_button.dart` - Enhanced Button
- **Modified**: Added support for nullable callbacks (for loading states)

## 🔌 API Integration Details

### Authentication Flow

```dart
// Registration
final result = await MLAPIService.registerUser(
  email: email,
  password: password,
  username: username,
  firstName: firstName,
  lastName: lastName,
);

// Login
await MLAPIService.loginUser(email: email, password: password);

// Get current user
final user = await MLAPIService.getCurrentUser();
```

### Clothing Management

```dart
// Upload clothing item
final result = await MLAPIService.uploadClothingItem(
  imageFile: imageFile,
  name: name,
  category: category,
  subcategory: subcategory,
  color: color,
  // ... other optional fields
);

// Get user's wardrobe
final items = await MLAPIService.getUserWardrobe(
  category: category,
  limit: 20,
);

// Get wardrobe statistics
final stats = await MLAPIService.getWardrobeStats();
```

### ML Services

```dart
// Analyze clothing image
final analysis = await MLAPIService.analyzeClothingImage(imageFile);

// Estimate body pose
final pose = await MLAPIService.estimateBodyPose(imageFile);

// Generate virtual try-on
final result = await MLAPIService.generateVirtualTryOn(
  personImage, 
  clothingImage
);

// Get AI recommendations
final recommendations = await MLAPIService.getRecommendations(
  context: {
    'category': 'casual',
    'weather': 'sunny',
    'temperature': 24,
  }
);
```

### Outfit Management

```dart
// Create outfit
final outfit = await MLAPIService.createOutfit(
  name: name,
  description: description,
  itemIds: [1, 2, 3],
  season: 'summer',
);

// Get user outfits
final outfits = await MLAPIService.getUserOutfits(
  season: 'summer',
  limit: 10,
);
```

## 🎯 Key Features

### 1. **Robust Error Handling**
- Network error detection
- Fallback to sample data when backend is unavailable
- User-friendly error messages
- Loading states throughout the app

### 2. **Authentication Integration**
- Seamless login/registration
- Token management
- Session persistence
- User profile access

### 3. **Real-time Data Sync**
- Live wardrobe statistics
- Dynamic category counts
- Fresh recommendations
- Automatic data refresh

### 4. **ML Service Integration**
- Clothing image analysis
- Body pose estimation
- Virtual try-on generation
- Context-aware recommendations

### 5. **Consistent UI/UX**
- Loading indicators
- Error states
- Success feedback
- Maintained FitSync theme [[memory:5702570]]

## 🔧 Configuration

### Backend URL Configuration
The backend URL is configured in `lib/services/MLAPI_service.dart`:

```dart
static const String baseUrl = 'http://127.0.0.1:8000/api/v1';
```

To change the backend URL (for production, staging, etc.), modify this constant.

### Request Timeout
Default timeout is set in the HTTP requests. You can modify timeouts by adding timeout parameters to individual requests.

## 🐛 Troubleshooting

### Common Issues

1. **Backend Connection Failed**
   - Check if backend server is running on localhost:8000
   - Verify network connectivity
   - Check the Backend Status Widget in Settings

2. **Authentication Errors**
   - Ensure valid email format
   - Check password requirements
   - Verify backend auth endpoints are working

3. **Image Upload Issues**
   - Check file size limits
   - Verify image format support
   - Ensure proper permissions for camera/gallery access

4. **ML Service Errors**
   - Verify ML models are loaded in backend
   - Check image quality and format
   - Ensure sufficient processing resources

### Debug Tools

- **Backend Status Widget**: Real-time connection monitoring
- **Error Messages**: Detailed error information in snackbars
- **Console Logs**: Debug information in Flutter console

## 🚀 Next Steps

### Recommended Enhancements

1. **Offline Support**
   - Implement local caching
   - Queue requests for when connection returns
   - Offline-first architecture

2. **Performance Optimization**
   - Image compression before upload
   - Lazy loading for large wardrobes
   - Request caching

3. **Advanced Features**
   - Push notifications
   - Social sharing
   - Advanced filtering
   - Batch operations

4. **Security**
   - Token refresh mechanism
   - Secure storage for credentials
   - API rate limiting

## 📞 Support

For issues with the backend integration:

1. Check the Backend Status Widget first
2. Review error messages in the app
3. Check Flutter console for detailed logs
4. Verify backend server status and logs

## 🔄 Version Compatibility

- **Flutter SDK**: ^3.0.0
- **Backend API**: v1.0.0
- **HTTP Package**: ^1.1.0
- **Image Picker**: ^1.0.0

---

**Integration completed successfully!** ✅

The FitSync Flutter app now has full backend connectivity with robust error handling, loading states, and seamless data synchronization. All major screens have been integrated with their respective backend endpoints while maintaining the consistent FitSync UI theme.
