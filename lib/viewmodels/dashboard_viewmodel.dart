// lib/viewmodels/dashboard_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitsyncgemini/models/dashboard_model.dart';
import 'package:fitsyncgemini/services/firestore_service.dart';
import 'package:fitsyncgemini/services/ml_service.dart';

class DashboardViewModel extends StateNotifier<DashboardModel> {
  final FirestoreService _firestoreService;
  final MLService _mlService;

  DashboardViewModel(this._firestoreService, this._mlService)
      : super(const DashboardModel(
          greeting: '',
          userName: '',
          styleArchetype: '',
          closetItemCount: 0,
          quickActions: [],
          features: [],
          styleInsights: StyleInsights(
            styleArchetype: '',
            description: '',
            traits: [],
            insights: {},
          ),
          recentActivities: [],
          weatherInfo: WeatherInfo(
            temperature: 0,
            condition: '',
          ),
        )) {
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    state = state.copyWith(isLoading: true);
    
    try {
      await Future.wait([
        _loadUserData(),
        _loadClosetData(),
        _loadWeatherData(),
        _loadRecentActivities(),
        _loadStyleInsights(),
      ]);
      
      _updateGreeting();
      _initializeQuickActions();
      _initializeFeatures();
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> _loadUserData() async {
    try {
      // Mock user ID - replace with actual user ID from auth
      const userId = 'current_user_id';
      final userData = await _firestoreService.getUserProfile(userId);
      if (userData != null) {
        state = state.copyWith(
          userName: userData['firstName'] ?? 'User',
          styleArchetype: userData['styleArchetype'] ?? 'Minimalist',
        );
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadClosetData() async {
    try {
      // Mock user ID - replace with actual user ID from auth
      const userId = 'current_user_id';
      final closetStream = _firestoreService.getClosetItems(userId);
      final closetItems = await closetStream.first;
      state = state.copyWith(closetItemCount: closetItems.length);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadWeatherData() async {
    try {
      // Mock weather data - replace with actual weather service
      const weatherInfo = WeatherInfo(
        temperature: 24.0,
        condition: 'Sunny',
      );
      state = state.copyWith(weatherInfo: weatherInfo);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadRecentActivities() async {
    try {
      // Mock recent activities - replace with actual implementation
      final activities = [
        const RecentActivity(
          id: '1',
          action: 'Added',
          item: 'Blue Denim Jacket',
          time: '2h ago',
          type: ActivityType.add,
        ),
        const RecentActivity(
          id: '2',
          action: 'Liked',
          item: 'Summer Vibes outfit',
          time: '4h ago',
          type: ActivityType.like,
        ),
        const RecentActivity(
          id: '3',
          action: 'Shared',
          item: 'Casual Look',
          time: '1d ago',
          type: ActivityType.share,
        ),
      ];
      state = state.copyWith(recentActivities: activities);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadStyleInsights() async {
    try {
      // Mock style insights - replace with actual ML service implementation
      const insights = StyleInsights(
        styleArchetype: 'Minimalist',
        description: 'Clean lines, neutral colors, timeless pieces',
        traits: ['Neutral Colors', 'Clean Lines', 'Timeless'],
        insights: {
          'Most Worn': 'White Tees',
          'Favorite Color': 'Black',
        },
      );
      state = state.copyWith(styleInsights: insights);
    } catch (e) {
      // Handle error
    }
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    String greeting;
    
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }
    
    state = state.copyWith(greeting: greeting);
  }

  void _initializeQuickActions() {
    final quickActions = [
      const QuickAction(
        id: 'add_item',
        label: 'Add Item',
        icon: 'camera',
        color: 'pink',
      ),
      const QuickAction(
        id: 'get_outfit',
        label: 'Get Outfit',
        icon: 'sparkles',
        color: 'purple',
      ),
      const QuickAction(
        id: 'try_on',
        label: 'Try On',
        icon: 'play',
        color: 'teal',
      ),
      const QuickAction(
        id: 'trends',
        label: 'Trends',
        icon: 'trendingUp',
        color: 'blue',
      ),
    ];
    
    state = state.copyWith(quickActions: quickActions);
  }

  void _initializeFeatures() {
    final features = [
      const DashboardFeature(
        id: 'closet',
        title: 'My Closet',
        subtitle: 'Manage your wardrobe',
        icon: 'shoppingBag',
        gradientColors: ['pink', 'purple'],
      ),
      const DashboardFeature(
        id: 'outfit_ai',
        title: 'Outfit AI',
        subtitle: 'Get suggestions',
        icon: 'sparkles',
        gradientColors: ['purple', 'teal'],
      ),
      const DashboardFeature(
        id: 'trends',
        title: 'Trends',
        subtitle: 'What\'s hot now',
        icon: 'trendingUp',
        gradientColors: ['teal', 'blue'],
      ),
      const DashboardFeature(
        id: 'nearby',
        title: 'Nearby',
        subtitle: 'Local inspiration',
        icon: 'mapPin',
        gradientColors: ['blue', 'pink'],
      ),
    ];
    
    state = state.copyWith(features: features);
  }

  Future<void> refreshDashboard() async {
    await _initializeDashboard();
  }

  Future<void> generateNewOutfitSuggestion() async {
    try {
      state = state.copyWith(isLoading: true);
      
      // Mock outfit suggestion - replace with actual ML service implementation
      const suggestion = OutfitSuggestion(
        id: '1',
        name: 'Perfect for Today\'s Weather',
        occasion: 'Casual',
        itemIds: ['item1', 'item2', 'item3'],
        matchPercentage: 95.0,
        description: 'Based on weather forecast and your minimalist style preference',
        weatherInfo: WeatherInfo(
          temperature: 24.0,
          condition: 'Sunny',
        ),
      );
      
      state = state.copyWith(
        todaysSuggestion: suggestion,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final dashboardViewModelProvider = StateNotifierProvider<DashboardViewModel, DashboardModel>(
  (ref) => DashboardViewModel(
    ref.read(firestoreServiceProvider),
    ref.read(mlServiceProvider),
  ),
);

// Service providers (these should be defined in your services)
final firestoreServiceProvider = Provider((ref) => FirestoreService());
final mlServiceProvider = Provider((ref) => MLService()); 