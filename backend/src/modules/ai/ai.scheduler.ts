import { Injectable, OnModuleInit, OnModuleDestroy, Logger } from '@nestjs/common';
import { Queue, QueueScheduler } from 'bullmq';
import { AI_QUEUE_NAME, AI_SCORE_ALL_JOB } from './ai.constants';

@Injectable()
export class AiScheduler implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(AiScheduler.name);
  private queue: Queue;
  private scheduler: QueueScheduler;

  constructor() {
    const connection = { connection: { url: process.env.REDIS_URL || 'redis://localhost:6379' } } as any;
    this.queue = new Queue(AI_QUEUE_NAME, connection);
    this.scheduler = new QueueScheduler(AI_QUEUE_NAME, connection);
  }

  async onModuleInit() {
    // schedule a repeatable job that enqueues scoring of all users every 5 minutes
    await this.queue.add(
      AI_SCORE_ALL_JOB,
      {},
      {
        repeat: { every: 5 * 60 * 1000 },
        removeOnComplete: true,
        removeOnFail: false,
        attempts: 3,
        backoff: { type: 'exponential', delay: 5000 },
      },
    );
    this.logger.log('AI scoring scheduler initialized and repeatable job scheduled');
  }

  async onModuleDestroy() {
    await this.scheduler.close();
    await this.queue.close();
  }

  // helper to enqueue a single user scoring job immediately
  async enqueueUserScore(userId: number) {
    await this.queue.add('score-user', { userId }, { removeOnComplete: true, attempts: 3, backoff: { type: 'exponential', delay: 3000 } });
  }
}
