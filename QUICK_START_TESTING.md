# 🧪 Quick Start - Make Backend Live for Testing

## 📋 Quick Setup (5 minutes)

### Prerequisites Check ✓
- ✅ Node.js v24.11.1 - Already installed
- ⚠️ PostgreSQL - Need to start
- ⚠️ Redis - Need to start

---

## 🚀 Step-by-Step Setup

### Step 1️⃣: Start Database Services (2 minutes)

**Start PostgreSQL:**
```bash
brew services start postgresql
```

**Start Redis:**
```bash
brew services start redis
```

**Verify they're running:**
```bash
psql -h localhost -U postgres -d companydb -c "SELECT 1;"
redis-cli ping
```

Expected outputs:
- PostgreSQL: `(1 row)`
- Redis: `PONG`

---

### Step 2️⃣: Start Backend API (30 seconds)

```bash
cd /Users/vinayakballary/Downloads/app-main/backend
./run-dev.sh
```

Or manually:
```bash
cd /Users/vinayakballary/Downloads/app-main/backend
npm run start:dev
```

**Backend is live when you see:**
```
[Nest] 12345  - 02/02/2026, 2:30:00 PM     LOG [NestFactory] Nest application successfully started +123ms
Server listening on http://localhost:3000
```

---

### Step 3️⃣: Configure Flutter App for Local Backend (1 minute)

Edit `lib/src/config/app_config.dart`:

**Line 29 - Change from:**
```dart
static const Environment environment = Environment.production;
```

**To:**
```dart
static const Environment environment = Environment.development;
```

Save the file.

---

### Step 4️⃣: Run Flutter App (1 minute)

**Terminal 2 (new terminal while backend runs):**
```bash
cd /Users/vinayakballary/Downloads/app-main
flutter run
```

**Select your device:**
- `1` - Android Emulator (if running)
- `2` - iOS Simulator (if running)  
- `3` - Web Browser
- `4` - Physical device (if connected)

---

### Step 5️⃣: Test Login

Once app opens, try:

**Email:** `admin@example.com`  
**Password:** `Admin@123456`

Or use any test account from your database.

---

## 📊 Verification Checklist

### ✅ Backend Running
```bash
curl http://localhost:3000/api/v1/health
```
Expected: `{"status":"ok"}`

### ✅ API Documentation
```
http://localhost:3000/api/docs
```
Opens Swagger UI in browser

### ✅ Database Connected
```bash
psql -h localhost -U postgres -d companydb
SELECT COUNT(*) FROM public."User";
```
Should return user count

### ✅ Redis Connected
```bash
redis-cli
PING
```
Should return `PONG`

### ✅ Flutter App Connected
- Open app in emulator/simulator/device
- Check that login screen loads
- Try logging in
- Check console for network requests

---

## 🎯 What's Now Live

| Component | Status | Location |
|-----------|--------|----------|
| **Backend API** | ✅ Running | `http://localhost:3000` |
| **API Docs** | ✅ Available | `http://localhost:3000/api/docs` |
| **Database** | ✅ Connected | PostgreSQL @ localhost:5432 |
| **Cache** | ✅ Connected | Redis @ localhost:6379 |
| **Flutter App** | ✅ Connected | Points to localhost backend |

---

## 🔧 Troubleshooting

### Backend won't start

**Error: "Cannot connect to the database"**
```bash
# Start PostgreSQL
brew services start postgresql

# Check status
brew services list
```

**Error: "Redis connection failed"**
```bash
# Start Redis
brew services start redis

# Test connection
redis-cli ping
```

### App can't reach backend

**For Android Emulator:**
- App automatically uses `http://10.0.2.2:3000`
- No changes needed

**For iOS Simulator:**
- App automatically uses `http://localhost:3000`
- Make sure backend is running

**For Physical Device:**
- Get your machine IP: `ifconfig | grep inet`
- Add to `app_config.dart`:
```dart
// Replace YOUR_MACHINE_IP with actual IP (e.g., 192.168.1.100)
return 'http://YOUR_MACHINE_IP:3000/api/v1';
```

### Port 3000 already in use

```bash
# Find what's using port 3000
lsof -i :3000

# Kill the process
kill -9 <PID>
```

---

## 📱 Testing Features

Once everything is live, you can test:

✅ User Authentication (Login/Signup)  
✅ 2FA Authentication  
✅ Employee Management  
✅ Profile Updates  
✅ Real-time Notifications (WebSocket)  
✅ Offline Mode (SQLite)  
✅ Biometric Authentication  

---

## 🛑 Stopping Services

```bash
# Stop backend (Ctrl+C in backend terminal)

# Stop PostgreSQL
brew services stop postgresql

# Stop Redis  
brew services stop redis
```

---

## 📚 Documentation Files

- **BACKEND_CONNECTIVITY_GUIDE.md** - Detailed backend configuration
- **TESTING_BACKEND_SETUP.md** - Full setup options
- **backend/run-dev.sh** - Automated startup script
- **backend/docker-compose.yml** - Docker setup (alternative)

---

## ✨ You're Ready!

Your backend is now **live for testing** with:
- ✅ Local API server
- ✅ Live database
- ✅ Real-time cache
- ✅ Full debugging capabilities
- ✅ Hot-reload support for backend changes

**Happy Testing! 🚀**

Need help? Check the documentation files or see the troubleshooting section above.
