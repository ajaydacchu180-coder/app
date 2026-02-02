import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import '../features/timesheet/timesheet_service.dart';
import '../services/api_service.dart';
import '../services/local_db.dart';

/// PlatformSync provides scaffolding to register background sync jobs.
/// NOTE: Background execution differs across platforms; this is a scaffold.
class PlatformSync {
  static const _taskName = 'sync_unsynced_segments';

  /// Initialize background sync. Registers WorkManager task on Android/iOS.
  static Future<void> initialize() async {
    // Skip on web - WorkManager not supported
    if (kIsWeb) {
      debugPrint('PlatformSync: Web platform - background sync not available');
      return;
    }

    try {
      // Only initialize on mobile platforms
      if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        await Workmanager().initialize(_callbackDispatcher);
        await Workmanager().registerPeriodicTask(
          _taskName,
          _taskName,
          frequency: const Duration(minutes: 15), // platform minimums apply
          initialDelay: const Duration(seconds: 30),
        );
      }
    } catch (e) {
      // ignore: avoid_print
      debugPrint('PlatformSync.initialize error: $e');
    }
  }

  /// WorkManager callback dispatcher.
  @pragma('vm:entry-point')
  static void _callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      try {
        // Simple sync attempt in background: create ApiService and TimesheetService
        final api = ApiService();
        final svc = TimesheetService(api);
        // Ensure DB initialized
        await LocalDb.instance.getUnsyncedSegments();
        await svc.syncUnsyncedSegments();
        return Future.value(true);
      } catch (e) {
        // ignore: avoid_print
        debugPrint('Background sync failed: $e');
        return Future.value(false);
      }
    });
  }
}
