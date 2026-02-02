import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/timesheet/timesheet_service.dart';
import '../services/api_service.dart';

/// SyncScheduler: periodically calls TimesheetService.syncUnsyncedSegments().
/// Runs in-app while the app is alive; for robust background sync on mobile,
/// integrate with platform-specific background services.
class SyncScheduler {
  final Ref ref;
  Timer? _timer;
  final Duration interval;

  SyncScheduler(this.ref, {this.interval = const Duration(minutes: 5)}) {
    start();
  }

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => _run());
  }

  Future<void> _run() async {
    try {
      // perform sync directly without depending on providers to avoid circular imports
      // Construct services directly to avoid relying on provider imports here.
      final api = ApiService();
      final svc = TimesheetService(api);
      final res = await svc.syncUnsyncedSegments();
      // In-app UI sync status is updated by manual sync path; scheduled sync logs only here.
      // ignore: avoid_print
      print('Scheduled sync result: ${res['status']}');
    } catch (e) {
      // Keep it simple: log and continue. Production should use structured logging and backoff.
      // ignore: avoid_print
      print('SyncScheduler error: $e');
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
