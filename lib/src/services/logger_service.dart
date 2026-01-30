/// Logging service for the Enterprise Attendance System.
///
/// Provides structured logging with log levels to replace print() statements.
/// In production, logs can be sent to a remote service or suppressed.
library;

import 'package:flutter/foundation.dart';
import 'package:enterprise_attendance/src/config/app_config.dart';

/// Log levels for categorizing messages
enum LogLevel {
  debug,
  info,
  warning,
  error,
  fatal,
}

/// Structured log entry
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? context;

  LogEntry({
    required this.level,
    required this.tag,
    required this.message,
    this.error,
    this.stackTrace,
    this.context,
  }) : timestamp = DateTime.now();

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'level': level.name,
        'tag': tag,
        'message': message,
        if (error != null) 'error': error.toString(),
        if (context != null) 'context': context,
      };

  @override
  String toString() {
    final prefix = '[${level.name.toUpperCase()}] [$tag]';
    final errorStr = error != null ? ' | Error: $error' : '';
    return '$prefix $message$errorStr';
  }
}

/// Application logger with structured logging support.
///
/// Usage:
/// ```dart
/// AppLogger.info('ApiService', 'User logged in', context: {'userId': '123'});
/// AppLogger.error('AuthService', 'Login failed', error: e, stackTrace: stack);
/// ```
class AppLogger {
  /// Maximum log entries to keep in memory
  static const int _maxLogEntries = 1000;

  /// In-memory log buffer for debugging
  static final List<LogEntry> _logBuffer = [];

  /// Get all buffered logs
  static List<LogEntry> get logs => List.unmodifiable(_logBuffer);

  /// Clear log buffer
  static void clearLogs() => _logBuffer.clear();

  /// Get logs filtered by level
  static List<LogEntry> getLogsByLevel(LogLevel minLevel) {
    return _logBuffer
        .where((log) => log.level.index >= minLevel.index)
        .toList();
  }

  /// Get logs for a specific tag
  static List<LogEntry> getLogsByTag(String tag) {
    return _logBuffer.where((log) => log.tag == tag).toList();
  }

  /// Log a debug message (development only)
  static void debug(String tag, String message,
      {Map<String, dynamic>? context}) {
    _log(LogEntry(
      level: LogLevel.debug,
      tag: tag,
      message: message,
      context: context,
    ));
  }

  /// Log an info message
  static void info(String tag, String message,
      {Map<String, dynamic>? context}) {
    _log(LogEntry(
      level: LogLevel.info,
      tag: tag,
      message: message,
      context: context,
    ));
  }

  /// Log a warning message
  static void warning(String tag, String message,
      {Object? error, Map<String, dynamic>? context}) {
    _log(LogEntry(
      level: LogLevel.warning,
      tag: tag,
      message: message,
      error: error,
      context: context,
    ));
  }

  /// Log an error message
  static void error(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    _log(LogEntry(
      level: LogLevel.error,
      tag: tag,
      message: message,
      error: error,
      stackTrace: stackTrace,
      context: context,
    ));
  }

  /// Log a fatal error message
  static void fatal(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    _log(LogEntry(
      level: LogLevel.fatal,
      tag: tag,
      message: message,
      error: error,
      stackTrace: stackTrace,
      context: context,
    ));
  }

  /// Internal logging method
  static void _log(LogEntry entry) {
    // Add to buffer
    _logBuffer.add(entry);
    if (_logBuffer.length > _maxLogEntries) {
      _logBuffer.removeAt(0);
    }

    // Only print in debug mode or for warnings and above
    if (AppConfig.showDebugLogs ||
        entry.level.index >= LogLevel.warning.index) {
      _printLog(entry);
    }

    // In production, could send to remote logging service
    if (AppConfig.isProduction && entry.level.index >= LogLevel.error.index) {
      _sendToRemoteLogging(entry);
    }
  }

  /// Print log to console
  static void _printLog(LogEntry entry) {
    final timestamp = entry.timestamp.toIso8601String().substring(11, 23);
    final prefix =
        '[$timestamp] [${entry.level.name.toUpperCase().padLeft(7)}] [${entry.tag}]';

    if (entry.level.index >= LogLevel.error.index) {
      debugPrint('$prefix ${entry.message}');
      if (entry.error != null) {
        debugPrint('$prefix Error: ${entry.error}');
      }
      if (entry.stackTrace != null) {
        debugPrint('$prefix Stack: ${entry.stackTrace}');
      }
    } else {
      debugPrint('$prefix ${entry.message}');
    }
  }

  /// Send critical logs to remote service (placeholder)
  static Future<void> _sendToRemoteLogging(LogEntry entry) async {
    // Note: Remote logging (e.g., Sentry, Firebase Crashlytics) to be implemented
    // This is a placeholder for production logging integration
  }
}

/// Extension for convenient logging from any class
extension LoggerMixin on Object {
  void logDebug(String message, {Map<String, dynamic>? context}) {
    AppLogger.debug(runtimeType.toString(), message, context: context);
  }

  void logInfo(String message, {Map<String, dynamic>? context}) {
    AppLogger.info(runtimeType.toString(), message, context: context);
  }

  void logWarning(String message,
      {Object? error, Map<String, dynamic>? context}) {
    AppLogger.warning(runtimeType.toString(), message,
        error: error, context: context);
  }

  void logError(String message,
      {Object? error, StackTrace? stackTrace, Map<String, dynamic>? context}) {
    AppLogger.error(runtimeType.toString(), message,
        error: error, stackTrace: stackTrace, context: context);
  }
}
