import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// BiometricAuthService provides biometric authentication capabilities
/// including Face ID, Touch ID, and fingerprint authentication.
///
/// This service addresses the Project Manager's requirement for:
/// - Face Recognition check-in
/// - Fingerprint/Touch ID integration
/// - Secure session management
class BiometricAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Secure storage keys
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _userTokenKey = 'user_auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _twoFactorSecretKey = 'two_factor_secret';

  /// Check if device supports biometric authentication
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// Check if biometrics are enrolled on the device
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// Check if Face ID is available
  Future<bool> isFaceIdAvailable() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.face);
  }

  /// Check if Fingerprint/Touch ID is available
  Future<bool> isFingerprintAvailable() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.fingerprint) ||
        biometrics.contains(BiometricType.strong);
  }

  /// Authenticate using biometrics
  /// Returns true if authentication was successful
  Future<BiometricAuthResult> authenticate({
    String reason = 'Please authenticate to continue',
    bool biometricOnly = false,
  }) async {
    try {
      final isSupported = await isDeviceSupported();
      if (!isSupported) {
        return BiometricAuthResult(
          success: false,
          error: BiometricError.notSupported,
          message: 'Biometric authentication is not supported on this device',
        );
      }

      final canCheck = await canCheckBiometrics();
      if (!canCheck) {
        return BiometricAuthResult(
          success: false,
          error: BiometricError.notEnrolled,
          message: 'No biometrics are enrolled on this device',
        );
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: biometricOnly,
          useErrorDialogs: true,
        ),
      );

      if (authenticated) {
        return BiometricAuthResult(
          success: true,
          message: 'Authentication successful',
        );
      } else {
        return BiometricAuthResult(
          success: false,
          error: BiometricError.failed,
          message: 'Authentication failed',
        );
      }
    } on PlatformException catch (e) {
      return BiometricAuthResult(
        success: false,
        error: _mapPlatformError(e.code),
        message: e.message ?? 'An error occurred during authentication',
      );
    }
  }

  /// Enable biometric login for the current user
  Future<bool> enableBiometricLogin() async {
    try {
      await _secureStorage.write(key: _biometricEnabledKey, value: 'true');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Disable biometric login
  Future<bool> disableBiometricLogin() async {
    try {
      await _secureStorage.write(key: _biometricEnabledKey, value: 'false');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if biometric login is enabled
  Future<bool> isBiometricLoginEnabled() async {
    try {
      final value = await _secureStorage.read(key: _biometricEnabledKey);
      return value == 'true';
    } catch (e) {
      return false;
    }
  }

  // =================== Secure Token Storage ===================

  /// Store authentication token securely
  Future<void> storeAuthToken(String token) async {
    await _secureStorage.write(key: _userTokenKey, value: token);
  }

  /// Retrieve authentication token
  Future<String?> getAuthToken() async {
    return await _secureStorage.read(key: _userTokenKey);
  }

  /// Store refresh token securely
  Future<void> storeRefreshToken(String token) async {
    await _secureStorage.write(key: _refreshTokenKey, value: token);
  }

  /// Retrieve refresh token
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  /// Store user ID securely
  Future<void> storeUserId(String userId) async {
    await _secureStorage.write(key: _userIdKey, value: userId);
  }

  /// Retrieve user ID
  Future<String?> getUserId() async {
    return await _secureStorage.read(key: _userIdKey);
  }

  /// Clear all stored credentials (for logout)
  Future<void> clearAllCredentials() async {
    await _secureStorage.delete(key: _userTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _userIdKey);
  }

  // =================== 2FA Secret Storage ===================

  /// Store 2FA secret securely
  Future<void> store2FASecret(String secret) async {
    await _secureStorage.write(key: _twoFactorSecretKey, value: secret);
  }

  /// Retrieve 2FA secret
  Future<String?> get2FASecret() async {
    return await _secureStorage.read(key: _twoFactorSecretKey);
  }

  /// Clear 2FA secret
  Future<void> clear2FASecret() async {
    await _secureStorage.delete(key: _twoFactorSecretKey);
  }

  /// Map platform exception codes to BiometricError
  BiometricError _mapPlatformError(String code) {
    switch (code) {
      case 'NotAvailable':
        return BiometricError.notAvailable;
      case 'NotEnrolled':
        return BiometricError.notEnrolled;
      case 'LockedOut':
        return BiometricError.lockedOut;
      case 'PermanentlyLockedOut':
        return BiometricError.permanentlyLockedOut;
      case 'Canceled':
        return BiometricError.cancelled;
      default:
        return BiometricError.unknown;
    }
  }
}

/// Result of a biometric authentication attempt
class BiometricAuthResult {
  final bool success;
  final BiometricError? error;
  final String message;

  BiometricAuthResult({
    required this.success,
    this.error,
    required this.message,
  });
}

/// Types of biometric errors
enum BiometricError {
  notSupported,
  notAvailable,
  notEnrolled,
  lockedOut,
  permanentlyLockedOut,
  cancelled,
  failed,
  unknown,
}

/// Extension to get user-friendly error messages
extension BiometricErrorMessage on BiometricError {
  String get message {
    switch (this) {
      case BiometricError.notSupported:
        return 'Biometric authentication is not supported on this device';
      case BiometricError.notAvailable:
        return 'Biometric authentication is not available';
      case BiometricError.notEnrolled:
        return 'No biometrics enrolled. Please set up fingerprint or face recognition in device settings';
      case BiometricError.lockedOut:
        return 'Too many failed attempts. Please try again later';
      case BiometricError.permanentlyLockedOut:
        return 'Biometric authentication is permanently locked. Please use your device passcode';
      case BiometricError.cancelled:
        return 'Authentication was cancelled';
      case BiometricError.failed:
        return 'Authentication failed. Please try again';
      case BiometricError.unknown:
        return 'An unknown error occurred';
    }
  }
}
