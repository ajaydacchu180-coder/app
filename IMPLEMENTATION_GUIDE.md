# Leave Management & Payroll Implementation Guide

## Overview
This document outlines the implementation of Leave Management and Payroll Management features for the Enterprise Attendance System.

## Database Schema Changes

### New Tables Added to Prisma Schema

#### Leave Management Tables
1. **LeaveType** - Defines types of leaves (Sick, Casual, Personal, etc.)
2. **LeaveBalance** - Tracks leave balance per employee per year
3. **LeaveRequest** - Stores leave applications with approval workflow
4. **LeaveApprovalWorkflow** - Manages approval escalation for leave requests
5. **HolidayCalendar** - Company holidays and regional holidays

#### Payroll Management Tables
1. **SalaryComponent** - Basic, Allowances, Deductions components
2. **SalaryStructure** - Employee-specific salary configuration
3. **Payslip** - Generated payslips with earnings and deductions
4. **PayslipLineItem** - Individual earning components in payslip
5. **PayslipDeduction** - Tax, PF, ESI deductions

## Backend Implementation

### Leave Module
**Location:** `backend/src/modules/leave/`

#### Services
- `LeaveService` - Core business logic for leave management
  - Leave type management
  - Leave balance tracking
  - Leave request CRUD operations
  - Leave approval/rejection workflow
  - Holiday calendar management
  - Business day calculation

#### Controllers
- `LeaveController` - REST API endpoints
  - GET `/leave/types` - Fetch all leave types
  - POST `/leave/types` - Create new leave type (HR only)
  - GET `/leave/balance/:year` - Get leave balance for a year
  - POST `/leave/request` - Create leave request
  - GET `/leave/requests` - Fetch leave requests
  - PUT `/leave/requests/:id/approve` - Approve leave (Manager/HR)
  - PUT `/leave/requests/:id/reject` - Reject leave (Manager/HR)
  - GET `/leave/holidays/:year` - Get holidays

#### DTOs
- `CreateLeaveRequestDto` - Leave request creation
- `UpdateLeaveRequestDto` - Leave request updates
- `LeaveBalanceDto` - Leave balance structure
- `LeaveRequestDto` - Leave request response

### Payroll Module
**Location:** `backend/src/modules/payroll/`

#### Services
- `PayrollService` - Payroll processing logic
  - Salary component management
  - Salary structure configuration
  - Payslip generation (single & bulk)
  - Payslip approval workflow
  - Salary data calculations with proration
  - Deduction calculations (Tax, PF, ESI)

#### Controllers
- `PayrollController` - REST API endpoints
  - GET `/payroll/components` - List salary components
  - POST `/payroll/components` - Create salary component (HR only)
  - GET `/payroll/structure/:userId` - Get salary structure
  - POST `/payroll/structure/:userId` - Set salary structure (HR only)
  - GET `/payroll/payslips` - List payslips with filters
  - POST `/payroll/payslips/generate` - Generate single payslip (HR only)
  - POST `/payroll/payslips/generate-month` - Generate bulk payslips (HR only)
  - PUT `/payroll/payslips/:id/approve` - Approve payslip (HR only)
  - PUT `/payroll/payslips/:id/mark-paid` - Mark as paid (HR only)
  - GET `/payroll/salary-data/:userId` - Get salary summary

#### DTOs
- `CreateSalaryComponentDto` - New salary component
- `CreateSalaryStructureDto` - Salary component assignment
- `CreatePayslipDto` - Payslip generation request
- `UpdatePayslipDto` - Payslip updates

## Frontend Implementation (Flutter)

### Screens Created

#### 1. Leave Management Screen
**Location:** `lib/src/screens/leave_management_screen.dart`

Features:
- **My Leaves Tab** - View all leave requests with status
- **Balance Tab** - Display leave balance per type with progress indicators
- **Requests Tab** - HR/Manager can view and approve pending requests
- Apply for Leave Dialog - Form to submit new leave requests
- Status indicators - PENDING, APPROVED, REJECTED, CANCELLED

UI Components:
- TabBar for navigation
- CommonCard widgets for display
- Status chips for visual feedback
- Progress bars for leave utilization
- Form validation and date pickers

#### 2. Payslip Screen
**Location:** `lib/src/screens/payslip_screen.dart`

Features:
- Month/Year filter dropdowns
- Payslip listing with key metrics
- Detailed payslip view modal showing:
  - Gross salary breakdown
  - Deductions (Tax, PF, ESI)
  - Net salary calculation
  - Attendance summary
- Download payslip as PDF
- Status indicators (DRAFT, APPROVED, PAID)

### Services Created

#### LeaveService
**Location:** `lib/src/features/leave/leave_service.dart`

Methods:
- `getLeaveTypes()` - Fetch available leave types
- `getMyLeaveRequests()` - Current user's leave requests
- `getLeaveBalance()` - Leave balance for current year
- `getLeaveRequestsForApproval()` - Pending approvals
- `createLeaveRequest()` - Submit new leave request
- `approveLeaveRequest()` - Approve pending request
- `rejectLeaveRequest()` - Reject leave request
- `getHolidays()` - Fetch company holidays

#### PayrollService
**Location:** `lib/src/features/payroll/payroll_service.dart`

Methods:
- `getPayslips()` - Fetch payslips with filters
- `getPayslipById()` - Single payslip details
- `getSalaryComponents()` - List salary components
- `getSalaryStructure()` - Employee's salary structure
- `getMySalaryData()` - Current salary information
- `approvePayslip()` - Approve payslip (HR)
- `markPayslipAsPaid()` - Update payment status

## API Integration Points

### Leave Management API

```bash
# Get leave types
GET /leave/types

# Create leave type (HR)
POST /leave/types
{
  "name": "Sick Leave",
  "maxDaysPerYear": 10,
  "requiresApproval": true
}

# Get leave balance
GET /leave/balance/2025

# Submit leave request
POST /leave/request
{
  "leaveTypeId": 1,
  "startDate": "2025-02-10",
  "endDate": "2025-02-12",
  "reason": "Personal work"
}

# Get leave requests
GET /leave/requests?status=PENDING

# Approve leave
PUT /leave/requests/1/approve
{ "notes": "Approved" }

# Get holidays
GET /leave/holidays/2025
```

### Payroll API

```bash
# Get salary components
GET /payroll/components

# Create component
POST /payroll/components
{
  "name": "Basic Salary",
  "type": "BASIC",
  "isFixed": true
}

# Get salary structure
GET /payroll/structure/1

# Generate payslip
POST /payroll/payslips/generate
{
  "userId": 1,
  "month": 1,
  "year": 2025,
  "workingDays": 22,
  "attendedDays": 20
}

# Get payslips
GET /payroll/payslips?month=1&year=2025

# Approve payslip
PUT /payroll/payslips/1/approve

# Mark paid
PUT /payroll/payslips/1/mark-paid
```

## Installation & Setup Steps

### 1. Database Migration
```bash
cd backend
npx prisma migrate dev --name add_leave_payroll
npx prisma generate
```

### 2. Backend Setup
```bash
cd backend
npm install

# Create seed data for leave types and salary components
# (Create seed.ts file)
npx prisma db seed
```

### 3. Flutter Setup
```bash
cd ../
flutter pub get
flutter pub cache repair
```

### 4. Environment Configuration
Add to `.env`:
```
LEAVE_APPROVAL_CHAIN_ENABLED=true
PAYROLL_TAX_RATE=0.10
PAYROLL_PF_RATE=0.12
```

## Key Features

### Leave Management
✅ Multiple leave types support
✅ Annual leave balance tracking
✅ Leave request workflow
✅ Manager/HR approval system
✅ Holiday calendar integration
✅ Business day calculation
✅ Leave history and reports

### Payroll Management
✅ Flexible salary structure configuration
✅ Multiple salary components (Basic, Allowances, Deductions)
✅ Automatic payslip generation
✅ Tax calculation (simplified, can be enhanced)
✅ PF & ESI deduction support
✅ Attendance-based proration
✅ Bulk payslip generation
✅ Payslip approval workflow
✅ Payment tracking

## Future Enhancements

1. **Advanced Expense Management**
   - Expense claim submission with receipts
   - Reimbursement tracking
   - Budget allocation per employee

2. **Enhanced Reporting**
   - Leave utilization reports
   - Payroll reconciliation reports
   - Department-wise analytics
   - Tax reports and compliance

3. **Integration Features**
   - Bank salary disbursement tracking
   - Statutory compliance calculations
   - Email notifications for approvals
   - SMS alerts for important events

4. **Mobile App Enhancements**
   - Biometric attendance integration
   - Geolocation check-in/out
   - Push notifications
   - Offline data sync

5. **Compliance & Security**
   - Audit logs for all payroll changes
   - Digital signature support
   - Data encryption at rest
   - Role-based access control enhancements

## Testing Checklist

- [ ] Leave type creation and retrieval
- [ ] Leave balance calculation
- [ ] Leave request approval workflow
- [ ] Business day calculation accuracy
- [ ] Salary component management
- [ ] Payslip generation with correct calculations
- [ ] Attendance-based proration
- [ ] Tax deduction calculation
- [ ] Bulk payslip generation
- [ ] Permission-based access control
- [ ] Error handling for edge cases
- [ ] PDF export functionality

## Support & Documentation

For detailed API documentation, see the controller files:
- [LeaveController](backend/src/modules/leave/leave.controller.ts)
- [PayrollController](backend/src/modules/payroll/payroll.controller.ts)

For frontend integration details, see service files:
- [LeaveService](lib/src/features/leave/leave_service.dart)
- [PayrollService](lib/src/features/payroll/payroll_service.dart)
