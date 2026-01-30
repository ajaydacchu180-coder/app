# 🚀 Netlify Deployment Guide
## Enterprise Attendance System - Flutter Web App

---

## 📋 Prerequisites

Before deploying to Netlify, ensure you have:

1. ✅ **Flutter SDK** installed (verified)
2. ✅ **Git** installed
3. ✅ **Netlify Account** (create at https://netlify.com)
4. ✅ **GitHub/GitLab Account** (recommended for continuous deployment)

---

## 🎯 Deployment Options

### Option 1: Netlify CLI (Recommended for Quick Deploy)

#### Step 1: Install Netlify CLI
```bash
npm install -g netlify-cli
```

#### Step 2: Login to Netlify
```bash
netlify login
```

#### Step 3: Initialize Netlify Site
```bash
netlify init
```

#### Step 4: Deploy
```bash
# Deploy to production
netlify deploy --prod

# Or deploy to preview first
netlify deploy
```

The CLI will walk you through:
- Creating a new site or linking to an existing one
- Confirming the build directory (`build/web`)
- Deploying your site

---

### Option 2: GitHub + Netlify (Recommended for CI/CD)

#### Step 1: Initialize Git Repository
```bash
git init
git add .
git commit -m "Initial commit - Enterprise Attendance System"
```

#### Step 2: Create GitHub Repository
1. Go to https://github.com/new
2. Create a new repository (e.g., `enterprise-attendance-app`)
3. **DO NOT** initialize with README (you already have code)

#### Step 3: Push to GitHub
```bash
git remote add origin https://github.com/YOUR_USERNAME/enterprise-attendance-app.git
git branch -M main
git push -u origin main
```

#### Step 4: Connect to Netlify
1. Go to https://app.netlify.com
2. Click **"Add new site"** → **"Import an existing project"**
3. Choose **GitHub**
4. Authorize Netlify to access your repositories
5. Select your `enterprise-attendance-app` repository

#### Step 5: Configure Build Settings
Netlify will auto-detect the `netlify.toml` file, but verify:

**Build settings:**
- **Base directory:** (leave empty or set to `.`)
- **Build command:** `flutter build web --release`
- **Publish directory:** `build/web`

**Environment variables:** (if needed)
- `FLUTTER_WEB_USE_SKIA` = `true`

#### Step 6: Deploy
Click **"Deploy site"**

Netlify will:
- Clone your repository
- Install Flutter
- Build your web app
- Deploy to a unique URL (e.g., `https://random-name-123.netlify.app`)

---

### Option 3: Manual Deploy (Drag & Drop)

#### Step 1: Build Your App
```bash
flutter build web --release
```

#### Step 2: Deploy via Netlify UI
1. Go to https://app.netlify.com
2. Drag and drop the `build/web` folder onto the Netlify dashboard
3. Your site will be deployed instantly!

**Pros:** Simple and fast  
**Cons:** No automatic updates, manual process each time

---

## 🔧 Configuration Files Created

### `netlify.toml`
Located in the root directory, this configures:
- Build command and publish directory
- Redirects for SPA routing
- Security headers (XSS protection, frame options)
- Cache control for static assets

### `build/web/_redirects`
Backup redirect rule for SPA routing:
```
/*    /index.html   200
```

---

## 🌐 Custom Domain Setup (Optional)

### Step 1: Add Custom Domain
1. In Netlify dashboard, go to **Site settings** → **Domain management**
2. Click **"Add custom domain"**
3. Enter your domain (e.g., `attendance.yourcompany.com`)

### Step 2: Configure DNS
Add the following DNS records at your domain registrar:

**For subdomain (e.g., attendance.yourcompany.com):**
```
Type: CNAME
Name: attendance
Value: your-site-name.netlify.app
```

**For apex domain (e.g., yourcompany.com):**
```
Type: A
Name: @
Value: 75.2.60.5
```

### Step 3: Enable HTTPS
Netlify automatically provisions SSL certificates via Let's Encrypt.
- Go to **Site settings** → **Domain management** → **HTTPS**
- Click **"Verify DNS configuration"**
- Certificate will be issued within minutes

---

## ⚙️ Environment Configuration

### Update for Production

Before deploying to production, update the configuration:

**File:** `lib/src/config/app_config.dart`

```dart
// Change this before production deployment
static const Environment environment = Environment.production;
```

Also update your API URLs if needed:
```dart
case Environment.production:
  return 'https://api.yourcompany.com/api/v1';
```

### Rebuild After Configuration Changes
```bash
flutter clean
flutter build web --release
```

---

## 🔍 Post-Deployment Verification

### Step 1: Check Site is Live
Visit your Netlify URL (e.g., `https://your-site-name.netlify.app`)

### Step 2: Test Core Functionality
- ✅ Login screen loads
- ✅ Navigation works
- ✅ No console errors
- ✅ Assets load correctly
- ✅ Responsive design works

### Step 3: Test on Multiple Browsers
- ✅ Chrome
- ✅ Firefox
- ✅ Safari
- ✅ Edge

### Step 4: Test on Mobile Devices
- ✅ iOS Safari
- ✅ Android Chrome

---

## 📊 Deployment Status Dashboard

### Monitoring Your Deployment

**Netlify Dashboard:**
- **Deploys:** View all deployments and their status
- **Functions:** (if you add serverless functions later)
- **Analytics:** View site traffic and performance
- **Logs:** Check build and deploy logs

**Build Logs:**
Access via: **Deploys** → Click on a deploy → **Deploy log**

---

## 🐛 Troubleshooting

### Build Fails on Netlify

**Problem:** Flutter not found
**Solution:** Netlify should auto-detect Flutter. If not:
1. Add build image in `netlify.toml`:
```toml
[build.environment]
  FLUTTER_VERSION = "3.x.x"
```

**Problem:** Dependencies fail to install
**Solution:** Ensure `pubspec.yaml` and `pubspec.lock` are committed to git

### Site Loads But Routes Don't Work

**Problem:** 404 on page refresh
**Solution:** Ensure `netlify.toml` redirects are configured (already done)

### Assets Not Loading

**Problem:** Images/fonts return 404
**Solution:** Check paths in your Flutter code are relative, not absolute

### CORS Errors

**Problem:** API calls blocked by CORS
**Solution:** Configure CORS on your backend API to allow your Netlify domain:
```javascript
// Backend (NestJS example)
app.enableCors({
  origin: ['https://your-site-name.netlify.app', 'https://yourdomain.com']
});
```

---

## 🔄 Continuous Deployment

### Automatic Deploys

Once connected to GitHub, Netlify will automatically:
- ✅ Deploy on every push to `main` branch
- ✅ Create preview deploys for pull requests
- ✅ Send deployment notifications

### Deploy Previews
Every pull request gets a unique preview URL:
```
https://deploy-preview-123--your-site-name.netlify.app
```

### Branch Deploys
Configure different branches for different environments:
- `main` → Production
- `staging` → Staging environment
- `develop` → Development environment

**Configuration in Netlify:**
**Site settings** → **Build & deploy** → **Continuous deployment** → **Branch deploys**

---

## 🔐 Security Best Practices

### 1. Environment Variables
Store sensitive data in Netlify environment variables:
- **Site settings** → **Build & deploy** → **Environment**
- Add variables like `API_KEY`, `BACKEND_URL`, etc.

### 2. Access Control
Restrict access during development:
- **Site settings** → **Access control**
- Set password protection or IP restrictions

### 3. HTTPS Only
Force HTTPS redirects:
- **Site settings** → **Domain management** → **HTTPS**
- Enable **"Force HTTPS"**

### 4. Security Headers
Already configured in `netlify.toml`:
- X-Frame-Options
- X-XSS-Protection
- X-Content-Type-Options
- Referrer-Policy

---

## 📈 Performance Optimization

### 1. Enable Asset Optimization
**Site settings** → **Build & deploy** → **Post processing**
- ✅ Bundle CSS
- ✅ Minify CSS
- ✅ Minify JS
- ✅ Image optimization

### 2. Cache Headers
Already configured in `netlify.toml` for:
- JavaScript files (1 year cache)
- CSS files (1 year cache)
- Fonts (1 year cache)

### 3. Prerendering (Optional)
For better SEO and initial load:
**Site settings** → **Build & deploy** → **Prerendering**

---

## 💰 Pricing & Limits

### Netlify Free Tier
- ✅ 100 GB bandwidth/month
- ✅ 300 build minutes/month
- ✅ Unlimited sites
- ✅ HTTPS/SSL included
- ✅ Continuous deployment
- ✅ Deploy previews

**Perfect for staging and small production deployments!**

### When to Upgrade
Consider Pro plan ($19/month) if you need:
- More bandwidth (400 GB)
- More build minutes (1000 min)
- Advanced analytics
- Priority support

---

## 📞 Support & Resources

### Netlify Documentation
- **Main Docs:** https://docs.netlify.com
- **Flutter Guide:** https://docs.netlify.com/frameworks/flutter/
- **CLI Reference:** https://cli.netlify.com

### Community Support
- **Netlify Community:** https://answers.netlify.com
- **Discord:** https://discord.gg/netlify

### Status Page
Check Netlify service status: https://www.netlifystatus.com

---

## ✅ Quick Deployment Checklist

**Before Deploying:**
- [ ] Run `flutter build web --release` successfully
- [ ] Test build locally (`flutter run -d chrome`)
- [ ] Update `AppConfig.environment` if needed
- [ ] Commit all changes to git
- [ ] Push to GitHub/GitLab

**Netlify Setup:**
- [ ] Create Netlify account
- [ ] Connect repository or install CLI
- [ ] Configure build settings
- [ ] Set environment variables (if needed)

**After Deploying:**
- [ ] Verify site loads correctly
- [ ] Test all major features
- [ ] Check on multiple browsers
- [ ] Monitor for errors
- [ ] Set up custom domain (optional)
- [ ] Enable HTTPS

---

## 🎉 Success!

Your Enterprise Attendance System is now live on Netlify!

**Your site URL will be:**
```
https://your-chosen-name.netlify.app
```

Or with custom domain:
```
https://attendance.yourcompany.com
```

---

## 📝 Next Steps After Deployment

1. **Share the URL** with stakeholders for testing
2. **Monitor the Netlify dashboard** for traffic and errors
3. **Set up analytics** (Netlify Analytics or Google Analytics)
4. **Configure custom domain** (if needed)
5. **Enable deploy notifications** (Slack, Email, etc.)
6. **Create staging environment** (separate site or branch deploy)

---

**Deployment Guide Version:** 1.0  
**Last Updated:** January 29, 2026  
**Maintained By:** Full Stack Developer Team
