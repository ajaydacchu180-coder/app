import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import {
  CreateLeaveRequestDto,
  LeaveBalanceDto,
  LeaveRequestDto,
  UpdateLeaveRequestDto,
} from './dto/leave.dto';

@Injectable()
export class LeaveService {
  constructor(private prisma: PrismaService) { }

  // ========== LEAVE TYPES ==========
  async getLeaveTypes() {
    return this.prisma.leaveType.findMany();
  }

  async createLeaveType(data: {
    name: string;
    description?: string;
    maxDaysPerYear: number;
    requiresApproval?: boolean;
  }) {
    return this.prisma.leaveType.create({
      data: {
        ...data,
        requiresApproval: data.requiresApproval ?? true,
      },
    });
  }

  // ========== LEAVE BALANCE ==========
  async getLeaveBalance(userId: number, year: number) {
    return this.prisma.leaveBalance.findMany({
      where: { userId, year },
      include: { leaveType: true },
    });
  }

  async updateLeaveBalance(userId: number, leaveTypeId: number, year: number, newBalance: number) {
    return this.prisma.leaveBalance.update({
      where: {
        userId_leaveTypeId_year: { userId, leaveTypeId, year },
      },
      data: {
        totalDays: newBalance,
        remainingDays: newBalance - (await this.getUsedLeaveDays(userId, leaveTypeId, year)),
      },
    });
  }

  private async getUsedLeaveDays(userId: number, leaveTypeId: number, year: number): Promise<number> {
    const result = await this.prisma.leaveRequest.aggregate({
      where: {
        userId,
        leaveTypeId,
        status: 'APPROVED',
        startDate: {
          gte: new Date(`${year}-01-01`),
          lt: new Date(`${year + 1}-01-01`),
        },
      },
      _sum: { numberOfDays: true },
    });
    return result._sum.numberOfDays || 0;
  }

  async initializeLeaveBalance(userId: number, year: number) {
    const leaveTypes = await this.prisma.leaveType.findMany();

    for (const leaveType of leaveTypes) {
      await this.prisma.leaveBalance.upsert({
        where: {
          userId_leaveTypeId_year: { userId, leaveTypeId: leaveType.id, year },
        },
        create: {
          userId,
          leaveTypeId: leaveType.id,
          totalDays: leaveType.maxDaysPerYear,
          remainingDays: leaveType.maxDaysPerYear,
          year,
        },
        update: {},
      });
    }
  }

  // ========== LEAVE REQUESTS ==========
  async createLeaveRequest(userId: number, dto: CreateLeaveRequestDto) {
    const numberOfDays = this.calculateBusinessDays(dto.startDate, dto.endDate);

    // Check leave balance
    const balance = await this.prisma.leaveBalance.findUnique({
      where: {
        userId_leaveTypeId_year: {
          userId,
          leaveTypeId: dto.leaveTypeId,
          year: new Date(dto.startDate).getFullYear(),
        },
      },
    });

    if (balance && balance.remainingDays < numberOfDays) {
      throw new Error('Insufficient leave balance');
    }

    return this.prisma.leaveRequest.create({
      data: {
        userId,
        leaveTypeId: dto.leaveTypeId,
        startDate: dto.startDate,
        endDate: dto.endDate,
        numberOfDays,
        reason: dto.reason,
        status: 'PENDING',
      },
      include: {
        user: true,
        leaveType: true,
        approvedBy: true,
      },
    });
  }

  async updateLeaveRequest(requestId: number, dto: UpdateLeaveRequestDto) {
    return this.prisma.leaveRequest.update({
      where: { id: requestId },
      data: dto,
      include: {
        user: true,
        leaveType: true,
        approvedBy: true,
      },
    });
  }

  async getLeaveRequests(userId?: number, status?: string) {
    return this.prisma.leaveRequest.findMany({
      where: {
        ...(userId && { userId }),
        ...(status && { status }),
      },
      include: {
        user: true,
        leaveType: true,
        approvedBy: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getLeaveRequestById(requestId: number) {
    return this.prisma.leaveRequest.findUnique({
      where: { id: requestId },
      include: {
        user: true,
        leaveType: true,
        approvedBy: true,
      },
    });
  }

  async approveLeaveRequest(requestId: number, approverId: number, notes?: string) {
    return this.prisma.$transaction(async (tx) => {
      const leaveRequest = await tx.leaveRequest.findUnique({
        where: { id: requestId },
        include: { leaveType: true },
      });

      if (!leaveRequest) throw new Error('Leave request not found');
      if (leaveRequest.status !== 'PENDING') throw new Error('Leave request is already processed');

      // Deduct from balance
      const year = new Date(leaveRequest.startDate).getFullYear();
      const balance = await tx.leaveBalance.findUnique({
        where: {
          userId_leaveTypeId_year: {
            userId: leaveRequest.userId,
            leaveTypeId: leaveRequest.leaveTypeId,
            year,
          },
        },
      });

      if (balance) {
        if (balance.remainingDays < leaveRequest.numberOfDays) {
          throw new Error('Insufficient leave balance at approval time');
        }

        await tx.leaveBalance.update({
          where: {
            userId_leaveTypeId_year: {
              userId: leaveRequest.userId,
              leaveTypeId: leaveRequest.leaveTypeId,
              year,
            },
          },
          data: {
            usedDays: { increment: leaveRequest.numberOfDays },
            remainingDays: { decrement: leaveRequest.numberOfDays },
          },
        });
      }

      return tx.leaveRequest.update({
        where: { id: requestId },
        data: {
          status: 'APPROVED',
          approvedById: approverId,
          approverNotes: notes,
          approvedAt: new Date(),
        },
      });
    });
  }

  async rejectLeaveRequest(requestId: number, approverId: number, notes?: string) {
    return this.prisma.leaveRequest.update({
      where: { id: requestId },
      data: {
        status: 'REJECTED',
        approvedById: approverId,
        approverNotes: notes,
        approvedAt: new Date(),
      },
    });
  }

  // ========== UTILITIES ==========
  private calculateBusinessDays(startDate: Date, endDate: Date): number {
    let count = 0;
    const current = new Date(startDate);

    while (current <= endDate) {
      const dayOfWeek = current.getDay();
      if (dayOfWeek !== 0 && dayOfWeek !== 6) {
        // Exclude Saturday and Sunday
        count++;
      }
      current.setDate(current.getDate() + 1);
    }

    return count;
  }

  async getHolidays(year: number) {
    return this.prisma.holidayCalendar.findMany({
      where: { year },
      orderBy: { date: 'asc' },
    });
  }

  async createHoliday(data: {
    name: string;
    date: Date;
    description?: string;
    type: string;
    year: number;
  }) {
    return this.prisma.holidayCalendar.create({ data });
  }
}
