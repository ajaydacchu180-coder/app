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
import { PayrollService } from './payroll.service';
import {
  CreateSalaryStructureDto,
  CreatePayslipDto,
  UpdatePayslipDto,
  CreateSalaryComponentDto,
} from './dto/payroll.dto';

@Controller('payroll')
@UseGuards(JwtAuthGuard, RolesGuard)
export class PayrollController {
  constructor(private payrollService: PayrollService) {}

  // ========== SALARY COMPONENTS ==========
  @Get('components')
  async getSalaryComponents() {
    return this.payrollService.getSalaryComponents();
  }

  @Post('components')
  @Roles('admin', 'hr')
  async createSalaryComponent(@Body() dto: CreateSalaryComponentDto) {
    return this.payrollService.createSalaryComponent(dto);
  }

  // ========== SALARY STRUCTURE ==========
  @Get('structure/:userId')
  async getSalaryStructure(@Param('userId') userId: string) {
    return this.payrollService.getSalaryStructure(parseInt(userId));
  }

  @Post('structure/:userId')
  @Roles('admin', 'hr')
  async setSalaryStructure(
    @Param('userId') userId: string,
    @Body() components: CreateSalaryStructureDto[],
  ) {
    return this.payrollService.setSalaryStructure(parseInt(userId), components);
  }

  // ========== PAYSLIPS ==========
  @Get('payslips')
  async getPayslips(
    @Request() req: RequestWithUser,
    @Query('month') month?: string,
    @Query('year') year?: string,
    @Query('status') status?: string,
    @Query('userId') userId?: string,
  ) {
    const queryUserId = userId ? parseInt(userId) : req.user?.id;

    return this.payrollService.getPayslips(
      queryUserId,
      month ? parseInt(month) : undefined,
      year ? parseInt(year) : undefined,
      status,
    );
  }

  @Get('payslips/user/:userId')
  async getPayslipsByUser(@Param('userId') userId: string) {
    return this.payrollService.getPayslipsByUser(parseInt(userId));
  }

  @Get('payslips/:id')
  async getPayslipById(@Param('id') id: string) {
    return this.payrollService.getPayslipById(parseInt(id));
  }

  @Post('payslips/generate')
  @Roles('admin', 'hr')
  async generatePayslip(@Body() dto: CreatePayslipDto) {
    return this.payrollService.generatePayslip(dto);
  }

  @Post('payslips/generate-month')
  @Roles('admin', 'hr')
  async generatePayslipsForMonth(
    @Body() data: { month: number; year: number; workingDays: number },
  ) {
    return this.payrollService.generatePayslipsForMonth(data.month, data.year, data.workingDays);
  }

  @Put('payslips/:id')
  @Roles('admin', 'hr')
  async updatePayslip(@Param('id') id: string, @Body() dto: UpdatePayslipDto) {
    return this.payrollService.updatePayslip(parseInt(id), dto);
  }

  @Put('payslips/:id/approve')
  @Roles('admin', 'hr')
  async approvePayslip(@Param('id') id: string, @Request() req: RequestWithUser) {
    return this.payrollService.approvePayslip(parseInt(id), req.user?.id);
  }

  @Put('payslips/:id/mark-paid')
  @Roles('admin', 'hr')
  async markPayslipAsPaid(@Param('id') id: string) {
    return this.payrollService.markPayslipAsPaid(parseInt(id));
  }

  // ========== SALARY DATA ==========
  @Get('salary-data/:userId')
  async getSalaryData(@Param('userId') userId: string) {
    return this.payrollService.getSalaryData(parseInt(userId));
  }

  @Get('my-salary-data')
  async getMySalaryData(@Request() req: RequestWithUser) {
    return this.payrollService.getSalaryData(req.user?.id);
  }
}
