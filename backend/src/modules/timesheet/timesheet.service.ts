import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class TimesheetService {
  constructor(private prisma: PrismaService) {}

  // Generate a draft timesheet for a user for a given date (UTC date)
  async generateDraftTimesheet(userId: number, dayUtc: Date) {
    const start = new Date(Date.UTC(dayUtc.getUTCFullYear(), dayUtc.getUTCMonth(), dayUtc.getUTCDate(), 0, 0, 0));
    const end = new Date(Date.UTC(dayUtc.getUTCFullYear(), dayUtc.getUTCMonth(), dayUtc.getUTCDate(), 23, 59, 59));

    // Query productive work sessions that intersect the day
    const sessions = await this.prisma.workSession.findMany({ where: { userId, productive: true, startAt: { lte: end }, OR: [{ endAt: null }, { endAt: { gte: start } }] }, include: { task: true } });

    // Aggregate hours per project/task
    const map = new Map<string, number>();
    for (const s of sessions) {
      const sStart = s.startAt < start ? start : s.startAt;
      const sEnd = s.endAt == null ? new Date() : (s.endAt > end ? end : s.endAt);
      const seconds = (sEnd.getTime() - sStart.getTime()) / 1000;
      const hours = seconds / 3600;
      const key = `${s.task?.projectId ?? 0}::${s.taskId ?? 0}`;
      map.set(key, (map.get(key) ?? 0) + hours);
    }

    // Build timesheet entries
    const entries = [] as any[];
    for (const [key, hours] of map.entries()) {
      const [projectId, taskId] = key.split('::').map(x => parseInt(x, 10));
      entries.push({ projectId, taskId, hours: Math.round(hours * 100) / 100 });
    }

    // Create draft timesheet record
    const ts = await this.prisma.timesheet.create({ data: { userId, date: start, status: 'DRAFT', draft: true } });
    for (const e of entries) {
      await this.prisma.timesheetEntry.create({ data: { timesheetId: ts.id, projectId: e.projectId, taskId: e.taskId, hours: e.hours } });
    }

    return { timesheetId: ts.id, entries };
  }

  // Submit timesheet (employee review -> creates approval entry)
  async submitTimesheet(timesheetId: number, approverId?: number) {
    await this.prisma.timesheet.update({ where: { id: timesheetId }, data: { draft: false, status: 'SUBMITTED' } });
    if (approverId) {
      await this.prisma.approval.create({ data: { timesheetId, approverId, approved: false } });
    }
    return { status: 'ok' };
  }
}
