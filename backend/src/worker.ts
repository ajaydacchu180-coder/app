import { PrismaService } from './prisma/prisma.service';
import { AiService } from './modules/ai/ai.service';
import { AiWorker } from './modules/ai/ai.worker';

async function bootstrap() {
  const prisma = new PrismaService();
  await prisma.$connect();

  const ai = new AiService(prisma);
  const worker = new AiWorker(prisma, ai);

  process.on('SIGINT', async () => {
    console.log('Shutdown signal received, closing worker...');
    await worker.close();
    await prisma.$disconnect();
    process.exit(0);
  });

  console.log('Worker started');
}

bootstrap().catch(err => {
  console.error('Worker bootstrap failed', err);
  process.exit(1);
});
