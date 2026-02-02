import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './modules/auth/auth.module';
import { ChatModule } from './modules/chat/chat.module';
import { AttendanceModule } from './modules/attendance/attendance.module';
import { ProjectsModule } from './modules/projects/projects.module';
import { WorkModule } from './modules/work/work.module';
import { TimesheetModule } from './modules/timesheet/timesheet.module';
import { LeaveModule } from './modules/leave/leave.module';
import { PayrollModule } from './modules/payroll/payroll.module';
import { AiModule } from './modules/ai/ai.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    AuthModule,
    ChatModule,
    AttendanceModule,
    ProjectsModule,
    WorkModule,
    TimesheetModule,
    LeaveModule,
    PayrollModule,
    AiModule,
  ],
})
export class AppModule { }
