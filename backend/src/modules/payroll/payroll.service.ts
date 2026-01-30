import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import {
  CreateSalaryStructureDto,
  CreatePayslipDto,
  UpdatePayslipDto,
  CreateSalaryComponentDto,
} from './dto/payroll.dto';

@Injectable()
export class PayrollService {
  constructor(private prisma: PrismaService) {}

  // ========== SALARY COMPONENTS ==========
  async getSalaryComponents() {
    return this.prisma.salaryComponent.findMany();
  }

  async createSalaryComponent(dto: CreateSalaryComponentDto) {
    return this.prisma.salaryComponent.create({
      data: dto,
    });
  }

  // ========== SALARY STRUCTURE ==========
  async setSalaryStructure(userId: number, components: CreateSalaryStructureDto[]) {
    const promises = components.map((comp) =>
      this.prisma.salaryStructure.upsert({
        where: {
          userId_componentId_effectiveFrom: {
            userId,
            componentId: comp.componentId,
            effectiveFrom: new Date(comp.effectiveFrom),
          },
        },
        create: {
          userId,
          componentId: comp.componentId,
          amount: comp.amount,
          percentage: comp.percentage,
          effectiveFrom: new Date(comp.effectiveFrom),
          effectiveTo: comp.effectiveTo ? new Date(comp.effectiveTo) : null,
        },
        update: {
          amount: comp.amount,
          percentage: comp.percentage,
          effectiveTo: comp.effectiveTo ? new Date(comp.effectiveTo) : null,
        },
      }),
    );

    return Promise.all(promises);
  }

  async getSalaryStructure(userId: number, date?: Date) {
    const queryDate = date || new Date();

    return this.prisma.salaryStructure.findMany({
      where: {
        userId,
        effectiveFrom: { lte: queryDate },
        OR: [{ effectiveTo: null }, { effectiveTo: { gte: queryDate } }],
      },
      include: { component: true },
    });
  }

  // ========== PAYSLIP GENERATION ==========
  async generatePayslip(dto: CreatePayslipDto) {
    const { userId, month, year, workingDays, attendedDays, leaveTaken } = dto;

    // Get salary structure
    const salaryStructure = await this.getSalaryStructure(userId);

    if (salaryStructure.length === 0) {
      throw new Error('No salary structure found for this employee');
    }

    let baseSalary = 0;
    let totalEarnings = 0;
    const lineItems = [];

    // Calculate earnings
    for (const struct of salaryStructure) {
      if (struct.component.type === 'BASIC') {
        baseSalary = struct.amount;
      }

      // Prorate for attendance (if not full days worked)
      const attendancePercentage = attendedDays / workingDays;
      let componentAmount = struct.amount;

      if (struct.percentage) {
        componentAmount = (baseSalary * struct.percentage) / 100;
      }

      // Apply proration for non-fixed allowances
      if (!struct.component.isFixed && struct.component.type === 'ALLOWANCE') {
        componentAmount = componentAmount * attendancePercentage;
      }

      totalEarnings += componentAmount;

      lineItems.push({
        componentId: struct.componentId,
        description: struct.component.name,
        amount: componentAmount,
        quantity: 1,
        rate: componentAmount,
      });
    }

    // Calculate deductions (simplified)
    const deductions = [];
    let totalDeductions = 0;

    // Income Tax (simplified calculation - ~10% of gross)
    const incomeTax = Math.round(totalEarnings * 0.1);
    deductions.push({
      type: 'INCOME_TAX',
      amount: incomeTax,
      description: 'Income Tax (TDS)',
    });

    // PF (12% of basic)
    const pf = Math.round(baseSalary * 0.12);
    deductions.push({
      type: 'PF',
      amount: pf,
      description: 'Provident Fund',
    });

    totalDeductions = incomeTax + pf;

    const netSalary = totalEarnings - totalDeductions;

    // Create payslip
    const payslip = await this.prisma.payslip.create({
      data: {
        userId,
        month,
        year,
        baseSalary,
        totalEarnings,
        totalDeductions,
        netSalary,
        workingDays,
        attendedDays,
        leaveTaken,
        status: 'DRAFT',
      },
    });

    // Add line items
    await Promise.all(
      lineItems.map((item) =>
        this.prisma.payslipLineItem.create({
          data: {
            ...item,
            payslipId: payslip.id,
          },
        }),
      ),
    );

    // Add deductions
    await Promise.all(
      deductions.map((deduction) =>
        this.prisma.payslipDeduction.create({
          data: {
            ...deduction,
            payslipId: payslip.id,
          },
        }),
      ),
    );

    return this.getPayslipById(payslip.id);
  }

  async getPayslipById(payslipId: number) {
    return this.prisma.payslip.findUnique({
      where: { id: payslipId },
      include: {
        user: true,
        lineItems: { include: { component: true } },
        deductions: true,
        approvedBy: true,
      },
    });
  }

  async getPayslips(userId?: number, month?: number, year?: number, status?: string) {
    return this.prisma.payslip.findMany({
      where: {
        ...(userId && { userId }),
        ...(month && { month }),
        ...(year && { year }),
        ...(status && { status }),
      },
      include: {
        user: true,
        lineItems: { include: { component: true } },
        deductions: true,
        approvedBy: true,
      },
      orderBy: [{ year: 'desc' }, { month: 'desc' }],
    });
  }

  async getPayslipsByUser(userId: number) {
    return this.prisma.payslip.findMany({
      where: { userId },
      include: {
        lineItems: { include: { component: true } },
        deductions: true,
        approvedBy: true,
      },
      orderBy: [{ year: 'desc' }, { month: 'desc' }],
    });
  }

  async updatePayslip(payslipId: number, dto: UpdatePayslipDto) {
    return this.prisma.payslip.update({
      where: { id: payslipId },
      data: dto,
      include: {
        user: true,
        lineItems: { include: { component: true } },
        deductions: true,
      },
    });
  }

  async approvePayslip(payslipId: number, approverId: number) {
    return this.prisma.payslip.update({
      where: { id: payslipId },
      data: {
        status: 'APPROVED',
        approvedById: approverId,
        approvedAt: new Date(),
      },
      include: {
        user: true,
        lineItems: { include: { component: true } },
        deductions: true,
        approvedBy: true,
      },
    });
  }

  async markPayslipAsPaid(payslipId: number) {
    return this.prisma.payslip.update({
      where: { id: payslipId },
      data: {
        status: 'PAID',
        paidAt: new Date(),
      },
    });
  }

  async generatePayslipsForMonth(month: number, year: number, workingDays: number) {
    // Get all active employees
    const employees = await this.prisma.user.findMany({
      where: {
        role: { name: { in: ['employee'] } },
      },
    });

    const payslips = [];

    for (const employee of employees) {
      // Get attended days from attendance records (simplified - should use actual attendance data)
      const attendedDays = workingDays; // This should be calculated from actual attendance

      const payslip = await this.generatePayslip({
        userId: employee.id,
        month,
        year,
        workingDays,
        attendedDays,
        leaveTaken: 0, // Should be calculated from leave records
      });

      payslips.push(payslip);
    }

    return payslips;
  }

  // ========== SALARY ADVANCE ==========
  async getSalaryData(userId: number) {
    const currentMonth = new Date().getMonth() + 1;
    const currentYear = new Date().getFullYear();

    const latestPayslip = await this.prisma.payslip.findFirst({
      where: { userId },
      orderBy: [{ year: 'desc' }, { month: 'desc' }],
    });

    const salaryStructure = await this.getSalaryStructure(userId);

    return {
      latestPayslip,
      salaryStructure,
      currentMonth,
      currentYear,
    };
  }
}
