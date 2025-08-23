// lib/screens/try_on/try_on_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.background,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with back button
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: scheme.surface,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(LucideIcons.arrowLeft, color: scheme.onSurface),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/dashboard');
                }
              },
            ),
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    LucideIcons.camera,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Virtual Try-On',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(LucideIcons.settings, color: scheme.onSurface),
                onPressed: () => _showSettings(context, viewModel),
              ),
              IconButton(
                icon: Icon(LucideIcons.share2, color: scheme.onSurface),
                onPressed: () => _shareResult(context, viewModel),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [scheme.surface, scheme.surface.withOpacity(0.8)],
                  ),
                ),
              ),
            ),
          ),

          // View Mode Toggle
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: scheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'View Mode',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildViewModeButton(
                          context,
                          'AR View',
                          LucideIcons.camera,
                          ViewMode.ar,
                          state.currentViewMode == ViewMode.ar,
                          AppColors.primary,
                          () => viewModel.switchViewMode(ViewMode.ar),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildViewModeButton(
                          context,
                          'Mirror Mode',
                          LucideIcons.eye,
                          ViewMode.mirror,
                          state.currentViewMode == ViewMode.mirror,
                          AppColors.secondary,
                          () => viewModel.switchViewMode(ViewMode.mirror),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
          ),

          // Camera View
          SliverToBoxAdapter(
            child: _buildCameraView(
              context,
              state,
              viewModel,
            ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
          ),

          // Outfit Selection
          SliverToBoxAdapter(
            child: _buildOutfitSelection(
              context,
              state,
              viewModel,
            ).animate().fadeIn(duration: 300.ms, delay: 200.ms),
          ),

          // Smart Features
          SliverToBoxAdapter(
            child: _buildSmartFeatures(
              context,
              state,
              viewModel,
            ).animate().fadeIn(duration: 300.ms, delay: 300.ms),
          ),

          // Action Buttons
          SliverToBoxAdapter(
            child: _buildActionButtons(
              context,
              state,
              viewModel,
            ).animate().fadeIn(duration: 300.ms, delay: 400.ms),
          ),

          // Pro Tips
          SliverToBoxAdapter(
            child: _buildProTips(
              context,
            ).animate().fadeIn(duration: 300.ms, delay: 500.ms),
          ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : scheme.surfaceVariant,
          border: Border.all(
            color: isSelected ? selectedColor : scheme.outline.withOpacity(0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color:
                  isSelected ? Colors.white : scheme.onSurface.withOpacity(0.7),
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color:
                    isSelected
                        ? Colors.white
                        : scheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView(
    BuildContext context,
    VirtualTryOnState state,
    VirtualTryOnViewModel viewModel,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.2), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [scheme.surface, scheme.surface.withOpacity(0.8)],
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
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
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
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Processing outfit...',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (state.processingProgress > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${(state.processingProgress * 100).round()}%',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                ),
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
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.zap,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'AI Active',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (viewModel.currentConfidenceScore != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surface.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: scheme.outline.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            '${(viewModel.currentConfidenceScore! * 100).round()}% Fit',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
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
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.camera,
                            color: Colors.white.withOpacity(0.7),
                            size: 32,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Position yourself in frame',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.7),
                            ),
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
                                    ? scheme.onSurface.withOpacity(0.3)
                                    : AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            LucideIcons.camera,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Rotate button
                      _buildControlButton(
                        icon: LucideIcons.rotateCcw,
                        onTap: () => _rotateCamera(),
                      ),

                      const SizedBox(width: 16),

                      // Download button
                      _buildControlButton(
                        icon: LucideIcons.download,
                        onTap: () => _downloadResult(viewModel),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: scheme.surface.withOpacity(0.9),
          shape: BoxShape.circle,
          border: Border.all(color: scheme.outline.withOpacity(0.2), width: 1),
        ),
        child: Icon(icon, color: scheme.onSurface, size: 20),
      ),
    );
  }

  Widget _buildOutfitSelection(
    BuildContext context,
    VirtualTryOnState state,
    VirtualTryOnViewModel viewModel,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    LucideIcons.sparkles,
                    color: AppColors.secondary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Try These Outfits',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...state.outfitSuggestions.asMap().entries.map((entry) {
              final index = entry.key;
              final outfit = entry.value;
              final isSelected = state.selectedOutfitIndex == index;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: GestureDetector(
                  onTap: () => viewModel.selectOutfit(index),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color:
                            isSelected
                                ? AppColors.primary
                                : scheme.outline.withOpacity(0.3),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      color:
                          isSelected
                              ? AppColors.primary.withOpacity(0.05)
                              : scheme.surfaceVariant,
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
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: scheme.surface,
                                      border: Border.all(
                                        color: scheme.outline.withOpacity(0.3),
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      outfit.occasion,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: scheme.onSurface.withOpacity(
                                              0.7,
                                            ),
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                outfit.items.join(' • '),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${(outfit.confidence * 100).round()}%',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'match',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurface.withOpacity(0.5),
                              ),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.tertiary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    LucideIcons.brain,
                    color: AppColors.tertiary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Smart Features',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...state.availableFeatures.map((feature) {
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            feature.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            feature.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurface.withOpacity(0.7),
                            ),
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
                        width: 44,
                        height: 24,
                        decoration: BoxDecoration(
                          color:
                              feature.enabled
                                  ? AppColors.success
                                  : scheme.onSurface.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 200),
                          alignment:
                              feature.enabled
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                          child: Container(
                            width: 18,
                            height: 18,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _saveLook(viewModel),
              icon: const Icon(LucideIcons.heart),
              label: const Text('Save Look'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(
                  color: scheme.outline.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _shareResult(context, viewModel),
              icon: const Icon(LucideIcons.share2, size: 18),
              label: const Text('Share Result'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProTips(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.2), width: 1),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.tertiary.withOpacity(0.1),
              AppColors.primary.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.tertiary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      LucideIcons.lightbulb,
                      color: AppColors.tertiary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Pro Tips',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...[
                    'Stand 3-4 feet away from your camera for best results',
                    'Ensure good lighting for accurate color representation',
                    'Try different poses to see how clothes move and fit',
                  ]
                  .map(
                    (tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(top: 8, right: 12),
                            decoration: BoxDecoration(
                              color: AppColors.tertiary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              tip,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ],
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Camera rotation coming soon!')),
    );
  }

  void _downloadResult(VirtualTryOnViewModel viewModel) {
    // Download the try-on result
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Download functionality coming soon!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _saveLook(VirtualTryOnViewModel viewModel) {
    viewModel.rateResult(rating: 5, isFavorite: true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Look saved to favorites!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _shareResult(
    BuildContext context,
    VirtualTryOnViewModel viewModel,
  ) async {
    final shareLink = await viewModel.shareResult();
    if (shareLink != null) {
      // Share the link using platform sharing
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Share link: $shareLink'),
          backgroundColor: AppColors.secondary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to generate share link'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showSettings(BuildContext context, VirtualTryOnViewModel viewModel) {
    // Show settings modal
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Try-On Settings',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),

            // Quality Settings
            Text(
              'Processing Quality',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<ProcessingQuality>(
              segments: const [
                ButtonSegment(
                  value: ProcessingQuality.low,
                  label: Text('Fast'),
                ),
                ButtonSegment(
                  value: ProcessingQuality.medium,
                  label: Text('Balanced'),
                ),
                ButtonSegment(
                  value: ProcessingQuality.high,
                  label: Text('Best'),
                ),
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
              activeColor: AppColors.primary,
            ),

            SwitchListTile(
              title: const Text('Auto-save Results'),
              subtitle: const Text('Automatically save successful try-ons'),
              value: state.userPreferences?.autoSaveResults ?? true,
              onChanged:
                  (value) =>
                      viewModel.updatePreferences(autoSaveResults: value),
              activeColor: AppColors.primary,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
