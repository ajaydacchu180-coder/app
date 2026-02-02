import { Module } from '@nestjs/common';
import { AttendanceService } from './attendance.service';
import { AttendanceController } from './attendance.controller';
import { AuthModule } from '../auth/auth.module';
import { PrismaModule } from '../../prisma/prisma.module';
import { RolesGuard } from '../../common/guards/roles.guard';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

@Module({
  imports: [AuthModule, PrismaModule],
  providers: [AttendanceService, RolesGuard, JwtAuthGuard],
  controllers: [AttendanceController],
})
export class AttendanceModule {}
