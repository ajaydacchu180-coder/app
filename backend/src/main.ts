import { NestFactory } from '@nestjs/core';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import helmet from 'helmet';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';
import { setupBullBoard } from './monitor/bull-board.setup';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.use(helmet());
  app.enableCors({ origin: true });
  // Global validation pipe (class-validator based)
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));

  // Mount Bull Board for job queue monitoring (admin access via /admin/queues)
  try {
    setupBullBoard(app);
    console.log('Bull Board mounted at /admin/queues');
  } catch (e) {
    console.warn('Bull Board setup failed:', e instanceof Error ? e.message : String(e));
  }

  // Setup Swagger API Documentation
  const config = new DocumentBuilder()
    .setTitle('Enterprise Productivity API')
    .setDescription('API documentation for Leave, Payroll, AI, and Attendance modules')
    .setVersion('1.0')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  await app.listen(process.env.PORT ? Number(process.env.PORT) : 3000);
  console.log('Server listening on', await app.getUrl());
}
bootstrap();
