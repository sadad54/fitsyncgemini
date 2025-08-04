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
  String _selectedCategory = 'Today';
  bool _isGenerating = false;

  final List<String> _categories = ['Today', 'Work', 'Casual', 'Event'];

  final List<Map<String, dynamic>> _todayOutfits = [
    {
      'id': '1',
      'name': 'Perfect for Today\'s Weather',
      'temperature': '24°C',
      'weather': 'Sunny',
      'matchPercentage': 95,
      'items': [
        {'name': 'White Cotton Tee', 'category': 'comfortable'},
        {'name': 'Light Blue Jeans', 'category': 'breathable'},
        {'name': 'White Sneakers', 'category': 'casual'},
      ],
      'description':
          'Based on weather forecast and your minimalist style preference',
    },
    {
      'id': '2',
      'name': 'Professional Power Look',
      'temperature': '24°C',
      'weather': 'Meeting Ready',
      'matchPercentage': 89,
      'items': [
        {'name': 'Navy Blazer', 'category': 'Professional'},
        {'name': 'White Button Shirt', 'category': 'Classic'},
        {'name': 'Tailored Trousers', 'category': 'Business'},
      ],
      'description': 'Perfect for important meetings and presentations',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: Row(
          children: [
            Text(
              'Outfit ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                gradient: AppColors.fitsyncGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'AI',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.rotateCcw, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(LucideIcons.moreHorizontal, color: Colors.black87),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(56),
          child: Container(
            height: 56,
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.pink,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: AppColors.pink,
              indicatorWeight: 3,
              labelStyle: TextStyle(fontWeight: FontWeight.w600),
              unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
              tabs:
                  _categories.map((category) {
                    return Tab(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (category == 'Today')
                              Container(
                                margin: EdgeInsets.only(right: 4),
                                child: Icon(
                                  LucideIcons.sparkles,
                                  size: 16,
                                  color:
                                      category == 'Today'
                                          ? AppColors.pink
                                          : Colors.grey.shade600,
                                ),
                              ),
                            Text(category),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayView(),
          _buildWorkView(),
          _buildCasualView(),
          _buildEventView(),
        ],
      ),
    );
  }

  Widget _buildGenerateMoreCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.pink.withOpacity(0.2),
          width: 1,
          style: BorderStyle.solid,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.pink.withOpacity(0.1),
            ),
            child: Icon(LucideIcons.sparkles, size: 28, color: AppColors.pink),
          ),
          SizedBox(height: 16),
          Text(
            'Need More Options?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Generate fresh outfit combinations based on your preferences',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.fitsyncGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: _isGenerating ? null : _generateOutfit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  _isGenerating
                      ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Generating...',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      )
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.refreshCw,
                            size: 18,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Generate New Suggestions',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildStyleFocusHeader(),
          SizedBox(height: 16),
          ..._todayOutfits.map((outfit) => _buildOutfitCard(outfit)).toList(),
          _buildGenerateMoreCard(),
          SizedBox(height: 100), // Bottom padding for any floating elements
        ],
      ),
    );
  }

  Widget _buildStyleFocusHeader() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Today\'s Style Focus',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.sun,
                      size: 16,
                      color: Colors.amber.shade700,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '24°C',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Minimalist • Light layers recommended for temperature changes',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutfitCard(Map<String, dynamic> outfit) {
    return MouseRegion(
      onEnter: (_) => setState(() {}),
      onExit: (_) => setState(() {}),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
            BoxShadow(
              color: AppColors.pink.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and match percentage
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          outfit['name'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        // Show weather info only for weather-related outfits
                        if (outfit['weather'] != 'Meeting Ready')
                          Row(
                            children: [
                              Text(
                                outfit['weather'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                ', ${outfit['temperature']}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          )
                        else
                          // For professional outfits, show occasion-specific subtitle
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Meeting Ready',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.purple,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${outfit['matchPercentage']}% match',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.teal,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Clothing items row
            Container(
              height: 120,
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // First item (main clothing)
                  Expanded(
                    flex: 2,
                    child: _buildClothingItemCard(
                      outfit['items'][0],
                      'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400',
                      isMain: true,
                    ),
                  ),
                  SizedBox(width: 12),
                  // Second item
                  Expanded(
                    child: _buildClothingItemCard(
                      outfit['items'][1],
                      'https://images.unsplash.com/photo-1602293589914-9e19a782a0e5?w=400',
                    ),
                  ),
                  SizedBox(width: 12),
                  // Third item
                  Expanded(
                    child: _buildClothingItemCard(
                      outfit['items'][2],
                      'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400',
                    ),
                  ),
                ],
              ),
            ),

            // Tags row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    outfit['items'].map<Widget>((item) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item['category'],
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),

            // Description
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(LucideIcons.sparkles, size: 16, color: AppColors.pink),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      outfit['description'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Action buttons
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  // Try On button
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppColors.fitsyncGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: () => context.go('/try-on'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.play,
                              size: 16,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Try On',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  // Save button
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () {},
                      icon: Icon(
                        LucideIcons.heart,
                        size: 20,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  // Share button
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () {},
                      icon: Icon(
                        LucideIcons.upload,
                        size: 20,
                        color: Colors.grey.shade600,
                      ),
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

  Widget _buildClothingItemCard(
    Map<String, dynamic> item,
    String imageUrl, {
    bool isMain = false,
  }) {
    return Container(
      height: isMain ? 120 : 100,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Placeholder for clothing image
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                LucideIcons.image,
                color: Colors.grey.shade400,
                size: isMain ? 32 : 24,
              ),
            ),
            // Item name overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Text(
                  item['name'],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMain ? 10 : 9,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.briefcase, size: 64, color: Colors.grey.shade400),
          SizedBox(height: 16),
          Text(
            'Work outfits coming soon',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Professional outfit suggestions based on your calendar',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCasualView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.coffee, size: 64, color: Colors.grey.shade400),
          SizedBox(height: 16),
          Text(
            'Casual looks coming soon',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Relaxed and comfortable outfit ideas for your downtime',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEventView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.calendar, size: 64, color: Colors.grey.shade400),
          SizedBox(height: 16),
          Text(
            'Event outfits coming soon',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Special occasion outfits for parties, dates, and events',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
