// lib/widgets/closet/manual_tagging_widget.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fitsyncgemini/constants/app_colors.dart';
import 'package:fitsyncgemini/constants/app_constants.dart';
import 'package:fitsyncgemini/services/clothing_detection_service.dart';

class ManualTaggingWidget extends ConsumerStatefulWidget {
  final File imageFile;
  final Function(Map<String, dynamic>) onComplete;

  const ManualTaggingWidget({
    super.key,
    required this.imageFile,
    required this.onComplete,
  });

  @override
  ConsumerState<ManualTaggingWidget> createState() =>
      _ManualTaggingWidgetState();
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
  String _analysisStatus = '';

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
      _analysisStatus = 'Connecting to AI service...';
    });

    try {
      final clothingDetectionService = ref.read(
        clothingDetectionServiceProvider,
      );

      // Check if service is healthy first
      setState(() {
        _analysisStatus = 'Checking service availability...';
      });

      final isHealthy = await clothingDetectionService.isServiceHealthy();
      if (!isHealthy) {
        throw ClothingDetectionException(
          'AI service is currently unavailable',
          503,
        );
      }

      setState(() {
        _analysisStatus = 'Analyzing clothing item...';
      });

      // Perform clothing analysis
      final analysisResult = await clothingDetectionService.analyzeClothing(
        widget.imageFile,
      );

      if (mounted) {
        setState(() {
          // Apply AI suggestions
          _nameController.text =
              analysisResult.suggestedName ?? 'Clothing Item';

          // Set category if detected and valid
          if (analysisResult.detectedCategory != null &&
              AppConstants.clothingCategories.contains(
                analysisResult.detectedCategory,
              )) {
            _selectedCategory = analysisResult.detectedCategory!;
          }

          // Set colors (filter to only include known colors)
          _selectedColors =
              analysisResult.colors
                  .where((color) => AppConstants.commonColors.contains(color))
                  .toList();

          // Set tags
          _tags = analysisResult.tags;

          _isAnalyzing = false;
          _analysisStatus =
              'Analysis complete (${(analysisResult.confidence * 100).toStringAsFixed(1)}% confidence)';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          if (e is ClothingDetectionException) {
            _analysisStatus = 'AI analysis failed: ${e.message}';
          } else {
            _analysisStatus = 'AI analysis failed: $e';
          }

          // Provide fallback values
          _nameController.text = 'Clothing Item';
          _selectedCategory = AppConstants.clothingCategories.first;
          _selectedColors = [];
          _tags = [];
        });

        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'AI analysis failed. You can still manually tag the item.',
            ),
            backgroundColor: Colors.orange,
            action: SnackBarAction(label: 'Retry', onPressed: _runAIAnalysis),
          ),
        );
      }
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
      'price':
          _priceController.text.isNotEmpty
              ? double.tryParse(_priceController.text)
              : null,
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
          // Image preview and analysis status
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
                      Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _analysisStatus,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Icon(
                            _analysisStatus.contains('failed')
                                ? LucideIcons.alertCircle
                                : LucideIcons.check,
                            color:
                                _analysisStatus.contains('failed')
                                    ? Colors.orange
                                    : Colors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _analysisStatus,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    if (!_isAnalyzing && _analysisStatus.contains('failed'))
                      TextButton(
                        onPressed: _runAIAnalysis,
                        child: const Text('Retry Analysis'),
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
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items:
                AppConstants.clothingCategories.map((category) {
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
            children:
                AppConstants.commonColors.map((color) {
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
              children:
                  _tags.map((tag) {
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
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}
