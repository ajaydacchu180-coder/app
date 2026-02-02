import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';

/// IdleWatcher: monitors user activity signals (formerly integrated with work/chat)
/// Now serves as a base activity monitor for future features
class IdleWatcher {
  final Ref ref;
  Timer? _timer;
  StreamSubscription? _chatSub;
  int _recentActivityEvents = 0;

  IdleWatcher(this.ref) {
    final ws = ref.read(wsServiceProvider);
    // subscribe to activity signals for monitoring
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
    
    // Activity monitoring - currently disabled as work/attendance features are removed
    final ai = ref.read(aiServiceProvider);
    final recentEvents = List<int>.filled(_recentActivityEvents, 1);
    
    // Perform idle detection but don't take action on work/attendance (removed features)
    await ai.detectIdle(recentActivityEvents: recentEvents, chatOnly: _recentActivityEvents > 0 && recentEvents.isNotEmpty);

    // reset activity counter for next window
    _recentActivityEvents = 0;
  }

  void dispose() {
    _timer?.cancel();
    _chatSub?.cancel();
  }
}
