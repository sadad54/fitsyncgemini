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
  static String realDeviceHost = "";

  static String resolveBaseRoot() {
    if (kIsWeb) {
      // When running Flutter Web locally, the browser can hit localhost
      return "http://127.0.0.1:8000";
    }

    if (Platform.isAndroid) {
      // Android emulator special alias to host machine
      return "http://10.0.2.2:8000";
    }

    if (Platform.isIOS ||
        Platform.isMacOS ||
        Platform.isWindows ||
        Platform.isLinux) {
      // iOS Simulator and desktop can use localhost
      return "http://127.0.0.1:8000";
    }

    // Fallback: if you’re on a real device, set your host once
    if (realDeviceHost.isNotEmpty) {
      return "http://$realDeviceHost:8000";
    }

    // Safe default
    return "http://127.0.0.1:8000";
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
  static String get epPoseEstimate =>
      "$apiBase/analyze/pose"; // if your backend uses /analyze/body-type, update this
  static String get epVirtualTryOn => "$apiBase/tryon/generate";
  static String get epRecommendations => "$apiBase/recommend/outfits";
  static String get epModelStatus => "$apiBase/analyze/models/status";

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
}

// Riverpod provider
final mlApiServiceProvider = Provider((ref) => MLAPIService());
