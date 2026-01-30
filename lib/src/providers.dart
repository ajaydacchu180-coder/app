import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/models.dart';
import 'services/api_service.dart';
import 'services/websocket_service.dart';
import 'services/ai_service.dart';
import 'features/auth/auth_service.dart';
import 'features/attendance/attendance_service.dart';
import 'features/work/work_service.dart';
import 'features/timesheet/timesheet_service.dart';
import 'features/idle/idle_watcher.dart';
import 'services/sync_scheduler.dart';
import 'services/local_db.dart';
// New security and feature services
import 'services/biometric_auth_service.dart';
import 'services/two_factor_auth_service.dart';
import 'services/audit_logging_service.dart';
import 'services/geolocation_service.dart';
import 'services/qr_clock_in_service.dart';
import 'services/ai_anomaly_detection_service.dart';
import 'services/hr_chatbot_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
final wsServiceProvider = Provider<WebSocketService>((ref) {
  final ws = WebSocketService();
  ws.connect();
  ref.onDispose(() => ws.dispose());
  return ws;
});
final aiServiceProvider = Provider<AIService>((ref) => AIService());
final timesheetServiceProvider =
    Provider((ref) => TimesheetService(ref.read(apiServiceProvider)));
final idleWatcherProvider = Provider<IdleWatcher>((ref) {
  final watcher = IdleWatcher(ref);
  ref.onDispose(() => watcher.dispose());
  return watcher;
});
final syncSchedulerProvider = Provider<SyncScheduler>((ref) {
  final scheduler = SyncScheduler(ref);
  ref.onDispose(() => scheduler.dispose());
  return scheduler;
});

// Provider to fetch unsynced segments for UI display
final unsyncedSegmentsProvider = FutureProvider.autoDispose<int>((ref) async {
  final list = await LocalDb.instance.getUnsyncedSegments();
  return list.length;
});

// Sync status model and notifier
class SyncStatus {
  final DateTime? lastSync;
  final bool success;
  final String message;

  SyncStatus({this.lastSync, this.success = false, this.message = ''});
}

class SyncNotifier extends StateNotifier<SyncStatus> {
  SyncNotifier() : super(SyncStatus());

  void setResult({required bool success, required String message}) {
    state = SyncStatus(
        lastSync: DateTime.now().toUtc(), success: success, message: message);
  }
}

final syncStatusProvider =
    StateNotifierProvider<SyncNotifier, SyncStatus>((ref) => SyncNotifier());

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final api = ref.read(apiServiceProvider);
  return AuthNotifier(api);
});

final projectsProvider = FutureProvider.autoDispose<List<Project>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final auth = ref.watch(authNotifierProvider);
  if (!auth.isAuthenticated) return [];
  return api.getProjects(auth.user!.id);
});

final attendanceProvider =
    StateNotifierProviderFamily<AttendanceNotifier, AttendanceState, String>(
        (ref, userId) {
  final api = ref.read(apiServiceProvider);
  return AttendanceNotifier(api, userId);
});

final workProvider =
    StateNotifierProviderFamily<WorkNotifier, WorkState, String>((ref, userId) {
  final api = ref.read(apiServiceProvider);
  return WorkNotifier(api, userId);
});

// =================== NEW SECURITY & FEATURE PROVIDERS ===================

/// Biometric Authentication Service Provider
/// Handles Face ID, Touch ID, fingerprint auth, and secure storage
final biometricAuthProvider = Provider<BiometricAuthService>((ref) {
  return BiometricAuthService();
});

/// Two-Factor Authentication Service Provider
/// Handles TOTP generation, verification, and 2FA setup
final twoFactorAuthProvider = Provider<TwoFactorAuthService>((ref) {
  final biometricService = ref.read(biometricAuthProvider);
  return TwoFactorAuthService(biometricService);
});

/// Audit Logging Service Provider
/// Handles device info detection, IP detection, and security event logging
final auditLoggingProvider = Provider<AuditLoggingService>((ref) {
  return AuditLoggingService();
});

/// Geolocation Service Provider
/// Handles GPS tracking, geofencing, and location verification
final geolocationProvider = Provider<GeolocationService>((ref) {
  final service = GeolocationService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// QR Code Clock-In Service Provider
/// Handles QR code generation and validation for attendance
final qrClockInProvider = Provider<QRClockInService>((ref) {
  return QRClockInService();
});

/// AI Anomaly Detection Service Provider
/// Handles attendance pattern analysis, burnout detection, and predictions
final aiAnomalyDetectionProvider = Provider<AIAnomalyDetectionService>((ref) {
  return AIAnomalyDetectionService();
});

/// HR Chatbot Service Provider
/// Handles intelligent HR assistant functionality
final hrChatbotProvider = Provider<HRChatbotService>((ref) {
  return HRChatbotService();
});

// =================== FEATURE STATE PROVIDERS ===================

/// 2FA Status Provider - tracks if 2FA is enabled for current user
final is2FAEnabledProvider = FutureProvider<bool>((ref) async {
  final twoFactorService = ref.read(twoFactorAuthProvider);
  return await twoFactorService.is2FAEnabled();
});

/// Biometric Availability Provider - checks if biometrics are available
final biometricAvailableProvider = FutureProvider<bool>((ref) async {
  final biometricService = ref.read(biometricAuthProvider);
  return await biometricService.canCheckBiometrics();
});

/// Location Permission Status Provider
final locationPermissionProvider = FutureProvider<bool>((ref) async {
  final geoService = ref.read(geolocationProvider);
  final permission = await geoService.checkPermission();
  return permission.toString().contains('always') ||
      permission.toString().contains('whileInUse');
});
