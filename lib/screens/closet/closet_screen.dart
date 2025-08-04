// lib/screens/closet/closet_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitsyncgemini/constants/app_colors.dart';
import 'package:fitsyncgemini/constants/app_constants.dart';
import 'package:fitsyncgemini/constants/app_data.dart';
import 'package:fitsyncgemini/models/clothing_item.dart';
import 'package:fitsyncgemini/widgets/closet/add_item_modal.dart';
import 'package:fitsyncgemini/widgets/closet/closet_filter_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

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

  final List<Map<String, dynamic>> _categories = [
    {'id': 'all', 'name': 'All', 'count': 0},
    {'id': 'tops', 'name': 'Tops', 'count': 0},
    {'id': 'bottoms', 'name': 'Bottoms', 'count': 0},
    {'id': 'dresses', 'name': 'Dresses', 'count': 0},
    {'id': 'outerwear', 'name': 'Outerwear', 'count': 0},
    {'id': 'shoes', 'name': 'Shoes', 'count': 0},
  ];

  final Map<String, dynamic> _closetStats = {
    'totalItems': 6,
    'recentlyAdded': 3,
    'mostWorn': 'White Button Shirt',
    'leastWorn': 'Black Dress',
    'totalValue': 2840,
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
    _updateCategoryCounts();
  }

  void _updateCategoryCounts() {
    _categories[0]['count'] = sampleCloset.length;
    _categories[1]['count'] =
        sampleCloset.where((item) => item.category == 'Tops').length;
    _categories[2]['count'] =
        sampleCloset.where((item) => item.category == 'Bottoms').length;
    _categories[3]['count'] =
        sampleCloset.where((item) => item.category == 'Dresses').length;
    _categories[4]['count'] =
        sampleCloset.where((item) => item.category == 'Outerwear').length;
    _categories[5]['count'] =
        sampleCloset.where((item) => item.category == 'Shoes').length;
  }

  List<ClothingItem> get _filteredItems {
    return sampleCloset.where((item) {
      final matchesSearch = item.name.toLowerCase().contains(
        _searchController.text.toLowerCase(),
      );
      final matchesCategory =
          _selectedCategory == 'all' ||
          item.category.toLowerCase() == _selectedCategory.toLowerCase();
      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _toggleItemSelection(String itemId) {
    setState(() {
      if (_selectedItems.contains(itemId)) {
        _selectedItems.remove(itemId);
      } else {
        _selectedItems.add(itemId);
      }
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
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            pinned: true,
            floating: true,
            snap: true,
            leading: IconButton(
              icon: const Icon(LucideIcons.chevronLeft, color: Colors.black87),
              onPressed: () => context.pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Closet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '${_closetStats['totalItems']} items',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isGridView ? LucideIcons.list : LucideIcons.grid,
                  color: Colors.black87,
                ),
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
              ),
              IconButton(
                icon: const Icon(LucideIcons.filter, color: Colors.black87),
                onPressed: () => _showFilterModal(),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.fitsyncGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddItemModal(),
                    icon: const Icon(
                      LucideIcons.plus,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Add Item',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search your closet...',
                    prefixIcon: const Icon(
                      LucideIcons.search,
                      color: Colors.grey,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Closet Overview
                  _buildClosetOverview(),
                  const SizedBox(height: 24),

                  // Categories
                  _buildCategories(),
                  const SizedBox(height: 24),

                  // Selected Items Action Bar
                  if (_selectedItems.isNotEmpty) ...[
                    _buildSelectedItemsBar(),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),

          // Items Grid/List
          _isGridView ? _buildItemsGrid() : _buildItemsList(),

          // Recent Activity & Add Item CTA
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  _buildRecentActivity(),
                  const SizedBox(height: 24),
                  _buildAddItemCTA(),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.pink.withOpacity(0.1),
            AppColors.teal.withOpacity(0.1),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.transparent),
      ),
      child: Row(
        children: [
          // Left Column: Quick Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Stats',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                _buildStatRow(
                  'Recently added:',
                  '${_closetStats['recentlyAdded']}',
                ),
                const SizedBox(height: 4),
                _buildStatRow(
                  'Total value:',
                  '\$${_closetStats['totalValue']}',
                ),
              ],
            ),
          ),
          // Right Column: Insights
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Insights',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Most worn:',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                Text(
                  _closetStats['mostWorn'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.teal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category['id'];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text('${category['name']} (${category['count']})'),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category['id'];
                });
              },
              selectedColor: AppColors.pink,
              backgroundColor: Colors.white,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.pink : Colors.grey.shade300,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedItemsBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pink,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_selectedItems.length} items selected',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(
                    LucideIcons.sparkles,
                    size: 16,
                    color: AppColors.pink,
                  ),
                  label: const Text(
                    'Create Outfit',
                    style: TextStyle(color: AppColors.pink, fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    LucideIcons.heart,
                    size: 16,
                    color: AppColors.pink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    LucideIcons.moreHorizontal,
                    size: 16,
                    color: AppColors.pink,
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
          final item = _filteredItems[index];
          final isSelected = _selectedItems.contains(item.id);

          return GestureDetector(
            onTap: () => _toggleItemSelection(item.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border:
                    isSelected
                        ? Border.all(color: AppColors.pink, width: 2)
                        : null,
                boxShadow: [
                  BoxShadow(
                    color:
                        isSelected
                            ? AppColors.pink.withOpacity(0.2)
                            : Colors.black.withOpacity(0.05),
                    blurRadius: isSelected ? 10 : 5,
                    offset: const Offset(0, 2),
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
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            child: Icon(
                              LucideIcons.image,
                              color: Colors.grey.shade400,
                              size: 40,
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: AppColors.pink,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
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
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.category,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children:
                                    item.colors.take(3).map((color) {
                                      return Container(
                                        width: 12,
                                        height: 12,
                                        margin: const EdgeInsets.only(right: 4),
                                        decoration: BoxDecoration(
                                          color: _getColorFromString(color),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                            width: 1,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }, childCount: _filteredItems.length),
      ),
    );
  }

  Widget _buildItemsList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = _filteredItems[index];
          final isSelected = _selectedItems.contains(item.id);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => _toggleItemSelection(item.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      isSelected
                          ? Border.all(color: AppColors.pink, width: 2)
                          : null,
                  boxShadow: [
                    BoxShadow(
                      color:
                          isSelected
                              ? AppColors.pink.withOpacity(0.2)
                              : Colors.black.withOpacity(0.05),
                      blurRadius: isSelected ? 10 : 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Image
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        LucideIcons.image,
                        color: Colors.grey.shade400,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.category,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ...item.colors.take(3).map((color) {
                                return Container(
                                  width: 12,
                                  height: 12,
                                  margin: const EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                    color: _getColorFromString(color),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.grey.shade300,
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
                            width: 20,
                            height: 20,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: const BoxDecoration(
                              color: AppColors.pink,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            LucideIcons.moreHorizontal,
                            size: 20,
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
        }, childCount: _filteredItems.length),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Row(
            children: [
              Icon(LucideIcons.calendar, size: 20, color: AppColors.teal),
              SizedBox(width: 8),
              Text(
                'Recent Activity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children:
                _recentActivity.map((activity) {
                  Color iconColor;
                  Color bgColor;
                  IconData icon;

                  switch (activity['type']) {
                    case 'add':
                      iconColor = Colors.green.shade600;
                      bgColor = Colors.green.shade100;
                      icon = LucideIcons.plus;
                      break;
                    case 'wear':
                      iconColor = Colors.blue.shade600;
                      bgColor = Colors.blue.shade100;
                      icon = LucideIcons.trendingUp;
                      break;
                    case 'like':
                      iconColor = Colors.pink.shade600;
                      bgColor = Colors.pink.shade100;
                      icon = LucideIcons.heart;
                      break;
                    default:
                      iconColor = Colors.grey.shade600;
                      bgColor = Colors.grey.shade100;
                      icon = LucideIcons.activity;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: bgColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, size: 16, color: iconColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: activity['action'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    TextSpan(text: ' ${activity['item']}'),
                                  ],
                                ),
                              ),
                              Text(
                                activity['time'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
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
        // Refresh closet data
        setState(() {
          _updateCategoryCounts();
        });
      }
    });
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ClosetFilterWidget(
        currentFilter: _currentFilter,
        onFilterChanged: (filter) {
          setState(() {
            _currentFilter = filter;
          });
        },
      ),
    );
  }

  Widget _buildAddItemCTA() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 2,
          style: BorderStyle.solid,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.pink.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.camera,
              size: 32,
              color: AppColors.pink,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Add New Items',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Take photos of your clothes to grow your digital closet',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppColors.fitsyncGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton.icon(
              onPressed: () => _showAddItemModal(),
              icon: const Icon(
                LucideIcons.camera,
                size: 16,
                color: Colors.white,
              ),
              label: const Text(
                'Take Photo',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
