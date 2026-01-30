/// Environment configuration for the Enterprise Attendance System.
///
/// This file provides centralized configuration for all environment-specific
/// values like API URLs, feature flags, and app settings.
///
/// Usage:
/// ```dart
/// final apiUrl = AppConfig.apiBaseUrl;
/// ```
library;

import 'package:flutter/foundation.dart';

/// Application environment types
enum Environment {
  development,
  staging,
  production,
}

/// Centralized application configuration.
///
/// All environment-specific values should be defined here rather than
/// hardcoded throughout the codebase.
class AppConfig {
  /// Current environment - change this for different builds
  static const Environment environment = Environment.development;

  /// Whether to use mock data (for development without backend)
  static bool get useMockData {
    if (environment == Environment.development) {
      return _useMockOverride ?? true; // Default to mock in development
    }
    return false; // Never use mock in staging/production
  }

  /// Override for mock mode (useful for testing)
  static bool? _useMockOverride;
  static void setMockMode(bool useMock) => _useMockOverride = useMock;
  static void clearMockOverride() => _useMockOverride = null;

  /// API Base URL
  static String get apiBaseUrl {
    switch (environment) {
      case Environment.development:
        if (kIsWeb) {
          return 'http://localhost:3000/api/v1';
        }
        // For mobile emulators, use 10.0.2.2 (Android) or localhost (iOS)
        return 'http://10.0.2.2:3000/api/v1';
      case Environment.staging:
        return 'https://staging-api.enterprise-attendance.com/api/v1';
      case Environment.production:
        return 'https://api.enterprise-attendance.com/api/v1';
    }
  }

  /// WebSocket URL
  static String get webSocketUrl {
    switch (environment) {
      case Environment.development:
        if (kIsWeb) {
          return 'ws://localhost:3000';
        }
        return 'ws://10.0.2.2:3000';
      case Environment.staging:
        return 'wss://staging-api.enterprise-attendance.com';
      case Environment.production:
        return 'wss://api.enterprise-attendance.com';
    }
  }

  /// 2FA/TOTP Issuer Name
  static String get totpIssuer {
    switch (environment) {
      case Environment.development:
        return 'Enterprise Attendance (Dev)';
      case Environment.staging:
        return 'Enterprise Attendance (Staging)';
      case Environment.production:
        return 'Enterprise Attendance';
    }
  }

  /// Application name
  static const String appName = 'Enterprise Attendance';

  /// Application version
  static const String appVersion = '1.0.0';

  /// Whether debug features are enabled
  static bool get isDebugMode => environment == Environment.development;

  /// Whether to show debug logging
  static bool get showDebugLogs => isDebugMode;

  /// API request timeout in seconds
  static const int apiTimeoutSeconds = 30;

  /// Token refresh buffer (refresh if expires within this many seconds)
  static const int tokenRefreshBufferSeconds = 300; // 5 minutes

  /// Maximum login history entries to display
  static const int maxLoginHistoryEntries = 10;

  /// Password minimum length
  static const int passwordMinLength = 8;

  /// 2FA code digits
  static const int twoFactorCodeDigits = 6;

  /// QR code expiry duration in minutes
  static const int qrCodeExpiryMinutes = 5;

  /// Geofence radius in meters
  static const double defaultGeofenceRadius = 100.0;

  /// Location update interval in seconds
  static const int locationUpdateIntervalSeconds = 30;

  /// Get environment display name
  static String get environmentName {
    switch (environment) {
      case Environment.development:
        return 'Development';
      case Environment.staging:
        return 'Staging';
      case Environment.production:
        return 'Production';
    }
  }

  /// Check if running in production
  static bool get isProduction => environment == Environment.production;

  /// Check if running in development
  static bool get isDevelopment => environment == Environment.development;
}
