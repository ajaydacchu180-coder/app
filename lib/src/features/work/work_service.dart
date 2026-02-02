import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models.dart';
import '../../services/api_service.dart';
import '../../services/local_db.dart';


class WorkState {
  final TaskState taskState;
  final Task? activeTask;
  final DateTime? startedAt;

  WorkState({this.taskState = TaskState.stopped, this.activeTask, this.startedAt});
}

class WorkNotifier extends StateNotifier<WorkState> {
  final ApiService api;
  final String userId;

  WorkNotifier(this.api, this.userId) : super(WorkState());

  Future<void> startTask(Task task) async {
    if (state.taskState == TaskState.running) throw Exception('Another task is already running');
    final res = await api.startTask(userId, task);
    state = WorkState(taskState: TaskState.running, activeTask: task, startedAt: DateTime.parse(res['startedAt']).toUtc());
  }

  Future<void> pauseTask() async {
    if (state.taskState != TaskState.running || state.activeTask == null) throw Exception('No running task to pause');
    await api.pauseTask(userId, state.activeTask!);
    // create a time segment from startedAt -> now and mark productive by default
    final now = DateTime.now().toUtc();
    final seg = TimeSegment(userId: userId, taskId: state.activeTask!.id, projectId: state.activeTask!.projectId, start: state.startedAt ?? now, end: now, productive: true);
    await LocalDb.instance.insertSegment(seg);
    state = WorkState(taskState: TaskState.paused, activeTask: state.activeTask, startedAt: state.startedAt);
  }

  /// Pause due to AI-detected idle. Records a non-productive segment and leaves an explanation available.
  Future<void> idlePause({required String explanation, required double confidence}) async {
    if (state.taskState != TaskState.running || state.activeTask == null) return;
    await api.pauseTask(userId, state.activeTask!);
    final now = DateTime.now().toUtc();
    final seg = TimeSegment(userId: userId, taskId: state.activeTask!.id, projectId: state.activeTask!.projectId, start: state.startedAt ?? now, end: now, productive: false);
    await LocalDb.instance.insertSegment(seg);
    state = WorkState(taskState: TaskState.paused, activeTask: state.activeTask, startedAt: state.startedAt);
    // In a full implementation we'd record the reason in an audit log; UI may surface `explanation` and `confidence`.
  }

  Future<void> stopTask() async {
    // stop and record final segment if any
    if (state.taskState == TaskState.running && state.activeTask != null && state.startedAt != null) {
      final now = DateTime.now().toUtc();
      final seg = TimeSegment(userId: userId, taskId: state.activeTask!.id, projectId: state.activeTask!.projectId, start: state.startedAt!, end: now, productive: true);
      await LocalDb.instance.insertSegment(seg);
    }
    state = WorkState();
  }
}
