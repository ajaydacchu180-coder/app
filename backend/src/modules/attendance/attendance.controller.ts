import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { AttendanceService } from './attendance.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/guards/roles.decorator';

@Controller('api/v1/attendance')
@UseGuards(JwtAuthGuard, RolesGuard)
export class AttendanceController {
  constructor(private svc: AttendanceService) {}

  @Post('check-in')
  @Roles('EMPLOYEE')
  async checkIn(@Body() body: any) {
    const { userId } = body;
    return this.svc.checkIn(userId);
  }

  @Post('check-out')
  @Roles('EMPLOYEE')
  async checkOut(@Body() body: any) {
    const { userId } = body;
    return this.svc.checkOut(userId);
  }
}
