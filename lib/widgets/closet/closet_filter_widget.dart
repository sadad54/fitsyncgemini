// lib/widgets/closet/closet_filter_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fitsyncgemini/constants/app_colors.dart';
import 'package:fitsyncgemini/constants/app_constants.dart';

class ClosetFilterWidget extends ConsumerStatefulWidget {
  final Function(ClosetFilter) onFilterChanged;
  final ClosetFilter currentFilter;

  const ClosetFilterWidget({
    super.key,
    required this.onFilterChanged,
    required this.currentFilter,
  });

  @override
  ConsumerState<ClosetFilterWidget> createState() => _ClosetFilterWidgetState();
}

class _ClosetFilterWidgetState extends ConsumerState<ClosetFilterWidget> {
  late ClosetFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.currentFilter;
  }

  void _updateFilter() {
    widget.onFilterChanged(_filter);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategoryFilter(),
                  const SizedBox(height: 24),
                  _buildColorFilter(),
                  const SizedBox(height: 24),
                  _buildSortOptions(),
                  const SizedBox(height: 24),
                  _buildDateFilter(),
                ],
              ),
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          const Text(
            'Filter & Sort',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              setState(() {
                _filter = ClosetFilter();
              });
            },
            child: const Text('Reset'),
          ),
          IconButton(
            icon: const Icon(LucideIcons.x),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categories',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['All', ...AppConstants.clothingCategories].map((category) {
            final isSelected = _filter.categories.contains(category) || 
                              (category == 'All' && _filter.categories.isEmpty);
            return FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (category == 'All') {
                    _filter = _filter.copyWith(categories: []);
                  } else {
                    final categories = List<String>.from(_filter.categories);
                    if (selected) {
                      categories.add(category);
                    } else {
                      categories.remove(category);
                    }
                    _filter = _filter.copyWith(categories: categories);
                  }
                });
              },
              selectedColor: AppColors.pink,
              backgroundColor: Colors.white,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildColorFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Colors',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppConstants.commonColors.map((color) {
            final isSelected = _filter.colors.contains(color);
            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getColorFromString(color),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(color),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  final colors = List<String>.from(_filter.colors);
                  if (selected) {
                    colors.add(color);
                  } else {
                    colors.remove(color);
                  }
                  _filter = _filter.copyWith(colors: colors);
                });
              },
              selectedColor: AppColors.teal,
              backgroundColor: Colors.white,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSortOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sort By',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...SortOption.values.map((option) {
          return RadioListTile<SortOption>(
            title: Text(_getSortOptionLabel(option)),
            value: option,
            groupValue: _filter.sortBy,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _filter = _filter.copyWith(sortBy: value);
                });
              }
            },
            activeColor: AppColors.pink,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildDateFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date Added',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...DateFilter.values.map((filter) {
          return RadioListTile<DateFilter>(
            title: Text(_getDateFilterLabel(filter)),
            value: filter,
            groupValue: _filter.dateFilter,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _filter = _filter.copyWith(dateFilter: value);
                });
              }
            },
            activeColor: AppColors.purple,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                _updateFilter();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pink,
                foregroundColor: Colors.white,
              ),
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'white': return Colors.white;
      case 'black': return Colors.black;
      case 'blue': return Colors.blue;
      case 'red': return Colors.red;
      case 'green': return Colors.green;
      case 'pink': return Colors.pink;
      case 'beige': return const Color(0xFFF5F5DC);
      case 'brown': return Colors.brown;
      case 'gray': case 'grey': return Colors.grey;
      default: return Colors.grey;
    }
  }

  String _getSortOptionLabel(SortOption option) {
    switch (option) {
      case SortOption.dateAdded: return 'Date Added';
      case SortOption.name: return 'Name';
      case SortOption.category: return 'Category';
      case SortOption.color: return 'Color';
      case SortOption.mostWorn: return 'Most Worn';
    }
  }

  String _getDateFilterLabel(DateFilter filter) {
    switch (filter) {
      case DateFilter.all: return 'All Time';
      case DateFilter.lastWeek: return 'Last Week';
      case DateFilter.lastMonth: return 'Last Month';
      case DateFilter.lastYear: return 'Last Year';
    }
  }
}

// Filter data classes
class ClosetFilter {
  final List<String> categories;
  final List<String> colors;
  final SortOption sortBy;
  final DateFilter dateFilter;
  final bool ascending;

  const ClosetFilter({
    this.categories = const [],
    this.colors = const [],
    this.sortBy = SortOption.dateAdded,
    this.dateFilter = DateFilter.all,
    this.ascending = false,
  });

  ClosetFilter copyWith({
    List<String>? categories,
    List<String>? colors,
    SortOption? sortBy,
    DateFilter? dateFilter,
    bool? ascending,
  }) {
    return ClosetFilter(
      categories: categories ?? this.categories,
      colors: colors ?? this.colors,
      sortBy: sortBy ?? this.sortBy,
      dateFilter: dateFilter ?? this.dateFilter,
      ascending: ascending ?? this.ascending,
    );
  }
}

enum SortOption {
  dateAdded,
  name,
  category,
  color,
  mostWorn,
}

enum DateFilter {
  all,
  lastWeek,
  lastMonth,
  lastYear,
}