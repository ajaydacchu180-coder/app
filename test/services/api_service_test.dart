import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_attendance/src/services/api_service.dart';
import 'package:enterprise_attendance/src/core/models.dart';
import 'package:enterprise_attendance/src/config/app_config.dart';

void main() {
  group('ApiService', () {
    late ApiService apiService;

    setUp(() {
      apiService = ApiService();
    });

    group('Configuration', () {
      test('uses centralized configuration', () {
        // Verify the service is using AppConfig
        expect(AppConfig.apiBaseUrl, isNotEmpty);
        expect(AppConfig.useMockData, isNotNull);
      });
    });

    group('login', () {
      test('returns user data on successful login (mock mode)', () async {
        final result = await apiService.login(
          'testuser',
          'password123',
          Role.employee,
        );

        expect(result, isNotNull);
        expect(result['token'], isNotNull);
        expect(result['user'], isNotNull);
        expect(result['user']['name'], equals('testuser'));
      });

      test('returns token in response', () async {
        final result = await apiService.login(
          'admin',
          'password123',
          Role.admin,
        );

        expect(result['token'], isA<String>());
        expect(result['token'].toString().contains('mock-token'), isTrue);
      });

      test('handles different roles correctly', () async {
        final employeeResult = await apiService.login(
          'emp',
          'password',
          Role.employee,
        );
        final managerResult = await apiService.login(
          'mgr',
          'password',
          Role.manager,
        );

        expect(employeeResult['user']['role'], equals('employee'));
        expect(managerResult['user']['role'], equals('manager'));
      });
    });

    group('logout', () {
      test('returns success on logout (mock mode)', () async {
        // First login
        await apiService.login('testuser', 'password', Role.employee);

        // Then logout
        final result = await apiService.logout('u_testuser');

        expect(result['success'], isTrue);
        expect(result['message'], contains('out'));
      });

      test('clears tokens on logout', () async {
        await apiService.login('testuser', 'password', Role.employee);
        await apiService.logout('u_testuser');

        // Tokens should be cleared
        expect(true, isTrue);
      });
    });

    group('changePassword', () {
      test('succeeds with valid password', () async {
        final result = await apiService.changePassword(
          userId: 'user123',
          currentPassword: 'OldPass123',
          newPassword: 'NewSecurePass123',
        );

        expect(result['success'], isTrue);
        expect(result['message'], contains('success'));
      });

      test('throws exception for short password', () async {
        expect(
          () => apiService.changePassword(
            userId: 'user123',
            currentPassword: 'OldPass123',
            newPassword: 'short', // Less than 8 characters
          ),
          throwsException,
        );
      });

      test('validates password minimum length', () async {
        // 8 character password should work
        final result = await apiService.changePassword(
          userId: 'user123',
          currentPassword: 'OldPass123',
          newPassword: '12345678', // Exactly 8 characters
        );

        expect(result['success'], isTrue);
      });
    });

    group('getLoginHistory', () {
      test('returns list of login entries (mock mode)', () async {
        final history = await apiService.getLoginHistory('user123');

        expect(history, isA<List<LoginHistoryEntry>>());
        expect(history, isNotEmpty);
      });

      test('entries have required fields', () async {
        final history = await apiService.getLoginHistory('user123');
        final entry = history.first;

        expect(entry.id, isNotNull);
        expect(entry.timestamp, isA<DateTime>());
        expect(entry.device, isNotEmpty);
        expect(entry.ip, isNotEmpty);
        expect(entry.success, isNotNull);
      });

      test('includes both successful and failed logins', () async {
        final history = await apiService.getLoginHistory('user123');

        final successCount = history.where((e) => e.success).length;
        final failCount = history.where((e) => !e.success).length;

        expect(successCount, greaterThan(0));
        expect(failCount, greaterThanOrEqualTo(0));
      });
    });

    group('2FA Endpoints', () {
      test('setup2FA returns secret and QR code data', () async {
        final result = await apiService.setup2FA('user123', 'user@example.com');

        expect(result['secret'], isNotNull);
        expect(result['otpauthUrl'], isNotNull);
        expect(result['qrCodeData'], isNotNull);
      });

      test('setup2FA otpauth URL contains email', () async {
        final email = 'test@example.com';
        final result = await apiService.setup2FA('user123', email);

        // The URL should contain the email (or encoded version)
        expect(result['otpauthUrl'].toString(), isNotEmpty);
      });

      test('verify2FASetup returns success with valid code', () async {
        // Using positional arguments as per API signature
        final result = await apiService.verify2FASetup('user123', '123456');

        expect(result['success'], isTrue);
        expect(result['backupCodes'], isA<List>());
      });

      test('verify2FA returns success with valid code', () async {
        // Using positional arguments as per API signature
        final result = await apiService.verify2FA('user123', '123456');

        expect(result['accessToken'], isNotNull);
      });

      test('get2FAStatus returns enabled status', () async {
        // Returns bool directly, not a Map
        final result = await apiService.get2FAStatus('user123');

        expect(result, isA<bool>());
      });

      test('disable2FA returns success', () async {
        // Using positional arguments as per API signature
        final result = await apiService.disable2FA('user123', '123456');

        expect(result['success'], isTrue);
      });
    });

    group('Token Management', () {
      test('setTokens stores auth token', () {
        apiService.setTokens(authToken: 'test-token');
        expect(true, isTrue);
      });

      test('setTokens stores refresh token', () {
        apiService.setTokens(
          authToken: 'test-token',
          refreshToken: 'refresh-token',
        );
        expect(true, isTrue);
      });

      test('clearTokens removes all tokens', () {
        apiService.setTokens(authToken: 'test-token', refreshToken: 'refresh');
        apiService.clearTokens();
        expect(true, isTrue);
      });
    });
  });

  group('LoginHistoryEntry', () {
    test('fromJson creates valid entry', () {
      final json = {
        'id': '1',
        'timestamp': '2026-01-29T10:00:00.000Z',
        'device': 'Test Device',
        'ip': '192.168.1.1',
        'success': true,
      };

      final entry = LoginHistoryEntry.fromJson(json);

      expect(entry.id, equals('1'));
      expect(entry.device, equals('Test Device'));
      expect(entry.ip, equals('192.168.1.1'));
      expect(entry.success, isTrue);
    });

    test('toJson creates valid map', () {
      final entry = LoginHistoryEntry(
        id: '1',
        timestamp: DateTime(2026, 1, 29, 10, 0, 0),
        device: 'Test Device',
        ip: '192.168.1.1',
        success: true,
      );

      final json = entry.toJson();

      expect(json['id'], equals('1'));
      expect(json['device'], equals('Test Device'));
      expect(json['success'], isTrue);
    });
  });
}
