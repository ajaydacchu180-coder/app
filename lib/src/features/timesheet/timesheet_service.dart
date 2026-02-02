import '../../services/api_service.dart';
import '../../services/local_db.dart';

class TimesheetEntry {
  final String projectId;
  final String taskId;
  double hours;
  TimesheetEntry({required this.projectId, required this.taskId, required this.hours});
}

class Timesheet {
  final String userId;
  final DateTime dayUtc;
  final List<TimesheetEntry> entries;

  Timesheet({required this.userId, required this.dayUtc, required this.entries});
}

/// Generates a timesheet by aggregating segments stored in local DB and removing non-productive time.
class TimesheetService {
  final ApiService api;
  TimesheetService(this.api);

  Future<Timesheet> generateDailyTimesheet(String userId, DateTime dayUtc) async {
    final segs = await LocalDb.instance.queryForDay(userId, dayUtc);
    final Map<String, double> map = {};

    for (final s in segs) {
      if (!s.productive) continue; // exclude idle / non-productive segments
      final dur = s.end.toUtc().difference(s.start.toUtc()).inSeconds / 3600.0;
      final key = '${s.projectId}::${s.taskId}';
      map[key] = (map[key] ?? 0) + dur;
    }

    final entries = map.entries.map((e) {
      final parts = e.key.split('::');
      return TimesheetEntry(projectId: parts[0], taskId: parts[1], hours: double.parse(e.value.toStringAsFixed(2)));
    }).toList();

    return Timesheet(userId: userId, dayUtc: DateTime.utc(dayUtc.year, dayUtc.month, dayUtc.day), entries: entries);
  }

  /// Sync unsynced segments with the server. Marks them as synced on success.
  Future<Map<String, dynamic>> syncUnsyncedSegments() async {
    final unsynced = await LocalDb.instance.getUnsyncedSegments();
    if (unsynced.isEmpty) return {'status': 'none'};

    // Aggregate by project:task
    final Map<String, double> payload = {};
    for (final s in unsynced) {
      if (!s.productive) continue; // skip non-productive
      final key = '${s.projectId}:${s.taskId}';
      final dur = s.end.toUtc().difference(s.start.toUtc()).inSeconds / 3600.0;
      payload[key] = (payload[key] ?? 0) + dur;
    }

    final res = await api.submitTimesheet(unsynced.first.userId, payload);
    if (res['status'] == 'ok') {
      for (final s in unsynced) {
        if (s.id != null) await LocalDb.instance.markSegmentSynced(s.id!);
      }
    }
    return res;
  }

  /// Submit a prepared Timesheet to the server (entries mapped to project:task -> hours)
  Future<Map<String, dynamic>> submitTimesheet(Timesheet ts) async {
    final payload = <String, double>{};
    for (final e in ts.entries) {
      payload['${e.projectId}:${e.taskId}'] = e.hours;
    }
    return api.submitTimesheet(ts.userId, payload);
  }
}
