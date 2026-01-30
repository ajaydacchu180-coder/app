import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class AttendanceService {
  constructor(private prisma: PrismaService) {}

  // Check-in: create session if none active
  async checkIn(userId: number) {
    // server-generated timestamp
    const active = await this.prisma.attendanceSession.findFirst({ where: { userId, endedAt: null } });
    if (active) throw new BadRequestException('Active session exists');
    const session = await this.prisma.attendanceSession.create({ data: { userId, state: 'CHECKED_IN' } });
    await this.prisma.attendanceEvent.create({ data: { sessionId: session.id, type: 'CHECK_IN' } });
    return session;
  }

  async checkOut(userId: number) {
    const active = await this.prisma.attendanceSession.findFirst({ where: { userId, endedAt: null } });
    if (!active) throw new BadRequestException('No active session');
    // enforce state transitions server-side
    await this.prisma.attendanceEvent.create({ data: { sessionId: active.id, type: 'CHECK_OUT' } });
    const updated = await this.prisma.attendanceSession.update({ where: { id: active.id }, data: { state: 'CHECKED_OUT', endedAt: new Date() } });
    return updated;
  }
}
