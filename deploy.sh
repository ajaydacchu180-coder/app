#!/bin/bash
# Quick Netlify Deployment Script for Enterprise Attendance System

echo "🚀 Starting Netlify Deployment Process..."
echo ""

# Step 1: Clean previous builds
echo "📦 Step 1: Cleaning previous builds..."
flutter clean
echo "✅ Clean complete"
echo ""

# Step 2: Get dependencies
echo "📥 Step 2: Getting dependencies..."
flutter pub get
echo "✅ Dependencies installed"
echo ""

# Step 3: Run tests
echo "🧪 Step 3: Running tests..."
flutter test
if [ $? -ne 0 ]; then
    echo "❌ Tests failed! Please fix before deploying."
    exit 1
fi
echo "✅ All tests passed"
echo ""

# Step 4: Build for web
echo "🏗️  Step 4: Building for web (release mode)..."
flutter build web --release
if [ $? -ne 0 ]; then
    echo "❌ Build failed! Please check errors above."
    exit 1
fi
echo "✅ Build complete"
echo ""

# Step 5: Create _redirects file
echo "📝 Step 5: Creating redirects file..."
echo "/*    /index.html   200" > build/web/_redirects
echo "✅ Redirects file created"
echo ""

# Step 6: Deploy to Netlify
echo "🌐 Step 6: Deploying to Netlify..."
netlify deploy --prod --dir=build/web

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 ============================================"
    echo "   Deployment Successful!"
    echo "============================================"
    echo ""
    echo "Your app is now live on Netlify!"
    echo ""
else
    echo ""
    echo "❌ Deployment failed. Please check the error above."
    exit 1
fi
