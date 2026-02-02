import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

export type Classification = 'ACTUALLY_WORKING' | 'LIKELY_IDLE' | 'NOT_WORKING';

@Injectable()
export class AiService {
  constructor(private prisma: PrismaService) { }

  // Hybrid rule-based scoring with explainable reason codes.
  // Returns classification, confidence (0-100), and reasons.
  async scoreUser(userId: number): Promise<{ classification: Classification; confidence: number; reasons: string[] }> {
    // Fetch recent activity signals and work sessions
    const fiveMinAgo = new Date(Date.now() - 5 * 60 * 1000);
    // Optimized: Use aggregation instead of fetching all raw signals
    const signalStats = await this.prisma.activitySignal.groupBy({
      by: ['type'],
      where: { userId, createdAt: { gte: fiveMinAgo } },
      _count: true,
    });

    const totalSignals = signalStats.reduce((acc, curr) => acc + curr._count, 0);
    const chatCount = signalStats.find(s => s.type === 'chat_message')?._count || 0;
    const taskCount = signalStats.find(s => s.type === 'task_interaction')?._count || 0;

    const recentWork = await this.prisma.workSession.findMany({ where: { userId, startAt: { lte: new Date() }, endAt: null } });

    const reasons: string[] = [];
    let score = 50; // neutral

    // Rule: active work session increases confidence
    if (recentWork.length > 0) {
      score += 30;
      reasons.push('active_work_session');
    }

    // Rule: recent interaction signals increase score
    if (totalSignals > 0) {
      score += Math.min(20, totalSignals * 5);
      reasons.push('recent_activity_signals');
    }

    // Rule: if there are many chat-only signals without task-related signals, reduce score
    if (chatCount > 0 && taskCount === 0) {
      score -= 25;
      reasons.push('chat_only_activity');
    }

    // Clamp
    const confidence = Math.max(0, Math.min(100, score));

    // Determine classification
    let classification: Classification = 'LIKELY_IDLE';
    if (confidence >= 70) classification = 'ACTUALLY_WORKING';
    else if (confidence <= 30) classification = 'NOT_WORKING';

    // Persist score for auditing and model training
    await this.prisma.aIProductivityScore.create({ data: { userId, score: Math.round(confidence), reason: reasons.join(','), confidence: Math.round(confidence) } });

    return { classification, confidence: Math.round(confidence), reasons };
  }
}
