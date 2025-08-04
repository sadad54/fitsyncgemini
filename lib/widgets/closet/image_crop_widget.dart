// lib/widgets/closet/image_crop_widget.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fitsyncgemini/constants/app_colors.dart';
import 'package:fitsyncgemini/services/camera_service.dart';

class ImageCropWidget extends ConsumerStatefulWidget {
  final File imageFile;
  final Function(File) onCropped;

  const ImageCropWidget({
    super.key,
    required this.imageFile,
    required this.onCropped,
  });

  @override
  ConsumerState<ImageCropWidget> createState() => _ImageCropWidgetState();
}

class _ImageCropWidgetState extends ConsumerState<ImageCropWidget> {
  bool _isProcessing = false;
  Rect? _cropRect;
  Size _imageSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _loadImageDimensions();
  }

  Future<void> _loadImageDimensions() async {
    try {
      final cameraService = ref.read(cameraServiceProvider);
      final dimensions = await cameraService.getImageDimensions(widget.imageFile);
      setState(() {
        _imageSize = Size(
          dimensions['width']!.toDouble(),
          dimensions['height']!.toDouble(),
        );
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _cropImage() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final cameraService = ref.read(cameraServiceProvider);
      
      File croppedFile;
      if (_cropRect != null) {
        croppedFile = await cameraService.cropAndOptimizeImage(
          widget.imageFile,
          cropX: _cropRect!.left.toInt(),
          cropY: _cropRect!.top.toInt(),
          cropWidth: _cropRect!.width.toInt(),
          cropHeight: _cropRect!.height.toInt(),
        );
      } else {
        croppedFile = await cameraService.cropAndOptimizeImage(widget.imageFile);
      }

      widget.onCropped(croppedFile);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to crop image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    // Image display
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      child: Image.file(
                        widget.imageFile,
                        fit: BoxFit.contain,
                      ),
                    ),
                    // Crop overlay (simplified version)
                    if (_cropRect != null)
                      Positioned.fromRect(
                        rect: _cropRect!,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.pink,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Crop presets
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCropPreset('Square', Icons.crop_square),
              _buildCropPreset('Portrait', Icons.crop_portrait),
              _buildCropPreset('Free', Icons.crop_free),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _cropRect = null;
                    });
                  },
                  icon: const Icon(LucideIcons.rotateCcw),
                  label: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _cropImage,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(LucideIcons.crop),
                  label: Text(_isProcessing ? 'Processing...' : 'Crop & Continue'),
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
    );
  }

  Widget _buildCropPreset(String label, IconData icon) {
    return GestureDetector(
      onTap: () {
        // Implement crop preset logic
        _applyCropPreset(label);
      },
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.pink.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.pink),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _applyCropPreset(String preset) {
    // Simplified crop preset application
    final containerSize = Size(300, 400); // Approximate container size
    
    switch (preset) {
      case 'Square':
        final size = containerSize.width < containerSize.height 
            ? containerSize.width 
            : containerSize.height;
        setState(() {
          _cropRect = Rect.fromLTWH(
            (containerSize.width - size) / 2,
            (containerSize.height - size) / 2,
            size,
            size,
          );
        });
        break;
      case 'Portrait':
        setState(() {
          _cropRect = Rect.fromLTWH(
            containerSize.width * 0.1,
            containerSize.height * 0.05,
            containerSize.width * 0.8,
            containerSize.height * 0.9,
          );
        });
        break;
      case 'Free':
        setState(() {
          _cropRect = null;
        });
        break;
    }
  }
}