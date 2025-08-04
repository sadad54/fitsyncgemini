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
//                       subtitle: '${sampleCloset.length} items',
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
//     final outfit = sampleOutfits.first;
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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fitsyncgemini/constants/app_colors.dart';
import 'package:fitsyncgemini/constants/app_data.dart';
import 'package:fitsyncgemini/viewmodels/auth_viewmodel.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _greeting = '';

  @override
  void initState() {
    super.initState();
    _updateGreeting();
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good Morning';
    } else if (hour < 17) {
      _greeting = 'Good Afternoon';
    } else {
      _greeting = 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

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
          // TODO: Implement refresh logic
          await Future.delayed(const Duration(seconds: 1));
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
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _buildFeaturesGrid(),
                    const SizedBox(height: 24),
                    _buildTodaysSuggestion(),
                    const SizedBox(height: 24),
                    _buildStyleInsights(),
                    const SizedBox(height: 24),
                    _buildRecentActivity(),
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
              const Icon(LucideIcons.sparkles, size: 16, color: AppColors.pink),
              const SizedBox(width: 6),
              Text(
                'Minimalist Style • ${sampleCloset.length} items in closet',
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

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildQuickActionChip(
                icon: LucideIcons.camera,
                label: 'Add Item',
                color: AppColors.pink,
                onTap: () => _showAddItemModal(),
              ),
              const SizedBox(width: 8),
              _buildQuickActionChip(
                icon: LucideIcons.sparkles,
                label: 'Get Outfit',
                color: AppColors.purple,
                onTap: () => context.go('/outfit-suggestions'),
              ),
              const SizedBox(width: 8),
              _buildQuickActionChip(
                icon: LucideIcons.play,
                label: 'Try On',
                color: AppColors.teal,
                onTap: () => context.go('/try-on'),
              ),
              const SizedBox(width: 8),
              _buildQuickActionChip(
                icon: LucideIcons.trendingUp,
                label: 'Trends',
                color: AppColors.blue,
                onTap: () => context.go('/trends'),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildQuickActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
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
          icon: LucideIcons.shoppingBag,
          title: 'My Closet',
          subtitle: '${sampleCloset.length} items',
          gradient: const LinearGradient(
            colors: [AppColors.pink, AppColors.purple],
          ),
          onTap: () => context.go('/closet'),
        ),
        _buildFeatureCard(
          icon: LucideIcons.sparkles,
          title: 'Outfit AI',
          subtitle: 'Get suggestions',
          gradient: const LinearGradient(
            colors: [AppColors.purple, AppColors.teal],
          ),
          onTap: () => context.go('/outfit-suggestions'),
        ),
        _buildFeatureCard(
          icon: LucideIcons.trendingUp,
          title: 'Trends',
          subtitle: 'What\'s hot now',
          gradient: const LinearGradient(
            colors: [AppColors.teal, AppColors.blue],
          ),
          onTap: () => context.go('/trends'),
        ),
        _buildFeatureCard(
          icon: LucideIcons.mapPin,
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
    required IconData icon,
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
              child: Icon(icon, color: Colors.white, size: 24),
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
    final outfit = sampleOutfits.first;
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
                            outfit.itemIds.take(3).toList().asMap().entries.map(
                              (entry) {
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
                                      backgroundImage: NetworkImage(item),
                                    ),
                                  ),
                                );
                              },
                            ).toList(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            outfit.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Perfect for ${outfit.occasion}',
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
                    const SizedBox(width: 12),
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

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(onPressed: () {}, child: const Text('View All')),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(3, (index) {
          final activities = [
            {
              'icon': LucideIcons.plus,
              'text': 'Added Blue Denim Jacket',
              'time': '2h ago',
              'color': Colors.green, // Green for "Added"
            },
            {
              'icon': LucideIcons.heart,
              'text': 'Liked Summer Vibes outfit',
              'time': '4h ago',
              'color': AppColors.pink, // Pink for "Liked"
            },
            {
              'icon': LucideIcons.share2,
              'text': 'Shared Casual Look',
              'time': '1d ago',
              'color': AppColors.blue, // Blue for "Shared"
            },
          ];
          final activity = activities[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: (activity['color'] as Color).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    activity['icon'] as IconData,
                    size: 16,
                    color: activity['color'] as Color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    activity['text'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Text(
                  activity['time'] as String,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          );
        }),
      ],
    ).animate().fadeIn(delay: 800.ms);
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Add to Closet',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // TODO: Implement camera functionality
                        },
                        icon: const Icon(LucideIcons.camera),
                        label: const Text('Take Photo'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // TODO: Implement gallery functionality
                        },
                        icon: const Icon(LucideIcons.upload),
                        label: const Text('Upload'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.pink,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(LucideIcons.sparkles, color: AppColors.teal),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'AI will automatically detect and categorize your item!',
                          style: TextStyle(fontWeight: FontWeight.w600),
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
}
