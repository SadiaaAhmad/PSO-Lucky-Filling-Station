import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/config/app_config.dart';
import 'package:frontend/core/utils/app_logger.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiClient {
  static final http.Client _client = http.Client();
  static bool _isAutoDiscovering = false;

  /// Candidate URLs for automatic discovery (cloud server first, then local/LAN)
  static List<String> get _candidateUrls => [
    'https://pso-lucky-filling-station.vercel.app', // 24/7 Live Cloud Server
    AppConfig.baseUrl,
    'http://127.0.0.1:8000', // ADB reverse local fallback
    'http://192.168.1.4:8000', // Host PC Wi-Fi
    'http://10.0.2.2:8000', // Android Emulator bridge
  ];

  /// Automatically discovers the active FastAPI backend on the local network
  static Future<String?> autoDiscoverBackend() async {
    if (AppConfig.baseUrl.startsWith('https://')) return AppConfig.baseUrl;
    if (_isAutoDiscovering) return AppConfig.baseUrl;
    _isAutoDiscovering = true;

    try {
      final futures = _candidateUrls.map((url) async {
        try {
          final uri = Uri.parse('$url/health');
          final res = await _client.get(uri).timeout(const Duration(milliseconds: 1500));
          if (res.statusCode == 200 && res.body.contains('healthy')) {
            return url;
          }
        } catch (_) {}
        return null;
      }).toList();

      final results = await Future.wait(futures);
      for (final activeUrl in results) {
        if (activeUrl != null) {
          await AppConfig.setBaseUrl(activeUrl);
          _isAutoDiscovering = false;
          return activeUrl;
        }
      }
    } catch (_) {}

    _isAutoDiscovering = false;
    return null;
  }

  /// Tests connectivity to current baseUrl health endpoint
  static Future<bool> testConnection() async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/health');
      final res = await _client.get(uri).timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Uri _buildUri(String path, [Map<String, dynamic>? queryParams]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final urlStr = '${AppConfig.baseUrl}$cleanPath';
    final uri = Uri.parse(urlStr);
    if (queryParams != null && queryParams.isNotEmpty) {
      final map = queryParams.map((k, v) => MapEntry(k, v.toString()));
      return uri.replace(queryParameters: map);
    }
    return uri;
  }

  static Future<dynamic> get(String path, [Map<String, dynamic>? queryParams]) async {
    AppLogger.api('GET Request', {'path': path, 'queryParams': queryParams});
    try {
      final uri = _buildUri(path, queryParams);
      final response = await _client.get(uri, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 10));
      
      AppLogger.api('GET Response', {'path': path, 'statusCode': response.statusCode});
      return _processResponse(response);
    } catch (e) {
      AppLogger.error('GET Error', {'path': path, 'error': e.toString()});
      if (e is! ApiException) {
        // Self-healing: scan for active backend on LAN / ADB reverse if current connection failed
        final discovered = await autoDiscoverBackend();
        if (discovered != null) {
          try {
            final retryUri = _buildUri(path, queryParams);
            final response = await _client.get(retryUri, headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            }).timeout(const Duration(seconds: 10));
            AppLogger.api('GET Retry Success', {'path': path, 'statusCode': response.statusCode});
            return _processResponse(response);
          } catch (_) {}
        }
      }
      if (e is ApiException) rethrow;
      throw ApiException(
        500,
        'Cannot connect to backend server at ${AppConfig.baseUrl}.\n'
        'Ensure FastAPI server is running on your network.',
      );
    }
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body) async {
    AppLogger.api('POST Request', {'path': path, 'body': body});
    try {
      final uri = _buildUri(path);
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 8));

      AppLogger.api('POST Response', {'path': path, 'statusCode': response.statusCode});
      return _processResponse(response);
    } catch (e) {
      AppLogger.error('POST Error', {'path': path, 'error': e.toString()});
      if (e is! ApiException) {
        final discovered = await autoDiscoverBackend();
        if (discovered != null) {
          try {
            final retryUri = _buildUri(path);
            final response = await _client.post(
              retryUri,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode(body),
            ).timeout(const Duration(seconds: 8));
            AppLogger.api('POST Retry Success', {'path': path, 'statusCode': response.statusCode});
            return _processResponse(response);
          } catch (_) {}
        }
      }
      if (e is ApiException) rethrow;
      throw ApiException(500, 'Network Error: Connection failed. ${e.toString()}');
    }
  }

  static dynamic _processResponse(http.Response response) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map && decoded.isEmpty) {
        AppLogger.warn('Response contains empty data shape');
      } else if (decoded is List && decoded.isEmpty) {
        AppLogger.warn('Response contains empty data shape');
      }
      return decoded;
    } else {
      String msg = 'Server returned HTTP ${response.statusCode}';
      if (decoded is Map && decoded.containsKey('detail')) {
        msg = decoded['detail'].toString();
      }
      throw ApiException(response.statusCode, msg);
    }
  }
}
