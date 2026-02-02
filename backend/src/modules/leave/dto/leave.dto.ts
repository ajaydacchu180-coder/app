export class CreateLeaveRequestDto {
  leaveTypeId!: number;
  startDate!: Date;
  endDate!: Date;
  reason?: string;
}

export class UpdateLeaveRequestDto {
  startDate?: Date;
  endDate?: Date;
  reason?: string;
  status?: string;
}

export class ApproveLeaveRequestDto {
  notes?: string;
}

export class LeaveRequestDto {
  id!: number;
  userId!: number;
  leaveTypeId!: number;
  startDate!: Date;
  endDate!: Date;
  numberOfDays!: number;
  reason?: string;
  status!: string;
  approverNotes?: string;
  approvedAt?: Date;
  createdAt!: Date;
}

export class LeaveBalanceDto {
  id!: number;
  userId!: number;
  leaveTypeId!: number;
  totalDays!: number;
  usedDays!: number;
  remainingDays!: number;
  year!: number;
}

export class CreateHolidayDto {
  name!: string;
  date!: Date;
  description?: string;
  type!: string;
  year!: number;
}
