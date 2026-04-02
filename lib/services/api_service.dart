import 'dart:convert';
import 'package:http/http.dart' as http;

/// Master configuration for API services.
/// ⚠️  To switch to production, change baseUrl here only.
class ApiConfig {
  static const String baseUrl = 'http://192.168.1.139:8000/api/v1';

  /// Helper to attach authorization headers
  static Map<String, String> authHeaders(String? token) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }
}

/// Helper method to process raw HTTP responses
Map<String, dynamic> _processResponse(http.Response response) {
  if (response.statusCode >= 200 && response.statusCode < 300) {
    if (response.body.isEmpty) return {};
    return jsonDecode(response.body) as Map<String, dynamic>;
  } else {
    throw Exception('API Error: ${response.statusCode} - ${response.body}');
  }
}

// ==========================================
// 1. Auth Service (/api/v1/auth)
// ==========================================
class AuthService {
  static const String _basePath = '${ApiConfig.baseUrl}/auth';

  /// POST /login
  /// Authenticates the user and returns a JWT.
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_basePath/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    return _processResponse(response);
  }

  /// POST /forgot-password
  /// Triggers a password reset flow (e.g., sends an email link).
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$_basePath/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
      }),
    );
    return _processResponse(response);
  }
}

// ==========================================
// 2. Social Metrics Service (/api/v1/social)
// ==========================================
class SocialService {
  static const String _basePath = '${ApiConfig.baseUrl}/social';

  /// GET /feed
  /// Fetches a paginated list of financial stories and user activities.
  static Future<Map<String, dynamic>> getFeed({required String token, int page = 1}) async {
    final uri = Uri.parse('$_basePath/feed').replace(queryParameters: {
      'page': page.toString(),
    });
    
    final response = await http.get(
      uri,
      headers: ApiConfig.authHeaders(token),
    );
    return _processResponse(response);
  }

  /// POST /likes
  /// Toggles a like on a specific story or metric.
  static Future<Map<String, dynamic>> toggleLike(String storyId, {required String token}) async {
    final response = await http.post(
      Uri.parse('$_basePath/likes'),
      headers: ApiConfig.authHeaders(token),
      body: jsonEncode({
        'story_id': storyId,
        'action': 'like',
      }),
    );
    return _processResponse(response);
  }

  /// POST /shares
  /// Records that a user shared a story externally.
  static Future<Map<String, dynamic>> recordShare(String storyId, String platform, {required String token}) async {
    final response = await http.post(
      Uri.parse('$_basePath/shares'),
      headers: ApiConfig.authHeaders(token),
      body: jsonEncode({
        'story_id': storyId,
        'platform': platform,
      }),
    );
    return _processResponse(response);
  }

  /// GET /templates
  /// Fetches dynamic "Financial Story" templates for the user to generate content.
  static Future<Map<String, dynamic>> getTemplates({required String token}) async {
    final response = await http.get(
      Uri.parse('$_basePath/templates'),
      headers: ApiConfig.authHeaders(token),
    );
    return _processResponse(response);
  }
}

// ==========================================
// 3. Referral Service (/api/v1/referrals)
// ==========================================
class ReferralService {
  static const String _basePath = '${ApiConfig.baseUrl}/referrals';

  /// GET /my-link
  /// Retrieves the authenticated user's unique referral link.
  static Future<Map<String, dynamic>> getMyLink({required String token}) async {
    final response = await http.get(
      Uri.parse('$_basePath/my-link'),
      headers: ApiConfig.authHeaders(token),
    );
    return _processResponse(response);
  }

  /// GET /rewards
  /// Fetches the user's earned rewards and pending referral status.
  static Future<Map<String, dynamic>> getRewards({required String token}) async {
    final response = await http.get(
      Uri.parse('$_basePath/rewards'),
      headers: ApiConfig.authHeaders(token),
    );
    return _processResponse(response);
  }
}
