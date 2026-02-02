#!/bin/bash

# Login Error Diagnostic Script
# Run this to identify why login is failing

echo ""
echo "╔════════════════════════════════════════════════╗"
echo "║  LOGIN ERROR DIAGNOSTIC TOOL                   ║"
echo "╚════════════════════════════════════════════════╝"
echo ""

# Check 1: App Configuration
echo "1️⃣  Checking app configuration..."
if grep -q "Environment.production" lib/src/config/app_config.dart; then
    echo "   ✅ App is set to PRODUCTION (Cloud backend)"
    BACKEND="production"
elif grep -q "Environment.development" lib/src/config/app_config.dart; then
    echo "   ✅ App is set to DEVELOPMENT (Local backend)"
    BACKEND="development"
else
    echo "   ⚠️  Cannot determine environment"
    BACKEND="unknown"
fi
echo ""

# Check 2: Internet Connection
echo "2️⃣  Checking internet connection..."
if ping -c 1 8.8.8.8 &> /dev/null; then
    echo "   ✅ Internet connection OK"
else
    echo "   ❌ No internet connection"
    echo "   ℹ️  Note: If using local backend, this is OK"
fi
echo ""

# Check 3: Cloud Backend Status
if [ "$BACKEND" = "production" ]; then
    echo "3️⃣  Checking cloud backend..."
    if curl -s -I https://api.enterprise-attendance.com/api/v1/health | grep -q "200\|302"; then
        echo "   ✅ Cloud backend is reachable"
    else
        echo "   ❌ Cloud backend is NOT reachable"
        echo "   🔧 Try: Check internet, or switch to local backend"
    fi
fi
echo ""

# Check 4: Local Backend Status
if [ "$BACKEND" = "development" ]; then
    echo "3️⃣  Checking local backend..."
    if curl -s http://localhost:3000/api/v1/health | grep -q "ok"; then
        echo "   ✅ Local backend is running"
    else
        echo "   ❌ Local backend is NOT running"
        echo "   🔧 Start it with: cd backend && npm run start:dev"
    fi
    echo ""
    
    echo "4️⃣  Checking PostgreSQL..."
    if psql -h localhost -U postgres -d companydb -c "SELECT 1" &> /dev/null; then
        echo "   ✅ PostgreSQL is running"
    else
        echo "   ❌ PostgreSQL is NOT running"
        echo "   🔧 Start it with: brew services start postgresql"
    fi
    echo ""
    
    echo "5️⃣  Checking Redis..."
    if redis-cli ping &> /dev/null | grep -q "PONG"; then
        echo "   ✅ Redis is running"
    else
        echo "   ❌ Redis is NOT running"
        echo "   🔧 Start it with: brew services start redis"
    fi
fi
echo ""

# Check 5: Database
echo "6️⃣  Checking database connectivity..."
if [ "$BACKEND" = "development" ]; then
    USERS=$(psql -h localhost -U postgres -d companydb -t -c "SELECT COUNT(*) FROM public.\"User\"" 2>/dev/null)
    if [ -n "$USERS" ]; then
        echo "   ✅ Database connected ($USERS users found)"
    else
        echo "   ❌ Cannot connect to database"
        echo "   🔧 Check PostgreSQL is running: brew services list"
    fi
fi
echo ""

# Summary
echo "╔════════════════════════════════════════════════╗"
echo "║  DIAGNOSTIC SUMMARY                            ║"
echo "╚════════════════════════════════════════════════╝"
echo ""
echo "Backend Mode: $BACKEND"
echo ""

if [ "$BACKEND" = "production" ]; then
    echo "🌐 Cloud Backend Configuration:"
    echo "   API: https://api.enterprise-attendance.com/api/v1"
    echo "   Database: Render.io (Managed)"
    echo "   Status: Check render.io dashboard"
    echo ""
    echo "💡 If login fails:"
    echo "   1. Check phone has internet"
    echo "   2. Verify credentials are correct"
    echo "   3. Try: admin@example.com / Admin@123456"
    echo "   4. Or switch to local backend for testing"
elif [ "$BACKEND" = "development" ]; then
    echo "💻 Local Backend Configuration:"
    echo "   API: http://localhost:3000"
    echo "   Database: PostgreSQL @ localhost:5432"
    echo "   Cache: Redis @ localhost:6379"
    echo ""
    echo "💡 If login fails:"
    echo "   1. Verify all services are running (see above)"
    echo "   2. Check database has user accounts"
    echo "   3. Review backend logs: npm run start:dev"
fi
echo ""

# Troubleshooting
echo "╔════════════════════════════════════════════════╗"
echo "║  RECOMMENDED ACTIONS                           ║"
echo "╚════════════════════════════════════════════════╝"
echo ""

if [ "$BACKEND" = "production" ]; then
    echo "✅ Ensure:"
    echo "   • Phone is connected to WiFi/Mobile data"
    echo "   • Using correct email/password"
    echo "   • Cloud backend is accessible (test with curl above)"
    echo ""
    echo "🔄 To switch to local backend:"
    echo "   1. Edit: lib/src/config/app_config.dart"
    echo "   2. Change: Environment.production → Environment.development"
    echo "   3. Rebuild: flutter build apk --release"
    echo "   4. Install new APK on phone"
elif [ "$BACKEND" = "development" ]; then
    echo "✅ Ensure:"
    echo "   • PostgreSQL is running: brew services start postgresql"
    echo "   • Redis is running: brew services start redis"
    echo "   • Backend is running: cd backend && npm run start:dev"
    echo "   • Phone can reach backend (check local IP: ifconfig)"
    echo ""
    echo "🔧 To debug further:"
    echo "   • Check app logs: flutter logs"
    echo "   • Check backend logs: npm run start:dev output"
    echo "   • Query database: psql -h localhost -U postgres -d companydb"
fi
echo ""

echo "📚 Documentation:"
echo "   • LOGIN_TROUBLESHOOTING.md - Full troubleshooting guide"
echo "   • QUICK_START_TESTING.md - Quick setup guide"
echo "   • BACKEND_CONNECTIVITY_GUIDE.md - Configuration details"
echo ""
