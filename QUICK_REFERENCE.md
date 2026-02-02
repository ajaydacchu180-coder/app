# Quick Reference Guide

## 🚀 Start Here

### Files Created/Modified (Summary)

```
📁 Backend
├── src/modules/
│   ├── leave/          (NEW) Complete leave system
│   ├── payroll/        (NEW) Complete payroll system
│   └── app.module.ts   (UPDATED) Module imports
└── prisma/
    └── schema.prisma   (UPDATED) 10 new tables

📁 Frontend
├── src/
│   ├── screens/
│   │   ├── leave_management_screen.dart   (NEW)
│   │   ├── payslip_screen.dart             (NEW)
│   │   ├── home_screen.dart                (UPDATED)
│   │   └── ...
│   ├── features/
│   │   ├── leave/leave_service.dart        (NEW)
│   │   ├── payroll/payroll_service.dart    (NEW)
│   │   └── ...
│   └── app.dart         (UPDATED) Routes

📁 Documentation
├── README_IMPLEMENTATION.md    (NEW) Overview
├── SETUP_GUIDE.md              (NEW) Quick start
├── IMPLEMENTATION_GUIDE.md     (NEW) Details
├── TECHNICAL_ARCHITECTURE.md   (NEW) Design
├── DEPLOYMENT_GUIDE.md         (NEW) Deployment
└── IMPLEMENTATION_CHECKLIST.md (NEW) Progress
```

---

## ⚡ Quick Commands

### Database Setup
```bash
# Create migration
cd backend && npx prisma migrate dev --name add_leave_payroll_systems

# Run seed
npx prisma db seed

# View schema
npx prisma studio

# Generate client
npx prisma generate
```

### Backend
```bash
# Install & build
npm install
npm run build

# Run
npm run start:dev    # Development
npm run start:prod   # Production

# Test
npm run test
npm run test:e2e
```

### Frontend
```bash
# Setup
flutter pub get
flutter pub cache repair

# Run
flutter run          # Debug
flutter run --release  # Release

# Build
flutter build apk    # Android
flutter build ios    # iOS
flutter build web    # Web
```

---

## 📊 Data Models Quick Reference

### Leave Models
```dart
LeaveType {
  id, name, maxDaysPerYear, requiresApproval
}

LeaveBalance {
  userId, leaveTypeId, year, totalDays, usedDays, remainingDays
}

LeaveRequest {
  userId, leaveTypeId, startDate, endDate, numberOfDays, 
  reason, status, approvedBy, approvedAt
}
```

### Payroll Models
```dart
SalaryComponent {
  id, name, type (BASIC/ALLOWANCE/DEDUCTION), isFixed
}

SalaryStructure {
  userId, componentId, amount, percentage, effectiveFrom, effectiveTo
}

Payslip {
  userId, month, year, baseSalary, totalEarnings, totalDeductions,
  netSalary, workingDays, attendedDays, status
}
```

---

## 🔌 API Examples

### Leave Request
```bash
# Submit leave
POST /leave/request
{
  "leaveTypeId": 1,
  "startDate": "2025-02-10",
  "endDate": "2025-02-12",
  "reason": "Personal"
}

# Get balance
GET /leave/balance/2025

# Approve
PUT /leave/requests/1/approve
{ "notes": "Approved" }
```

### Payroll
```bash
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

# Approve
PUT /payroll/payslips/1/approve
```

---

## 📱 Screen Navigation

```
Home Screen
├── Leave Management (/leave)
│   ├── My Leaves Tab
│   ├── Balance Tab
│   └── Requests Tab
├── Payslip (/payslip)
│   ├── Filter (Month/Year)
│   └── Payslip Details
└── ... other screens
```

---

## 🔐 Permissions

| Action | Permission |
|--------|-----------|
| View own leave | Employee |
| Submit leave request | Employee |
| View leave balance | Employee |
| Approve leave | Manager/HR |
| Create leave type | HR/Admin |
| View own payslip | Employee |
| Generate payslip | HR/Admin |
| Approve payslip | HR/Admin |
| Manage salary structure | HR/Admin |

---

## 🧪 Test Scenarios

### Leave Management
```
1. Submit leave request
   ✓ Valid dates, sufficient balance, proper type

2. Check balance before approval
   ✓ Deducts only after approval

3. Manager approval
   ✓ Only managers can approve
   ✓ Balance updated after approval

4. Business day calculation
   ✓ Weekends excluded
   ✓ Holidays considered
```

### Payroll
```
1. Generate payslip
   ✓ Correct gross calculation
   ✓ Deductions accurate
   ✓ Net salary correct

2. Attendance proration
   ✓ Salary reduced for absent days
   ✓ Allowances adjusted

3. Bulk generation
   ✓ All employees included
   ✓ Calculations consistent

4. Approval workflow
   ✓ Only HR can approve
   ✓ Status updated correctly
```

---

## 📊 Calculation Formulas

### Payslip Calculations
```
Gross = Basic + Allowances

Attendance% = AttendedDays / WorkingDays

Prorated Basic = Basic × Attendance%

Prorated Allowance = (Basic × AllowancePercent) × Attendance%

Gross Salary = Sum of all components

Income Tax = Gross × 10%

PF = Basic × 12%

Net Salary = Gross - Deductions
```

### Leave Balance
```
Total Days = MaxDaysPerYear (from LeaveType)

Used Days = Sum of approved leave days

Remaining = Total - Used

Proration = (Used / Total) × 100%
```

---

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| Migration fails | Check database connection, backup exists, rollback with `prisma migrate resolve` |
| Prisma mismatch | Run `npx prisma generate` |
| API errors | Check JWT token, verify role, check request body |
| UI not updating | Refresh page, clear cache, check API calls |
| Balance calculation wrong | Verify attendance data, check leave approval status |
| Payslip math off | Check salary components, verify tax rates, verify proration |

---

## 📋 Deployment Checklist

- [ ] Database migrated
- [ ] Seed data loaded
- [ ] Backend built & running
- [ ] Frontend dependencies installed
- [ ] Routes working
- [ ] API endpoints responsive
- [ ] Authentication working
- [ ] Leave request creation works
- [ ] Payslip generation works
- [ ] Approval workflow works
- [ ] All permissions verified
- [ ] Error handling tested
- [ ] Performance acceptable

---

## 🔗 Important Links

| Document | Purpose |
|----------|---------|
| README_IMPLEMENTATION.md | Start here - Overview |
| SETUP_GUIDE.md | Installation steps |
| IMPLEMENTATION_GUIDE.md | Feature details |
| TECHNICAL_ARCHITECTURE.md | System design |
| DEPLOYMENT_GUIDE.md | Production deployment |
| IMPLEMENTATION_CHECKLIST.md | Progress tracking |

---

## 💡 Pro Tips

1. **Test with multiple leave types** before production
2. **Use Prisma Studio** to verify data: `npx prisma studio`
3. **Keep backup before migration** to production
4. **Monitor API logs** after deployment
5. **Validate tax rates** match your region
6. **Test bulk payslip generation** with sample data first
7. **Set up email notifications** for approvals
8. **Document any customizations** for future maintenance

---

## 📞 Key Contacts

- **Backend Issues**: Check `backend/src/modules/leave` or `backend/src/modules/payroll`
- **Frontend Issues**: Check `lib/src/screens/leave_management_screen.dart` or `payslip_screen.dart`
- **Database Issues**: Check `backend/prisma/schema.prisma`
- **Documentation**: Check markdown files in root directory

---

## ✅ Implementation Status

```
├─ Database Schema         ✅ Complete
├─ Backend Services        ✅ Complete
├─ Backend Controllers     ✅ Complete
├─ Flutter Screens         ✅ Complete
├─ Flutter Services        ✅ Complete
├─ Navigation Integration  ✅ Complete
├─ Documentation           ✅ Complete
├─ Testing                 ⏳ Ready
└─ Deployment              ⏳ Ready
```

---

**Last Updated**: January 22, 2026
**Version**: 1.0
**Status**: Ready for Deployment ✅

---

## 🎉 You're All Set!

Everything is implemented and documented. Time to deploy! 🚀

Start with:
1. Review README_IMPLEMENTATION.md
2. Run database migration
3. Follow SETUP_GUIDE.md
4. Deploy using DEPLOYMENT_GUIDE.md

**Questions?** Check the documentation files - they have detailed answers!
