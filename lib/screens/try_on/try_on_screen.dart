// lib/screens/try_on/try_on_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fitsyncgemini/constants/app_colors.dart';
import 'package:fitsyncgemini/models/virtual_tryon_model.dart';
import 'package:fitsyncgemini/viewmodels/virtual_tryon_viewmodel.dart';
import 'package:fitsyncgemini/widgets/common/loading_indicator.dart';
import 'package:fitsyncgemini/widgets/common/gradient_button.dart';

class TryOnScreen extends ConsumerStatefulWidget {
  const TryOnScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TryOnScreen> createState() => _TryOnScreenState();
}

class _TryOnScreenState extends ConsumerState<TryOnScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      // Check camera permission first
      final cameraPermission = await Permission.camera.request();
      if (cameraPermission != PermissionStatus.granted) {
        debugPrint('Camera permission denied');
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final frontCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );

        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(virtualTryOnViewModelProvider);
    final viewModel = ref.read(virtualTryOnViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header
          _buildHeader(context, state, viewModel),

          // Content
          Expanded(
            child:
                state.isLoading
                    ? const Center(child: LoadingIndicator())
                    : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Virtual Mirror/Camera View
                          _buildCameraView(context, state, viewModel),

                          const SizedBox(height: 24),

                          // Outfit Selection
                          _buildOutfitSelection(context, state, viewModel),

                          const SizedBox(height: 24),

                          // Smart Features
                          _buildSmartFeatures(context, state, viewModel),

                          const SizedBox(height: 24),

                          // Action Buttons
                          _buildActionButtons(context, state, viewModel),

                          const SizedBox(height: 24),

                          // Pro Tips
                          _buildProTips(context),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    VirtualTryOnState state,
    VirtualTryOnViewModel viewModel,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top header with title and actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        Future.microtask(
                          () => Navigator.of(
                            context,
                          ).pushReplacementNamed('/dashboard'),
                        );
                      }
                    },
                    icon: const Icon(Icons.arrow_back),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Virtual Try-On',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'AI-powered fitting room',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showSettings(context, viewModel),
                    icon: const Icon(Icons.settings),
                  ),
                  IconButton(
                    onPressed: () => _shareResult(context, viewModel),
                    icon: const Icon(Icons.share),
                  ),
                ],
              ),
            ),

            // View Mode Toggle
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  _buildViewModeButton(
                    context,
                    'AR View',
                    Icons.camera_alt,
                    ViewMode.ar,
                    state.currentViewMode == ViewMode.ar,
                    AppColors.pink,
                    () => viewModel.switchViewMode(ViewMode.ar),
                  ),
                  const SizedBox(width: 8),
                  _buildViewModeButton(
                    context,
                    'Mirror Mode',
                    Icons.visibility,
                    ViewMode.mirror,
                    state.currentViewMode == ViewMode.mirror,
                    AppColors.teal,
                    () => viewModel.switchViewMode(ViewMode.mirror),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewModeButton(
    BuildContext context,
    String text,
    IconData icon,
    ViewMode mode,
    bool isSelected,
    Color selectedColor,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? selectedColor : Colors.transparent,
            border: Border.all(
              color: isSelected ? selectedColor : Colors.grey[300]!,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraView(
    BuildContext context,
    VirtualTryOnState state,
    VirtualTryOnViewModel viewModel,
  ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2D3748), Color(0xFF1A202C)],
            ),
          ),
          child: Stack(
            children: [
              // Camera preview or placeholder
              if (_isCameraInitialized &&
                  _cameraController != null &&
                  state.currentViewMode == ViewMode.mirror)
                Positioned.fill(child: CameraPreview(_cameraController!))
              else
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Color(0x33000000),
                        Color(0x66000000),
                      ],
                    ),
                  ),
                ),

              // Processing overlay
              if (state.isProcessing)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Processing outfit...',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                        ),
                        if (state.processingProgress > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${(state.processingProgress * 100).round()}%',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.white70),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

              // Top indicators
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.pink,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'AI Active',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (viewModel.currentConfidenceScore != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          '${(viewModel.currentConfidenceScore! * 100).round()}% Fit',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                  ],
                ),
              ),

              // Center placeholder for user positioning
              if (!state.isProcessing)
                Center(
                  child: Container(
                    width: 200,
                    height: 280,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                        style:
                            BorderStyle
                                .values[1], // Dashed would need custom painter
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          color: Colors.white.withOpacity(0.7),
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Position yourself in frame',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.white.withOpacity(0.7)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

              // Bottom controls
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Try-on button
                    GestureDetector(
                      onTap:
                          state.isProcessing
                              ? null
                              : () => _startTryOn(viewModel),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color:
                              state.isProcessing
                                  ? Colors.grey[400]
                                  : AppColors.pink,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.pink.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Rotate button
                    _buildControlButton(
                      icon: Icons.rotate_right,
                      onTap: () => _rotateCamera(),
                    ),

                    const SizedBox(width: 12),

                    // Download button
                    _buildControlButton(
                      icon: Icons.download,
                      onTap: () => _downloadResult(viewModel),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.grey[700], size: 20),
      ),
    );
  }

  Widget _buildOutfitSelection(
    BuildContext context,
    VirtualTryOnState state,
    VirtualTryOnViewModel viewModel,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: AppColors.purple,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Try These Outfits',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...state.outfitSuggestions.asMap().entries.map((entry) {
              final index = entry.key;
              final outfit = entry.value;
              final isSelected = state.selectedOutfitIndex == index;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => viewModel.selectOutfit(index),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? AppColors.pink : Colors.grey[300]!,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color:
                          isSelected ? AppColors.pink.withOpacity(0.05) : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    outfit.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey[400]!,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      outfit.occasion,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                outfit.items.join(' • '),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${(outfit.confidence * 100).round()}%',
                              style: Theme.of(
                                context,
                              ).textTheme.titleSmall?.copyWith(
                                color: AppColors.teal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'match',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartFeatures(
    BuildContext context,
    VirtualTryOnState state,
    VirtualTryOnViewModel viewModel,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Smart Features',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...state.availableFeatures.map((feature) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            feature.name,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            feature.description,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap:
                          () => viewModel.toggleFeature(
                            feature.id,
                            !feature.enabled,
                          ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 40,
                        height: 24,
                        decoration: BoxDecoration(
                          color:
                              feature.enabled
                                  ? AppColors.teal
                                  : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 200),
                          alignment:
                              feature.enabled
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                          child: Container(
                            width: 16,
                            height: 16,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    VirtualTryOnState state,
    VirtualTryOnViewModel viewModel,
  ) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _saveLook(viewModel),
            icon: const Icon(Icons.favorite_border),
            label: const Text('Save Look'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GradientButton(
            onPressed: () => _shareResult(context, viewModel),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.share, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Share Result'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProTips(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.teal.withOpacity(0.1),
              AppColors.blue.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '💡 Pro Tips',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...[
                    '• Stand 3-4 feet away from your camera for best results',
                    '• Ensure good lighting for accurate color representation',
                    '• Try different poses to see how clothes move and fit',
                  ]
                  .map(
                    (tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        tip,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ],
          ),
        ),
      ),
    );
  }

  // Action methods
  void _startTryOn(VirtualTryOnViewModel viewModel) async {
    // Take photo if camera is available
    List<int>? imageBytes;
    if (_isCameraInitialized && _cameraController != null) {
      try {
        final image = await _cameraController!.takePicture();
        imageBytes = await image.readAsBytes();
      } catch (e) {
        debugPrint('Error taking photo: $e');
      }
    }

    await viewModel.startTryOn(userImageBytes: imageBytes);
  }

  void _rotateCamera() {
    // Switch between front and back camera
    // Implementation would require re-initializing camera
  }

  void _downloadResult(VirtualTryOnViewModel viewModel) {
    // Download the try-on result
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download functionality coming soon!')),
    );
  }

  void _saveLook(VirtualTryOnViewModel viewModel) {
    viewModel.rateResult(rating: 5, isFavorite: true);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Look saved to favorites!')));
  }

  void _shareResult(
    BuildContext context,
    VirtualTryOnViewModel viewModel,
  ) async {
    final shareLink = await viewModel.shareResult();
    if (shareLink != null) {
      // Share the link using platform sharing
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Share link: $shareLink')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to generate share link')),
      );
    }
  }

  void _showSettings(BuildContext context, VirtualTryOnViewModel viewModel) {
    // Show settings modal
    showModalBottomSheet(
      context: context,
      builder: (context) => const TryOnSettingsModal(),
    );
  }
}

class TryOnSettingsModal extends ConsumerWidget {
  const TryOnSettingsModal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(virtualTryOnViewModelProvider);
    final viewModel = ref.read(virtualTryOnViewModelProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Try-On Settings',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Quality Settings
          Text(
            'Processing Quality',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SegmentedButton<ProcessingQuality>(
            segments: const [
              ButtonSegment(value: ProcessingQuality.low, label: Text('Fast')),
              ButtonSegment(
                value: ProcessingQuality.medium,
                label: Text('Balanced'),
              ),
              ButtonSegment(value: ProcessingQuality.high, label: Text('Best')),
            ],
            selected: {
              state.userPreferences?.processingQuality ??
                  ProcessingQuality.high,
            },
            onSelectionChanged: (Set<ProcessingQuality> selection) {
              viewModel.updatePreferences(processingQuality: selection.first);
            },
          ),

          const SizedBox(height: 24),

          // Privacy Settings
          SwitchListTile(
            title: const Text('Store Images'),
            subtitle: const Text('Save try-on images for future reference'),
            value: state.userPreferences?.storeImages ?? true,
            onChanged:
                (value) => viewModel.updatePreferences(storeImages: value),
          ),

          SwitchListTile(
            title: const Text('Auto-save Results'),
            subtitle: const Text('Automatically save successful try-ons'),
            value: state.userPreferences?.autoSaveResults ?? true,
            onChanged:
                (value) => viewModel.updatePreferences(autoSaveResults: value),
          ),
        ],
      ),
    );
  }
}
