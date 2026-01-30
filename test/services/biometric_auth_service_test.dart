import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_attendance/src/services/biometric_auth_service.dart';

void main() {
  group('BiometricAuthService', () {
    // Service is created in setUp - available for platform-specific tests
    // Currently only testing the model classes which don't need the service
    late BiometricAuthService service;

    setUp(() {
      service = BiometricAuthService();
      // Silence analyzer warning - service is available for extending tests
      service.hashCode; // ignore: unnecessary_statements
    });

    group('BiometricAuthResult', () {
      test('should create successful result', () {
        final result = BiometricAuthResult(
          success: true,
          message: 'Authentication successful',
        );

        expect(result.success, isTrue);
        expect(result.message, equals('Authentication successful'));
        expect(result.error, isNull);
      });

      test('should create failed result with error', () {
        final result = BiometricAuthResult(
          success: false,
          error: BiometricError.notEnrolled,
          message: 'No biometrics enrolled',
        );

        expect(result.success, isFalse);
        expect(result.error, equals(BiometricError.notEnrolled));
        expect(result.message, equals('No biometrics enrolled'));
      });
    });

    group('BiometricError extension', () {
      test('should return correct message for notSupported', () {
        expect(
          BiometricError.notSupported.message,
          equals('Biometric authentication is not supported on this device'),
        );
      });

      test('should return correct message for notAvailable', () {
        expect(
          BiometricError.notAvailable.message,
          equals('Biometric authentication is not available'),
        );
      });

      test('should return correct message for notEnrolled', () {
        expect(
          BiometricError.notEnrolled.message,
          contains('No biometrics enrolled'),
        );
      });

      test('should return correct message for lockedOut', () {
        expect(
          BiometricError.lockedOut.message,
          contains('Too many failed attempts'),
        );
      });

      test('should return correct message for permanentlyLockedOut', () {
        expect(
          BiometricError.permanentlyLockedOut.message,
          contains('permanently locked'),
        );
      });

      test('should return correct message for cancelled', () {
        expect(
          BiometricError.cancelled.message,
          equals('Authentication was cancelled'),
        );
      });

      test('should return correct message for failed', () {
        expect(
          BiometricError.failed.message,
          contains('Authentication failed'),
        );
      });

      test('should return correct message for unknown', () {
        expect(
          BiometricError.unknown.message,
          equals('An unknown error occurred'),
        );
      });
    });

    // Note: Platform-specific tests would require mocking local_auth
    // These are unit tests for the model classes
  });
}
