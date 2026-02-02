import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { TimesheetService } from './timesheet.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/guards/roles.decorator';

@Controller('api/v1/timesheet')
@UseGuards(JwtAuthGuard, RolesGuard)
export class TimesheetController {
  constructor(private svc: TimesheetService) {}

  @Post('generate-draft')
  @Roles('EMPLOYEE')
  async generateDraft(@Body() body: any) {
    const { userId, date } = body;
    return this.svc.generateDraftTimesheet(userId, new Date(date));
  }

  @Post('submit')
  @Roles('EMPLOYEE')
  async submit(@Body() body: any) {
    const { timesheetId, approverId } = body;
    return this.svc.submitTimesheet(timesheetId, approverId);
  }
}
