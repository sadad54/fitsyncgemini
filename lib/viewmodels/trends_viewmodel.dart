// lib/viewmodels/trends_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitsyncgemini/models/trends_model.dart';
import 'package:fitsyncgemini/services/ml_service.dart';
import 'package:fitsyncgemini/services/backend_api.dart';

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
      final list = await BackendApi.getTrendsList();
      final trending =
          list
              .map((t) {
                final id = (t['id'] ?? '').toString();
                final title =
                    t['keyword']?.toString() ??
                    t['title']?.toString() ??
                    'Trend';
                final growthVal =
                    (t['growth_rate'] ?? t['growth'] ?? 0).toString();
                final growth =
                    growthVal.endsWith('%') ? growthVal : '+$growthVal%';
                final posts = (t['search_volume'] ?? 0) as int? ?? 0;
                return TrendingStyle(
                  id: id.isEmpty ? title : id,
                  title: title,
                  growth: growth,
                  trend: TrendDirection.up,
                  description: t['category']?.toString() ?? '',
                  image: '',
                  tags: List<String>.from(t['style_tags'] ?? const <String>[]),
                  engagement: posts,
                  posts: posts,
                );
              })
              .toList()
              .cast<TrendingStyle>();

      state = state.copyWith(trendingNow: trending);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadFashionInsights() async {
    try {
      final analysis = await BackendApi.getTrendAnalysis();
      final insights = <FashionInsight>[];
      final topCats =
          (analysis['top_categories'] as List<dynamic>? ?? [])
              .map((e) => e[0]?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .toList();
      if (topCats.isNotEmpty) {
        insights.add(
          FashionInsight(
            category: 'Top Categories',
            trending: topCats,
            declining: const <String>[],
          ),
        );
      }
      state = state.copyWith(fashionInsights: insights);
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
