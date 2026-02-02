#!/bin/bash

# Backend Testing Setup Script
# This script sets up and runs the backend for local testing

set -e

BACKEND_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$BACKEND_DIR"

echo "=================================="
echo "🚀 Backend Testing Setup"
echo "=================================="
echo ""

# Check Node.js
echo "✓ Checking Node.js..."
NODE_VERSION=$(node --version)
echo "  Node.js: $NODE_VERSION"
echo ""

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "✓ Creating .env file..."
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
    echo "  .env created successfully"
else
    echo "✓ .env file already exists"
fi
echo ""

# Install dependencies
if [ ! -d "node_modules" ]; then
    echo "✓ Installing dependencies..."
    npm install --legacy-peer-deps > /dev/null 2>&1
    echo "  Dependencies installed"
else
    echo "✓ Dependencies already installed"
fi
echo ""

# Build if dist doesn't exist
if [ ! -d "dist" ]; then
    echo "✓ Building backend..."
    npm run build > /dev/null 2>&1
    echo "  Backend built successfully"
else
    echo "✓ Backend already built"
fi
echo ""

# Check PostgreSQL
echo "🔍 Checking PostgreSQL..."
if command -v psql &> /dev/null; then
    if psql -h localhost -U postgres -d companydb -c "SELECT 1" &> /dev/null; then
        echo "  ✓ PostgreSQL is running at localhost:5432"
    else
        echo "  ⚠️  PostgreSQL is not responding"
        echo "  Start PostgreSQL: brew services start postgresql"
    fi
else
    echo "  ⚠️  PostgreSQL not found"
fi
echo ""

# Check Redis
echo "🔍 Checking Redis..."
if command -v redis-cli &> /dev/null; then
    if redis-cli ping > /dev/null 2>&1; then
        echo "  ✓ Redis is running at localhost:6379"
    else
        echo "  ⚠️  Redis is not responding"
        echo "  Start Redis: brew services start redis"
    fi
else
    echo "  ⚠️  Redis not found"
fi
echo ""

echo "=================================="
echo "📝 BEFORE STARTING:"
echo "=================================="
echo ""
echo "Make sure you have:"
echo "1. PostgreSQL running on localhost:5432"
echo "2. Redis running on localhost:6379"
echo ""
echo "To start them:"
echo "  brew services start postgresql"
echo "  brew services start redis"
echo ""

echo "=================================="
echo "🚀 STARTING BACKEND..."
echo "=================================="
echo ""
echo "Backend will be available at: http://localhost:3000"
echo "API Docs at: http://localhost:3000/api/docs"
echo ""
echo "Press Ctrl+C to stop"
echo ""

# Start the backend
npm run start:dev
