// lib/widgets/closet/add_item_modal.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fitsyncgemini/constants/app_colors.dart';
import 'package:fitsyncgemini/constants/app_constants.dart';
import 'package:fitsyncgemini/services/camera_service.dart';
import 'package:fitsyncgemini/widgets/closet/image_crop_widget.dart';
import 'package:fitsyncgemini/widgets/closet/manual_tagging_widget.dart';

class AddItemModal extends ConsumerStatefulWidget {
  const AddItemModal({super.key});

  @override
  ConsumerState<AddItemModal> createState() => _AddItemModalState();
}

class _AddItemModalState extends ConsumerState<AddItemModal> {
  File? _selectedImage;
  File? _croppedImage;
  bool _isProcessing = false;
  int _currentStep = 0; // 0: Select, 1: Crop, 2: Tag, 3: Save

  final _nameController = TextEditingController();
  String _selectedCategory = AppConstants.clothingCategories.first;
  List<String> _selectedColors = [];
  List<String> _tags = [];
  String? _brand;
  double? _price;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectImageSource(ImageSource source) async {
    final cameraService = ref.read(cameraServiceProvider);

    setState(() {
      _isProcessing = true;
    });

    try {
      File? imageFile;
      if (source == ImageSource.camera) {
        imageFile = await cameraService.takePhoto();
      } else {
        imageFile = await cameraService.pickFromGallery();
      }

      if (imageFile != null) {
        setState(() {
          _selectedImage = imageFile;
          _currentStep = 1;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to select image: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _onImageCropped(File croppedImage) {
    setState(() {
      _croppedImage = croppedImage;
      _currentStep = 2;
    });
  }

  void _onTaggingComplete(Map<String, dynamic> tagData) {
    setState(() {
      _nameController.text = tagData['name'] ?? '';
      _selectedCategory =
          tagData['category'] ?? AppConstants.clothingCategories.first;
      _selectedColors = List<String>.from(tagData['colors'] ?? []);
      _tags = List<String>.from(tagData['tags'] ?? []);
      _brand = tagData['brand'];
      _price = tagData['price'];
      _currentStep = 3;
    });
  }

  Future<void> _saveItem() async {
    if (_croppedImage == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // TODO: Implement actual save logic with ML analysis
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      _showErrorSnackBar('Failed to save item: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildProgressIndicator(),
          Expanded(child: _buildCurrentStep()),
          if (_isProcessing) _buildProcessingOverlay(),
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
          if (_currentStep > 0)
            IconButton(
              icon: const Icon(LucideIcons.chevronLeft),
              onPressed: () {
                setState(() {
                  _currentStep = _currentStep - 1;
                });
              },
            ),
          Expanded(
            child: Text(
              _getStepTitle(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.x),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LinearProgressIndicator(
        value: (_currentStep + 1) / 4,
        backgroundColor: Colors.grey.shade200,
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.pink),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildSelectImageStep();
      case 1:
        return _buildCropImageStep();
      case 2:
        return _buildTaggingStep();
      case 3:
        return _buildSaveStep();
      default:
        return _buildSelectImageStep();
    }
  }

  Widget _buildSelectImageStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppColors.fitsyncGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.camera,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Add New Item',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Take a photo or upload from gallery',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectImageSource(ImageSource.camera),
                  icon: const Icon(LucideIcons.camera),
                  label: const Text('Take Photo'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _selectImageSource(ImageSource.gallery),
                  icon: const Icon(LucideIcons.upload),
                  label: const Text('Upload'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.pink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(LucideIcons.sparkles, color: AppColors.teal),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI will automatically detect and categorize your item!',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropImageStep() {
    if (_selectedImage == null) return const SizedBox();

    return ImageCropWidget(
      imageFile: _selectedImage!,
      onCropped: _onImageCropped,
    );
  }

  Widget _buildTaggingStep() {
    if (_croppedImage == null) return const SizedBox();

    return ManualTaggingWidget(
      imageFile: _croppedImage!,
      onComplete: _onTaggingComplete,
    );
  }

  Widget _buildSaveStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (_croppedImage != null)
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: FileImage(_croppedImage!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            _nameController.text.isNotEmpty ? _nameController.text : 'New Item',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedCategory,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          if (_selectedColors.isNotEmpty)
            Wrap(
              spacing: 8,
              children:
                  _selectedColors.map((color) {
                    return Chip(
                      label: Text(color),
                      backgroundColor: AppColors.teal.withOpacity(0.1),
                    );
                  }).toList(),
            ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveItem,
              icon: const Icon(LucideIcons.check),
              label: const Text('Add to Closet'),
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

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Processing...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Select Image';
      case 1:
        return 'Crop Image';
      case 2:
        return 'Add Details';
      case 3:
        return 'Review & Save';
      default:
        return 'Add Item';
    }
  }
}

enum ImageSource { camera, gallery }
