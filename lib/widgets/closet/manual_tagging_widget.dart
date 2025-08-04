// lib/widgets/closet/manual_tagging_widget.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fitsyncgemini/constants/app_colors.dart';
import 'package:fitsyncgemini/constants/app_constants.dart';

class ManualTaggingWidget extends ConsumerStatefulWidget {
  final File imageFile;
  final Function(Map<String, dynamic>) onComplete;

  const ManualTaggingWidget({
    super.key,
    required this.imageFile,
    required this.onComplete,
  });

  @override
  ConsumerState<ManualTaggingWidget> createState() => _ManualTaggingWidgetState();
}

class _ManualTaggingWidgetState extends ConsumerState<ManualTaggingWidget> {
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _priceController = TextEditingController();
  final _tagController = TextEditingController();

  String _selectedCategory = AppConstants.clothingCategories.first;
  List<String> _selectedColors = [];
  List<String> _tags = [];
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _runAIAnalysis();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _runAIAnalysis() async {
    setState(() {
      _isAnalyzing = true;
    });

    // Simulate AI analysis
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _nameController.text = 'White Cotton T-Shirt';
        _selectedCategory = 'Tops';
        _selectedColors = ['White'];
        _tags = ['casual', 'cotton', 'basic'];
        _isAnalyzing = false;
      });
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _toggleColor(String color) {
    setState(() {
      if (_selectedColors.contains(color)) {
        _selectedColors.remove(color);
      } else {
        _selectedColors.add(color);
      }
    });
  }

  void _complete() {
    final data = {
      'name': _nameController.text,
      'category': _selectedCategory,
      'colors': _selectedColors,
      'tags': _tags,
      'brand': _brandController.text.isNotEmpty ? _brandController.text : null,
      'price': _priceController.text.isNotEmpty ? double.tryParse(_priceController.text) : null,
    };
    widget.onComplete(data);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image preview
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: FileImage(widget.imageFile),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isAnalyzing)
                      const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('AI analyzing...'),
                        ],
                      )
                    else
                      const Row(
                        children: [
                          Icon(LucideIcons.check, color: Colors.green, size: 16),
                          SizedBox(width: 8),
                          Text('Analysis complete'),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Item name
          _buildSectionTitle('Item Name'),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'Enter item name',
              border: OutlineInputBorder(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Category selection
          _buildSectionTitle('Category'),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            items: AppConstants.clothingCategories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCategory = value;
                });
              }
            },
          ),
          
          const SizedBox(height: 16),
          
          // Color selection
          _buildSectionTitle('Colors'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.commonColors.map((color) {
              final isSelected = _selectedColors.contains(color);
              return FilterChip(
                label: Text(color),
                selected: isSelected,
                onSelected: (_) => _toggleColor(color),
                selectedColor: AppColors.pink,
                backgroundColor: Colors.white,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          // Tags
          _buildSectionTitle('Tags'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagController,
                  decoration: const InputDecoration(
                    hintText: 'Add tag',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _addTag(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _addTag,
                icon: const Icon(LucideIcons.plus),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.pink,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          
          if (_tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.map((tag) {
                return Chip(
                  label: Text(tag),
                  deleteIcon: const Icon(LucideIcons.x, size: 16),
                  onDeleted: () => _removeTag(tag),
                  backgroundColor: AppColors.teal.withOpacity(0.1),
                );
              }).toList(),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Optional fields
          ExpansionTile(
            title: const Text('Additional Details'),
            children: [
              const SizedBox(height: 8),
              TextField(
                controller: _brandController,
                decoration: const InputDecoration(
                  labelText: 'Brand',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Continue button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _complete,
              icon: const Icon(LucideIcons.arrowRight),
              label: const Text('Continue'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}