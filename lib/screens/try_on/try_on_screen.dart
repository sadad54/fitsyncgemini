import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fitsyncgemini/constants/app_colors.dart';
import 'package:fitsyncgemini/services/MLAPI_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TryOnScreen extends StatefulWidget {
  const TryOnScreen({super.key});

  @override
  State<TryOnScreen> createState() => _TryOnScreenState();
}

class _TryOnScreenState extends State<TryOnScreen> {
  bool _hasUserPhoto = false;
  bool _isProcessing = false;
  File? _userPhoto;
  File? _selectedClothingImage;
  Map<String, dynamic>? _poseAnalysis;
  List<Map<String, dynamic>> _availableClothing = [];

  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text(
          'Virtual Try-On',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.bell),
            onPressed: () => _showHelpDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (!_hasUserPhoto) _buildUploadPhotoCard(),
            if (_hasUserPhoto) _buildTryOnInterface(),
            const SizedBox(height: 20),
            _buildFeaturesInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadPhotoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.user,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Upload Your Photo',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Take or upload a full-body photo to start trying on outfits',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _uploadPhoto('camera'),
                    icon: const Icon(LucideIcons.camera),
                    label: const Text('Take Photo'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _uploadPhoto('gallery'),
                    icon: const Icon(LucideIcons.upload),
                    label: const Text('Upload'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.pink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildTryOnInterface() {
    return Column(
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: Container(
            height: 400,
            width: double.infinity,
            color: Colors.grey.shade100,
            child: Stack(
              children: [
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.user, size: 80, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Your Photo', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                if (_isProcessing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Processing outfit...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Outfit to Try',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child:
                      _availableClothing.isEmpty
                          ? Center(
                            child: Text(
                              'No clothing items available',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          )
                          : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _availableClothing.length,
                            separatorBuilder:
                                (context, index) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final item = _availableClothing[index];
                              return _buildOutfitOption(item, index);
                            },
                          ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _hasUserPhoto = false),
                icon: const Icon(LucideIcons.rotateCcw),
                label: const Text('New Photo'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _tryOnOutfit(),
                icon: const Icon(LucideIcons.play),
                label: const Text('Try On'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pink,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildOutfitOption(Map<String, dynamic> item, int index) {
    final isSelected =
        _selectedClothingImage != null; // You can make this more specific

    return GestureDetector(
      onTap: () {
        // For demo purposes, we'll simulate selecting this clothing item
        // In a real app, you'd need the actual image file from the server
        setState(() {
          // You'd need to download or get the image file here
          // _selectedClothingImage = File(item['image_url']);
        });
        _showSuccessSnackBar('Selected: ${item['name']}');
      },
      child: Container(
        width: 80,
        height: 100,
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.pink.withOpacity(0.2)
                  : AppColors.pink.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isSelected ? AppColors.pink : AppColors.pink.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.shirt,
              color: AppColors.pink,
              size: isSelected ? 24 : 20,
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                item['name'] ?? 'Item',
                style: TextStyle(
                  fontSize: 9,
                  color: AppColors.pink,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesInfo() {
    return Card(
      color: AppColors.teal.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.sparkles, color: AppColors.teal),
                const SizedBox(width: 8),
                const Text(
                  'AI-Powered Try-On',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('• Realistic outfit visualization'),
            const SizedBox(height: 4),
            const Text('• Size and fit prediction'),
            const SizedBox(height: 4),
            const Text('• Color matching analysis'),
            const SizedBox(height: 4),
            const Text('• Save and share your looks'),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadAvailableClothing();
  }

  Future<void> _loadAvailableClothing() async {
    try {
      final items = await MLAPIService.getUserWardrobe(limit: 20);
      setState(() {
        _availableClothing = items;
      });
    } catch (e) {
      print('Failed to load clothing: $e');
    }
  }

  Future<void> _uploadPhoto(String source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        setState(() {
          _userPhoto = file;
          _hasUserPhoto = true;
        });

        // Analyze pose when user uploads photo
        await _analyzePose(file);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to select photo: ${e.toString()}');
    }
  }

  Future<void> _analyzePose(File imageFile) async {
    try {
      setState(() {
        _isProcessing = true;
      });

      final analysis = await MLAPIService.estimateBodyPose(imageFile);
      setState(() {
        _poseAnalysis = analysis;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to analyze pose: ${e.toString()}');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _tryOnOutfit() async {
    if (_userPhoto == null || _selectedClothingImage == null) {
      _showErrorSnackBar('Please select both a photo and clothing item');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await MLAPIService.generateVirtualTryOn(
        _userPhoto!,
        _selectedClothingImage!,
      );

      // Handle the virtual try-on result
      _showSuccessSnackBar('Virtual try-on completed!');
      // You can display the result image or save it
    } catch (e) {
      _showErrorSnackBar('Virtual try-on failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('How to use Virtual Try-On'),
            content: const Text(
              'Upload a clear, full-body photo with good lighting. '
              'Select an outfit from your closet and let our AI show you how it looks!',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ],
          ),
    );
  }
}
