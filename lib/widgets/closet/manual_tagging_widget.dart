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

  // Enhanced analysis results
  ClothingAnalysisResult? _analysisResult;
  ColorAnalysisResult? _colorAnalysis;
  StyleSuggestionsResult? _styleSuggestions;

  @override
  void initState() {
    super.initState();
    _runComprehensiveAIAnalysis();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _runComprehensiveAIAnalysis() async {
    setState(() {
      _isAnalyzing = true;
      _analysisStatus = 'Initializing AI analysis...';
    });

    try {
      final clothingDetectionService = ref.read(
        clothingDetectionServiceProvider,
      );

      // Check if service is healthy first
      setState(() {
        _analysisStatus = 'Checking AI service availability...';
      });

      final isHealthy = await clothingDetectionService.isServiceHealthy();
      if (!isHealthy) {
        throw ClothingDetectionException(
          'AI service is currently unavailable',
          503,
        );
      }

      setState(() {
        _analysisStatus = 'Running comprehensive analysis (3 AI models)...';
      });

      // Perform comprehensive analysis using all endpoints
      final analysisResult = await clothingDetectionService.analyzeClothing(
        widget.imageFile,
      );

      if (mounted) {
        setState(() {
          _analysisResult = analysisResult;
          _colorAnalysis = analysisResult.colorAnalysis;
          _styleSuggestions = analysisResult.styleSuggestions;

          // Apply AI suggestions with enhanced data
          _nameController.text =
              analysisResult.suggestedName ?? 'Clothing Item';

          // Set category if detected and valid
          if (analysisResult.detectedCategory != null &&
              AppConstants.clothingCategories.contains(
                analysisResult.detectedCategory,
              )) {
            _selectedCategory = analysisResult.detectedCategory!;
          }

          // Enhanced color detection - prioritize dominant colors from color analysis
          List<String> detectedColors = [];
          if (_colorAnalysis != null) {
            detectedColors.addAll(_colorAnalysis!.dominantColors);
            if (_colorAnalysis!.primaryColor != null) {
              detectedColors.insert(0, _colorAnalysis!.primaryColor!);
            }
          }
          detectedColors.addAll(analysisResult.colors);

          // Filter to only include known colors and remove duplicates
          _selectedColors =
              detectedColors
                  .toSet()
                  .where((color) => AppConstants.commonColors.contains(color))
                  .toList();

          // Enhanced tags from multiple sources
          Set<String> allTags = {};
          allTags.addAll(analysisResult.tags);
          if (_styleSuggestions != null) {
            allTags.addAll(_styleSuggestions!.occasions);
            if (_styleSuggestions!.styleArchetype != null) {
              allTags.add(_styleSuggestions!.styleArchetype!.toLowerCase());
            }
          }
          _tags = allTags.toList();

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
            content: const Text(
              'AI analysis failed. You can still manually tag the item.',
            ),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _runComprehensiveAIAnalysis,
            ),
          ),
        );
      }
    }
  }

  Future<void> _runSpecificAnalysis(String analysisType) async {
    final clothingDetectionService = ref.read(clothingDetectionServiceProvider);

    setState(() {
      _isAnalyzing = true;
      _analysisStatus = 'Running $analysisType analysis...';
    });

    try {
      switch (analysisType) {
        case 'color':
          final colorResult = await clothingDetectionService.analyzeColors(
            widget.imageFile,
          );
          setState(() {
            _colorAnalysis = colorResult;
            // Update colors based on new analysis
            final newColors =
                colorResult.dominantColors
                    .where((color) => AppConstants.commonColors.contains(color))
                    .toList();
            _selectedColors =
                [..._selectedColors, ...newColors].toSet().toList();
          });
          break;
        case 'style':
          final styleResult = await clothingDetectionService
              .getStyleSuggestions(widget.imageFile);
          setState(() {
            _styleSuggestions = styleResult;
            // Add style-based tags
            final newTags = <String>[];
            newTags.addAll(styleResult.occasions);
            if (styleResult.styleArchetype != null) {
              newTags.add(styleResult.styleArchetype!.toLowerCase());
            }
            _tags = [..._tags, ...newTags].toSet().toList();
          });
          break;
      }

      setState(() {
        _isAnalyzing = false;
        _analysisStatus = '$analysisType analysis complete';
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _analysisStatus = '$analysisType analysis failed';
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
      'price':
          _priceController.text.isNotEmpty
              ? double.tryParse(_priceController.text)
              : null,
      // Include AI analysis results for potential future use
      'aiAnalysis': {
        'clothingAnalysis': _analysisResult?.toJson(),
        'colorAnalysis': _colorAnalysis?.toJson(),
        'styleSuggestions': _styleSuggestions?.toJson(),
      },
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
          _buildAnalysisHeader(),

          const SizedBox(height: 24),

          // AI Insights Panel (if available)
          if (_analysisResult != null ||
              _colorAnalysis != null ||
              _styleSuggestions != null)
            _buildAIInsightsPanel(),

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

          // Color selection with enhanced controls
          _buildColorSection(),

          const SizedBox(height: 16),

          // Tags section with style suggestions
          _buildTagsSection(),

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

  Widget _buildAnalysisHeader() {
    return Row(
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    if (!_analysisStatus.contains('failed'))
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => _runSpecificAnalysis('color'),
                            icon: const Icon(LucideIcons.palette, size: 14),
                            label: const Text(
                              'Color',
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _runSpecificAnalysis('style'),
                            icon: const Icon(LucideIcons.sparkles, size: 14),
                            label: const Text(
                              'Style',
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    if (_analysisStatus.contains('failed'))
                      TextButton(
                        onPressed: _runComprehensiveAIAnalysis,
                        child: const Text('Retry Analysis'),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAIInsightsPanel() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.teal.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.teal.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.brain, color: AppColors.teal, size: 16),
              SizedBox(width: 6),
              Text(
                'AI Insights',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_styleSuggestions?.complementaryItems.isNotEmpty == true) ...[
            Text(
              'Pairs well with: ${_styleSuggestions!.complementaryItems.take(3).join(', ')}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
          ],
          if (_styleSuggestions?.occasions.isNotEmpty == true) ...[
            Text(
              'Perfect for: ${_styleSuggestions!.occasions.take(3).join(', ')}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
          ],
          if (_colorAnalysis?.primaryColor != null) ...[
            Text(
              'Primary color: ${_colorAnalysis!.primaryColor}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildColorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionTitle('Colors'),
            const Spacer(),
            if (_colorAnalysis != null && !_isAnalyzing)
              TextButton.icon(
                onPressed: () => _runSpecificAnalysis('color'),
                icon: const Icon(LucideIcons.refreshCw, size: 14),
                label: const Text('Re-analyze', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              AppConstants.commonColors.map((color) {
                final isSelected = _selectedColors.contains(color);
                final isAISuggested =
                    _colorAnalysis?.dominantColors.contains(color) == true;
                return FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(color),
                      if (isAISuggested) ...[
                        const SizedBox(width: 4),
                        const Icon(LucideIcons.sparkles, size: 12),
                      ],
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (_) => _toggleColor(color),
                  selectedColor: AppColors.pink,
                  backgroundColor:
                      isAISuggested
                          ? AppColors.teal.withOpacity(0.1)
                          : Colors.white,
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

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionTitle('Tags'),
            const Spacer(),
            if (_styleSuggestions != null && !_isAnalyzing)
              TextButton.icon(
                onPressed: () => _runSpecificAnalysis('style'),
                icon: const Icon(LucideIcons.refreshCw, size: 14),
                label: const Text(
                  'Get suggestions',
                  style: TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
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
                  final isAISuggested =
                      _styleSuggestions?.occasions.contains(tag) == true ||
                      _styleSuggestions?.styleArchetype?.toLowerCase() == tag;
                  return Chip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(tag),
                        if (isAISuggested) ...[
                          const SizedBox(width: 4),
                          const Icon(LucideIcons.sparkles, size: 10),
                        ],
                      ],
                    ),
                    deleteIcon: const Icon(LucideIcons.x, size: 16),
                    onDeleted: () => _removeTag(tag),
                    backgroundColor:
                        isAISuggested
                            ? AppColors.purple.withOpacity(0.1)
                            : AppColors.teal.withOpacity(0.1),
                  );
                }).toList(),
          ),
        ],

        // Style suggestions quick add
        if (_styleSuggestions?.occasions.isNotEmpty == true) ...[
          const SizedBox(height: 8),
          const Text(
            'Suggested occasions:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children:
                _styleSuggestions!.occasions.take(5).map((occasion) {
                  final isAlreadyAdded = _tags.contains(occasion);
                  return ActionChip(
                    label: Text(occasion, style: const TextStyle(fontSize: 11)),
                    onPressed:
                        isAlreadyAdded
                            ? null
                            : () {
                              setState(() {
                                _tags.add(occasion);
                              });
                            },
                    backgroundColor:
                        isAlreadyAdded
                            ? Colors.grey.withOpacity(0.1)
                            : AppColors.purple.withOpacity(0.1),
                    side: BorderSide(
                      color:
                          isAlreadyAdded
                              ? Colors.grey.withOpacity(0.3)
                              : AppColors.purple.withOpacity(0.3),
                    ),
                  );
                }).toList(),
          ),
        ],
      ],
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
