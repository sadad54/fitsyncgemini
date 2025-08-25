import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/api_config.dart';
import 'MLAPI_service.dart';

class BackendApi {
  static Map<String, String> _authHeaders({bool jsonContent = false}) {
    final token = MLAPIService.authToken;
    final base =
        jsonContent
            ? Map<String, String>.from(ApiConfig.defaultJsonHeaders)
            : Map<String, String>.from(ApiConfig.defaultMultipartHeaders);
    if (token != null) {
      base['Authorization'] = 'Bearer $token';
    }
    return base;
  }

  // POST /api/v1/clothing/ (multipart)
  static Future<Map<String, dynamic>> createClothingItem({
    required File image,
    required String name,
    String? category,
    List<String>? colors,
    List<String>? tags,
  }) async {
    final uri = Uri.parse('${ApiConfig.clothingBase}/');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_authHeaders());

    request.fields['name'] = name;
    if (category != null) request.fields['category'] = category;
    if (colors != null) request.fields['colors'] = json.encode(colors);
    if (tags != null) request.fields['tags'] = json.encode(tags);

    final mimeType = _lookupMime(image);
    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        image.path,
        contentType: MediaType(mimeType.item1, mimeType.item2),
      ),
    );

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return Map<String, dynamic>.from(json.decode(resp.body));
    }
    throw HttpException(
      'createClothingItem failed: ${resp.statusCode} ${resp.body}',
    );
  }

  // GET /api/v1/clothing/recommendations/smart
  static Future<Map<String, dynamic>> getSmartRecommendations({
    String occasion = 'casual',
    double? weatherLat,
    double? weatherLon,
    String budgetRange = 'medium',
  }) async {
    final qp = <String, String>{
      'occasion': occasion,
      'budget_range': budgetRange,
    };
    if (weatherLat != null && weatherLon != null) {
      qp['weather_lat'] = weatherLat.toString();
      qp['weather_lon'] = weatherLon.toString();
    }
    final uri = Uri.parse(
      '${ApiConfig.clothingBase}/recommendations/smart',
    ).replace(queryParameters: qp);
    final resp = await http
        .get(uri, headers: _authHeaders(jsonContent: true))
        .timeout(ApiConfig.requestTimeout);
    if (resp.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(resp.body));
    }
    throw HttpException('getSmartRecommendations failed: ${resp.statusCode}');
  }

  // POST /api/v1/tryon/sessions
  static Future<Map<String, dynamic>> createTryOnSession({
    String? sessionName,
    String viewMode = 'ar',
  }) async {
    final uri = Uri.parse('${ApiConfig.tryOnBase}/sessions');
    final req = http.MultipartRequest('POST', uri);
    req.headers.addAll(_authHeaders());
    if (sessionName != null) req.fields['session_name'] = sessionName;
    req.fields['view_mode'] = viewMode;
    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return Map<String, dynamic>.from(json.decode(resp.body));
    }
    throw HttpException(
      'createTryOnSession failed: ${resp.statusCode} ${resp.body}',
    );
  }

  // POST /virtual-tryon/single (basic try-on)
  static Future<Map<String, dynamic>> tryOnSingle({
    required String userId,
    required File personImage,
    required File clothingImage,
    String tryonType = 'full_body',
  }) async {
    final uri = Uri.parse('${ApiConfig.virtualTryOnBase}/single');
    final req = http.MultipartRequest('POST', uri);
    // Virtual try-on router currently doesn't require auth by dependency, so no bearer header
    req.fields['user_id'] = userId;
    req.fields['tryon_type'] = tryonType;
    final pMime = _lookupMime(personImage);
    final cMime = _lookupMime(clothingImage);
    req.files.add(
      await http.MultipartFile.fromPath(
        'person_image',
        personImage.path,
        contentType: MediaType(pMime.item1, pMime.item2),
      ),
    );
    req.files.add(
      await http.MultipartFile.fromPath(
        'clothing_image',
        clothingImage.path,
        contentType: MediaType(cMime.item1, cMime.item2),
      ),
    );

    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return Map<String, dynamic>.from(json.decode(resp.body));
    }
    throw HttpException('tryOnSingle failed: ${resp.statusCode} ${resp.body}');
  }

  // GET /api/v1/weather/current?lat=&lon=
  static Future<Map<String, dynamic>> getCurrentWeather({
    required double lat,
    required double lon,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.weatherBase}/current',
    ).replace(queryParameters: {'lat': lat.toString(), 'lon': lon.toString()});
    final resp = await http
        .get(uri, headers: ApiConfig.defaultJsonHeaders)
        .timeout(ApiConfig.requestTimeout);
    if (resp.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(resp.body));
    }
    throw HttpException('getCurrentWeather failed: ${resp.statusCode}');
  }

  // -------- Community API --------
  static Future<List<dynamic>> getCommunityPosts() async {
    final uri = Uri.parse('${ApiConfig.communityBase}/posts');
    final resp = await http
        .get(uri, headers: _authHeaders(jsonContent: true))
        .timeout(ApiConfig.requestTimeout);
    if (resp.statusCode == 200) {
      return List<dynamic>.from(json.decode(resp.body));
    }
    throw HttpException('getCommunityPosts failed: ${resp.statusCode}');
  }

  static Future<Map<String, dynamic>> createCommunityPost({
    required String content,
    File? image,
  }) async {
    final uri = Uri.parse('${ApiConfig.communityBase}/posts');
    final req = http.MultipartRequest('POST', uri);
    req.headers.addAll(_authHeaders());
    req.fields['content'] = content;
    if (image != null) {
      final m = _lookupMime(image);
      req.files.add(
        await http.MultipartFile.fromPath(
          'image',
          image.path,
          contentType: MediaType(m.item1, m.item2),
        ),
      );
    }
    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return Map<String, dynamic>.from(json.decode(resp.body));
    }
    throw HttpException(
      'createCommunityPost failed: ${resp.statusCode} ${resp.body}',
    );
  }

  static Future<Map<String, dynamic>> likePost(String postId) async {
    final uri = Uri.parse('${ApiConfig.communityBase}/posts/$postId/like');
    final resp = await http
        .post(uri, headers: _authHeaders(jsonContent: true))
        .timeout(ApiConfig.requestTimeout);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return Map<String, dynamic>.from(json.decode(resp.body));
    }
    throw HttpException('likePost failed: ${resp.statusCode}');
  }

  static Future<void> unlikePost(String postId) async {
    final uri = Uri.parse('${ApiConfig.communityBase}/posts/$postId/like');
    final resp = await http
        .delete(uri, headers: _authHeaders(jsonContent: true))
        .timeout(ApiConfig.requestTimeout);
    if (resp.statusCode >= 200 && resp.statusCode < 300) return;
    throw HttpException('unlikePost failed: ${resp.statusCode}');
  }

  // -------- Locations API --------
  static Future<Map<String, dynamic>> getNearby({
    required double lat,
    required double lon,
    int radius = 5000,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/locations/nearby',
    ).replace(
      queryParameters: {
        'lat': lat.toString(),
        'lon': lon.toString(),
        'radius': radius.toString(),
      },
    );
    final resp = await http
        .get(uri, headers: ApiConfig.defaultJsonHeaders)
        .timeout(ApiConfig.requestTimeout);
    if (resp.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(resp.body));
    }
    throw HttpException('getNearby failed: ${resp.statusCode}');
  }

  // -------- Trends API --------
  static Future<List<dynamic>> getTrendsList() async {
    final uri = Uri.parse('${ApiConfig.trendsBase}/');
    final resp = await http
        .get(uri, headers: _authHeaders(jsonContent: true))
        .timeout(ApiConfig.requestTimeout);
    if (resp.statusCode == 200) {
      return List<dynamic>.from(json.decode(resp.body));
    }
    throw HttpException('getTrendsList failed: ${resp.statusCode}');
  }

  static Future<Map<String, dynamic>> getTrendAnalysis() async {
    final uri = Uri.parse('${ApiConfig.trendsBase}/analysis');
    final resp = await http
        .get(uri, headers: _authHeaders(jsonContent: true))
        .timeout(ApiConfig.requestTimeout);
    if (resp.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(resp.body));
    }
    throw HttpException('getTrendAnalysis failed: ${resp.statusCode}');
  }

  // Utility: detect mime type from file extension
  static _Tuple2 _lookupMime(File file) {
    final path = file.path.toLowerCase();
    if (path.endsWith('.png')) return _Tuple2('image', 'png');
    if (path.endsWith('.jpg') || path.endsWith('.jpeg'))
      return _Tuple2('image', 'jpeg');
    if (path.endsWith('.webp')) return _Tuple2('image', 'webp');
    return _Tuple2('application', 'octet-stream');
  }
}

class _Tuple2 {
  final String item1;
  final String item2;
  const _Tuple2(this.item1, this.item2);
}
