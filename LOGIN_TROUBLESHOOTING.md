# 🔧 Login Error Troubleshooting Guide

## ❌ Login Error on Android Phone - Solutions

The login error typically occurs when the app cannot connect to the backend API. Here are the solutions:

---

## 🔍 Common Login Errors & Fixes

### Error Type 1: "Connection Refused" / "Failed to connect"

**Cause:** Backend server is not running or unreachable

**Solution:**

#### Option A: Use Cloud Backend (Recommended)
- ✅ App is already configured to use cloud (`https://api.enterprise-attendance.com`)
- Ensure your phone has internet connection
- Try login again with:
  - Email: `admin@example.com`
  - Password: `Admin@123456`

#### Option B: Use Local Backend (For Testing)
**Step 1:** Start backend services on your Mac
```bash
# Terminal 1 - Start databases
brew services start postgresql
brew services start redis

# Terminal 2 - Start backend
cd /Users/vinayakballary/Downloads/app-main/backend
./run-dev.sh
```

**Step 2:** Configure app for local backend

Edit `lib/src/config/app_config.dart`:
```dart
// Line 29: Change from
static const Environment environment = Environment.production;

// To:
static const Environment environment = Environment.development;
```

**Step 3:** Rebuild and deploy APK
```bash
flutter clean
flutter pub get
flutter build apk --release
```

Transfer new APK to phone and install.

---

### Error Type 2: "Invalid Credentials"

**Cause:** Wrong email/password combination

**Solution:**

Try these test credentials:

| Email | Password | Role |
|-------|----------|------|
| `admin@example.com` | `Admin@123456` | Admin |
| `manager@example.com` | `Manager@123` | Manager |
| `employee@example.com` | `Employee@123` | Employee |

Or check your database for valid users:
```bash
psql -h localhost -U postgres -d companydb
SELECT "email", "role" FROM public."User" LIMIT 10;
```

---

### Error Type 3: "2FA Required"

**Cause:** Two-factor authentication is enabled for your account

**Solution:**

1. You will see "2FA Required" message
2. Check your authenticator app (Google Authenticator, Authy, etc.)
3. Enter the 6-digit code
4. Login will succeed

---

### Error Type 4: "Network Timeout"

**Cause:** Backend is slow to respond or unreachable

**Solution:**

1. **Check Internet Connection**
   - Ensure phone is connected to WiFi or mobile data
   - Try browsing a website to verify connectivity

2. **Check Backend Status**
   ```bash
   # From your Mac
   curl https://api.enterprise-attendance.com/api/v1/health
   ```
   Should respond with `{"status":"ok"}`

3. **For Local Backend**
   ```bash
   # From your Mac
   curl http://localhost:3000/api/v1/health
   ```

---

## 🔍 Diagnostic Steps

### Step 1: Identify the Exact Error
Look at the error message in the app:

**Where to find it:**
1. Open app
2. Try to login
3. Look at the snackbar message at the bottom

**Common messages:**
- "Connection refused" → Backend not running
- "Invalid credentials" → Wrong password
- "Timeout after 30 seconds" → Backend too slow
- "Cannot resolve host" → Wrong endpoint

### Step 2: Check Backend Status

**Cloud Backend:**
```bash
# From your Mac
curl -I https://api.enterprise-attendance.com/api/v1/health
```

**Local Backend:**
```bash
# From your Mac
curl -I http://localhost:3000/api/v1/health
```

### Step 3: Check Network Connectivity

**On Phone:**
1. Open Settings → WiFi
2. Verify connected to network
3. Or use mobile data

**Test connectivity:**
```bash
# From your Mac - check if phone can reach backend
# Get your Mac's IP:
ifconfig | grep inet

# Then from phone browser:
# Try accessing: http://YOUR_MAC_IP:3000/api/docs
```

---

## 🚀 Quick Fix Checklist

### For Cloud Backend (Recommended)
- [ ] Phone has internet connection
- [ ] App config set to `Environment.production`
- [ ] APK is latest version
- [ ] Using correct credentials
- [ ] Cloud backend is running (check render.io dashboard)

### For Local Backend
- [ ] PostgreSQL is running (`brew services list`)
- [ ] Redis is running (`redis-cli ping` returns PONG)
- [ ] Backend is running (`npm run start:dev`)
- [ ] Phone can reach backend IP:3000
- [ ] App config set to `Environment.development`
- [ ] APK rebuilt after config change

---

## 📱 Phone-Specific Setup (For Local Testing)

### On Physical Android Phone:

**Step 1: Find Mac's IP Address**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```
Example output: `192.168.1.100`

**Step 2: Update App Configuration**
Edit `lib/src/config/app_config.dart`:
```dart
case Environment.development:
  if (kIsWeb) {
    return 'http://localhost:3000/api/v1';
  }
  // For physical device, use Mac's IP
  return 'http://192.168.1.100:3000/api/v1';  // Replace with your IP
```

**Step 3: Rebuild APK**
```bash
flutter clean
flutter pub get
flutter build apk --release
```

**Step 4: Install on Phone**
- Transfer APK to phone
- Install it
- Try login

---

## 🛠️ Advanced Debugging

### Enable Debug Logs
Edit `lib/src/config/app_config.dart`:
```dart
// Change to development mode to enable debug logs
static const Environment environment = Environment.development;
```

**Logs will show:**
- Network request URLs
- API response status
- Error messages with stack traces

### View App Logs
```bash
# While app is running on phone:
flutter logs
```

This will show real-time logs from the app.

### Check Network Requests
1. Open app
2. Try to login
3. Check logs with `flutter logs`
4. Look for API endpoint being called
5. Verify the URL matches your backend

---

## 📊 Environment Comparison

### Production (Cloud)
```
API: https://api.enterprise-attendance.com
Database: Cloud (Render.io)
Status: Always available
Credentials: Real employee accounts
```

### Development (Local)
```
API: http://localhost:3000 (or your Mac IP:3000)
Database: Local PostgreSQL
Status: Only when running
Credentials: Test accounts from database
```

---

## ✨ Solution Summary

| Issue | Solution |
|-------|----------|
| Cannot connect | Check backend running, phone internet |
| Invalid credentials | Use correct email/password, check database |
| 2FA error | Check authenticator app |
| Timeout | Backend too slow, increase timeout or check network |
| Network error | Phone offline, backend unreachable, firewall blocking |

---

## 📞 Need More Help?

### Check These Files:
- `BACKEND_CONNECTIVITY_GUIDE.md` - Backend configuration details
- `QUICK_START_TESTING.md` - Detailed testing setup
- `TESTING_BACKEND_SETUP.md` - Full backend setup options
- `lib/src/config/app_config.dart` - Current environment settings
- `lib/src/services/api_service.dart` - API implementation

### Run Tests:
```bash
# Test API connectivity
flutter test test/services/api_service_test.dart
```

### Common Test Credentials:
If you're using local backend with seeded test data:
- Email: `test@example.com` / Password: `Test@123456`
- Email: `admin@test.com` / Password: `Admin@123456`

---

## 🎯 Next Steps

1. **Identify which backend you want to use** (Cloud or Local)
2. **Fix the specific error** using solutions above
3. **Test login** with valid credentials
4. **Check logs** if still having issues (`flutter logs`)
5. **Ask for help** with error message details

You're almost there! 🚀
