import { Logger } from '@nestjs/common';
import { Worker, Queue, Job } from 'bullmq';
import { AI_QUEUE_NAME, AI_SCORE_JOB, AI_SCORE_ALL_JOB } from './ai.constants';
import { PrismaService } from '../../prisma/prisma.service';
import { AiService } from './ai.service';

export class AiWorker {
  private worker: Worker;
  private readonly logger = new Logger(AiWorker.name);
  private queue: Queue;

  constructor(private prisma: PrismaService, private ai: AiService) {
    const opts = { connection: { url: process.env.REDIS_URL || 'redis://localhost:6379' } } as any;
    this.queue = new Queue(AI_QUEUE_NAME, opts);
    this.worker = new Worker(
      AI_QUEUE_NAME,
      async (job: Job) => {
        if (job.name === AI_SCORE_JOB || job.name === 'score-user') {
          const userId = job.data.userId as number;
          this.logger.log(`Processing score for user ${userId}`);
          await this.ai.scoreUser(userId);
          return { ok: true };
        }

        if (job.name === AI_SCORE_ALL_JOB || job.name === 'score-all-users') {
          this.logger.log('Processing score-all job: enqueueing per-user jobs');
          // fetch active users and enqueue per-user jobs
          const users = await this.prisma.user.findMany({ select: { id: true } });
          for (const u of users) {
            await this.queue.add('score-user', { userId: u.id }, { attempts: 3, backoff: { type: 'exponential', delay: 3000 }, removeOnComplete: true });
          }
          return { enqueued: users.length };
        }

        return { skipped: true };
      },
      opts,
    );

    this.worker.on('completed', job => this.logger.log(`Job ${job.id} completed`));
    this.worker.on('failed', (job, err) => this.logger.error(`Job ${job?.id} failed: ${err}`));
  }

  async close() {
    await this.worker.close();
    await this.queue.close();
  }
}
