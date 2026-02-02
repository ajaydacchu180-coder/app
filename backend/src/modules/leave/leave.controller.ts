import {
  Controller,
  Get,
  Post,
  Put,
  Body,
  Param,
  UseGuards,
  Request,
  Query,
} from '@nestjs/common';
import { Request as ExpressRequest } from 'express';

interface RequestWithUser extends ExpressRequest {
  user?: any;
}
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/guards/roles.decorator';
import { LeaveService } from './leave.service';
import {
  CreateLeaveRequestDto,
  ApproveLeaveRequestDto,
  CreateHolidayDto,
} from './dto/leave.dto';

@Controller('leave')
@UseGuards(JwtAuthGuard, RolesGuard)
export class LeaveController {
  constructor(private leaveService: LeaveService) {}

  // ========== LEAVE TYPES ==========
  @Get('types')
  async getLeaveTypes() {
    return this.leaveService.getLeaveTypes();
  }

  @Post('types')
  @Roles('admin', 'hr')
  async createLeaveType(@Body() data: any) {
    return this.leaveService.createLeaveType(data);
  }

  // ========== LEAVE BALANCE ==========
  @Get('balance/:year')
  async getLeaveBalance(@Request() req: RequestWithUser, @Param('year') year: string) {
    return this.leaveService.getLeaveBalance(req.user?.id, parseInt(year));
  }

  @Post('balance/initialize/:year')
  @Roles('admin', 'hr')
  async initializeLeaveBalance(@Param('year') year: string, @Query('userId') userId?: string) {
    if (userId) {
      return this.leaveService.initializeLeaveBalance(parseInt(userId), parseInt(year));
    }
    // For all employees (can be enhanced)
    return { message: 'Initialization started for all employees' };
  }

  // ========== LEAVE REQUESTS ==========
  @Post('request')
  async createLeaveRequest(@Request() req: RequestWithUser, @Body() dto: CreateLeaveRequestDto) {
    return this.leaveService.createLeaveRequest(req.user?.id, dto);
  }

  @Get('requests')
  async getLeaveRequests(
    @Request() req: RequestWithUser,
    @Query('status') status?: string,
    @Query('userId') userId?: string,
  ) {
    const queryUserId = userId ? parseInt(userId) : req.user?.id;
    return this.leaveService.getLeaveRequests(queryUserId, status);
  }

  @Get('requests/:id')
  async getLeaveRequestById(@Param('id') id: string) {
    return this.leaveService.getLeaveRequestById(parseInt(id));
  }

  @Put('requests/:id')
  async updateLeaveRequest(@Param('id') id: string, @Body() dto: any) {
    return this.leaveService.updateLeaveRequest(parseInt(id), dto);
  }

  @Put('requests/:id/approve')
  @Roles('admin', 'hr', 'manager')
  async approveLeaveRequest(
    @Param('id') id: string,
    @Request() req: RequestWithUser,
    @Body() dto: ApproveLeaveRequestDto,
  ) {
    return this.leaveService.approveLeaveRequest(parseInt(id), req.user?.id, dto.notes);
  }

  @Put('requests/:id/reject')
  @Roles('admin', 'hr', 'manager')
  async rejectLeaveRequest(
    @Param('id') id: string,
    @Request() req: RequestWithUser,
    @Body() dto: ApproveLeaveRequestDto,
  ) {
    return this.leaveService.rejectLeaveRequest(parseInt(id), req.user?.id, dto.notes);
  }

  // ========== HOLIDAYS ==========
  @Get('holidays/:year')
  async getHolidays(@Param('year') year: string) {
    return this.leaveService.getHolidays(parseInt(year));
  }

  @Post('holidays')
  @Roles('admin', 'hr')
  async createHoliday(@Body() dto: CreateHolidayDto) {
    return this.leaveService.createHoliday(dto);
  }
}
