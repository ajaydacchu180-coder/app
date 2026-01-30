import 'dart:math';
import '../core/models.dart';

/// Privacy-safe AIService mock: uses non-invasive signals to infer idle.
class AIService {
  /// Analyze a small set of signals and return IdleDetectionResult.
  /// Signals must be privacy-safe: activity timestamps, app focus durations, chat-only flags.
  Future<IdleDetectionResult> detectIdle({required List<int> recentActivityEvents, required bool chatOnly}) async {
    await Future.delayed(const Duration(milliseconds: 220));
    final inactivityScore = (recentActivityEvents.isEmpty) ? 1.0 : max(0.0, 1 - (recentActivityEvents.length / 20));
    final chatPenalty = chatOnly ? 0.5 : 0.0; // chat-only reduces confidence this is productive
    final confidence = (inactivityScore + chatPenalty).clamp(0.0, 1.0);
    final explanation = chatOnly
        ? 'User only active in chat; low task activity detected.'
        : (inactivityScore > 0.6 ? 'No interaction events recently.' : 'Some recent interactions detected.');
    return IdleDetectionResult(confidence: confidence, explanation: explanation);
  }
}
