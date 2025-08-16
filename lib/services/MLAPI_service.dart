import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ---------- Runtime base URL resolution ----------
/// Android emulator can't reach 127.0.0.1 inside the emulator process,
/// so we use 10.0.2.2. Everything else can use localhost.
class ApiConfig {
  /// If you run on a REAL DEVICE, set this to your PC's LAN IP once
  /// (e.g. "192.168.1.45"). Leave empty to use emulator/simulator defaults.
  static String realDeviceHost = "10.20.1.121";
  static bool _printedBase = false;

  static String resolveBaseRoot() {
    if (kIsWeb) {
      // When running Flutter Web locally, the browser can hit localhost
      final base = "http://127.0.0.1:8000";
      if (!_printedBase) {
        // Debug once to confirm device base resolution at runtime
        // ignore: avoid_print
        print("🔧 MLAPI baseRoot resolved: $base");
        _printedBase = true;
      }
      return base;
    }

    // If running on a physical device and a LAN host is configured, prefer it
    if (realDeviceHost.isNotEmpty) {
      final base = "http://$realDeviceHost:8000";
      if (!_printedBase) {
        // ignore: avoid_print
        print("🔧 MLAPI baseRoot resolved: $base");
        _printedBase = true;
      }
      return base;
    }

    if (Platform.isAndroid) {
      // Android emulator special alias to host machine
      final base = "http://10.0.2.2:8000";
      if (!_printedBase) {
        // ignore: avoid_print
        print("🔧 MLAPI baseRoot resolved: $base");
        _printedBase = true;
      }
      return base;
    }

    if (Platform.isIOS ||
        Platform.isMacOS ||
        Platform.isWindows ||
        Platform.isLinux) {
      // iOS Simulator and desktop can use localhost
      final base = "http://127.0.0.1:8000";
      if (!_printedBase) {
        // ignore: avoid_print
        print("🔧 MLAPI baseRoot resolved: $base");
        _printedBase = true;
      }
      return base;
    }

    // Safe default
    final base = "http://127.0.0.1:8000";
    if (!_printedBase) {
      // ignore: avoid_print
      print("🔧 MLAPI baseRoot resolved: $base");
      _printedBase = true;
    }
    return base;
  }
}

class MLAPIService {
  // Root => http://host:8000
  static String get baseRoot => ApiConfig.resolveBaseRoot();

  // API base => http://host:8000/api/v1
  static String get apiBase => "$baseRoot/api/v1";

  // ---- Endpoints (edit here if your backend paths differ) ----
  // Auth
  static String get epRegister => "$apiBase/auth/register";
  static String get epLogin => "$apiBase/auth/login";
  static String get epMe => "$apiBase/auth/me";
  static String get epLogout => "$apiBase/auth/logout";

  // Clothing / Wardrobe
  static String get epClothingUpload => "$apiBase/clothing/upload";
  static String get epClothingCreate => "$apiBase/clothing/create";
  static String get epClothingItems => "$apiBase/clothing/items";
  static String get epWardrobeStats => "$apiBase/clothing/stats/wardrobe";

  // ML / Analyze / Try-on (rename to match your backend if needed)
  static String get epAnalyzeClothing => "$apiBase/analyze/clothing";
  static String get epPoseEstimate => "$apiBase/ml/pose/estimate";
  static String get epVirtualTryOn => "$apiBase/ml/virtual-tryon";
  static String get epRecommendations => "$apiBase/ml/recommendations/outfits";
  static String get epModelStatus => "$apiBase/analyze/models/status";

  // Explore Screen Endpoints
  static String get epExploreCategories => "$apiBase/ml/explore/categories";
  static String get epExploreTrendingStyles =>
      "$apiBase/ml/explore/trending-styles";
  static String get epExploreItems => "$apiBase/ml/explore/items";

  // Trends Screen Endpoints
  static String get epTrendsTrendingNow => "$apiBase/ml/trends/trending-now";
  static String get epTrendsFashionInsights =>
      "$apiBase/ml/trends/fashion-insights";
  static String get epTrendsInfluencerSpotlight =>
      "$apiBase/ml/trends/influencer-spotlight";

  // Nearby Screen Endpoints
  static String get epNearbyPeople => "$apiBase/nearby/people";
  static String get epNearbyEvents => "$apiBase/nearby/events";
  static String get epNearbyHotspots => "$apiBase/nearby/hotspots";
  static String get epNearbyMap => "$apiBase/nearby/map";

  // Virtual Try-On Endpoints
  static String get epTryOnSessions => "$apiBase/tryon/sessions";
  static String get epTryOnDashboard => "$apiBase/tryon/dashboard";
  static String get epTryOnPreferences => "$apiBase/tryon/preferences";
  static String get epTryOnFeatures => "$apiBase/tryon/features";
  static String get epTryOnSuggestions => "$apiBase/tryon/suggestions/quick";
  static String get epTryOnDeviceCapabilities =>
      "$apiBase/tryon/device/capabilities";

  // Quiz and Style Preferences
  static String get epQuizCompletion => "$apiBase/users/quiz-completion";
  static String get epStylePreferences => "$apiBase/users/style-preferences";

  // Health
  static String get epHealth => "$baseRoot/health";

  // ------------------------------------------------------------

  static const Duration _timeout = Duration(seconds: 30);
  static String? _authToken;

  static void setAuthToken(String token) {
    _authToken = token;
  }

  static String? get authToken => _authToken;

  static Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // ---------- Helpers ----------
  static Exception _httpException(
    http.Response r, {
    String fallback = 'Request failed',
  }) {
    try {
      final body = json.decode(r.body);
      final msg = body['error']?['message'] ?? body['detail'] ?? fallback;
      return Exception('$fallback (${r.statusCode}): $msg');
    } catch (_) {
      return Exception('$fallback (${r.statusCode})');
    }
  }

  // ---------- Auth ----------
  static Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String username,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final r = await http
          .post(
            Uri.parse(epRegister),
            headers: _headers,
            body: json.encode({
              'email': email,
              'password': password,
              'confirm_password': password, // Add this field
              'username': username,
              'first_name': firstName, // Changed from firstName
              'last_name': lastName, // Changed from lastName
            }),
          )
          .timeout(_timeout);

      if (r.statusCode == 201) {
        return json.decode(r.body);
      }
      throw _httpException(r, fallback: 'Registration failed');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final r = await http
          .post(
            Uri.parse(epLogin),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'email': email, 'password': password}),
          )
          .timeout(_timeout);

      if (r.statusCode == 200) {
        final result = json.decode(r.body);
        print('🔍 MLAPIService: Login response: $result');
        if (result['access_token'] != null) {
          setAuthToken(result['access_token']);
        }
        return result;
      }
      throw _httpException(r, fallback: 'Login failed');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final r = await http
          .get(Uri.parse(epMe), headers: _headers)
          .timeout(_timeout);
      if (r.statusCode == 200) return json.decode(r.body);
      throw _httpException(r, fallback: 'Failed to get user info');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<void> logout() async {
    try {
      await http.post(Uri.parse(epLogout), headers: _headers).timeout(_timeout);
    } catch (_) {
      // ignore
    } finally {
      _authToken = null;
    }
  }

  // ---------- Clothing ----------
  static Future<Map<String, dynamic>> uploadClothingItem({
    required File imageFile,
    required String name,
    required String category,
    required String subcategory,
    required String color,
    String? brand,
    String? size,
    double? price,
    String? season,
    String? occasion,
  }) async {
    try {
      final req = http.MultipartRequest('POST', Uri.parse(epClothingUpload));
      req.headers.addAll(_headers);

      req.fields['name'] = name;
      req.fields['category'] = category;
      req.fields['subcategory'] = subcategory;
      req.fields['color'] = color;
      if (brand != null) req.fields['brand'] = brand;
      if (size != null) req.fields['size'] = size;
      if (price != null) req.fields['price'] = price.toString();
      if (season != null) req.fields['season'] = season;
      if (occasion != null) req.fields['occasion'] = occasion;

      req.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      final res = await req.send().timeout(_timeout);
      final body = await res.stream.bytesToString();

      if (res.statusCode == 201) {
        return json.decode(body);
      }
      return Future.error(
        _httpException(
          http.Response(body, res.statusCode),
          fallback: 'Upload failed',
        ),
      );
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> createClothingItem({
    required String name,
    required String category,
    required String subcategory,
    required String color,
    String? colorHex,
    String? pattern,
    String? material,
    String? brand,
    String? size,
    double? price,
    String? imageUrl,
    List<String>? seasons,
    List<String>? occasions,
    List<String>? styleTags,
    String? fitType,
    String? neckline,
    String? sleeveType,
    String? length,
  }) async {
    try {
      final data = <String, dynamic>{
        'name': name,
        'category': category,
        'subcategory': subcategory,
        'color': color,
      };

      if (colorHex != null) data['color_hex'] = colorHex;
      if (pattern != null) data['pattern'] = pattern;
      if (material != null) data['material'] = material;
      if (brand != null) data['brand'] = brand;
      if (size != null) data['size'] = size;
      if (price != null) data['price'] = price;
      if (imageUrl != null) data['image_url'] = imageUrl;
      if (seasons != null) data['seasons'] = seasons;
      if (occasions != null) data['occasions'] = occasions;
      if (styleTags != null) data['style_tags'] = styleTags;
      if (fitType != null) data['fit_type'] = fitType;
      if (neckline != null) data['neckline'] = neckline;
      if (sleeveType != null) data['sleeve_type'] = sleeveType;
      if (length != null) data['length'] = length;

      final r = await http
          .post(
            Uri.parse(epClothingCreate),
            headers: _headers,
            body: json.encode(data),
          )
          .timeout(_timeout);

      if (r.statusCode == 201) {
        return json.decode(r.body);
      }
      throw _httpException(r, fallback: 'Failed to create clothing item');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getUserWardrobe({
    String? category,
    String? color,
    String? season,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final qp = <String, String>{'limit': '$limit', 'offset': '$offset'};
      if (category != null) qp['category'] = category;
      if (color != null) qp['color'] = color;
      if (season != null) qp['season'] = season;

      final uri = Uri.parse(epClothingItems).replace(queryParameters: qp);
      final r = await http.get(uri, headers: _headers).timeout(_timeout);
      if (r.statusCode == 200) {
        final List<dynamic> items = json.decode(r.body);
        return items.cast<Map<String, dynamic>>();
      }
      throw _httpException(r, fallback: 'Failed to fetch wardrobe');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getWardrobeStats() async {
    try {
      final r = await http
          .get(Uri.parse(epWardrobeStats), headers: _headers)
          .timeout(_timeout);
      if (r.statusCode == 200) return json.decode(r.body);
      throw _httpException(r, fallback: 'Failed to fetch stats');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ---------- ML / Analyze / Try-on ----------
  static Future<Map<String, dynamic>> analyzeClothingImage(
    File imageFile,
  ) async {
    try {
      final req = http.MultipartRequest('POST', Uri.parse(epAnalyzeClothing));
      req.headers.addAll(_headers);
      // Make sure your backend expects field name 'file' or change here to match
      req.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final res = await req.send().timeout(_timeout);
      final body = await res.stream.bytesToString();
      if (res.statusCode == 200) return json.decode(body);
      return Future.error(
        _httpException(
          http.Response(body, res.statusCode),
          fallback: 'Analysis failed',
        ),
      );
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ---------- Quiz and Style Preferences ----------
  static Future<Map<String, dynamic>> completeQuiz(
    Map<String, dynamic> quizAnswers,
  ) async {
    try {
      print('🔍 MLAPIService: completeQuiz called with answers: $quizAnswers');
      print(
        '🔍 MLAPIService: Auth token: ${_authToken != null ? 'exists' : 'null'}',
      );
      print('🔍 MLAPIService: Headers: $_headers');

      final r = await http
          .post(
            Uri.parse(epQuizCompletion),
            headers: _headers,
            body: json.encode(quizAnswers),
          )
          .timeout(_timeout);

      print('🔍 MLAPIService: Response status: ${r.statusCode}');
      print('🔍 MLAPIService: Response body: ${r.body}');

      if (r.statusCode == 201) {
        return json.decode(r.body);
      }
      throw _httpException(r, fallback: 'Quiz completion failed');
    } catch (e) {
      print('❌ MLAPIService: Error in completeQuiz: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getStylePreferences() async {
    try {
      final r = await http
          .get(Uri.parse(epStylePreferences), headers: _headers)
          .timeout(_timeout);
      if (r.statusCode == 200) return json.decode(r.body);
      throw _httpException(r, fallback: 'Failed to get style preferences');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> estimateBodyPose(File imageFile) async {
    try {
      final req = http.MultipartRequest('POST', Uri.parse(epPoseEstimate));
      req.headers.addAll(_headers);
      req.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final res = await req.send().timeout(_timeout);
      final body = await res.stream.bytesToString();
      if (res.statusCode == 200) return json.decode(body);
      return Future.error(
        _httpException(
          http.Response(body, res.statusCode),
          fallback: 'Pose estimation failed',
        ),
      );
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> generateVirtualTryOn(
    File personImage,
    File clothingImage,
  ) async {
    try {
      final req = http.MultipartRequest('POST', Uri.parse(epVirtualTryOn));
      req.headers.addAll(_headers);
      req.files.add(
        await http.MultipartFile.fromPath('person_image', personImage.path),
      );
      req.files.add(
        await http.MultipartFile.fromPath('clothing_image', clothingImage.path),
      );

      final res = await req.send().timeout(_timeout);
      final body = await res.stream.bytesToString();
      if (res.statusCode == 200) return json.decode(body);
      return Future.error(
        _httpException(
          http.Response(body, res.statusCode),
          fallback: 'Virtual try-on failed',
        ),
      );
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getRecommendations({
    Map<String, dynamic>? context,
  }) async {
    try {
      final qp = <String, String>{};
      if (context != null) qp['context'] = json.encode(context);

      final uri = Uri.parse(
        epRecommendations,
      ).replace(queryParameters: qp.isNotEmpty ? qp : null);
      final r = await http.get(uri, headers: _headers).timeout(_timeout);
      if (r.statusCode == 200) return json.decode(r.body);
      throw _httpException(r, fallback: 'Recommendations failed');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getModelStatus() async {
    try {
      final r = await http
          .get(Uri.parse(epModelStatus), headers: _headers)
          .timeout(_timeout);
      if (r.statusCode == 200) return json.decode(r.body);
      throw _httpException(r, fallback: 'Failed to get model status');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ---------- Health ----------
  static Future<Map<String, dynamic>> healthCheck() async {
    try {
      final r = await http
          .get(Uri.parse(epHealth), headers: {'Accept': 'application/json'})
          .timeout(_timeout);
      if (r.statusCode == 200) return json.decode(r.body);
      throw _httpException(r, fallback: 'Health check failed');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ---------- Explore Screen Methods ----------
  static Future<List<String>> getCategories() async {
    try {
      final r = await http
          .get(Uri.parse(epExploreCategories), headers: _headers)
          .timeout(_timeout);
      if (r.statusCode == 200) {
        final result = json.decode(r.body);
        return List<String>.from(result['categories']);
      }
      throw _httpException(r, fallback: 'Failed to get categories');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getTrendingStyles({
    int limit = 10,
  }) async {
    try {
      final qp = <String, String>{'limit': '$limit'};
      final uri = Uri.parse(
        epExploreTrendingStyles,
      ).replace(queryParameters: qp);
      final r = await http.get(uri, headers: _headers).timeout(_timeout);
      if (r.statusCode == 200) return json.decode(r.body);
      throw _httpException(r, fallback: 'Failed to get trending styles');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getExploreItems({
    String? category,
    bool? trending,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final qp = <String, String>{'limit': '$limit', 'offset': '$offset'};
      if (category != null) qp['category'] = category;
      if (trending != null) qp['trending'] = '$trending';

      final uri = Uri.parse(epExploreItems).replace(queryParameters: qp);
      final r = await http.get(uri, headers: _headers).timeout(_timeout);
      if (r.statusCode == 200) return json.decode(r.body);
      throw _httpException(r, fallback: 'Failed to get explore items');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ---------- Trends Screen Methods ----------
  static Future<Map<String, dynamic>> getTrendingNow({
    String scope = 'global',
    String timeframe = 'week',
    int limit = 10,
  }) async {
    try {
      final qp = <String, String>{
        'scope': scope,
        'timeframe': timeframe,
        'limit': '$limit',
      };
      final uri = Uri.parse(epTrendsTrendingNow).replace(queryParameters: qp);
      final r = await http.get(uri, headers: _headers).timeout(_timeout);
      if (r.statusCode == 200) return json.decode(r.body);
      throw _httpException(r, fallback: 'Failed to get trending items');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getFashionInsights({
    String scope = 'global',
    String timeframe = 'week',
  }) async {
    try {
      final qp = <String, String>{'scope': scope, 'timeframe': timeframe};
      final uri = Uri.parse(
        epTrendsFashionInsights,
      ).replace(queryParameters: qp);
      final r = await http.get(uri, headers: _headers).timeout(_timeout);
      if (r.statusCode == 200) return json.decode(r.body);
      throw _httpException(r, fallback: 'Failed to get fashion insights');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getInfluencerSpotlight({
    String scope = 'global',
    int limit = 10,
  }) async {
    try {
      final qp = <String, String>{'scope': scope, 'limit': '$limit'};
      final uri = Uri.parse(
        epTrendsInfluencerSpotlight,
      ).replace(queryParameters: qp);
      final r = await http.get(uri, headers: _headers).timeout(_timeout);
      if (r.statusCode == 200) return json.decode(r.body);
      throw _httpException(r, fallback: 'Failed to get influencer spotlight');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ---------- Nearby Screen Methods (Map-ready) ----------
  static Future<Map<String, dynamic>> getNearbyPeople({
    required double lat,
    required double lng,
    double radiusKm = 5.0,
    int limit = 20,
  }) async {
    try {
      final qp = <String, String>{
        'lat': '$lat',
        'lng': '$lng',
        'radius_km': '$radiusKm',
        'limit': '$limit',
      };
      final uri = Uri.parse(epNearbyPeople).replace(queryParameters: qp);
      final r = await http.get(uri, headers: _headers).timeout(_timeout);
      if (r.statusCode == 200) return json.decode(r.body);
      throw _httpException(r, fallback: 'Failed to get nearby people');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getNearbyEvents({
    required double lat,
    required double lng,
    double radiusKm = 5.0,
    int limit = 20,
  }) async {
    try {
      final qp = <String, String>{
        'lat': '$lat',
        'lng': '$lng',
        'radius_km': '$radiusKm',
        'limit': '$limit',
      };
      final uri = Uri.parse(epNearbyEvents).replace(queryParameters: qp);
      final r = await http.get(uri, headers: _headers).timeout(_timeout);
      if (r.statusCode == 200) return json.decode(r.body);
      throw _httpException(r, fallback: 'Failed to get nearby events');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getHotspots({
    required double lat,
    required double lng,
    double radiusKm = 5.0,
    int limit = 20,
  }) async {
    try {
      final qp = <String, String>{
        'lat': '$lat',
        'lng': '$lng',
        'radius_km': '$radiusKm',
        'limit': '$limit',
      };
      final uri = Uri.parse(epNearbyHotspots).replace(queryParameters: qp);
      final r = await http.get(uri, headers: _headers).timeout(_timeout);
      if (r.statusCode == 200) return json.decode(r.body);
      throw _httpException(r, fallback: 'Failed to get hotspots');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getNearbyMap({
    required double lat,
    required double lng,
    double radiusKm = 5.0,
    int limitPeople = 10,
    int limitEvents = 10,
    int limitHotspots = 10,
  }) async {
    try {
      final qp = <String, String>{
        'lat': '$lat',
        'lng': '$lng',
        'radius_km': '$radiusKm',
        'limit_people': '$limitPeople',
        'limit_events': '$limitEvents',
        'limit_hotspots': '$limitHotspots',
      };
      final uri = Uri.parse(epNearbyMap).replace(queryParameters: qp);
      final r = await http.get(uri, headers: _headers).timeout(_timeout);
      if (r.statusCode == 200) return json.decode(r.body);
      throw _httpException(r, fallback: 'Failed to get nearby map data');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ============================================================================
  // VIRTUAL TRY-ON METHODS
  // ============================================================================

  /// Create a new virtual try-on session
  static Future<Map<String, dynamic>> createTryOnSession({
    String? sessionName,
    String viewMode = 'ar',
    Map<String, dynamic>? deviceInfo,
  }) async {
    try {
      final body = {
        if (sessionName != null) 'session_name': sessionName,
        'view_mode': viewMode,
        if (deviceInfo != null) 'device_info': deviceInfo,
      };

      final r = await http
          .post(
            Uri.parse(epTryOnSessions),
            headers: _headers,
            body: json.encode(body),
          )
          .timeout(_timeout);

      if (r.statusCode == 200) {
        return json.decode(r.body);
      }
      throw _httpException(r, fallback: 'Failed to create try-on session');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get try-on dashboard data
  static Future<Map<String, dynamic>> getTryOnDashboard() async {
    try {
      final r = await http
          .get(Uri.parse(epTryOnDashboard), headers: _headers)
          .timeout(_timeout);

      if (r.statusCode == 200) {
        return json.decode(r.body);
      }
      throw _httpException(r, fallback: 'Failed to get dashboard');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get user's try-on preferences
  static Future<Map<String, dynamic>> getTryOnPreferences() async {
    try {
      final r = await http
          .get(Uri.parse(epTryOnPreferences), headers: _headers)
          .timeout(_timeout);

      if (r.statusCode == 200) {
        return json.decode(r.body);
      }
      throw _httpException(r, fallback: 'Failed to get preferences');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Update user's try-on preferences
  static Future<Map<String, dynamic>> updateTryOnPreferences({
    String? defaultViewMode,
    bool? autoSaveResults,
    bool? shareAnonymously,
    Map<String, bool>? enabledFeatures,
    String? processingQuality,
    int? maxProcessingTime,
    bool? storeImages,
    bool? allowAnalytics,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (defaultViewMode != null) body['default_view_mode'] = defaultViewMode;
      if (autoSaveResults != null) body['auto_save_results'] = autoSaveResults;
      if (shareAnonymously != null)
        body['share_anonymously'] = shareAnonymously;
      if (enabledFeatures != null) body['enabled_features'] = enabledFeatures;
      if (processingQuality != null)
        body['processing_quality'] = processingQuality;
      if (maxProcessingTime != null)
        body['max_processing_time'] = maxProcessingTime;
      if (storeImages != null) body['store_images'] = storeImages;
      if (allowAnalytics != null) body['allow_analytics'] = allowAnalytics;

      final r = await http
          .put(
            Uri.parse(epTryOnPreferences),
            headers: _headers,
            body: json.encode(body),
          )
          .timeout(_timeout);

      if (r.statusCode == 200) {
        return json.decode(r.body);
      }
      throw _httpException(r, fallback: 'Failed to update preferences');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get available try-on features
  static Future<List<Map<String, dynamic>>> getTryOnFeatures() async {
    try {
      final r = await http
          .get(Uri.parse(epTryOnFeatures), headers: _headers)
          .timeout(_timeout);

      if (r.statusCode == 200) {
        final result = json.decode(r.body);
        return List<Map<String, dynamic>>.from(result['features']);
      }
      throw _httpException(r, fallback: 'Failed to get features');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get quick outfit suggestions for try-on
  static Future<List<Map<String, dynamic>>> getTryOnSuggestions({
    int limit = 3,
    String? occasion,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        if (occasion != null) 'occasion': occasion,
      };

      final uri = Uri.parse(
        epTryOnSuggestions,
      ).replace(queryParameters: queryParams);
      final r = await http.get(uri, headers: _headers).timeout(_timeout);

      if (r.statusCode == 200) {
        final List<dynamic> result = json.decode(r.body);
        return List<Map<String, dynamic>>.from(result);
      }
      throw _httpException(r, fallback: 'Failed to get suggestions');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Add outfit to try-on session
  static Future<Map<String, dynamic>> addOutfitToSession({
    required String sessionId,
    required String outfitName,
    String? occasion,
    required List<Map<String, dynamic>> clothingItems,
  }) async {
    try {
      final body = {
        'outfit_name': outfitName,
        if (occasion != null) 'occasion': occasion,
        'clothing_items': clothingItems,
      };

      final r = await http
          .post(
            Uri.parse('$epTryOnSessions/$sessionId/outfits'),
            headers: _headers,
            body: json.encode(body),
          )
          .timeout(_timeout);

      if (r.statusCode == 200) {
        return json.decode(r.body);
      }
      throw _httpException(r, fallback: 'Failed to add outfit');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Process virtual try-on for an outfit
  static Future<Map<String, dynamic>> processOutfitTryOn({
    required String sessionId,
    required String attemptId,
    List<int>? imageBytes,
  }) async {
    try {
      final uri = Uri.parse(
        '$epTryOnSessions/$sessionId/outfits/$attemptId/process',
      );

      if (imageBytes != null) {
        final request = http.MultipartRequest('POST', uri);
        request.headers.addAll(_headers);
        request.files.add(
          http.MultipartFile.fromBytes(
            'user_image',
            imageBytes,
            filename: 'user_photo.jpg',
          ),
        );

        final response = await request.send().timeout(_timeout);
        final responseBody = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          return json.decode(responseBody);
        }
        throw Exception('Failed to process try-on: ${response.statusCode}');
      } else {
        final r = await http.post(uri, headers: _headers).timeout(_timeout);

        if (r.statusCode == 200) {
          return json.decode(r.body);
        }
        throw _httpException(r, fallback: 'Failed to process try-on');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get processing status for outfit attempt
  static Future<Map<String, dynamic>> getTryOnProcessingStatus({
    required String sessionId,
    required String attemptId,
  }) async {
    try {
      final r = await http
          .get(
            Uri.parse('$epTryOnSessions/$sessionId/outfits/$attemptId/status'),
            headers: _headers,
          )
          .timeout(_timeout);

      if (r.statusCode == 200) {
        return json.decode(r.body);
      }
      throw _httpException(r, fallback: 'Failed to get status');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Rate an outfit attempt
  static Future<Map<String, dynamic>> rateOutfitAttempt({
    required String sessionId,
    required String attemptId,
    required int rating,
    bool isFavorite = false,
  }) async {
    try {
      final queryParams = {
        'rating': rating.toString(),
        'is_favorite': isFavorite.toString(),
      };

      final uri = Uri.parse(
        '$epTryOnSessions/$sessionId/outfits/$attemptId/rate',
      ).replace(queryParameters: queryParams);

      final r = await http.post(uri, headers: _headers).timeout(_timeout);

      if (r.statusCode == 200) {
        return json.decode(r.body);
      }
      throw _httpException(r, fallback: 'Failed to rate outfit');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Share try-on session
  static Future<Map<String, dynamic>> shareTryOnSession({
    required String sessionId,
    Map<String, dynamic>? shareOptions,
  }) async {
    try {
      final body = shareOptions ?? {};

      final r = await http
          .post(
            Uri.parse('$epTryOnSessions/$sessionId/share'),
            headers: _headers,
            body: json.encode(body),
          )
          .timeout(_timeout);

      if (r.statusCode == 200) {
        return json.decode(r.body);
      }
      throw _httpException(r, fallback: 'Failed to share session');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}

// Riverpod provider
final mlApiServiceProvider = Provider((ref) => MLAPIService());
