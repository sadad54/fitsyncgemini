// lib/models/virtual_tryon_model.dart

enum ViewMode {
  ar('ar'),
  mirror('mirror');

  const ViewMode(this.value);
  final String value;

  static ViewMode fromString(String value) {
    return ViewMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => ViewMode.ar,
    );
  }
}

enum TryOnStatus {
  pending('pending'),
  processing('processing'),
  completed('completed'),
  failed('failed');

  const TryOnStatus(this.value);
  final String value;

  static TryOnStatus fromString(String value) {
    return TryOnStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TryOnStatus.pending,
    );
  }
}

enum ProcessingQuality {
  low('low'),
  medium('medium'),
  high('high');

  const ProcessingQuality(this.value);
  final String value;

  static ProcessingQuality fromString(String value) {
    return ProcessingQuality.values.firstWhere(
      (quality) => quality.value == value,
      orElse: () => ProcessingQuality.high,
    );
  }
}

class TryOnFeature {
  final String id;
  final String name;
  final String description;
  final bool isPremium;
  final bool isAvailable;
  final bool requiresGpu;
  final bool enabled;

  const TryOnFeature({
    required this.id,
    required this.name,
    required this.description,
    this.isPremium = false,
    this.isAvailable = true,
    this.requiresGpu = false,
    this.enabled = true,
  });

  factory TryOnFeature.fromJson(Map<String, dynamic> json) {
    return TryOnFeature(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      isPremium: json['is_premium'] as bool? ?? false,
      isAvailable: json['is_available'] as bool? ?? true,
      requiresGpu: json['requires_gpu'] as bool? ?? false,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'is_premium': isPremium,
      'is_available': isAvailable,
      'requires_gpu': requiresGpu,
      'enabled': enabled,
    };
  }

  TryOnFeature copyWith({
    String? id,
    String? name,
    String? description,
    bool? isPremium,
    bool? isAvailable,
    bool? requiresGpu,
    bool? enabled,
  }) {
    return TryOnFeature(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isPremium: isPremium ?? this.isPremium,
      isAvailable: isAvailable ?? this.isAvailable,
      requiresGpu: requiresGpu ?? this.requiresGpu,
      enabled: enabled ?? this.enabled,
    );
  }
}

class ClothingItemForTryOn {
  final String id;
  final String name;
  final String category;
  final String imageUrl;
  final String? color;
  final String? size;
  final String? brand;

  const ClothingItemForTryOn({
    required this.id,
    required this.name,
    required this.category,
    required this.imageUrl,
    this.color,
    this.size,
    this.brand,
  });

  factory ClothingItemForTryOn.fromJson(Map<String, dynamic> json) {
    return ClothingItemForTryOn(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      imageUrl: json['image_url'] as String,
      color: json['color'] as String?,
      size: json['size'] as String?,
      brand: json['brand'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'image_url': imageUrl,
      if (color != null) 'color': color,
      if (size != null) 'size': size,
      if (brand != null) 'brand': brand,
    };
  }
}

class FitAnalysisDetail {
  final String itemId;
  final double fitScore;
  final String? sizeRecommendation;
  final List<String> fitIssues;
  final Map<String, double>? measurements;

  const FitAnalysisDetail({
    required this.itemId,
    required this.fitScore,
    this.sizeRecommendation,
    this.fitIssues = const [],
    this.measurements,
  });

  factory FitAnalysisDetail.fromJson(Map<String, dynamic> json) {
    return FitAnalysisDetail(
      itemId: json['item_id'] as String,
      fitScore: (json['fit_score'] as num).toDouble(),
      sizeRecommendation: json['size_recommendation'] as String?,
      fitIssues: List<String>.from(json['fit_issues'] ?? []),
      measurements:
          json['measurements'] != null
              ? Map<String, double>.from(
                (json['measurements'] as Map).map(
                  (key, value) =>
                      MapEntry(key.toString(), (value as num).toDouble()),
                ),
              )
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'fit_score': fitScore,
      if (sizeRecommendation != null) 'size_recommendation': sizeRecommendation,
      'fit_issues': fitIssues,
      if (measurements != null) 'measurements': measurements,
    };
  }
}

class ColorAnalysisDetail {
  final String itemId;
  final double colorAccuracy;
  final bool lightingAdjusted;
  final String? recommendedLighting;

  const ColorAnalysisDetail({
    required this.itemId,
    required this.colorAccuracy,
    this.lightingAdjusted = false,
    this.recommendedLighting,
  });

  factory ColorAnalysisDetail.fromJson(Map<String, dynamic> json) {
    return ColorAnalysisDetail(
      itemId: json['item_id'] as String,
      colorAccuracy: (json['color_accuracy'] as num).toDouble(),
      lightingAdjusted: json['lighting_adjusted'] as bool? ?? false,
      recommendedLighting: json['recommended_lighting'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'color_accuracy': colorAccuracy,
      'lighting_adjusted': lightingAdjusted,
      if (recommendedLighting != null)
        'recommended_lighting': recommendedLighting,
    };
  }
}

class TryOnOutfitAttempt {
  final String id;
  final String sessionId;
  final String outfitName;
  final String? occasion;
  final List<ClothingItemForTryOn> clothingItems;
  final double? confidenceScore;
  final List<FitAnalysisDetail>? fitAnalysis;
  final List<ColorAnalysisDetail>? colorAnalysis;
  final double? styleScore;
  final int? userRating;
  final bool isFavorite;
  final bool isShared;
  final int? processingTimeMs;
  final String? resultImageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const TryOnOutfitAttempt({
    required this.id,
    required this.sessionId,
    required this.outfitName,
    this.occasion,
    required this.clothingItems,
    this.confidenceScore,
    this.fitAnalysis,
    this.colorAnalysis,
    this.styleScore,
    this.userRating,
    this.isFavorite = false,
    this.isShared = false,
    this.processingTimeMs,
    this.resultImageUrl,
    required this.createdAt,
    this.updatedAt,
  });

  factory TryOnOutfitAttempt.fromJson(Map<String, dynamic> json) {
    return TryOnOutfitAttempt(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      outfitName: json['outfit_name'] as String,
      occasion: json['occasion'] as String?,
      clothingItems:
          (json['clothing_items'] as List)
              .map((item) => ClothingItemForTryOn.fromJson(item))
              .toList(),
      confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
      fitAnalysis:
          (json['fit_analysis'] as List?)
              ?.map((analysis) => FitAnalysisDetail.fromJson(analysis))
              .toList(),
      colorAnalysis:
          (json['color_analysis'] as List?)
              ?.map((analysis) => ColorAnalysisDetail.fromJson(analysis))
              .toList(),
      styleScore: (json['style_score'] as num?)?.toDouble(),
      userRating: json['user_rating'] as int?,
      isFavorite: json['is_favorite'] as bool? ?? false,
      isShared: json['is_shared'] as bool? ?? false,
      processingTimeMs: json['processing_time_ms'] as int?,
      resultImageUrl: json['result_image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'outfit_name': outfitName,
      if (occasion != null) 'occasion': occasion,
      'clothing_items': clothingItems.map((item) => item.toJson()).toList(),
      if (confidenceScore != null) 'confidence_score': confidenceScore,
      if (fitAnalysis != null)
        'fit_analysis':
            fitAnalysis!.map((analysis) => analysis.toJson()).toList(),
      if (colorAnalysis != null)
        'color_analysis':
            colorAnalysis!.map((analysis) => analysis.toJson()).toList(),
      if (styleScore != null) 'style_score': styleScore,
      if (userRating != null) 'user_rating': userRating,
      'is_favorite': isFavorite,
      'is_shared': isShared,
      if (processingTimeMs != null) 'processing_time_ms': processingTimeMs,
      if (resultImageUrl != null) 'result_image_url': resultImageUrl,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}

class TryOnSession {
  final String id;
  final int userId;
  final String? sessionName;
  final ViewMode viewMode;
  final TryOnStatus status;
  final double processingProgress;
  final String? errorMessage;
  final String? resultImageUrl;
  final double? confidenceScore;
  final int? processingTimeMs;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final List<TryOnOutfitAttempt>? outfitAttempts;

  const TryOnSession({
    required this.id,
    required this.userId,
    this.sessionName,
    required this.viewMode,
    required this.status,
    required this.processingProgress,
    this.errorMessage,
    this.resultImageUrl,
    this.confidenceScore,
    this.processingTimeMs,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.outfitAttempts,
  });

  factory TryOnSession.fromJson(Map<String, dynamic> json) {
    return TryOnSession(
      id: json['id'] as String,
      userId: json['user_id'] as int,
      sessionName: json['session_name'] as String?,
      viewMode: ViewMode.fromString(json['view_mode'] as String),
      status: TryOnStatus.fromString(json['status'] as String),
      processingProgress: (json['processing_progress'] as num).toDouble(),
      errorMessage: json['error_message'] as String?,
      resultImageUrl: json['result_image_url'] as String?,
      confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
      processingTimeMs: json['processing_time_ms'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
      completedAt:
          json['completed_at'] != null
              ? DateTime.parse(json['completed_at'] as String)
              : null,
      outfitAttempts:
          (json['outfit_attempts'] as List?)
              ?.map((attempt) => TryOnOutfitAttempt.fromJson(attempt))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      if (sessionName != null) 'session_name': sessionName,
      'view_mode': viewMode.value,
      'status': status.value,
      'processing_progress': processingProgress,
      if (errorMessage != null) 'error_message': errorMessage,
      if (resultImageUrl != null) 'result_image_url': resultImageUrl,
      if (confidenceScore != null) 'confidence_score': confidenceScore,
      if (processingTimeMs != null) 'processing_time_ms': processingTimeMs,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      if (outfitAttempts != null)
        'outfit_attempts':
            outfitAttempts!.map((attempt) => attempt.toJson()).toList(),
    };
  }
}

class TryOnPreferences {
  final int id;
  final int userId;
  final ViewMode defaultViewMode;
  final bool autoSaveResults;
  final bool shareAnonymously;
  final Map<String, bool> enabledFeatures;
  final ProcessingQuality processingQuality;
  final int maxProcessingTime;
  final bool storeImages;
  final bool allowAnalytics;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const TryOnPreferences({
    required this.id,
    required this.userId,
    required this.defaultViewMode,
    required this.autoSaveResults,
    required this.shareAnonymously,
    required this.enabledFeatures,
    required this.processingQuality,
    required this.maxProcessingTime,
    required this.storeImages,
    required this.allowAnalytics,
    required this.createdAt,
    this.updatedAt,
  });

  factory TryOnPreferences.fromJson(Map<String, dynamic> json) {
    return TryOnPreferences(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      defaultViewMode: ViewMode.fromString(json['default_view_mode'] as String),
      autoSaveResults: json['auto_save_results'] as bool,
      shareAnonymously: json['share_anonymously'] as bool,
      enabledFeatures: Map<String, bool>.from(json['enabled_features'] as Map),
      processingQuality: ProcessingQuality.fromString(
        json['processing_quality'] as String,
      ),
      maxProcessingTime: json['max_processing_time'] as int,
      storeImages: json['store_images'] as bool,
      allowAnalytics: json['allow_analytics'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'default_view_mode': defaultViewMode.value,
      'auto_save_results': autoSaveResults,
      'share_anonymously': shareAnonymously,
      'enabled_features': enabledFeatures,
      'processing_quality': processingQuality.value,
      'max_processing_time': maxProcessingTime,
      'store_images': storeImages,
      'allow_analytics': allowAnalytics,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}

class QuickOutfitSuggestion {
  final String id;
  final String name;
  final String occasion;
  final List<String> items;
  final double confidence;
  final String? previewImageUrl;
  final int estimatedProcessingTime;

  const QuickOutfitSuggestion({
    required this.id,
    required this.name,
    required this.occasion,
    required this.items,
    required this.confidence,
    this.previewImageUrl,
    required this.estimatedProcessingTime,
  });

  factory QuickOutfitSuggestion.fromJson(Map<String, dynamic> json) {
    return QuickOutfitSuggestion(
      id: json['id'] as String,
      name: json['name'] as String,
      occasion: json['occasion'] as String,
      items: List<String>.from(json['items'] as List),
      confidence: (json['confidence'] as num).toDouble(),
      previewImageUrl: json['preview_image_url'] as String?,
      estimatedProcessingTime: json['estimated_processing_time'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'occasion': occasion,
      'items': items,
      'confidence': confidence,
      if (previewImageUrl != null) 'preview_image_url': previewImageUrl,
      'estimated_processing_time': estimatedProcessingTime,
    };
  }
}

class TryOnProcessingStatus {
  final String sessionId;
  final TryOnStatus status;
  final double progress;
  final int? estimatedCompletionSeconds;
  final String? currentStep;
  final String? errorMessage;

  const TryOnProcessingStatus({
    required this.sessionId,
    required this.status,
    required this.progress,
    this.estimatedCompletionSeconds,
    this.currentStep,
    this.errorMessage,
  });

  factory TryOnProcessingStatus.fromJson(Map<String, dynamic> json) {
    return TryOnProcessingStatus(
      sessionId: json['session_id'] as String,
      status: TryOnStatus.fromString(json['status'] as String),
      progress: (json['progress'] as num).toDouble(),
      estimatedCompletionSeconds: json['estimated_completion_seconds'] as int?,
      currentStep: json['current_step'] as String?,
      errorMessage: json['error_message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'status': status.value,
      'progress': progress,
      if (estimatedCompletionSeconds != null)
        'estimated_completion_seconds': estimatedCompletionSeconds,
      if (currentStep != null) 'current_step': currentStep,
      if (errorMessage != null) 'error_message': errorMessage,
    };
  }
}

class DeviceCapabilities {
  final String? cameraResolution;
  final bool hasDepthSensor;
  final int? cpuCores;
  final double? ramGb;
  final bool gpuAvailable;
  final bool arSupport;
  final String platform;

  const DeviceCapabilities({
    this.cameraResolution,
    required this.hasDepthSensor,
    this.cpuCores,
    this.ramGb,
    required this.gpuAvailable,
    required this.arSupport,
    required this.platform,
  });

  factory DeviceCapabilities.fromJson(Map<String, dynamic> json) {
    return DeviceCapabilities(
      cameraResolution: json['camera_resolution'] as String?,
      hasDepthSensor: json['has_depth_sensor'] as bool,
      cpuCores: json['cpu_cores'] as int?,
      ramGb: (json['ram_gb'] as num?)?.toDouble(),
      gpuAvailable: json['gpu_available'] as bool,
      arSupport: json['ar_support'] as bool,
      platform: json['platform'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (cameraResolution != null) 'camera_resolution': cameraResolution,
      'has_depth_sensor': hasDepthSensor,
      if (cpuCores != null) 'cpu_cores': cpuCores,
      if (ramGb != null) 'ram_gb': ramGb,
      'gpu_available': gpuAvailable,
      'ar_support': arSupport,
      'platform': platform,
    };
  }
}
