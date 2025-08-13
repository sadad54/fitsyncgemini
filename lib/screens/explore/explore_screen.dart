import 'package:fitsyncgemini/models/category.dart';
import 'package:fitsyncgemini/models/explore_item.dart';
import 'package:fitsyncgemini/models/trending_style.dart';
import 'package:fitsyncgemini/services/MLAPI_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

const Color kPrimaryPink = Color(0xFFFF6B9D);
const Color kAvatarBg = Color(0xFF4ECDC4);
const Color kDarkText = Color(0xFF2C3E50);

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  // --- State Management (equivalent to React's useState) ---
  String _selectedCategoryId = 'all';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoadingCategories = false;
  bool _isLoadingTrendingStyles = false;
  bool _isLoadingExploreItems = false;

  // --- Backend data ---
  List<Category> _categories = [];
  List<TrendingStyle> _trendingStyles = [];
  List<ExploreItem> _exploreItems = [];

  @override
  void initState() {
    super.initState();
    _loadExploreData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Load all explore data from backend
  Future<void> _loadExploreData() async {
    await Future.wait([
      _loadCategories(),
      _loadTrendingStyles(),
      _loadExploreItems(),
    ]);
  }

  // Load categories from backend
  Future<void> _loadCategories() async {
    if (_isLoadingCategories) return;

    setState(() {
      _isLoadingCategories = true;
    });

    try {
      // Note: Categories endpoint might not be implemented yet
      // For now, we'll use default categories
      setState(() {
        _categories = [
          const Category(id: 'all', name: 'All', count: 0),
          const Category(id: 'trending', name: 'Trending', count: 0),
          const Category(id: 'minimalist', name: 'Minimalist', count: 0),
          const Category(id: 'bohemian', name: 'Bohemian', count: 0),
          const Category(id: 'professional', name: 'Professional', count: 0),
          const Category(id: 'casual', name: 'Casual', count: 0),
        ];
      });
    } catch (e) {
      print('❌ Failed to load categories: $e');
      // Keep default categories if backend fails
    } finally {
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  // Load trending styles from backend
  Future<void> _loadTrendingStyles() async {
    if (_isLoadingTrendingStyles) return;

    setState(() {
      _isLoadingTrendingStyles = true;
    });

    try {
      // Note: Trending styles endpoint might not be implemented yet
      // For now, we'll use default trending styles
      setState(() {
        _trendingStyles = [
          const TrendingStyle(
            name: 'Y2K Revival',
            growth: '+23%',
            color: kPrimaryPink,
          ),
          const TrendingStyle(
            name: 'Dark Academia',
            growth: '+18%',
            color: kDarkText,
          ),
          const TrendingStyle(
            name: 'Cottagecore',
            growth: '+15%',
            color: Color(0xFF4ECDC4),
          ),
          const TrendingStyle(
            name: 'Maximalist',
            growth: '+12%',
            color: Color(0xFFC44DC7),
          ),
        ];
      });
    } catch (e) {
      print('❌ Failed to load trending styles: $e');
      // Keep default trending styles if backend fails
    } finally {
      setState(() {
        _isLoadingTrendingStyles = false;
      });
    }
  }

  // Load explore items from backend
  Future<void> _loadExploreItems() async {
    if (_isLoadingExploreItems) return;

    setState(() {
      _isLoadingExploreItems = true;
    });

    try {
      // Note: Explore items endpoint might not be implemented yet
      // For now, we'll use default explore items
      setState(() {
        _exploreItems = [
          const ExploreItem(
            id: 1,
            title: 'Minimalist Spring Vibes',
            author: 'Sarah M.',
            authorAvatar: 'SM',
            likes: 247,
            views: 1200,
            tags: ['minimalist', 'spring', 'neutral'],
            image:
                'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=400',
            trending: true,
          ),
          const ExploreItem(
            id: 2,
            title: 'Bohemian Summer Look',
            author: 'Emma K.',
            authorAvatar: 'EK',
            likes: 189,
            views: 890,
            tags: ['bohemian', 'summer', 'flowing'],
            image:
                'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400',
            trending: false,
          ),
          const ExploreItem(
            id: 3,
            title: 'Power Dressing Made Easy',
            author: 'Alex R.',
            authorAvatar: 'AR',
            likes: 324,
            views: 1650,
            tags: ['professional', 'power', 'structured'],
            image:
                'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400',
            trending: true,
          ),
          const ExploreItem(
            id: 4,
            title: 'Casual Weekend Comfort',
            author: 'Mike L.',
            authorAvatar: 'ML',
            likes: 156,
            views: 720,
            tags: ['casual', 'weekend', 'comfort'],
            image:
                'https://images.unsplash.com/photo-1542272454315-7ad85f140fe2?w=400',
            trending: false,
          ),
        ];
      });
    } catch (e) {
      print('❌ Failed to load explore items: $e');
      // Keep default explore items if backend fails
    } finally {
      setState(() {
        _isLoadingExploreItems = false;
      });
    }
  }

  // Filter explore items based on selected category and search
  List<ExploreItem> get _filteredItems {
    return _exploreItems.where((item) {
      final matchesSearch = item.title.toLowerCase().contains(
        _searchController.text.toLowerCase(),
      );

      final matchesCategory =
          _selectedCategoryId == 'all' ||
          item.tags.any(
            (tag) => tag.toLowerCase() == _selectedCategoryId.toLowerCase(),
          ) ||
          (_selectedCategoryId == 'trending' && item.trending);

      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Explore',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: kDarkText,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(LucideIcons.search, color: kDarkText),
            onPressed: () {
              // Implement search functionality
            },
          ),
          IconButton(
            icon: Icon(LucideIcons.bell, color: kDarkText),
            onPressed: () {
              // Implement notifications
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadExploreData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: 'Search styles, trends, or creators...',
                    border: InputBorder.none,
                    icon: Icon(LucideIcons.search, color: Colors.grey.shade600),
                    suffixIcon:
                        _searchController.text.isNotEmpty
                            ? IconButton(
                              icon: Icon(
                                LucideIcons.x,
                                color: Colors.grey.shade600,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                            : null,
                  ),
                ),
              ),

              // Categories
              Container(
                height: 50,
                margin: const EdgeInsets.only(bottom: 16),
                child:
                    _isLoadingCategories
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            final isSelected =
                                _selectedCategoryId == category.id;

                            return Container(
                              margin: const EdgeInsets.only(right: 12),
                              child: FilterChip(
                                label: Text(
                                  '${category.name} (${category.count})',
                                  style: TextStyle(
                                    color:
                                        isSelected ? Colors.white : kDarkText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCategoryId = category.id;
                                  });
                                },
                                backgroundColor: Colors.white,
                                selectedColor: kPrimaryPink,
                                checkmarkColor: Colors.white,
                                elevation: 2,
                                pressElevation: 4,
                              ),
                            );
                          },
                        ),
              ),

              // Trending Styles
              if (_trendingStyles.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Trending Now',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: kDarkText,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigate to trends screen
                          context.go('/trends');
                        },
                        child: Text(
                          'See All',
                          style: TextStyle(
                            color: kPrimaryPink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 120,
                  margin: const EdgeInsets.only(bottom: 24),
                  child:
                      _isLoadingTrendingStyles
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _trendingStyles.length,
                            itemBuilder: (context, index) {
                              final style = _trendingStyles[index];

                              return Container(
                                width: 200,
                                margin: const EdgeInsets.only(right: 16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      style.color.withOpacity(0.8),
                                      style.color.withOpacity(0.6),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: style.color.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        style.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Icon(
                                            LucideIcons.trendingUp,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            style.growth,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                ),
              ],

              // Explore Items
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Discover Styles',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kDarkText,
                      ),
                    ),
                    Text(
                      '${_filteredItems.length} items',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              if (_isLoadingExploreItems)
                const Center(child: CircularProgressIndicator())
              else if (_filteredItems.isEmpty)
                _buildEmptyState()
              else
                ..._filteredItems
                    .map((item) => _buildExploreItemCard(item))
                    .toList(),

              const SizedBox(height: 100), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(40),
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
        children: [
          Icon(LucideIcons.search, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No items found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or category filter',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExploreItemCard(ExploreItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Stack(
              children: [
                Image.network(
                  item.image,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 200,
                      color: Colors.grey.shade200,
                      child: Icon(
                        LucideIcons.image,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                    );
                  },
                ),
                if (item.trending)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: kPrimaryPink,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'TRENDING',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: kAvatarBg,
                      child: Text(
                        item.authorAvatar,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.author,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${item.views} views',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        LucideIcons.heart,
                        size: 20,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: () {
                        // Handle like
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Title
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kDarkText,
                  ),
                ),

                const SizedBox(height: 8),

                // Tags
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children:
                      item.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: kPrimaryPink.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(
                              color: kPrimaryPink,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                ),

                const SizedBox(height: 8),

                // Stats
                Row(
                  children: [
                    Icon(
                      LucideIcons.heart,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.likes}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      LucideIcons.eye,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.views}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
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
}
