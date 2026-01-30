import 'dart:math';
import 'dart:typed_data';
import 'package:otp/otp.dart';
import 'package:base32/base32.dart';
import 'biometric_auth_service.dart';
import 'package:enterprise_attendance/src/config/app_config.dart';

/// TwoFactorAuthService provides TOTP-based two-factor authentication.
///
/// This implements the Project Manager's requirement for 2FA security:
/// - TOTP code generation and verification
/// - Secret key generation and storage
/// - QR code data for authenticator apps
class TwoFactorAuthService {
  final BiometricAuthService _secureStorage;

  TwoFactorAuthService(this._secureStorage);

  // Use centralized configuration for issuer
  String get _issuer => AppConfig.totpIssuer;
  static const int _digits = AppConfig.twoFactorCodeDigits;
  static const int _period = 30;

  /// Generate a new secret key for 2FA setup
  String generateSecret() {
    final random = Random.secure();
    final bytes = List<int>.generate(20, (_) => random.nextInt(256));
    return base32.encode(Uint8List.fromList(bytes));
  }

  /// Generate TOTP code from secret
  String generateTOTP(String secret) {
    return OTP.generateTOTPCodeString(
      secret,
      DateTime.now().millisecondsSinceEpoch,
      length: _digits,
      interval: _period,
      algorithm: Algorithm.SHA1,
      isGoogle: true,
    );
  }

  /// Verify a TOTP code
  bool verifyTOTP(String secret, String code) {
    final expectedCode = generateTOTP(secret);

    // Also check previous and next period for clock skew tolerance
    final now = DateTime.now().millisecondsSinceEpoch;
    final previousCode = OTP.generateTOTPCodeString(
      secret,
      now - (_period * 1000),
      length: _digits,
      interval: _period,
      algorithm: Algorithm.SHA1,
      isGoogle: true,
    );
    final nextCode = OTP.generateTOTPCodeString(
      secret,
      now + (_period * 1000),
      length: _digits,
      interval: _period,
      algorithm: Algorithm.SHA1,
      isGoogle: true,
    );

    return code == expectedCode || code == previousCode || code == nextCode;
  }

  /// Get the time remaining until current TOTP expires (in seconds)
  int getTimeRemaining() {
    return _period - (DateTime.now().millisecondsSinceEpoch ~/ 1000) % _period;
  }

  /// Generate otpauth URL for QR code (compatible with Google Authenticator, Authy, etc.)
  String generateOtpauthUrl({
    required String secret,
    required String userEmail,
    String? issuer,
  }) {
    final encodedIssuer = Uri.encodeComponent(issuer ?? _issuer);
    final encodedEmail = Uri.encodeComponent(userEmail);

    return 'otpauth://totp/$encodedIssuer:$encodedEmail'
        '?secret=$secret'
        '&issuer=$encodedIssuer'
        '&algorithm=SHA1'
        '&digits=$_digits'
        '&period=$_period';
  }

  /// Setup 2FA for a user - generates and stores secret
  Future<TwoFactorSetupResult> setup2FA(String userEmail) async {
    final secret = generateSecret();
    final otpauthUrl = generateOtpauthUrl(secret: secret, userEmail: userEmail);

    // Store secret securely
    await _secureStorage.store2FASecret(secret);

    return TwoFactorSetupResult(
      secret: secret,
      otpauthUrl: otpauthUrl,
      qrCodeData: otpauthUrl,
    );
  }

  /// Verify 2FA setup with user-provided code
  Future<bool> verifySetup(String code) async {
    final secret = await _secureStorage.get2FASecret();
    if (secret == null) return false;

    return verifyTOTP(secret, code);
  }

  /// Verify 2FA during login
  Future<TwoFactorVerifyResult> verify(String code) async {
    final secret = await _secureStorage.get2FASecret();

    if (secret == null) {
      return TwoFactorVerifyResult(
        success: false,
        error: TwoFactorError.notSetup,
        message: '2FA is not set up for this account',
      );
    }

    final isValid = verifyTOTP(secret, code);

    if (isValid) {
      return TwoFactorVerifyResult(
        success: true,
        message: '2FA verification successful',
      );
    } else {
      return TwoFactorVerifyResult(
        success: false,
        error: TwoFactorError.invalidCode,
        message: 'Invalid verification code. Please try again.',
      );
    }
  }

  /// Check if 2FA is enabled for current user
  Future<bool> is2FAEnabled() async {
    final secret = await _secureStorage.get2FASecret();
    return secret != null && secret.isNotEmpty;
  }

  /// Disable 2FA
  Future<void> disable2FA() async {
    await _secureStorage.clear2FASecret();
  }

  /// Generate backup codes for account recovery
  List<String> generateBackupCodes({int count = 8}) {
    final random = Random.secure();
    return List.generate(count, (_) {
      final code = List.generate(8, (_) => random.nextInt(10)).join();
      return '${code.substring(0, 4)}-${code.substring(4, 8)}';
    });
  }
}

/// Result of 2FA setup
class TwoFactorSetupResult {
  final String secret;
  final String otpauthUrl;
  final String qrCodeData;

  TwoFactorSetupResult({
    required this.secret,
    required this.otpauthUrl,
    required this.qrCodeData,
  });
}

/// Result of 2FA verification
class TwoFactorVerifyResult {
  final bool success;
  final TwoFactorError? error;
  final String message;

  TwoFactorVerifyResult({
    required this.success,
    this.error,
    required this.message,
  });
}

/// 2FA error types
enum TwoFactorError {
  notSetup,
  invalidCode,
  expired,
  rateLimit,
}

/// Extension for error messages
extension TwoFactorErrorMessage on TwoFactorError {
  String get message {
    switch (this) {
      case TwoFactorError.notSetup:
        return '2FA is not configured for this account';
      case TwoFactorError.invalidCode:
        return 'The verification code is invalid';
      case TwoFactorError.expired:
        return 'The verification code has expired';
      case TwoFactorError.rateLimit:
        return 'Too many attempts. Please try again later';
    }
  }
}
