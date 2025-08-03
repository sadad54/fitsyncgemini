import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fitsyncgemini/constants/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TryOnScreen extends StatefulWidget {
  const TryOnScreen({super.key});

  @override
  State<TryOnScreen> createState() => _TryOnScreenState();
}

class _TryOnScreenState extends State<TryOnScreen> {
  bool _hasUserPhoto = false;
  bool _isProcessing = false;

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
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 5,
                    separatorBuilder:
                        (context, index) => const SizedBox(width: 12),
                    itemBuilder: (context, index) => _buildOutfitOption(index),
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

  Widget _buildOutfitOption(int index) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 80,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.pink.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.pink.withOpacity(0.3)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.shirt, color: AppColors.pink),
            SizedBox(height: 4),
            Text(
              'Outfit',
              style: TextStyle(fontSize: 10, color: AppColors.pink),
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

  void _uploadPhoto(String source) {
    // TODO: Implement camera/gallery photo selection
    setState(() {
      _hasUserPhoto = true;
    });
  }

  void _tryOnOutfit() {
    setState(() {
      _isProcessing = true;
    });

    // Simulate processing time
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    });
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
