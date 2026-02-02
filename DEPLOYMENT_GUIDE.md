# Deployment & Migration Guide

## Pre-Deployment Checklist

- [ ] All modules registered in `app.module.ts`
- [ ] Prisma schema updated with new models
- [ ] DTOs created and validated
- [ ] API endpoints tested
- [ ] Flutter screens implemented
- [ ] Services integrated
- [ ] Environment variables configured
- [ ] Tests passing
- [ ] Code reviewed

## Step-by-Step Deployment

### Phase 1: Database Migration

#### 1.1 Create Migration File
```bash
cd backend
npx prisma migrate dev --name add_leave_payroll_systems
```

This will:
- Create migration files
- Apply migration to database
- Generate Prisma client

#### 1.2 Verify Schema Changes
```bash
# Check Prisma schema
npx prisma db push --skip-generate

# View database schema
npx prisma studio
```

#### 1.3 Rollback (if needed)
```bash
npx prisma migrate resolve --rolled-back add_leave_payroll_systems
```

### Phase 2: Seed Initial Data

#### 2.1 Create Seed File
Create `backend/prisma/seed.ts`:

```typescript
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('Starting seed...');

  // Clear existing data (optional)
  // await prisma.leaveType.deleteMany();
  // await prisma.salaryComponent.deleteMany();

  // Seed Leave Types
  const leaveTypes = await prisma.leaveType.createMany({
    data: [
      {
        name: 'Sick Leave',
        description: 'For medical emergencies and health issues',
        maxDaysPerYear: 10,
        requiresApproval: true,
      },
      {
        name: 'Casual Leave',
        description: 'For personal or other reasons',
        maxDaysPerYear: 12,
        requiresApproval: true,
      },
      {
        name: 'Personal Leave',
        description: 'For personal emergencies',
        maxDaysPerYear: 5,
        requiresApproval: true,
      },
      {
        name: 'Annual Leave',
        description: 'Planned vacation',
        maxDaysPerYear: 20,
        requiresApproval: true,
      },
      {
        name: 'Maternity Leave',
        description: 'For maternity purposes',
        maxDaysPerYear: 180,
        requiresApproval: true,
      },
    ],
    skipDuplicates: true,
  });

  console.log(`Created ${leaveTypes.count} leave types`);

  // Seed Salary Components
  const components = await prisma.salaryComponent.createMany({
    data: [
      {
        name: 'Basic Salary',
        type: 'BASIC',
        description: 'Basic monthly salary',
        isFixed: true,
      },
      {
        name: 'Dearness Allowance (DA)',
        type: 'ALLOWANCE',
        description: 'Dearness allowance percentage of basic',
        isFixed: true,
      },
      {
        name: 'House Rent Allowance (HRA)',
        type: 'ALLOWANCE',
        description: 'House rent allowance percentage of basic',
        isFixed: true,
      },
      {
        name: 'Travel Allowance',
        type: 'ALLOWANCE',
        description: 'Fixed travel allowance',
        isFixed: true,
      },
      {
        name: 'Performance Bonus',
        type: 'ALLOWANCE',
        description: 'Performance-based bonus',
        isFixed: false,
      },
      {
        name: 'Income Tax',
        type: 'DEDUCTION',
        description: 'Income tax deduction',
        isFixed: false,
      },
      {
        name: 'Provident Fund (PF)',
        type: 'DEDUCTION',
        description: 'Employee provident fund contribution',
        isFixed: false,
      },
      {
        name: 'Employee State Insurance (ESI)',
        type: 'DEDUCTION',
        description: 'Employee state insurance',
        isFixed: false,
      },
    ],
    skipDuplicates: true,
  });

  console.log(`Created ${components.count} salary components`);

  // Seed Holidays for 2025
  const holidays = await prisma.holidayCalendar.createMany({
    data: [
      {
        name: 'Republic Day',
        date: new Date('2025-01-26'),
        description: 'Indian Republic Day',
        type: 'NATIONAL',
        year: 2025,
      },
      {
        name: 'Independence Day',
        date: new Date('2025-08-15'),
        description: 'Indian Independence Day',
        type: 'NATIONAL',
        year: 2025,
      },
      {
        name: 'Gandhi Jayanti',
        date: new Date('2025-10-02'),
        description: 'Mahatma Gandhi Birthday',
        type: 'NATIONAL',
        year: 2025,
      },
      {
        name: 'Christmas',
        date: new Date('2025-12-25'),
        description: 'Christmas Day',
        type: 'NATIONAL',
        year: 2025,
      },
      {
        name: 'Holi',
        date: new Date('2025-03-14'),
        description: 'Holi Festival',
        type: 'NATIONAL',
        year: 2025,
      },
      {
        name: 'Diwali',
        date: new Date('2025-11-01'),
        description: 'Diwali Festival',
        type: 'NATIONAL',
        year: 2025,
      },
    ],
    skipDuplicates: true,
  });

  console.log(`Created ${holidays.count} holidays`);

  console.log('Seed completed successfully!');
}

main()
  .catch((e) => {
    console.error('Error during seeding:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
```

#### 2.2 Update package.json
Add prisma seed configuration to `backend/package.json`:

```json
{
  "prisma": {
    "seed": "ts-node prisma/seed.ts"
  }
}
```

#### 2.3 Run Seed
```bash
npx prisma db seed
```

### Phase 3: Backend Deployment

#### 3.1 Install Dependencies
```bash
cd backend
npm install
```

#### 3.2 Build Backend
```bash
npm run build
```

#### 3.3 Run Tests
```bash
npm run test
npm run test:e2e
```

#### 3.4 Start Backend
```bash
# Development
npm run start:dev

# Production
npm run start:prod
```

### Phase 4: Flutter App Deployment

#### 4.1 Get Dependencies
```bash
cd ../
flutter pub get
flutter pub cache repair
```

#### 4.2 Run App
```bash
# Development
flutter run

# Debug mode with verbose logging
flutter run -v

# Release mode
flutter run --release
```

#### 4.3 Build App
```bash
# APK (Android)
flutter build apk --split-per-abi

# IPA (iOS)
flutter build ios

# Web
flutter build web

# Windows
flutter build windows
```

### Phase 5: Verification

#### 5.1 Verify Database
```bash
# Connect to database and verify tables
psql -U postgres -d attendance_db -c "\dt"

# Should see new tables:
# - leave_type
# - leave_balance
# - leave_request
# - leave_approval_workflow
# - holiday_calendar
# - salary_component
# - salary_structure
# - payslip
# - payslip_line_item
# - payslip_deduction
```

#### 5.2 Test API Endpoints
```bash
# Get Leave Types
curl http://localhost:3000/leave/types \
  -H "Authorization: Bearer <token>"

# Get Payroll Components
curl http://localhost:3000/payroll/components \
  -H "Authorization: Bearer <token>"

# Get Leave Balance
curl http://localhost:3000/leave/balance/2025 \
  -H "Authorization: Bearer <token>"
```

#### 5.3 Test Flutter App
1. Login with test credentials
2. Navigate to Leave Management screen
3. Check Leave Balance tab
4. Try submitting a leave request
5. Navigate to Payslip screen
6. Filter by month/year
7. View payslip details

## Production Deployment

### Environment Setup

#### .env (Backend)
```
# Database
DATABASE_URL="postgresql://user:password@localhost:5432/attendance_db"

# JWT
JWT_SECRET="your-jwt-secret-key-here"
JWT_EXPIRY="24h"

# Leave Management
LEAVE_APPROVAL_ENABLED=true
LEAVE_APPROVAL_CHAIN_ENABLED=true

# Payroll
PAYROLL_TAX_RATE=0.10
PAYROLL_PF_RATE=0.12
PAYROLL_ESI_RATE=0.00

# Email (for notifications)
SMTP_HOST="smtp.gmail.com"
SMTP_PORT=587
SMTP_USER="your-email@gmail.com"
SMTP_PASSWORD="your-app-password"

# Server
NODE_ENV="production"
PORT=3000
```

#### Flutter Configuration
Update API endpoints in `lib/src/services/api_service.dart`:
```dart
static const String baseUrl = 'https://api.yourcompany.com';
```

### Backup Strategy

#### 1. Pre-Deployment Backup
```bash
# Backup PostgreSQL database
pg_dump -U postgres -d attendance_db > backup_$(date +%Y%m%d_%H%M%S).sql

# Backup to cloud storage (AWS S3)
aws s3 cp backup_*.sql s3://backups/attendance-db/
```

#### 2. Regular Backups
```bash
# Daily backup script (Linux/Mac)
0 2 * * * /path/to/backup-script.sh

# Windows Task Scheduler for .bat backup script
```

### Monitoring & Health Checks

#### Health Check Endpoint
Add to your main.ts:
```typescript
@Get('health')
health() {
  return {
    status: 'ok',
    timestamp: new Date(),
    database: await this.prisma.$queryRaw`SELECT 1`,
  };
}
```

Monitor:
```bash
# Check API health
curl http://localhost:3000/health

# Monitor logs
tail -f logs/application.log

# Monitor database connections
SELECT count(*) FROM pg_stat_activity;
```

## Rollback Procedure

### If Migration Fails

```bash
# Rollback last migration
npx prisma migrate resolve --rolled-back add_leave_payroll_systems

# Reset to previous state (careful!)
npx prisma migrate reset --skip-seed
```

### If Deployment Fails

1. Revert code changes
```bash
git revert HEAD
npm run build
npm run start:prod
```

2. Restore database from backup
```bash
psql -U postgres -d attendance_db < backup_*.sql
```

## Performance Optimization

### Database Optimization
```sql
-- Add indexes for common queries
CREATE INDEX idx_leave_balance_user_year ON leave_balance(user_id, year);
CREATE INDEX idx_leave_request_user_status ON leave_request(user_id, status);
CREATE INDEX idx_payslip_user_month_year ON payslip(user_id, month, year);

-- Analyze query performance
EXPLAIN ANALYZE SELECT * FROM leave_balance WHERE user_id = 1;
```

### Caching Strategy
```typescript
// In NestJS services
@Cacheable()
async getSalaryComponents() {
  return this.prisma.salaryComponent.findMany();
}

// Cache TTL: 1 hour
// Can be invalidated on update
```

## Monitoring Checklist

After deployment, verify:

- [ ] All API endpoints responding
- [ ] Database connections stable
- [ ] Flutter app connecting successfully
- [ ] Leave requests processing correctly
- [ ] Payslips generating accurately
- [ ] Approval workflows functioning
- [ ] User permissions enforced
- [ ] Error logging active
- [ ] Performance within acceptable range
- [ ] Backups running successfully

## Support & Troubleshooting

### Common Issues

**Issue**: Prisma client mismatch
```bash
Solution: npx prisma generate
```

**Issue**: Database connection timeout
```bash
Solution: Check DATABASE_URL, verify PostgreSQL running
ps aux | grep postgres
```

**Issue**: Migration conflicts
```bash
Solution: 
npx prisma migrate resolve --rolled-back [migration-name]
npx prisma migrate dev --name [new-name]
```

**Issue**: Flutter API connection error
```bash
Solution: Verify baseUrl, check CORS settings, verify JWT token
```

---

**Version**: 1.0
**Last Updated**: January 22, 2026
**Status**: Ready for Deployment
