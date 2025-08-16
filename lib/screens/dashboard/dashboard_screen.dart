// // lib/screens/dashboard/dashboard_screen.dart
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:lucide_icons/lucide_icons.dart';
// import 'package:fitsyncgemini/constants/app_colors.dart';
// import 'package:fitsyncgemini/constants/app_data.dart';
// import 'package:flutter_animate/flutter_animate.dart';

// class DashboardScreen extends StatelessWidget {
//   const DashboardScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Theme.of(context).colorScheme.background,
//         elevation: 1,
//         shadowColor: Colors.black.withOpacity(0.1),
//         title: Row(
//           children: [
//             Image.asset('assets/images/fitSyncLogo.png', width: 32, height: 32),
//             const SizedBox(width: 8),
//             Text(
//               'FitSync',
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 foreground:
//                     Paint()
//                       ..shader = AppColors.fitsyncGradient.createShader(
//                         const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0),
//                       ),
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(LucideIcons.smartphone, size: 20),
//             onPressed: () => context.go('/mockups'),
//           ),
//           IconButton(
//             icon: const Icon(LucideIcons.palette, size: 20),
//             onPressed: () => context.go('/assets'),
//           ),
//           const Padding(
//             padding: EdgeInsets.only(right: 16.0, left: 8.0),
//             child: CircleAvatar(
//               radius: 16,
//               child: Text(
//                 'JS',
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               backgroundColor: AppColors.pink,
//             ),
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//                 GridView.count(
//                   crossAxisCount: 2,
//                   shrinkWrap: true,
//                   physics: const NeverScrollableScrollPhysics(),
//                   crossAxisSpacing: 16,
//                   mainAxisSpacing: 16,
//                   childAspectRatio: 1.2,
//                   children: [
//                     _buildFeatureCard(
//                       context,
//                       icon: LucideIcons.shoppingBag,
//                       title: 'My Closet',
//                       subtitle: '${_closetItems.length} items',
//                       gradient: const LinearGradient(
//                         colors: [AppColors.pink, AppColors.purple],
//                       ),
//                       onTap: () => context.go('/closet'),
//                     ),
//                     _buildFeatureCard(
//                       context,
//                       icon: LucideIcons.sparkles,
//                       title: 'Outfit AI',
//                       subtitle: 'Get suggestions',
//                       gradient: const LinearGradient(
//                         colors: [AppColors.purple, AppColors.teal],
//                       ),
//                       onTap: () {},
//                     ),
//                     _buildFeatureCard(
//                       context,
//                       icon: LucideIcons.trendingUp,
//                       title: 'Trends',
//                       subtitle: 'What\'s hot now',
//                       gradient: const LinearGradient(
//                         colors: [AppColors.teal, AppColors.blue],
//                       ),
//                       onTap: () {},
//                     ),
//                     _buildFeatureCard(
//                       context,
//                       icon: LucideIcons.mapPin,
//                       title: 'Nearby',
//                       subtitle: 'Local inspiration',
//                       gradient: const LinearGradient(
//                         colors: [AppColors.blue, AppColors.pink],
//                       ),
//                       onTap: () {},
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 24),
//                 _buildSuggestionCard(context),
//                 const SizedBox(height: 16),
//                 _buildStyleDnaCard(context),
//               ]
//               .animate(interval: 100.ms)
//               .fadeIn(duration: 300.ms)
//               .slideY(begin: 0.2),
//         ),
//       ),
//     );
//   }

//   Widget _buildFeatureCard(
//     BuildContext context, {
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     required Gradient gradient,
//     required VoidCallback onTap,
//   }) {
//     return Card(
//       clipBehavior: Clip.antiAlias,
//       child: InkWell(
//         onTap: onTap,
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               width: 48,
//               height: 48,
//               decoration: BoxDecoration(
//                 gradient: gradient,
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(icon, color: Colors.white, size: 24),
//             ),
//             const SizedBox(height: 12),
//             Text(
//               title,
//               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               subtitle,
//               style: Theme.of(
//                 context,
//               ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSuggestionCard(BuildContext context) {
//     // Use first outfit from backend data if available, otherwise show empty state
//     final outfit = _outfits.isNotEmpty ? _outfits.first : null;
//     return Card(
//       color: AppColors.pink.withOpacity(0.05),
//       elevation: 0,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//         side: BorderSide.none,
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   width: 32,
//                   height: 32,
//                   decoration: const BoxDecoration(
//                     gradient: AppColors.fitsyncGradient,
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Icon(
//                     LucideIcons.zap,
//                     color: Colors.white,
//                     size: 16,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 const Text(
//                   'Today\'s Outfit Suggestion',
//                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             Row(
//               children: [
//                 SizedBox(
//                   width: 80,
//                   height: 48,
//                   child: Stack(
//                     children:
//                         outfit.itemIds.take(3).toList().asMap().entries.map((
//                           entry,
//                         ) {
//                           final index = entry.key;
//                           final item = entry.value;
//                           return Positioned(
//                             left: (index * 20).toDouble(),
//                             child: CircleAvatar(
//                               radius: 24,
//                               backgroundColor: Theme.of(context).cardColor,
//                               child: CircleAvatar(
//                                 radius: 22,
//                                 backgroundImage: NetworkImage(item),
//                               ),
//                             ),
//                           );
//                         }).toList(),
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         outfit.name,
//                         style: const TextStyle(fontWeight: FontWeight.w600),
//                       ),
//                       Text(
//                         'Perfect for ${outfit.occasion}',
//                         style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                           color: Colors.grey.shade600,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 ElevatedButton(
//                   onPressed: () {},
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     foregroundColor: Colors.white,
//                     backgroundColor: AppColors.pink,
//                   ),
//                   child: const Text('Try On'),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStyleDnaCard(BuildContext context) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Row(
//               children: [
//                 Icon(LucideIcons.star, color: AppColors.gold, size: 20),
//                 SizedBox(width: 8),
//                 Text(
//                   'Your Style DNA',
//                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             Row(
//               children: [
//                 Container(
//                   width: 64,
//                   height: 64,
//                   decoration: const BoxDecoration(
//                     gradient: AppColors.quizGradient,
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Center(
//                     child: Text('✨', style: TextStyle(fontSize: 28)),
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         'Minimalist',
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 18,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         'Clean lines, neutral colors, timeless pieces',
//                         style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                           color: Colors.grey.shade600,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Wrap(
//                         spacing: 8,
//                         children:
//                             ['Neutral Colors', 'Clean Lines', 'Timeless']
//                                 .map(
//                                   (trait) => Chip(
//                                     label: Text(trait),
//                                     padding: const EdgeInsets.symmetric(
//                                       horizontal: 4,
//                                     ),
//                                     labelStyle:
//                                         Theme.of(context).textTheme.bodySmall,
//                                     backgroundColor:
//                                         Theme.of(
//                                           context,
//                                         ).scaffoldBackgroundColor,
//                                   ),
//                                 )
//                                 .toList(),
//                       ),
//                     ],
//                   ),
//                 ),
//                 OutlinedButton(onPressed: () {}, child: const Text('Explore')),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:fitsyncgemini/widgets/closet/add_item_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fitsyncgemini/constants/app_colors.dart';
import 'package:fitsyncgemini/services/MLAPI_service.dart';
import 'package:fitsyncgemini/services/personalization_service.dart';
import 'package:fitsyncgemini/widgets/dashboard/stats_overview_widget.dart';
import 'package:fitsyncgemini/widgets/dashboard/quick_actions_widget.dart';
import 'package:fitsyncgemini/widgets/dashboard/recent_activity_widget.dart';
import 'package:fitsyncgemini/providers/providers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fitsyncgemini/widgets/common/fitsync_assets.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _greeting = '';

  // Backend data variables
  List<Map<String, dynamic>> _closetItems = [];
  List<Map<String, dynamic>> _outfits = [];
  // ignore: unused_field
  Map<String, dynamic> _wardrobeStats = {};
  bool _isLoadingCloset = false;
  bool _isLoadingOutfits = false;
  bool _isLoadingStats = false;

  // Personalization variables
  String _userArchetype = 'minimalist';
  // ignore: unused_field
  Map<String, dynamic> _styleRecommendations = {};
  // ignore: unused_field
  List<Map<String, dynamic>> _personalizedOutfits = [];
  bool _isLoadingPersonalization = false;

  @override
  void initState() {
    super.initState();
    _updateGreeting();
    _loadDashboardData();
    _loadPersonalizationData();
  }

  // Load dashboard data from backend
  Future<void> _loadDashboardData() async {
    await Future.wait([
      _loadClosetItems(),
      _loadOutfits(),
      _loadWardrobeStats(),
    ]);
  }

  // Load personalization data
  Future<void> _loadPersonalizationData() async {
    if (_isLoadingPersonalization) return;

    setState(() {
      _isLoadingPersonalization = true;
    });

    try {
      // Get user's style preferences from backend
      await PersonalizationService.getStylePreferences();

      // Get current archetype
      _userArchetype = PersonalizationService.getCurrentArchetype();

      // Get personalized recommendations
      _styleRecommendations = PersonalizationService.getStyleRecommendations();

      // Get personalized outfit suggestions
      _personalizedOutfits =
          PersonalizationService.getPersonalizedOutfitSuggestions();

      print('✅ Personalization data loaded for archetype: $_userArchetype');
    } catch (e) {
      print('❌ Failed to load personalization data: $e');
      // Use default values if backend fails
    } finally {
      setState(() {
        _isLoadingPersonalization = false;
      });
    }
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good morning';
    } else if (hour < 17) {
      _greeting = 'Good afternoon';
    } else {
      _greeting = 'Good evening';
    }
  }

  Future<void> _loadClosetItems() async {
    if (_isLoadingCloset) return;

    setState(() {
      _isLoadingCloset = true;
    });

    try {
      final items = await MLAPIService.getUserWardrobe(limit: 10);
      setState(() {
        _closetItems = items;
      });
    } catch (e) {
      print('❌ Failed to load closet items: $e');
      // Keep empty list if backend fails
    } finally {
      setState(() {
        _isLoadingCloset = false;
      });
    }
  }

  Future<void> _loadOutfits() async {
    if (_isLoadingOutfits) return;

    setState(() {
      _isLoadingOutfits = true;
    });

    try {
      // Note: Outfits endpoint might not be implemented yet
      // For now, we'll use an empty list
      setState(() {
        _outfits = [];
      });
    } catch (e) {
      print('❌ Failed to load outfits: $e');
    } finally {
      setState(() {
        _isLoadingOutfits = false;
      });
    }
  }

  Future<void> _loadWardrobeStats() async {
    if (_isLoadingStats) return;

    setState(() {
      _isLoadingStats = true;
    });

    try {
      final stats = await MLAPIService.getWardrobeStats();
      setState(() {
        _wardrobeStats = stats;
      });
    } catch (e) {
      print('❌ Failed to load wardrobe stats: $e');
      // Use default stats if backend fails
      setState(() {
        _wardrobeStats = {
          'total_items': 0,
          'total_value': 0,
          'recently_added': 0,
        };
      });
    } finally {
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // final authState = ref.watch(authViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        title: Row(
          children: [
            Image.asset('assets/images/fitSyncLogo.png', width: 32, height: 32),
            const SizedBox(width: 8),
            Text(
              'FitSync',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                foreground:
                    Paint()
                      ..shader = AppColors.fitsyncGradient.createShader(
                        const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0),
                      ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.search, size: 20),
            onPressed: () => _showSearchBottomSheet(),
          ),
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            onPressed: () => _loadDashboardData(),
            tooltip: 'Refresh Data',
          ),
          // Dev button for injecting dummy data
          IconButton(
            icon: const Icon(LucideIcons.database, size: 20),
            onPressed: () => _showDevOptions(),
            tooltip: 'Dev Options',
          ),
          IconButton(
            icon: const Icon(LucideIcons.bell, size: 20),
            onPressed: () => _showNotifications(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 8.0),
            child: GestureDetector(
              onTap: () => context.go('/profile'),
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.pink,
                child: Text(
                  'JS',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadDashboardData();
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreetingSection(),
                    const SizedBox(height: 24),
                    const QuickActionsWidget(),
                    const SizedBox(height: 24),
                    const StatsOverviewWidget(),
                    const SizedBox(height: 24),
                    _buildFeaturesGrid(),
                    const SizedBox(height: 24),
                    if (_isLoadingOutfits)
                      const Center(child: CircularProgressIndicator())
                    else
                      _buildTodaysSuggestion(),
                    const SizedBox(height: 24),
                    _buildStyleInsights(),
                    const SizedBox(height: 24),
                    const RecentActivityWidget(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildGreetingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$_greeting, John! ✨',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ).animate().fadeIn(duration: 600.ms),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.pink.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FitSyncFeatureIcon(type: 'ai', size: 14, container: 24),
              const SizedBox(width: 6),
              Text(
                '$_userArchetype Style • ${_closetItems.length} items in closet',
                style: const TextStyle(
                  color: AppColors.pink,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }

  Widget _buildFeaturesGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildFeatureCard(
          iconWidget: const FitSyncFeatureIcon(
            type: 'wardrobe',
            size: 22,
            container: 48,
          ),
          title: 'My Closet',
          subtitle: '${_closetItems.length} items',
          gradient: const LinearGradient(
            colors: [AppColors.pink, AppColors.purple],
          ),
          onTap: () => context.go('/closet'),
        ),
        _buildFeatureCard(
          iconWidget: const FitSyncFeatureIcon(
            type: 'ai',
            size: 22,
            container: 48,
          ),
          title: 'Outfit AI',
          subtitle: 'Get suggestions',
          gradient: const LinearGradient(
            colors: [AppColors.purple, AppColors.teal],
          ),
          onTap: () => context.go('/outfit-suggestions'),
        ),
        _buildFeatureCard(
          iconWidget: const FitSyncFeatureIcon(
            type: 'trends',
            size: 22,
            container: 48,
          ),
          title: 'Trends',
          subtitle: 'What\'s hot now',
          gradient: const LinearGradient(
            colors: [AppColors.teal, AppColors.blue],
          ),
          onTap: () => context.go('/trends'),
        ),
        _buildFeatureCard(
          iconWidget: const FitSyncFeatureIcon(
            type: 'virtual',
            size: 22,
            container: 48,
          ),
          title: 'Nearby',
          subtitle: 'Local inspiration',
          gradient: const LinearGradient(
            colors: [AppColors.blue, AppColors.pink],
          ),
          onTap: () => context.go('/nearby'),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildFeatureCard({
    IconData? icon,
    Widget? iconWidget,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: gradient,
                shape: BoxShape.circle,
              ),
              child: iconWidget ?? Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysSuggestion() {
    // Use first outfit from backend data if available, otherwise show empty state
    final outfit = _outfits.isNotEmpty ? _outfits.first : null;

    // If no outfit available, show empty state
    if (outfit == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today\'s Pick',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () => context.go('/outfit-suggestions'),
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: const Text('New'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            color: AppColors.pink.withOpacity(0.05),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide.none,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          gradient: AppColors.fitsyncGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.zap,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'No outfit suggestions yet',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Complete your wardrobe to get personalized outfit suggestions!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Today\'s Pick',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () => context.go('/outfit-suggestions'),
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('New'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          color: AppColors.pink.withOpacity(0.05),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide.none,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        gradient: AppColors.fitsyncGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.zap,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Perfect for today\'s weather',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.sun, size: 12, color: Colors.orange),
                          SizedBox(width: 4),
                          Text(
                            '24°C',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(
                      width: 100,
                      height: 48,
                      child: Stack(
                        children:
                            (outfit['item_ids'] as List<dynamic>?)
                                ?.take(3)
                                .toList()
                                .asMap()
                                .entries
                                .map((entry) {
                                  final index = entry.key;
                                  final item = entry.value;
                                  return Positioned(
                                    left: (index * 25).toDouble(),
                                    child: CircleAvatar(
                                      radius: 24,
                                      backgroundColor:
                                          Theme.of(context).cardColor,
                                      child: CircleAvatar(
                                        radius: 22,
                                        backgroundImage: NetworkImage(
                                          item.toString(),
                                        ),
                                      ),
                                    ),
                                  );
                                })
                                .toList() ??
                            [],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            outfit['name'] ?? 'Outfit',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Perfect for ${outfit['occasion'] ?? 'any occasion'}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: () => context.go('/try-on'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            foregroundColor: Colors.white,
                            backgroundColor: AppColors.pink,
                          ),
                          child: const Text('Try On'),
                        ),
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Save',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildStyleInsights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Style Insights',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        gradient: AppColors.quizGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('✨', style: TextStyle(fontSize: 24)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Style DNA',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Minimalist',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.gold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => context.go('/explore'),
                      child: const Text('Explore'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInsightCard(
                        icon: LucideIcons.trendingUp,
                        title: 'Most Worn',
                        value: 'White Tees',
                        color: AppColors.teal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInsightCard(
                        icon: LucideIcons.heart,
                        title: 'Favorite Color',
                        value: 'Black',
                        color: AppColors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 700.ms);
  }

  Widget _buildInsightCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => _showAddItemModal(),
      backgroundColor: AppColors.pink,
      child: const Icon(LucideIcons.plus, color: Colors.white),
    );
  }

  void _showSearchBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Search FitSync',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search outfits, items, styles...',
                    prefixIcon: const Icon(LucideIcons.search),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recent Searches',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ...[
                        'Black dress',
                        'Summer outfits',
                        'Minimalist style',
                      ].map(
                        (search) => ListTile(
                          leading: const Icon(LucideIcons.clock, size: 16),
                          title: Text(search),
                          trailing: const Icon(
                            LucideIcons.arrowUpLeft,
                            size: 16,
                          ),
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const ListTile(
                  leading: Icon(LucideIcons.sparkles, color: AppColors.pink),
                  title: Text('New outfit suggestion ready!'),
                  subtitle: Text('Based on today\'s weather'),
                  trailing: Text('5m ago'),
                ),
                const ListTile(
                  leading: Icon(LucideIcons.trendingUp, color: AppColors.teal),
                  title: Text('Trending: Oversized blazers'),
                  subtitle: Text('See what\'s popular in your area'),
                  trailing: Text('2h ago'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('View All Notifications'),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showAddItemModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddItemModal(),
    );
  }

  void _showDevOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Developer Options',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Inject dummy data for testing and showcasing the app',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _injectDummyData();
                    },
                    icon: const Icon(LucideIcons.database),
                    label: const Text('Inject Dummy Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.pink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _showDummyDataStats();
                    },
                    icon: const Icon(LucideIcons.barChart3),
                    label: const Text('View Data Stats'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _injectDummyData() async {
    try {
      final dummyDataService = ref.read(dummyDataServiceProvider);

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Injecting dummy data...'),
                ],
              ),
            ),
      );

      await dummyDataService.injectDummyData();

      // Close loading dialog
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Dummy data injected successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error injecting dummy data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showDummyDataStats() async {
    try {
      final dummyDataService = ref.read(dummyDataServiceProvider);
      final stats = dummyDataService.getDummyDataStats();

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Dummy Data Statistics'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    stats.entries
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              '${entry.key.replaceAll('_', ' ').toUpperCase()}: ${entry.value}',
                            ),
                          ),
                        )
                        .toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error getting stats: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
