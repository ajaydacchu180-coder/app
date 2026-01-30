import { Module } from '@nestjs/common';
import { TimesheetService } from './timesheet.service';
import { PrismaModule } from '../../prisma/prisma.module';
import { TimesheetController } from './timesheet.controller';
import { RolesGuard } from '../../common/guards/roles.guard';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

@Module({
	imports: [PrismaModule],
	providers: [TimesheetService, RolesGuard, JwtAuthGuard],
	controllers: [TimesheetController],
	exports: [TimesheetService],
})
export class TimesheetModule {}
