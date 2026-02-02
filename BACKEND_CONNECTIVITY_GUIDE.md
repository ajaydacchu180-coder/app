# Backend Connectivity Guide

## 🌐 Current Status: **CLOUD DEPLOYMENT CONFIGURED**

The backend is configured for **both local development and cloud deployment** with environment-specific endpoints.

---

## 📍 Backend Endpoints by Environment

### Production (Current - Cloud ☁️)
```
API Endpoint:       https://api.enterprise-attendance.com/api/v1
WebSocket Endpoint: wss://api.enterprise-attendance.com
Port:               443 (HTTPS/WSS)
Host:               Cloud (Render.io)
Database:           PostgreSQL (Render Managed DB)
Cache:              Redis (Render Managed)
```

**Status**: Production-ready, deployed on Render.io with managed databases

---

### Staging (Cloud ☁️)
```
API Endpoint:       https://staging-api.enterprise-attendance.com/api/v1
WebSocket Endpoint: wss://staging-api.enterprise-attendance.com
Port:               443 (HTTPS/WSS)
Host:               Cloud (Render.io)
Database:           PostgreSQL (Render Managed DB)
Cache:              Redis (Render Managed)
```

**Status**: Pre-production testing environment

---

### Development (Local 🖥️)
```
API Endpoint:       http://10.0.2.2:3000/api/v1  (Android Emulator)
                    http://localhost:3000/api/v1  (Web & iOS)
WebSocket Endpoint: ws://10.0.2.2:3000  (Android)
                    ws://localhost:3000   (Web & iOS)
Port:               3000 (HTTP/WS)
Host:               localhost
Database:           PostgreSQL (Docker Local)
Cache:              Redis (Docker Local)
```

**Status**: Local development environment (Docker compose)

---

## 🚀 Current App Configuration

The Flutter app (`lib/src/config/app_config.dart`) is currently set to:

```dart
static const Environment environment = Environment.production;
```

### This means:
✅ **App is connecting to CLOUD** (`https://api.enterprise-attendance.com`)
✅ **All requests use HTTPS** (secure)
✅ **Mock data is DISABLED** (uses real backend)
✅ **Debug logs are DISABLED** (production mode)

---

## 🔧 Local Development Setup (If Needed)

To switch to **local development** backend:

### Step 1: Change App Configuration
Edit `lib/src/config/app_config.dart`:
```dart
// Change from:
static const Environment environment = Environment.production;

// To:
static const Environment environment = Environment.development;
```

### Step 2: Start Backend Services
```bash
cd backend
docker-compose up -d
```

This starts:
- **Backend API** on `http://localhost:3000`
- **PostgreSQL Database** on `localhost:5432`
- **Redis Cache** on `localhost:6379`

### Step 3: Run Flutter App
```bash
flutter run
```

The app will now connect to `http://10.0.2.2:3000` (Android) or `http://localhost:3000` (Web/iOS)

---

## 📊 Backend Services Architecture

### Production (Cloud)
```
Flutter App (v1.0.0)
      ↓
HTTPS to: api.enterprise-attendance.com
      ↓
Render.io Web Service (NestJS Backend)
      ↓
Managed PostgreSQL (enterprise-db)
Managed Redis (enterprise-redis)
Bull Queue (Async Jobs)
```

### Development (Local Docker)
```
Flutter App
      ↓
HTTP to: localhost:3000
      ↓
NestJS Backend (Docker Container)
      ↓
PostgreSQL (Docker)
Redis (Docker)
Bull Queue
```

---

## 🔐 Security & Authentication

### JWT Authentication Flow
1. **Login Request** → Backend validates credentials
2. **Access Token Generated** → Short-lived (24h in production)
3. **Refresh Token** → Long-lived token for renewing access
4. **Requests** → All API calls include `Authorization: Bearer <token>`
5. **Token Refresh** → Automatic when expired

### Current Secrets (Production)
```
JWT_ACCESS_SECRET:  ••••••• (in render.yaml)
JWT_REFRESH_SECRET: ••••••• (in render.yaml)
DATABASE_URL:       Managed by Render
REDIS_URL:          Managed by Render
```

---

## ✅ Verification

### Check Backend Connectivity from App
The app automatically verifies backend connectivity:
- ✅ Performs health check on startup
- ✅ Logs connection status (in dev mode)
- ✅ Handles network timeouts (30 seconds)
- ✅ Implements automatic retry with exponential backoff

### Test API Endpoints
```bash
# Check production backend
curl https://api.enterprise-attendance.com/api/v1/health

# Check local backend (if running)
curl http://localhost:3000/api/v1/health

# View API documentation
https://api.enterprise-attendance.com/api/docs
```

---

## 📚 Related Files

| File | Purpose |
|------|---------|
| `lib/src/config/app_config.dart` | Environment configuration (prod/staging/dev) |
| `backend/src/main.ts` | Backend server setup (NestJS) |
| `backend/docker-compose.yml` | Local development Docker setup |
| `render.yaml` | Cloud deployment configuration (Render.io) |
| `.github/workflows/release-build.yml` | CI/CD pipeline for automated builds |

---

## 🎯 Current Status Summary

| Component | Current | Environment |
|-----------|---------|-------------|
| **App Version** | 1.0.0 | Production |
| **API Endpoint** | api.enterprise-attendance.com | Cloud (Render.io) |
| **Database** | PostgreSQL (Managed) | Render.io |
| **Cache** | Redis (Managed) | Render.io |
| **Authentication** | JWT | Production |
| **Debug Mode** | Disabled | Production |
| **Mock Data** | Disabled | Production |

✅ **The app is fully connected to the production cloud backend and ready for deployment!**

---

## 🚀 Deployment Options

### Option 1: Current Production (Recommended) ✅
- Backend: Render.io (Cloud)
- Database: Render.io Managed PostgreSQL
- Redis: Render.io Managed Redis
- Status: Active and ready

### Option 2: Local Development
- Backend: Docker (localhost:3000)
- Database: Docker PostgreSQL
- Redis: Docker Redis
- Setup: `cd backend && docker-compose up -d`

### Option 3: Custom Cloud Deployment
- Backend: Deploy backend to your own cloud (AWS, Azure, GCP, etc.)
- Database: Use managed database service
- Update: Change API endpoint in `app_config.dart`

---

## 📞 Support

For backend API documentation, visit:
```
https://api.enterprise-attendance.com/api/docs
```

For deployment assistance, see:
- `DEPLOYMENT_GUIDE.md` - Complete deployment instructions
- `DEPLOYMENT_READINESS_REPORT.md` - Pre-deployment checklist
- `CI_SECRETS_SETUP.md` - CI/CD secrets configuration
