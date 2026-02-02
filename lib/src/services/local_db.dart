import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../core/models.dart';

class LocalDb {
  LocalDb._();
  static final LocalDb instance = LocalDb._();

  Database? _db;

  Future<void> _init() async {
    if (_db != null) return;
    final docs = await getApplicationDocumentsDirectory();
    final path = join(docs.path, 'enterprise_attendance.db');
    _db = await openDatabase(path, version: 1, onCreate: (db, v) async {
      await db.execute('''
        CREATE TABLE segments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId TEXT NOT NULL,
          taskId TEXT NOT NULL,
          projectId TEXT NOT NULL,
          start TEXT NOT NULL,
          end TEXT NOT NULL,
          productive INTEGER NOT NULL DEFAULT 1,
          synced INTEGER NOT NULL DEFAULT 0
        )
      ''');
    });
  }

  Future<int> insertSegment(TimeSegment seg) async {
    await _init();
    return await _db!.insert('segments', seg.toMap());
  }

  Future<List<TimeSegment>> queryForDay(String userId, DateTime dayUtc) async {
    await _init();
    final startOfDay = DateTime.utc(dayUtc.year, dayUtc.month, dayUtc.day).toIso8601String();
    final endOfDay = DateTime.utc(dayUtc.year, dayUtc.month, dayUtc.day).add(const Duration(days: 1)).toIso8601String();
    final rows = await _db!.query('segments', where: 'userId = ? AND start < ? AND end > ?', whereArgs: [userId, endOfDay, startOfDay]);
    return rows.map((r) => TimeSegment.fromMap(r)).toList();
  }

  Future<List<TimeSegment>> getUnsyncedSegments() async {
    await _init();
    final rows = await _db!.query('segments', where: 'synced = 0');
    return rows.map((r) => TimeSegment.fromMap(r)).toList();
  }

  Future<void> markSegmentSynced(int id) async {
    await _init();
    await _db!.update('segments', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
