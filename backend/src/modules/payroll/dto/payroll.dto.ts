export class CreateSalaryComponentDto {
  name!: string;
  type!: 'BASIC' | 'ALLOWANCE' | 'DEDUCTION';
  description?: string;
  isFixed?: boolean;
}

export class CreateSalaryStructureDto {
  componentId!: number;
  amount!: number;
  percentage?: number;
  effectiveFrom!: Date | string;
  effectiveTo?: Date | string;
}

export class CreatePayslipDto {
  userId!: number;
  month!: number;
  year!: number;
  workingDays!: number;
  attendedDays!: number;
  leaveTaken?: number;
}

export class UpdatePayslipDto {
  status?: string;
  workingDays?: number;
  attendedDays?: number;
  leaveTaken?: number;
}

export class PayslipDto {
  id!: number;
  userId!: number;
  month!: number;
  year!: number;
  baseSalary!: number;
  totalEarnings!: number;
  totalDeductions!: number;
  netSalary!: number;
  workingDays!: number;
  attendedDays!: number;
  leaveTaken!: number;
  status!: string;
  generatedAt!: Date;
  approvedAt?: Date;
  paidAt?: Date;
}

export class PayslipLineItemDto {
  id!: number;
  payslipId!: number;
  componentId!: number;
  description!: string;
  amount!: number;
  quantity!: number;
  rate?: number;
}

export class PayslipDeductionDto {
  id!: number;
  payslipId!: number;
  type!: string;
  amount!: number;
  description?: string;
}
