enum Role { employee, manager, admin }

enum AttendanceState { checkedOut, checkedIn, working, idle }

enum TaskState { stopped, running, paused }

class User {
  final String id;
  final String name;
  final Role role;

  User({required this.id, required this.name, required this.role});
}

class Project {
  final String id;
  final String name;

  Project({required this.id, required this.name});
}

class Task {
  final String id;
  final String title;
  final String projectId;

  Task({required this.id, required this.title, required this.projectId});
}

class AttendanceRecord {
  final String userId;
  final DateTime timestamp;
  final AttendanceState state;

  AttendanceRecord({required this.userId, required this.timestamp, required this.state});
}

class IdleDetectionResult {
  final double confidence; // 0..1
  final String explanation;

  IdleDetectionResult({required this.confidence, required this.explanation});
}

class TimeSegment {
  final int? id;
  final String userId;
  final String taskId;
  final String projectId;
  final DateTime start;
  final DateTime end;
  final bool productive;
  final bool synced;

  TimeSegment({this.id, required this.userId, required this.taskId, required this.projectId, required this.start, required this.end, this.productive = true, this.synced = false});

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'userId': userId,
        'taskId': taskId,
        'projectId': projectId,
        'start': start.toUtc().toIso8601String(),
        'end': end.toUtc().toIso8601String(),
        'productive': productive ? 1 : 0,
        'synced': synced ? 1 : 0,
      };

  static TimeSegment fromMap(Map<String, dynamic> m) => TimeSegment(
        id: m['id'] is int ? m['id'] as int : int.tryParse(m['id'].toString()),
        userId: m['userId'] as String,
        taskId: m['taskId'] as String,
        projectId: m['projectId'] as String,
        start: DateTime.parse(m['start']).toUtc(),
        end: DateTime.parse(m['end']).toUtc(),
        productive: (m['productive'] == 1 || m['productive'] == true),
        synced: (m['synced'] == 1 || m['synced'] == true),
      );
}
