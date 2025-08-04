// lib/screens/outfit_suggestions/outfit_suggestions_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitsyncgemini/constants/app_colors.dart';
import 'package:fitsyncgemini/constants/app_constants.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

class OutfitSuggestionsScreen extends ConsumerStatefulWidget {
  const OutfitSuggestionsScreen({super.key});

  @override
  ConsumerState<OutfitSuggestionsScreen> createState() =>
      _OutfitSuggestionsScreenState();
}

class _OutfitSuggestionsScreenState
    extends ConsumerState<OutfitSuggestionsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedOccasion = 'Casual';
  bool _isGenerating = false;

  // Use your real AppConstants.occasions
  final List<String> _occasions = AppConstants.occasions;

  final List<Map<String, dynamic>> _sampleOutfits = [
    {
      'id': '1',
      'name': 'Casual Weekend',
      'style': 'Minimalist',
      'occasion': 'Casual',
      'weather': 'Sunny, 24°C',
      'items': ['White T-Shirt', 'Blue Jeans', 'Sneakers'],
      'confidence': 92,
      'colors': [AppColors.pink, AppColors.teal],
    },
    {
      'id': '2',
      'name': 'Office Ready',
      'style': 'Professional',
      'occasion': 'Work',
      'weather': 'Cloudy, 20°C',
      'items': ['Blazer', 'Trousers', 'Dress Shoes'],
      'confidence': 88,
      'colors': [AppColors.purple, AppColors.teal],
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _generateOutfit() {
    setState(() {
      _isGenerating = true;
    });

    // Simulate AI generation
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('Outfit AI'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.bone),
            onPressed: _showFilterDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.pink,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.pink,
          tabs: const [Tab(text: 'Suggestions'), Tab(text: 'Favorites')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildSuggestionsView(), _buildFavoritesView()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isGenerating ? null : _generateOutfit,
        backgroundColor: AppColors.pink,
        icon:
            _isGenerating
                ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : Icon(LucideIcons.sparkles),
        label: Text(_isGenerating ? 'Generating...' : 'Generate Outfit'),
      ),
    );
  }

  Widget _buildSuggestionsView() {
    return Column(
      children: [
        // Weather and occasion header
        _buildHeaderSection(),
        // Occasion filter
        _buildOccasionFilter(),
        // AI generation status
        if (_isGenerating) _buildGeneratingCard(),
        // Outfit suggestions
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(AppConstants.paddingMedium),
            itemCount: _sampleOutfits.length,
            itemBuilder: (context, index) {
              return _buildOutfitCard(_sampleOutfits[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.sun, color: Colors.amber, size: 16),
                    SizedBox(width: 4),
                    Text('24°C', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.pink.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '✨ Minimalist Style',
                  style: TextStyle(
                    color: AppColors.pink,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.paddingMedium),
          const Text(
            'Perfect outfits for today',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            'AI-curated suggestions based on weather and your style',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildOccasionFilter() {
    return Container(
      height: 50,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
        itemCount: _occasions.length,
        itemBuilder: (context, index) {
          final occasion = _occasions[index];
          final isSelected = occasion == _selectedOccasion;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(occasion),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedOccasion = occasion;
                });
              },
              selectedColor: AppColors.pink.withOpacity(0.2),
              checkmarkColor: AppColors.pink,
            ),
          );
        },
      ),
    );
  }

  Widget _buildGeneratingCard() {
    return Container(
      margin: EdgeInsets.all(AppConstants.paddingMedium),
      padding: EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.pink.withOpacity(0.1),
            AppColors.teal.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(color: AppColors.pink),
          SizedBox(height: AppConstants.paddingMedium),
          const Text(
            'AI is creating your perfect outfit...',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          SizedBox(height: AppConstants.paddingSmall),
          Text(
            'Analyzing your style preferences and wardrobe',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildOutfitCard(Map<String, dynamic> outfit) {
    return Card(
      margin: EdgeInsets.only(bottom: AppConstants.paddingMedium),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Outfit preview
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: outfit['colors'] as List<Color>),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: const Center(
              child: Text('👕 👖 👟', style: TextStyle(fontSize: 48)),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            outfit['name'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.teal.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  outfit['style'],
                                  style: const TextStyle(
                                    color: AppColors.teal,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.purple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  outfit['occasion'],
                                  style: const TextStyle(
                                    color: AppColors.purple,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${outfit['confidence']}%',
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Match',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: AppConstants.paddingMedium),
                // Items
                const Text(
                  'Items:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                SizedBox(height: AppConstants.paddingSmall),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children:
                      (outfit['items'] as List<String>).map((item) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item,
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }).toList(),
                ),
                SizedBox(height: AppConstants.paddingMedium),
                // Weather info
                Row(
                  children: [
                    const Icon(LucideIcons.sun, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      outfit['weather'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppConstants.paddingMedium),
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(LucideIcons.heart, size: 16),
                        label: const Text(
                          'Save',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    SizedBox(width: AppConstants.paddingSmall),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.go('/try-on'),
                        icon: const Icon(LucideIcons.play, size: 16),
                        label: const Text(
                          'Try On',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.pink,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    SizedBox(width: AppConstants.paddingSmall),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(LucideIcons.share2, size: 16),
                        label: const Text(
                          'Share',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.heart, size: 64, color: Colors.grey),
          SizedBox(height: AppConstants.paddingMedium),
          const Text(
            'No favorites yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: AppConstants.paddingSmall),
          const Text(
            'Save outfits you love to see them here',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Filter Options'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Style Preference'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children:
                      AppConstants.styleArchetypes.map((style) {
                        return FilterChip(
                          label: Text(style),
                          selected: style == 'Minimalist',
                          onSelected: (selected) {
                            // TODO: Implement style filtering
                          },
                        );
                      }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Apply filters
                },
                child: const Text('Apply'),
              ),
            ],
          ),
    );
  }
}
