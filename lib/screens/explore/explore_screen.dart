import 'package:fitsyncgemini/models/category.dart';
import 'package:fitsyncgemini/models/explore_item.dart';
import 'package:fitsyncgemini/models/trending_style.dart';
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

  // --- Data (equivalent to component's const data) ---
  final List<Category> _categories = const [
    Category(id: 'all', name: 'All', count: 2847),
    Category(id: 'trending', name: 'Trending', count: 156),
    Category(id: 'minimalist', name: 'Minimalist', count: 432),
    Category(id: 'bohemian', name: 'Bohemian', count: 287),
    Category(id: 'professional', name: 'Professional', count: 612),
    Category(id: 'casual', name: 'Casual', count: 891),
  ];

  final List<TrendingStyle> _trendingStyles = const [
    TrendingStyle(name: 'Y2K Revival', growth: '+23%', color: kPrimaryPink),
    TrendingStyle(name: 'Dark Academia', growth: '+18%', color: kDarkText),
    TrendingStyle(
      name: 'Cottagecore',
      growth: '+15%',
      color: Color(0xFF4ECDC4),
    ),
    TrendingStyle(name: 'Maximalist', growth: '+12%', color: Color(0xFFC44DC7)),
  ];

  final List<ExploreItem> _exploreItems = const [
    ExploreItem(
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
    ExploreItem(
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
    ExploreItem(
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
    ExploreItem(
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // --- Header & Search Bar (equivalent to sticky header) ---
          SliverAppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            pinned: true,
            floating: true,
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, size: 20),
              onPressed:
                  () => Navigator.of(context).pop(), // Equivalent to onBack
            ),
            title: const Text(
              'Explore',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.filter, size: 20),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(LucideIcons.bookmark, size: 20),
                onPressed: () {},
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60.0),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search styles, outfits, or users...',
                    prefixIcon: const Icon(
                      LucideIcons.search,
                      size: 16,
                      color: Colors.grey,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // --- Main Content ---
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // --- Trending Styles Card ---
                _buildTrendingStylesCard(),
                const SizedBox(height: 24),

                // --- Categories ---
                _buildCategoriesList(),
                const SizedBox(height: 16),

                // --- Explore Grid ---
                _buildExploreItemsList(),

                // --- Load More Button ---
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    onPressed: () {},
                    child: const Text('Load More Styles'),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget Builders for cleaner code ---

  Widget _buildTrendingStylesCard() {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(LucideIcons.trendingUp, size: 20, color: kPrimaryPink),
                SizedBox(width: 8),
                Text(
                  'Trending Styles',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 3.5,
              ),
              itemCount: _trendingStyles.length,
              itemBuilder: (context, index) {
                final style = _trendingStyles[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.grey[200]!),
                    gradient: LinearGradient(
                      colors: [Colors.grey[50]!, Colors.white],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            style.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: style.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        style.growth,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesList() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategoryId == category.id;
          return ChoiceChip(
            label: Text('${category.name} (${category.count})'),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _selectedCategoryId = category.id;
                });
              }
            },
            selectedColor: kPrimaryPink,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            shape: StadiumBorder(
              side: BorderSide(
                color: isSelected ? kPrimaryPink : Colors.grey[300]!,
              ),
            ),
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          );
        },
      ),
    );
  }

  Widget _buildExploreItemsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _exploreItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _ExploreItemCard(item: _exploreItems[index]);
      },
    );
  }
}

// --- A dedicated widget for the Explore Item Card ---

class _ExploreItemCard extends StatelessWidget {
  final ExploreItem item;

  const _ExploreItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Image with Overlays ---
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.network(
                  item.image,
                  fit: BoxFit.cover,
                  // Equivalent to ImageWithFallback
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Icon(Icons.broken_image));
                  },
                ),
              ),
              if (item.trending)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Chip(
                    label: const Text('Trending'),
                    labelStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    avatar: const Icon(
                      LucideIcons.trendingUp,
                      color: Colors.white,
                      size: 14,
                    ),
                    backgroundColor: kPrimaryPink,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                  ),
                ),
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  children: [
                    _buildOverlayButton(LucideIcons.heart),
                    const SizedBox(width: 8),
                    _buildOverlayButton(LucideIcons.share2),
                  ],
                ),
              ),
            ],
          ),

          // --- Card Content ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: kAvatarBg,
                                child: Text(
                                  item.authorAvatar,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item.author,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(
                        LucideIcons.chevronRight,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStat(
                      icon: LucideIcons.heart,
                      value: item.likes.toString(),
                    ),
                    const SizedBox(width: 16),
                    _buildStat(
                      icon: LucideIcons.eye,
                      value: item.views.toString(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6.0,
                  runSpacing: 6.0,
                  children:
                      item.tags
                          .map(
                            (tag) => Chip(
                              label: Text(tag),
                              labelStyle: TextStyle(color: Colors.grey[700]),
                              backgroundColor: Colors.grey[100],
                              side: BorderSide(color: Colors.grey[300]!),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayButton(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, size: 18),
        onPressed: () {},
        padding: EdgeInsets.zero,
        splashRadius: 20,
      ),
    );
  }

  Widget _buildStat({required IconData icon, required String value}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
      ],
    );
  }
}
