class AppLogger {
  static bool _enabled = true; // Set to false for production
  
  static void enable() => _enabled = true;
  static void disable() => _enabled = false;
  
  static void api(String message, [Map<String, dynamic>? params]) {
    _log('[API]', message, params);
  }
  static void data(String message, [Map<String, dynamic>? params]) {
    _log('[DATA]', message, params);
  }
  static void mock(String message, [Map<String, dynamic>? params]) {
    _log('[MOCK]', message, params);
  }
  static void calc(String message, [Map<String, dynamic>? params]) {
    _log('[CALC]', message, params);
  }
  static void ledger(String message, [Map<String, dynamic>? params]) {
    _log('[LEDGER]', message, params);
  }
  static void audit(String message, [Map<String, dynamic>? params]) {
    _log('[AUDIT]', message, params);
  }
  static void warn(String message, [Map<String, dynamic>? params]) {
    _log('[WARN]', message, params);
  }
  static void error(String message, [Map<String, dynamic>? params]) {
    _log('[ERROR]', message, params);
  }
  
  static void _log(String prefix, String message, [Map<String, dynamic>? params]) {
    if (!_enabled) return;
    final timestamp = DateTime.now().toIso8601String().substring(11, 23);
    final paramStr = params != null ? ' | ${params.entries.map((e) => '${e.key}=${e.value}').join(', ')}' : '';
    // ignore: avoid_print
    print('$timestamp $prefix $message$paramStr');
  }
}
