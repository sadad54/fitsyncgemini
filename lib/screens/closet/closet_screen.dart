// lib/screens/closet/closet_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitsyncgemini/constants/app_colors.dart';
import 'package:fitsyncgemini/models/clothing_item.dart';
import 'package:fitsyncgemini/widgets/closet/add_item_modal.dart';
import 'package:fitsyncgemini/widgets/closet/closet_filter_widget.dart';
import 'package:fitsyncgemini/services/MLAPI_service.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fitsyncgemini/widgets/common/fitsync_assets.dart';

class ClosetScreen extends ConsumerStatefulWidget {
  const ClosetScreen({super.key});

  @override
  ConsumerState<ClosetScreen> createState() => _ClosetScreenState();
}

class _ClosetScreenState extends ConsumerState<ClosetScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'all';
  bool _isGridView = true;
  List<String> _selectedItems = [];
  ClosetFilter _currentFilter = const ClosetFilter();

  // Pagination variables
  int _itemsPerPage = 12;
  bool _showAllItems = false;

  // Backend integration variables
  List<Map<String, dynamic>> _backendItems = [];
  bool _isLoadingItems = false;
  bool _isLoadingStats = false;

  final List<Map<String, dynamic>> _categories = [
    {'id': 'all', 'name': 'All', 'count': 0, 'icon': LucideIcons.grid},
    {'id': 'tops', 'name': 'Tops', 'count': 0, 'icon': LucideIcons.shirt},
    {
      'id': 'bottoms',
      'name': 'Bottoms',
      'count': 0,
      'icon': LucideIcons.briefcase,
    },
    {'id': 'dresses', 'name': 'Dresses', 'count': 0, 'icon': LucideIcons.user},
    {
      'id': 'outerwear',
      'name': 'Outerwear',
      'count': 0,
      'icon': LucideIcons.zap,
    },
    {
      'id': 'shoes',
      'name': 'Shoes',
      'count': 0,
      'icon': LucideIcons.footprints,
    },
  ];

  Map<String, dynamic> _closetStats = {
    'totalItems': 0,
    'recentlyAdded': 0,
    'mostWorn': 'N/A',
    'leastWorn': 'N/A',
    'totalValue': 0,
  };

  final List<Map<String, dynamic>> _recentActivity = [
    {
      'action': 'Added',
      'item': 'Blue Denim Jacket',
      'time': '2h ago',
      'type': 'add',
    },
    {
      'action': 'Wore',
      'item': 'White Button Shirt',
      'time': '1d ago',
      'type': 'wear',
    },
    {
      'action': 'Liked',
      'item': 'Black Blazer',
      'time': '2d ago',
      'type': 'like',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadWardrobeData();
    _loadWardrobeStats();
  }

  // Load wardrobe data from backend
  Future<void> _loadWardrobeData() async {
    if (_isLoadingItems) return;

    setState(() {
      _isLoadingItems = true;
    });

    try {
      final items = await MLAPIService.getUserWardrobe(
        category: _selectedCategory == 'all' ? null : _selectedCategory,
        limit: 100, // Load all items for now
      );

      setState(() {
        _backendItems = items;
        _updateCategoryCounts();
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load wardrobe: ${e.toString()}');
      // Fallback to sample data if backend fails
      setState(() {
        _updateCategoryCounts();
      });
    } finally {
      setState(() {
        _isLoadingItems = false;
      });
    }
  }

  // Load wardrobe statistics from backend
  Future<void> _loadWardrobeStats() async {
    if (_isLoadingStats) return;

    setState(() {
      _isLoadingStats = true;
    });

    try {
      final stats = await MLAPIService.getWardrobeStats();
      setState(() {
        _closetStats = {
          'totalItems': stats['total_items'] ?? 0,
          'recentlyAdded': stats['recent_count'] ?? 0,
          'mostWorn': stats['most_worn_item'] ?? 'N/A',
          'leastWorn': stats['least_worn_item'] ?? 'N/A',
          'totalValue': stats['total_value'] ?? 0,
        };
      });
    } catch (e) {
      // Keep default stats if backend fails
      print('Failed to load stats: $e');
    } finally {
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  void _updateCategoryCounts() {
    // Update category counts based on backend data only
    final itemsToCount = _backendItems;

    _categories[0]['count'] = itemsToCount.length;
    _categories[1]['count'] =
        itemsToCount
            .where(
              (item) =>
                  item['category']?.toLowerCase() == 'tops' ||
                  item['category']?.toLowerCase() == 'top',
            )
            .length;
    _categories[2]['count'] =
        itemsToCount
            .where(
              (item) =>
                  item['category']?.toLowerCase() == 'bottoms' ||
                  item['category']?.toLowerCase() == 'bottom',
            )
            .length;
    _categories[3]['count'] =
        itemsToCount
            .where(
              (item) =>
                  item['category']?.toLowerCase() == 'dresses' ||
                  item['category']?.toLowerCase() == 'dress',
            )
            .length;
    _categories[4]['count'] =
        itemsToCount
            .where(
              (item) =>
                  item['category']?.toLowerCase() == 'outerwear' ||
                  item['category']?.toLowerCase() == 'jacket',
            )
            .length;
    _categories[5]['count'] =
        itemsToCount
            .where(
              (item) =>
                  item['category']?.toLowerCase() == 'shoes' ||
                  item['category']?.toLowerCase() == 'shoe',
            )
            .length;
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<dynamic> get _filteredItems {
    // Only use backend items - no fallback to hardcoded data
    return _backendItems.where((item) {
      final matchesSearch = (item['name'] ?? '').toLowerCase().contains(
        _searchController.text.toLowerCase(),
      );
      final itemCategory = (item['category'] ?? '').toLowerCase();
      final matchesCategory =
          _selectedCategory == 'all' ||
          itemCategory == _selectedCategory.toLowerCase() ||
          itemCategory.contains(_selectedCategory.toLowerCase());
      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<dynamic> get _displayedItems {
    if (_showAllItems) {
      return _filteredItems;
    }
    return _filteredItems.take(_itemsPerPage).toList();
  }

  bool get _hasMoreItems =>
      _filteredItems.length > _itemsPerPage && !_showAllItems;

  void _toggleItemSelection(String itemId) {
    setState(() {
      if (_selectedItems.contains(itemId)) {
        _selectedItems.remove(itemId);
      } else {
        _selectedItems.add(itemId);
      }
    });
  }

  void _toggleShowAllItems() {
    setState(() {
      _showAllItems = !_showAllItems;
    });
  }

  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'white':
        return Colors.white;
      case 'black':
        return Colors.black;
      case 'blue':
        return Colors.blue;
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'pink':
        return Colors.pink;
      case 'beige':
        return const Color(0xFFF5F5DC);
      case 'brown':
        return Colors.brown;
      case 'gray':
        return Colors.grey;
      case 'grey':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.background,
      body: CustomScrollView(
        slivers: [
          // Stunning App Bar with Wardrobe branding
          SliverAppBar(
            expandedHeight: 140,
            floating: true,
            pinned: true,
            backgroundColor: scheme.surface,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(LucideIcons.arrowLeft, color: scheme.onSurface),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/dashboard');
                }
              },
            ),
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    LucideIcons.shirt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Wardrobe',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    Text(
                      '${_closetStats['totalItems']} items',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isGridView ? LucideIcons.list : LucideIcons.grid,
                  color: scheme.onSurface,
                ),
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
              ),
              IconButton(
                icon: Icon(LucideIcons.filter, color: scheme.onSurface),
                onPressed: () => _showFilterModal(),
              ),
              Container(
                margin: const EdgeInsets.only(right: 16),
                child: ElevatedButton.icon(
                  onPressed: () => _showAddItemModal(),
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('Add Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [scheme.surface, scheme.surface.withOpacity(0.8)],
                  ),
                ),
              ),
            ),
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: scheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search your wardrobe...',
                  prefixIcon: Icon(
                    LucideIcons.search,
                    color: scheme.onSurface.withOpacity(0.5),
                    size: 20,
                  ),
                  filled: true,
                  fillColor: scheme.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
          ),

          // Closet Overview Stats
          SliverToBoxAdapter(
            child: _buildClosetOverview().animate().fadeIn(
              duration: 300.ms,
              delay: 100.ms,
            ),
          ),

          // Categories
          SliverToBoxAdapter(
            child: _buildCategories().animate().fadeIn(
              duration: 300.ms,
              delay: 200.ms,
            ),
          ),

          // Selected Items Action Bar
          if (_selectedItems.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildSelectedItemsBar().animate().fadeIn(
                duration: 300.ms,
                delay: 300.ms,
              ),
            ),

          // Items Grid/List
          _isGridView ? _buildItemsGrid() : _buildItemsList(),

          // View More Button
          if (_hasMoreItems)
            SliverToBoxAdapter(
              child: _buildViewMoreButton().animate().fadeIn(
                duration: 300.ms,
                delay: 600.ms,
              ),
            ),

          // Recent Activity & Add Item CTA
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  _buildRecentActivity().animate().fadeIn(
                    duration: 300.ms,
                    delay: 400.ms,
                  ),
                  const SizedBox(height: 24),
                  _buildAddItemCTA().animate().fadeIn(
                    duration: 300.ms,
                    delay: 500.ms,
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClosetOverview() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Left Column: Quick Stats
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          LucideIcons.barChart3,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Quick Stats',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildStatRow(
                    'Recently added:',
                    '${_closetStats['recentlyAdded']}',
                    LucideIcons.plus,
                  ),
                  const SizedBox(height: 8),
                  _buildStatRow(
                    'Total value:',
                    '\$${_closetStats['totalValue']}',
                    LucideIcons.dollarSign,
                  ),
                ],
              ),
            ),
            // Right Column: Insights
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          LucideIcons.lightbulb,
                          color: AppColors.secondary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Insights',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Most worn:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    _closetStats['mostWorn'],
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
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

  Widget _buildStatRow(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 16, color: scheme.onSurface.withOpacity(0.5)),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withOpacity(0.7),
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategories() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category['id'];

          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category['id'];
                  _showAllItems =
                      false; // Reset pagination when category changes
                });
                _loadWardrobeData();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 80,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : scheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        isSelected
                            ? AppColors.primary
                            : scheme.outline.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                          : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      category['icon'],
                      size: 24,
                      color: isSelected ? Colors.white : scheme.onSurface,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category['name'],
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : scheme.onSurface,
                      ),
                    ),
                    Text(
                      '${category['count']}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            isSelected
                                ? Colors.white.withOpacity(0.8)
                                : scheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedItemsBar() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_selectedItems.length} items selected',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Creating outfit...'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  icon: const Icon(
                    LucideIcons.shirt,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  label: const Text(
                    'Create Outfit',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Sharing items...'),
                        backgroundColor: AppColors.secondary,
                      ),
                    );
                  },
                  icon: const Icon(
                    LucideIcons.share2,
                    size: 18,
                    color: AppColors.secondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Opening virtual try-on...'),
                        backgroundColor: AppColors.tertiary,
                      ),
                    );
                  },
                  icon: const Icon(
                    LucideIcons.camera,
                    size: 18,
                    color: AppColors.tertiary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsGrid() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = _displayedItems[index];
          final itemId =
              _backendItems.isNotEmpty
                  ? item['id'].toString()
                  : (item as ClothingItem).id;
          final itemName =
              _backendItems.isNotEmpty
                  ? item['name'] ?? 'Unknown Item'
                  : (item as ClothingItem).name;
          final itemCategory =
              _backendItems.isNotEmpty
                  ? item['category'] ?? 'Unknown'
                  : (item as ClothingItem).category;
          final itemColors =
              _backendItems.isNotEmpty
                  ? [item['color'] ?? 'grey']
                  : (item as ClothingItem).colors;
          final isSelected = _selectedItems.contains(itemId);

          return GestureDetector(
            onTap: () => _toggleItemSelection(itemId),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(20),
                border:
                    isSelected
                        ? Border.all(color: AppColors.primary, width: 2)
                        : Border.all(
                          color: scheme.outline.withOpacity(0.2),
                          width: 1,
                        ),
                boxShadow: [
                  BoxShadow(
                    color:
                        isSelected
                            ? AppColors.primary.withOpacity(0.2)
                            : Colors.black.withOpacity(0.05),
                    blurRadius: isSelected ? 12 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: scheme.surfaceVariant,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: scheme.surfaceVariant,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            child: Icon(
                              LucideIcons.image,
                              color: scheme.onSurface.withOpacity(0.3),
                              size: 40,
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            itemCategory,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ...itemColors.take(3).map((color) {
                              return Container(
                                width: 16,
                                height: 16,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: _getColorFromString(color),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: scheme.outline.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }, childCount: _displayedItems.length),
      ),
    );
  }

  Widget _buildItemsList() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = _displayedItems[index];
          final itemId =
              _backendItems.isNotEmpty
                  ? item['id'].toString()
                  : (item as ClothingItem).id;
          final itemName =
              _backendItems.isNotEmpty
                  ? item['name'] ?? 'Unknown Item'
                  : (item as ClothingItem).name;
          final itemCategory =
              _backendItems.isNotEmpty
                  ? item['category'] ?? 'Unknown'
                  : (item as ClothingItem).category;
          final itemColors =
              _backendItems.isNotEmpty
                  ? [item['color'] ?? 'grey']
                  : (item as ClothingItem).colors;
          final isSelected = _selectedItems.contains(itemId);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => _toggleItemSelection(itemId),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border:
                      isSelected
                          ? Border.all(color: AppColors.primary, width: 2)
                          : Border.all(
                            color: scheme.outline.withOpacity(0.2),
                            width: 1,
                          ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          isSelected
                              ? AppColors.primary.withOpacity(0.2)
                              : Colors.black.withOpacity(0.05),
                      blurRadius: isSelected ? 12 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Image
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: scheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        LucideIcons.image,
                        color: scheme.onSurface.withOpacity(0.3),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            itemName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              itemCategory,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurface.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              ...itemColors.take(3).map((color) {
                                return Container(
                                  width: 16,
                                  height: 16,
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: _getColorFromString(color),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: scheme.outline.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Actions
                    Row(
                      children: [
                        if (isSelected)
                          Container(
                            width: 24,
                            height: 24,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        IconButton(
                          onPressed: () {},
                          icon: Icon(
                            LucideIcons.moreHorizontal,
                            size: 20,
                            color: scheme.onSurface,
                          ),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }, childCount: _displayedItems.length),
      ),
    );
  }

  Widget _buildRecentActivity() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.tertiary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LucideIcons.activity,
                  color: AppColors.tertiary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Recent Activity',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            children:
                _recentActivity.map((activity) {
                  Color iconColor;
                  Color bgColor;
                  IconData icon;

                  switch (activity['type']) {
                    case 'add':
                      iconColor = AppColors.success;
                      bgColor = AppColors.success.withOpacity(0.1);
                      icon = LucideIcons.plus;
                      break;
                    case 'wear':
                      iconColor = AppColors.primary;
                      bgColor = AppColors.primary.withOpacity(0.1);
                      icon = LucideIcons.trendingUp;
                      break;
                    case 'like':
                      iconColor = AppColors.secondary;
                      bgColor = AppColors.secondary.withOpacity(0.1);
                      icon = LucideIcons.heart;
                      break;
                    default:
                      iconColor = scheme.onSurface.withOpacity(0.5);
                      bgColor = scheme.surfaceVariant;
                      icon = LucideIcons.activity;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, size: 18, color: iconColor),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurface,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: activity['action'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    TextSpan(text: ' ${activity['item']}'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                activity['time'],
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  void _showAddItemModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddItemModal(),
    ).then((result) {
      if (result == true) {
        // Refresh closet data from backend
        _loadWardrobeData();
        _loadWardrobeStats();
      }
    });
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => ClosetFilterWidget(
            currentFilter: _currentFilter,
            onFilterChanged: (filter) {
              setState(() {
                _currentFilter = filter;
              });
            },
          ),
    );
  }

  Widget _buildViewMoreButton() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: _toggleShowAllItems,
        icon: Icon(
          _showAllItems ? LucideIcons.chevronUp : LucideIcons.chevronDown,
          size: 20,
        ),
        label: Text(
          _showAllItems
              ? 'Show Less'
              : 'View More (${_filteredItems.length - _itemsPerPage} more items)',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          side: BorderSide(color: scheme.outline.withOpacity(0.2), width: 1),
        ),
      ),
    );
  }

  Widget _buildAddItemCTA() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              LucideIcons.camera,
              size: 36,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Add New Items',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Take photos of your clothes to grow your digital wardrobe',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _showAddItemModal(),
              icon: const Icon(LucideIcons.camera, size: 20),
              label: const Text(
                'Take Photo',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
