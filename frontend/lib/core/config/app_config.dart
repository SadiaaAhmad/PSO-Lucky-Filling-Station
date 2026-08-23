import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const String _keyBaseUrl = 'fastapi_base_url';
  
  // 24/7 Live Cloud API endpoint (bypasses local Wi-Fi & laptop dependency)
  static String baseUrl = 'https://pso-lucky-filling-station.vercel.app';
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
