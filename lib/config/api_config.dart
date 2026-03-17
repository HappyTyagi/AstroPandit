import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // Base URL - Same as Astrologer
  // static const String baseUrl = 'http://192.168.29.235:1234';
  static String get baseUrl => _env('BASE_URL', 'http://192.168.29.235:1234');
  static String get adminSupportMobileNo =>
      _env('ADMIN_MOBILE_NO', '8057700080');
  static String get panditMobileNo => _env('PANDIT_MOBILE_NO', '7852040757');

  // OTP Endpoints
  static const String sendOtp = '/otp/send';
  static const String verifyOtp = '/otp/verify';

  // Pandit endpoints
  static const String panditUpcomingPujas = '/api/pandit/upcoming-pujas';

  // Profile Endpoints
  static const String updateProfile = '/profile/update';
  static const String getProfile = '/profile/get';

  // Headers
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> getAuthHeaders(String token) => {
    ...headers,
    'Authorization': 'Bearer $token',
  };

  static String _env(String key, String fallback) {
    final String raw = dotenv.env[key]?.trim() ?? '';
    return raw.isEmpty ? fallback : raw;
  }
}
