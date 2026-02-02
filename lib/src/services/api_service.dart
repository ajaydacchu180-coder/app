import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:enterprise_attendance/src/core/models.dart';
import 'package:enterprise_attendance/src/services/audit_logging_service.dart';
import 'package:enterprise_attendance/src/config/app_config.dart';

/// Enhanced ApiService with real backend integration capabilities.
///
/// Supports both mock mode (for development) and production mode (for real backend).
/// Addresses Project Manager requirements for:
/// - Real API integration
/// - Proper authentication flow
/// - Login history fetching
/// - Password change
/// - 2FA endpoints
/// - Audit logging
class ApiService {
  // Use centralized configuration
  String get _baseUrl => AppConfig.apiBaseUrl;
  bool get _useMock => AppConfig.useMockData;

  String? _authToken;
  String? _refreshToken;

  // Set authentication tokens
  void setTokens({required String authToken, String? refreshToken}) {
    _authToken = authToken;
    _refreshToken = refreshToken;
  }

  // Clear tokens on logout
  void clearTokens() {
    _authToken = null;
    _refreshToken = null;
  }

  // HTTP headers with auth
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  // =================== AUTH ENDPOINTS ===================

  Future<Map<String, dynamic>> login(
      String username, String password, Role role) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 600));
      return {
        'token': 'mock-token-$username',
        'user': {'id': 'u_$username', 'name': username, 'role': role.name},
        'requires2FA': false,
      };
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['accessToken'] != null) {
        setTokens(
          authToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
      }
      return data;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> logout(String userId) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      clearTokens();
      return {'success': true, 'message': 'Logged out successfully'};
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/auth/logout'),
      headers: _headers,
      body: jsonEncode({
        'userId': userId,
        'refreshToken': _refreshToken,
      }),
    );

    clearTokens();

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {'success': true, 'message': 'Logged out'};
  }

  Future<Map<String, dynamic>> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      // Simulate validation
      if (newPassword.length < 8) {
        throw Exception('Password must be at least 8 characters');
      }
      return {'success': true, 'message': 'Password changed successfully'};
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/auth/change-password'),
      headers: _headers,
      body: jsonEncode({
        'userId': userId,
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Password change failed');
    }
  }

  Future<List<LoginHistoryEntry>> getLoginHistory(String userId) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      // Return realistic mock data
      final now = DateTime.now();
      return [
        LoginHistoryEntry(
          id: '1',
          timestamp: now.subtract(const Duration(hours: 2)),
          device: 'Windows PC',
          ip: '192.168.1.100',
          success: true,
        ),
        LoginHistoryEntry(
          id: '2',
          timestamp: now.subtract(const Duration(days: 1)),
          device: 'iPhone',
          ip: '192.168.1.105',
          success: true,
        ),
        LoginHistoryEntry(
          id: '3',
          timestamp: now.subtract(const Duration(days: 2)),
          device: 'Android Device',
          ip: '10.0.0.50',
          success: true,
        ),
        LoginHistoryEntry(
          id: '4',
          timestamp: now.subtract(const Duration(days: 3)),
          device: 'Unknown Device',
          ip: '203.45.67.89',
          success: false,
        ),
      ];
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/auth/login-history/$userId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => LoginHistoryEntry.fromJson(e)).toList();
    }
    throw Exception('Failed to fetch login history');
  }

  // =================== 2FA ENDPOINTS ===================

  Future<Map<String, dynamic>> setup2FA(String userId, String email) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      final mockSecret = 'JBSWY3DPEHPK3PXP';
      return {
        'secret': mockSecret,
        'otpauthUrl':
            'otpauth://totp/Enterprise%20Attendance:$email?secret=$mockSecret&issuer=Enterprise%20Attendance',
        'qrCodeData':
            'otpauth://totp/Enterprise%20Attendance:$email?secret=$mockSecret&issuer=Enterprise%20Attendance',
      };
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/auth/2fa/setup'),
      headers: _headers,
      body: jsonEncode({'userId': userId, 'email': email}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to setup 2FA');
  }

  Future<Map<String, dynamic>> verify2FASetup(
      String userId, String code) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (code.length != 6) {
        throw Exception('Invalid code format');
      }
      return {
        'success': true,
        'message': '2FA enabled successfully',
        'backupCodes': ['1234-5678', '2345-6789', '3456-7890', '4567-8901'],
      };
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/auth/2fa/verify-setup'),
      headers: _headers,
      body: jsonEncode({'userId': userId, 'code': code}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to verify 2FA setup');
  }

  Future<Map<String, dynamic>> verify2FA(String userId, String code) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      return {
        'accessToken': 'mock-token-after-2fa',
        'refreshToken': 'mock-refresh-token',
      };
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/auth/2fa/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'code': code}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setTokens(
          authToken: data['accessToken'], refreshToken: data['refreshToken']);
      return data;
    }
    throw Exception('2FA verification failed');
  }

  Future<bool> get2FAStatus(String userId) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      return false; // Default to disabled in mock
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/auth/2fa/status/$userId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['enabled'] ?? false;
    }
    return false;
  }

  Future<Map<String, dynamic>> disable2FA(String userId, String code) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      return {'success': true, 'message': '2FA disabled'};
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/auth/2fa/disable'),
      headers: _headers,
      body: jsonEncode({'userId': userId, 'code': code}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to disable 2FA');
  }

  // =================== EMPLOYEE MANAGEMENT ENDPOINTS ===================

  /// Create a new employee account
  /// Returns employee details including generated credentials
  Future<Map<String, dynamic>> createEmployee({
    required String employeeId,
    required String email,
    required String name,
    required String department,
    required String password,
  }) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 800));
      // Mock successful employee creation
      return {
        'success': true,
        'employeeId': employeeId,
        'email': email,
        'name': name,
        'department': department,
        'createdAt': DateTime.now().toIso8601String(),
        'message': 'Employee created successfully',
      };
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/admin/employees/create'),
      headers: _headers,
      body: jsonEncode({
        'employeeId': employeeId,
        'email': email,
        'name': name,
        'department': department,
        'password': password,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to create employee');
    }
  }

  /// Get list of all employees (admin only)
  Future<List<Map<String, dynamic>>> getEmployees() async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      return [
        {
          'employeeId': 'EMP001',
          'email': 'john.doe@company.com',
          'name': 'John Doe',
          'department': 'Engineering',
          'createdAt': DateTime.now()
              .subtract(const Duration(days: 30))
              .toIso8601String(),
        },
        {
          'employeeId': 'EMP002',
          'email': 'jane.smith@company.com',
          'name': 'Jane Smith',
          'department': 'HR',
          'createdAt': DateTime.now()
              .subtract(const Duration(days: 15))
              .toIso8601String(),
        },
      ];
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/admin/employees'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to fetch employees');
  }

  // =================== AUDIT LOG ENDPOINTS ===================

  Future<void> sendAuditLog(AuditLogEntry entry) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 100));
      return;
    }

    await http.post(
      Uri.parse('$_baseUrl/audit/log'),
      headers: _headers,
      body: jsonEncode(entry.toJson()),
    );
  }

  // =================== EXISTING ENDPOINTS (unchanged) ===================

  Future<T> get<T>(String url) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      return {} as T;
    }

    final response =
        await http.get(Uri.parse('$_baseUrl$url'), headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as T;
    }
    throw Exception('GET request failed');
  }

  Future<T> post<T>(String url, {Map<String, dynamic>? body}) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      return {} as T;
    }

    final response = await http.post(
      Uri.parse('$_baseUrl$url'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as T;
    }
    throw Exception('POST request failed');
  }

  Future<T> put<T>(String url, {Map<String, dynamic>? body}) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      return {} as T;
    }

    final response = await http.put(
      Uri.parse('$_baseUrl$url'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as T;
    }
    throw Exception('PUT request failed');
  }

  Future<T> delete<T>(String url) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      return {} as T;
    }

    final response =
        await http.delete(Uri.parse('$_baseUrl$url'), headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as T;
    }
    throw Exception('DELETE request failed');
  }

  Future<DateTime> getServerTimeUtc() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return DateTime.now().toUtc();
  }

  Future<List<Project>> getProjects(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      Project(id: 'p1', name: 'Core Platform'),
      Project(id: 'p2', name: 'Mobile App')
    ];
  }

  Future<AttendanceRecord> checkIn(String userId) async {
    final t = await getServerTimeUtc();
    return AttendanceRecord(
        userId: userId, timestamp: t, state: AttendanceState.checkedIn);
  }

  Future<AttendanceRecord> checkOut(String userId) async {
    final t = await getServerTimeUtc();
    return AttendanceRecord(
        userId: userId, timestamp: t, state: AttendanceState.checkedOut);
  }

  Future<Map<String, dynamic>> startTask(String userId, Task task) async {
    final t = await getServerTimeUtc();
    return {'taskId': task.id, 'startedAt': t.toIso8601String()};
  }

  Future<Map<String, dynamic>> pauseTask(String userId, Task task) async {
    final t = await getServerTimeUtc();
    return {'taskId': task.id, 'pausedAt': t.toIso8601String()};
  }

  Future<List<Task>> getTasks(String projectId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return [Task(id: 't1', title: 'Implement auth', projectId: projectId)];
  }

  Future<Map<String, dynamic>> submitTimesheet(
      String userId, Map<String, double> entries) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return {
      'status': 'ok',
      'submittedAt': DateTime.now().toUtc().toIso8601String()
    };
  }
}

/// Login history entry model
class LoginHistoryEntry {
  final String id;
  final DateTime timestamp;
  final String device;
  final String ip;
  final bool success;

  LoginHistoryEntry({
    required this.id,
    required this.timestamp,
    required this.device,
    required this.ip,
    required this.success,
  });

  factory LoginHistoryEntry.fromJson(Map<String, dynamic> json) =>
      LoginHistoryEntry(
        id: json['id'].toString(),
        timestamp: DateTime.parse(json['timestamp']),
        device: json['device'] ?? 'Unknown',
        ip: json['ip'] ?? 'Unknown',
        success: json['success'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'device': device,
        'ip': ip,
        'success': success,
      };
}
