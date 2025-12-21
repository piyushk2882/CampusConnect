import 'dart:developer' as developer;

/// A utility class for logging debug information
class AppLogger {
  static const String _name = 'CampusConnect';

  /// Log general information
  static void info(String message, {String? tag}) {
    developer.log(
      message,
      name: _name,
      level: 800, // INFO level
      time: DateTime.now(),
      error: tag,
    );
  }

  /// Log debug information
  static void debug(String message, {String? tag}) {
    developer.log(
      message,
      name: _name,
      level: 500, // DEBUG level
      time: DateTime.now(),
      error: tag,
    );
  }

  /// Log warnings
  static void warning(String message, {String? tag}) {
    developer.log(
      message,
      name: _name,
      level: 900, // WARNING level
      time: DateTime.now(),
      error: tag,
    );
  }

  /// Log errors
  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: _name,
      level: 1000, // ERROR level
      time: DateTime.now(),
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log Supabase connection status
  static void supabase(String message) {
    info('🔵 SUPABASE: $message', tag: 'SUPABASE');
  }

  /// Log authentication events
  static void auth(String message) {
    info('🔐 AUTH: $message', tag: 'AUTH');
  }

  /// Log Google sign-in events
  static void google(String message) {
    info('🔴 GOOGLE: $message', tag: 'GOOGLE');
  }
}
