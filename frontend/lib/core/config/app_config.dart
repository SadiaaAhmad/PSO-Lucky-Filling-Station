import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const String _keyBaseUrl = 'fastapi_base_url';
  
  // ADB reverse forwarded port is http://127.0.0.1:8000 (bypasses Windows Firewall & router isolation)
  static String baseUrl = 'http://127.0.0.1:8000';
  static String get apiBaseUrl => baseUrl;
  
  static const String appName = 'PSO Lucky Filling Station';
  static const String appVersion = 'v1.0.0';

  static Future<void> loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(_keyBaseUrl);
      if (savedUrl != null && savedUrl.isNotEmpty) {
        baseUrl = savedUrl;
      }
    } catch (_) {}
  }

  static Future<void> setBaseUrl(String url) async {
    baseUrl = url;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyBaseUrl, url);
    } catch (_) {}
  }

  static Future<void> setApiBaseUrl(String url) => setBaseUrl(url);
}
