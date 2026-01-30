import type { INestApplication } from '@nestjs/common';

// Placeholder for Bull Board setup
// To enable, install: npm i @bull-board/api @bull-board/express @types/express
// Then uncomment the full implementation in production
export function setupBullBoard(app: INestApplication) {
  // TODO: Wire up Bull Board UI at /admin/queues
  // For now, log that it's disabled
  console.log('Bull Board monitoring available at /admin/queues (setup pending)');
}
