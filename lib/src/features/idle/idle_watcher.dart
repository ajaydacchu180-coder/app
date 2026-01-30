import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models.dart';
import '../../providers.dart';

/// IdleWatcher: subscribes to chat/activity signals and periodically asks AIService
/// whether the user appears idle. If confidence is high and a task is running,
/// it triggers an idle pause on the work notifier and updates attendance.
class IdleWatcher {
  final Ref ref;
  Timer? _timer;
  StreamSubscription? _chatSub;
  int _recentActivityEvents = 0;

  IdleWatcher(this.ref) {
    final ws = ref.read(wsServiceProvider);
    // increment activity counter when chat messages arrive (privacy-safe signal)
    _chatSub = ws.chatStream.listen((_) {
      _recentActivityEvents++;
    });
    start();
  }

  void start() {
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _check());
  }

  Future<void> _check() async {
    final auth = ref.read(authNotifierProvider);
    if (!auth.isAuthenticated) return;
    final userId = auth.user!.id;
    final workState = ref.read(workProvider(userId));
    if (workState.taskState != TaskState.running) {
      _recentActivityEvents = 0;
      return;
    }

    final ai = ref.read(aiServiceProvider);
    // Pass a simple privacy-safe list representing recent events (only counts)
    final recentEvents = List<int>.filled(_recentActivityEvents, 1);
    final chatOnly = _recentActivityEvents > 0 && recentEvents.isNotEmpty;
    final result = await ai.detectIdle(recentActivityEvents: recentEvents, chatOnly: chatOnly);

    // threshold is configurable; choose 0.75 as conservative default
    if (result.confidence >= 0.75) {
      final workNotifier = ref.read(workProvider(userId).notifier);
      await workNotifier.idlePause(explanation: result.explanation, confidence: result.confidence);
      // mark attendance as idle as well
      final attendance = ref.read(attendanceProvider(userId).notifier);
      attendance.setIdle();
    }

    // reset activity counter for next window
    _recentActivityEvents = 0;
  }

  void dispose() {
    _timer?.cancel();
    _chatSub?.cancel();
  }
}
