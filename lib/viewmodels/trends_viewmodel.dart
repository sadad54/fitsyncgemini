// lib/viewmodels/trends_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitsyncgemini/models/trends_model.dart';
import 'package:fitsyncgemini/services/ml_service.dart';

class TrendsViewModel extends StateNotifier<TrendsModel> {
  final MLService _mlService;

  TrendsViewModel(this._mlService) : super(const TrendsModel()) {
    _initializeTrends();
  }

  Future<void> _initializeTrends() async {
    state = state.copyWith(isLoading: true);

    try {
      await Future.wait([
        _loadTrendingNow(),
        _loadFashionInsights(),
        _loadInfluencerSpotlight(),
      ]);

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _loadTrendingNow() async {
    try {
      // Mock trending styles - replace with actual ML service implementation
      final trendingNow = [
        const TrendingStyle(
          id: '1',
          title: 'Y2K Revival',
          growth: '+23%',
          trend: TrendDirection.up,
          description:
              'Low-rise jeans, metallic fabrics, and butterfly accessories making a comeback',
          image: 'https://picsum.photos/400/400?random=1',
          tags: ['retro', 'metallic', 'bold'],
          engagement: 15420,
          posts: 342,
        ),
        const TrendingStyle(
          id: '2',
          title: 'Dark Academia',
          growth: '+18%',
          trend: TrendDirection.up,
          description:
              'Tweed blazers, plaid skirts, and vintage-inspired pieces for intellectual elegance',
          image: 'https://picsum.photos/400/400?random=2',
          tags: ['vintage', 'academic', 'sophisticated'],
          engagement: 12890,
          posts: 267,
        ),
        const TrendingStyle(
          id: '3',
          title: 'Oversized Blazers',
          growth: '+12%',
          trend: TrendDirection.up,
          description:
              'Power dressing with relaxed silhouettes for modern professional wear',
          image: 'https://picsum.photos/400/400?random=3',
          tags: ['professional', 'oversized', 'power'],
          engagement: 9876,
          posts: 189,
        ),
        const TrendingStyle(
          id: '4',
          title: 'Neon Colors',
          growth: '-8%',
          trend: TrendDirection.down,
          description:
              'Bright fluorescent colors losing momentum as neutrals take center stage',
          image: 'https://picsum.photos/400/400?random=4',
          tags: ['bright', 'bold', 'statement'],
          engagement: 5432,
          posts: 98,
        ),
      ];

      state = state.copyWith(trendingNow: trendingNow);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadFashionInsights() async {
    try {
      // Mock fashion insights - replace with actual implementation
      final fashionInsights = [
        const FashionInsight(
          category: 'Colors',
          trending: ['Sage Green', 'Warm Beige', 'Soft Lavender'],
          declining: ['Hot Pink', 'Electric Blue'],
        ),
        const FashionInsight(
          category: 'Silhouettes',
          trending: ['Oversized', 'High-waisted', 'Cropped'],
          declining: ['Bodycon', 'Low-rise'],
        ),
        const FashionInsight(
          category: 'Fabrics',
          trending: ['Corduroy', 'Velvet', 'Organic Cotton'],
          declining: ['Polyester Blends', 'Shiny Materials'],
        ),
      ];

      state = state.copyWith(fashionInsights: fashionInsights);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadInfluencerSpotlight() async {
    try {
      // Mock influencer spotlight - replace with actual implementation
      final influencerSpotlight = [
        const InfluencerSpotlight(
          id: '1',
          name: 'Emma Chamberlain',
          handle: '@emmachamberlain',
          trendSetter: 'Vintage Mix',
          followers: '12.2M',
          engagement: '8.4%',
          recentTrend: 'Thrifted Designer Mix',
        ),
        const InfluencerSpotlight(
          id: '2',
          name: 'Wisdom Kaye',
          handle: '@wisdomkaye',
          trendSetter: 'Gender-Fluid Fashion',
          followers: '2.1M',
          engagement: '12.1%',
          recentTrend: 'Colorful Maximalism',
        ),
      ];

      state = state.copyWith(influencerSpotlight: influencerSpotlight);
    } catch (e) {
      // Handle error
    }
  }

  void setSelectedScope(String scope) {
    state = state.copyWith(selectedScope: scope);
  }

  void setSelectedTimeframe(String timeframe) {
    state = state.copyWith(selectedTimeframe: timeframe);
  }

  Future<void> refreshTrends() async {
    await _initializeTrends();
  }

  Future<void> loadTrendsForCategory(String category) async {
    try {
      state = state.copyWith(isLoading: true);

      // Mock category-specific trends - replace with actual implementation
      await Future.delayed(const Duration(seconds: 1));

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final trendsViewModelProvider =
    StateNotifierProvider<TrendsViewModel, TrendsModel>(
      (ref) => TrendsViewModel(ref.read(mlServiceProvider)),
    );
