# Backend Testing Setup Guide

## 🚀 Make Backend Live for Testing

You have **two options** to run the backend for testing:

---

## ✅ Option 1: Docker Compose (Recommended - All Services)

### Prerequisites
- ✅ Docker Desktop installed and running
- ✅ Docker Daemon started

### Start All Services
```bash
cd /Users/vinayakballary/Downloads/app-main/backend
docker-compose up -d
```

This will start:
- **Backend API** on `http://localhost:3000`
- **PostgreSQL Database** on `localhost:5432`
- **Redis Cache** on `localhost:6379`

### Stop Services
```bash
docker-compose down
```

### View Logs
```bash
docker-compose logs -f backend
```

---

## ✅ Option 2: Local Node.js Run (For Quick Testing)

### Prerequisites
- ✅ Node.js v24.11.1 ✓ (Already installed!)
- ⚠️ PostgreSQL and Redis must be running separately

### Step 1: Install Dependencies
```bash
cd /Users/vinayakballary/Downloads/app-main/backend
npm install
```

### Step 2: Build Backend
```bash
npm run build
```

### Step 3: Set Environment Variables
```bash
# Create .env file
cat > .env << 'EOF'
PORT=3000
NODE_ENV=development
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/companydb?schema=public
REDIS_URL=redis://localhost:6379
JWT_ACCESS_SECRET=dev-access-secret-change-in-prod
JWT_REFRESH_SECRET=dev-refresh-secret-change-in-prod
CORS_ORIGIN=http://localhost:3000
LOG_LEVEL=debug
EOF
```

### Step 4: Run Backend Locally
```bash
npm run start:dev
```

Backend will be available at: `http://localhost:3000`

### View API Documentation
```bash
http://localhost:3000/api/docs
```

---

## 🧪 Configure Flutter App for Testing

### Switch to Local Backend

Edit `lib/src/config/app_config.dart`:

```dart
// Line 29 - Change from:
static const Environment environment = Environment.production;

// To:
static const Environment environment = Environment.development;
```

### For Android Emulator
The app will automatically use: `http://10.0.2.2:3000`

### For iOS Simulator/Web
The app will automatically use: `http://localhost:3000`

### For Physical Device
You need to update the development URL to your machine's IP:

Edit `lib/src/config/app_config.dart`:
```dart
case Environment.development:
  if (kIsWeb) {
    return 'http://localhost:3000/api/v1';
  }
  // For physical device, use your machine IP (e.g., 192.168.1.100)
  return 'http://YOUR_MACHINE_IP:3000/api/v1';
```

---

## 📱 Run Flutter App for Testing

### Step 1: Switch to Development Environment
```bash
# Edit lib/src/config/app_config.dart
# Change: Environment.production → Environment.development
```

### Step 2: Hot Reload
```bash
flutter run
```

### Step 3: Test Login
```
Email: test@example.com
Password: Test@123456
```

---

## ✅ Verification Checklist

### Backend is Running
```bash
# Check if backend is responding
curl http://localhost:3000/api/v1/health

# Expected response:
# {"status":"ok"}
```

### API Documentation
```
http://localhost:3000/api/docs
```

### Database Connection
```bash
# Check PostgreSQL
psql -h localhost -U postgres -d companydb

# Query test:
SELECT * FROM public."User" LIMIT 1;
```

### Redis Connection
```bash
# Test Redis
redis-cli ping

# Expected: PONG
```

---

## 🐛 Troubleshooting

### Docker Daemon Not Running
```bash
# Mac: Start Docker Desktop
open /Applications/Docker.app

# Or start daemon manually
colima start
```

### Port Already in Use
```bash
# Find process using port 3000
lsof -i :3000

# Kill the process
kill -9 <PID>
```

### PostgreSQL Connection Error
```bash
# Start PostgreSQL if not running
brew services start postgresql

# Or use Docker:
docker run -d \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=companydb \
  -p 5432:5432 \
  postgres:15
```

### Redis Connection Error
```bash
# Start Redis
brew services start redis

# Or use Docker:
docker run -d -p 6379:6379 redis:7
```

---

## 📊 Architecture for Testing

### Local Testing Setup
```
Flutter App (Development Mode)
      ↓
HTTP to: localhost:3000 (or 10.0.2.2 for Android)
      ↓
NestJS Backend (Local or Docker)
      ↓
PostgreSQL (Local or Docker)
Redis (Local or Docker)
```

### Database Reset (Clean Testing)
```bash
# Drop and recreate database
npm run prisma:reset

# This will:
# 1. Drop database
# 2. Create new database
# 3. Run migrations
# 4. Seed test data
```

---

## 🎯 Testing Scenarios

### Scenario 1: Full Cloud Testing
- **Backend**: Cloud (Render.io) - `https://api.enterprise-attendance.com`
- **Database**: Cloud (PostgreSQL on Render)
- **Config**: `Environment.production`
- **Use**: Production testing, load testing

### Scenario 2: Local Backend + Flutter Dev
- **Backend**: Local Docker - `http://localhost:3000`
- **Database**: Docker PostgreSQL
- **Config**: `Environment.development`
- **Use**: Feature development, debugging

### Scenario 3: Hybrid Testing
- **Backend**: Local - `http://localhost:3000`
- **Database**: Cloud - Production data
- **Config**: Custom endpoint in `app_config.dart`
- **Use**: Integration testing with real data

---

## 📝 Quick Commands

```bash
# Start everything (Docker)
cd backend && docker-compose up -d

# View logs
docker-compose logs -f

# Stop everything
docker-compose down

# Build backend
npm run build

# Start backend (local)
npm run start:dev

# Test API
curl http://localhost:3000/api/docs

# Reset database
npm run prisma:reset

# Run migrations
npm run prisma:migrate

# Seed test data
npm run prisma:seed
```

---

## 🔗 Related Documentation

- `BACKEND_CONNECTIVITY_GUIDE.md` - Backend configuration options
- `DEPLOYMENT_GUIDE.md` - Production deployment
- `backend/README.md` - Backend-specific documentation
- `backend/docker-compose.yml` - Docker configuration

---

## ✨ Next Steps

1. **Start Backend** (choose Option 1 or 2 above)
2. **Switch Flutter App** to development environment
3. **Run Flutter App** with `flutter run`
4. **Test Features** using the app
5. **View Logs** for debugging

You're now ready to test your application locally! 🚀
