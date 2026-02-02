import { Module } from '@nestjs/common';
import { AiService } from './ai.service';
import { PrismaModule } from '../../prisma/prisma.module';
import { AiScheduler } from './ai.scheduler';

@Module({
  imports: [PrismaModule],
  providers: [AiService, AiScheduler],
  exports: [AiService],
})
export class AiModule {}
