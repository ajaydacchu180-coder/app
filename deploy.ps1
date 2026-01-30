# PowerShell Deployment Script for Netlify
# Enterprise Attendance System

Write-Host "🚀 Starting Netlify Deployment Process..." -ForegroundColor Cyan
Write-Host ""

# Step 1: Clean previous builds
Write-Host "📦 Step 1: Cleaning previous builds..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Clean complete" -ForegroundColor Green
} else {
    Write-Host "❌ Clean failed" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 2: Get dependencies
Write-Host "📥 Step 2: Getting dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Dependencies installed" -ForegroundColor Green
} else {
    Write-Host "❌ Dependency installation failed" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 3: Run tests
Write-Host "🧪 Step 3: Running tests..." -ForegroundColor Yellow
flutter test
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ All tests passed" -ForegroundColor Green
} else {
    Write-Host "❌ Tests failed! Please fix before deploying." -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 4: Build for web
Write-Host "🏗️  Step 4: Building for web (release mode)..." -ForegroundColor Yellow
flutter build web --release
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Build complete" -ForegroundColor Green
} else {
    Write-Host "❌ Build failed! Please check errors above." -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 5: Create _redirects file
Write-Host "📝 Step 5: Creating redirects file..." -ForegroundColor Yellow
"/*    /index.html   200" | Out-File -FilePath "build\web\_redirects" -Encoding ASCII
Write-Host "✅ Redirects file created" -ForegroundColor Green
Write-Host ""

# Step 6: Check if Netlify CLI is installed
Write-Host "🔍 Step 6: Checking Netlify CLI..." -ForegroundColor Yellow
$netlifyInstalled = Get-Command netlify -ErrorAction SilentlyContinue
if (-not $netlifyInstalled) {
    Write-Host "⚠️  Netlify CLI not found!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please install Netlify CLI with:" -ForegroundColor Cyan
    Write-Host "  npm install -g netlify-cli" -ForegroundColor White
    Write-Host ""
    Write-Host "After installation, run this script again." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Alternatively, you can:" -ForegroundColor Yellow
    Write-Host "  1. Go to https://app.netlify.com" -ForegroundColor White
    Write-Host "  2. Drag and drop the 'build\web' folder" -ForegroundColor White
    exit 1
}
Write-Host "✅ Netlify CLI found" -ForegroundColor Green
Write-Host ""

# Step 7: Deploy to Netlify
Write-Host "🌐 Step 7: Deploying to Netlify..." -ForegroundColor Yellow
Write-Host ""
netlify deploy --prod --dir=build/web

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "   🎉 Deployment Successful!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your app is now live on Netlify!" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "❌ Deployment failed. Please check the error above." -ForegroundColor Red
    exit 1
}
