# Leave & Payroll System - Technical Architecture

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        Flutter App                           │
├─────────────────────────────────────────────────────────────┤
│  • LeaveManagementScreen    • PayslipScreen                 │
│  • LeaveService             • PayrollService                │
│  • API Integration Layer    • Local Database Caching         │
└──────────────────────┬──────────────────────────────────────┘
                       │ HTTPS REST API
┌──────────────────────▼──────────────────────────────────────┐
│                    NestJS Backend                            │
├─────────────────────────────────────────────────────────────┤
│  LeaveModule                │ PayrollModule                  │
│  ├── LeaveController        ├── PayrollController           │
│  ├── LeaveService           ├── PayrollService              │
│  └── DTOs                   └── DTOs                        │
└──────────────────────┬──────────────────────────────────────┘
                       │ Prisma ORM
┌──────────────────────▼──────────────────────────────────────┐
│               PostgreSQL Database                            │
├─────────────────────────────────────────────────────────────┤
│  Users          LeaveType       SalaryComponent              │
│  LeaveBalance   LeaveRequest    SalaryStructure              │
│  Payslip        PayslipLineItem PayslipDeduction             │
│  HolidayCalendar                                             │
└─────────────────────────────────────────────────────────────┘
```

## Leave Management Workflow

```
┌─────────────────┐
│   Employee      │
└────────┬────────┘
         │
         │ Submit Leave Request
         ▼
    ┌─────────────────────────────────────┐
    │  LeaveRequest (PENDING)              │
    │  - Start Date                        │
    │  - End Date                          │
    │  - Reason                            │
    │  - Status: PENDING                   │
    └────────┬────────────────────────────┘
             │
             │ Check Leave Balance
             ▼
    ┌─────────────────────────────────────┐
    │  Sufficient Balance?                 │
    │  YES ─→ Continue                     │
    │  NO  ─→ Reject                       │
    └────────┬────────────────────────────┘
             │
             │ Manager/HR Review
             ▼
    ┌─────────────────────────────────────┐
    │  Decision                            │
    ├─────────────────────────────────────┤
    │  ├── APPROVE                         │
    │  │   └─→ Deduct from Balance         │
    │  │       Status: APPROVED            │
    │  │                                   │
    │  └── REJECT                          │
    │      └─→ Status: REJECTED            │
    └─────────────────────────────────────┘
             │
             ▼
    ┌─────────────────────────────────────┐
    │  Notification to Employee            │
    └─────────────────────────────────────┘
```

## Payroll Processing Workflow

```
┌──────────────────────────────────────────────────────────────┐
│  Monthly Payroll Processing                                  │
└──────────┬───────────────────────────────────────────────────┘
           │
           ├─ 1. Gather Employee Data
           │      ├── Salary Structure
           │      ├── Attendance Records
           │      └── Leave Taken
           │
           ├─ 2. Calculate Salary
           │      ├── Base Salary
           │      ├── Allowances (Basic × %)
           │      ├── Prorate by Attendance
           │      └── Gross Salary = Sum
           │
           ├─ 3. Calculate Deductions
           │      ├── Income Tax (10% of gross)
           │      ├── PF (12% of basic)
           │      ├── ESI (if applicable)
           │      └── Total Deductions
           │
           ├─ 4. Calculate Net
           │      └── Net = Gross - Deductions
           │
           ├─ 5. Generate Payslip
           │      ├── Status: DRAFT
           │      ├── Line Items (earnings)
           │      ├── Deductions
           │      └── Summary
           │
           ├─ 6. HR Review & Approval
           │      ├── Status: APPROVED
           │      └── ApprovedAt: Timestamp
           │
           └─ 7. Mark Paid
                  └── Status: PAID
                      PaidAt: Timestamp
```

## Data Models - Detailed

### Leave Module

```
LeaveType {
  id: Int (PK)
  name: String (unique)
  description: String?
  maxDaysPerYear: Int
  requiresApproval: Boolean
  createdAt: DateTime
}

LeaveBalance {
  id: Int (PK)
  userId: Int (FK)
  leaveTypeId: Int (FK)
  totalDays: Float
  usedDays: Float
  remainingDays: Float
  year: Int
  
  Unique(userId, leaveTypeId, year)
}

LeaveRequest {
  id: Int (PK)
  userId: Int (FK)
  leaveTypeId: Int (FK)
  startDate: DateTime
  endDate: DateTime
  numberOfDays: Float
  reason: String?
  status: Enum (PENDING, APPROVED, REJECTED, CANCELLED)
  approverNotes: String?
  approvedById: Int? (FK)
  approvedAt: DateTime?
  createdAt: DateTime
  updatedAt: DateTime
}

HolidayCalendar {
  id: Int (PK)
  name: String
  date: DateTime
  description: String?
  type: String (NATIONAL, REGIONAL, COMPANY)
  year: Int
  createdAt: DateTime
}
```

### Payroll Module

```
SalaryComponent {
  id: Int (PK)
  name: String (unique)
  type: Enum (BASIC, ALLOWANCE, DEDUCTION)
  description: String?
  isFixed: Boolean
  createdAt: DateTime
}

SalaryStructure {
  id: Int (PK)
  userId: Int (FK)
  componentId: Int (FK)
  amount: Float
  percentage: Float?
  effectiveFrom: DateTime
  effectiveTo: DateTime?
  createdAt: DateTime
  
  Unique(userId, componentId, effectiveFrom)
}

Payslip {
  id: Int (PK)
  userId: Int (FK)
  month: Int (1-12)
  year: Int (2025)
  baseSalary: Float
  totalEarnings: Float
  totalDeductions: Float
  netSalary: Float
  workingDays: Int
  attendedDays: Int
  leaveTaken: Float
  status: Enum (DRAFT, SUBMITTED, APPROVED, PAID)
  generatedAt: DateTime
  approvedById: Int? (FK)
  approvedAt: DateTime?
  paidAt: DateTime?
  
  Unique(userId, month, year)
}

PayslipLineItem {
  id: Int (PK)
  payslipId: Int (FK)
  componentId: Int (FK)
  description: String
  amount: Float
  quantity: Float
  rate: Float?
}

PayslipDeduction {
  id: Int (PK)
  payslipId: Int (FK)
  type: Enum (INCOME_TAX, PF, ESI, OTHER)
  amount: Float
  description: String?
}
```

## API Response Examples

### Leave Request Response
```json
{
  "id": 1,
  "userId": 5,
  "leaveTypeId": 1,
  "startDate": "2025-02-10",
  "endDate": "2025-02-12",
  "numberOfDays": 3,
  "reason": "Personal work",
  "status": "PENDING",
  "approverNotes": null,
  "approvedAt": null,
  "createdAt": "2025-01-22T10:30:00Z",
  "user": {
    "id": 5,
    "name": "Raj Kumar",
    "email": "raj@company.com"
  },
  "leaveType": {
    "id": 1,
    "name": "Sick Leave",
    "maxDaysPerYear": 10
  }
}
```

### Payslip Response
```json
{
  "id": 1,
  "userId": 5,
  "month": 1,
  "year": 2025,
  "baseSalary": 50000,
  "totalEarnings": 60000,
  "totalDeductions": 8400,
  "netSalary": 51600,
  "workingDays": 22,
  "attendedDays": 20,
  "leaveTaken": 2,
  "status": "DRAFT",
  "generatedAt": "2025-01-22T10:00:00Z",
  "approvedAt": null,
  "paidAt": null,
  "lineItems": [
    {
      "id": 1,
      "description": "Basic Salary",
      "amount": 50000,
      "component": {
        "id": 1,
        "name": "Basic Salary",
        "type": "BASIC"
      }
    }
  ],
  "deductions": [
    {
      "id": 1,
      "type": "INCOME_TAX",
      "amount": 6000,
      "description": "Income Tax (TDS)"
    },
    {
      "id": 2,
      "type": "PF",
      "amount": 2400,
      "description": "Provident Fund"
    }
  ]
}
```

## Calculation Examples

### Payslip Calculation Example

**Input:**
- Basic Salary: ₹50,000
- HRA (40% of Basic): ₹20,000
- DA (20% of Basic): ₹10,000
- Working Days: 22
- Attended Days: 20
- Leave Taken: 2

**Calculations:**
```
Basic Salary:           ₹50,000 (fixed)
HRA:                    ₹40,000 × 0.40 × (20/22) = ₹18,182 (prorated)
DA:                     ₹50,000 × 0.20 × (20/22) = ₹9,091 (prorated)
─────────────────────────────────────────
Gross Salary:           ₹77,273

Income Tax (10%):       ₹7,727
PF (12% of basic):      ₹6,000
─────────────────────────────────────────
Total Deductions:       ₹13,727

Net Salary:             ₹63,546
```

### Leave Balance Calculation

**Initial Balance (Annual):**
- Sick Leave: 10 days
- Casual Leave: 12 days
- Personal Leave: 5 days

**After Approval:**
- Requested: 3 days of Sick Leave
- Used: 3 days
- Remaining: 7 days

**Calculation Logic:**
```
Remaining = Total - Used
7 = 10 - 3
```

## Error Handling

### Leave Request Errors
```
1. Insufficient Balance
   Status: 400
   Message: "Insufficient leave balance for this leave type"

2. Invalid Date Range
   Status: 400
   Message: "End date must be after start date"

3. Past Date
   Status: 400
   Message: "Cannot apply leave for past dates"

4. Leave Type Not Found
   Status: 404
   Message: "Leave type not found"
```

### Payslip Errors
```
1. No Salary Structure
   Status: 400
   Message: "No salary structure found for this employee"

2. Invalid Attendance
   Status: 400
   Message: "Attended days cannot be more than working days"

3. Already Generated
   Status: 409
   Message: "Payslip already exists for this month"

4. User Not Found
   Status: 404
   Message: "User not found"
```

## Performance Considerations

### Optimization Strategies
1. **Indexing**
   - Index on (userId, year) for LeaveBalance queries
   - Index on (userId, month, year) for Payslip queries
   - Index on (userId, leaveTypeId) for LeaveRequest queries

2. **Caching**
   - Cache salary components (rarely change)
   - Cache holiday calendar per year
   - Cache employee salary structure

3. **Batch Operations**
   - Bulk payslip generation with pagination
   - Batch leave balance initialization
   - Bulk holiday imports

## Security Considerations

1. **Access Control**
   - Employees can only view their own data
   - Managers can view team data
   - HR has full access
   - Implement fine-grained authorization

2. **Data Protection**
   - Encrypt sensitive payroll data
   - Audit logs for all modifications
   - Secure PDF generation for payslips

3. **Validation**
   - Input validation on all endpoints
   - Business logic validation (balance checks)
   - Date range validation
   - Department authorization checks

## Monitoring & Maintenance

### Key Metrics
- Leave request approval time
- Payslip generation duration
- API response times
- Database query performance

### Regular Tasks
- Archive old payslips
- Update leave balances at year start
- Validate attendance data
- Review approval workflows

---

**Document Version**: 1.0
**Last Updated**: January 22, 2026
