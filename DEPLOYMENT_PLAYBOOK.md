# 🚀 Deployment Playbook – Production Release Checklist

**Version:** 1.0.0  
**Last Updated:** February 2, 2026  
**Status:** Ready for Staging → Production

---

## Pre-Deployment (Dev/Staging)

### 1. Local Testing & Build
- [ ] All tests pass: `flutter test`
- [ ] Static analysis clean: `flutter analyze`
- [ ] Code review completed
- [ ] Staging API endpoints verified in `lib/src/config/app_config.dart`
- [ ] All feature flags set to non-mock for staging

```bash
# Quick verification
flutter analyze
flutter test
flutter build appbundle --release      # Android
flutter build ios --release --no-codesign  # iOS (no signing for staging)
flutter build web --release            # Web
```

### 2. Staging Deployment

**For Android:**
```bash
# Build and upload to Play Store internal testing track
flutter build appbundle --release
# Use Google Play Console to upload to internal testing
```

**For iOS:**
```bash
# Build and upload to TestFlight
flutter build ios --release
# Use Xcode or App Store Connect to upload
```

**For Web:**
- Deploy to staging domain (e.g., `staging.enterprise-attendance.com`)
- Serve `build/web` content from CDN

### 3. Staging Validation (QA Team)

- [ ] User authentication works end-to-end
- [ ] API calls hit staging backend
- [ ] Crash reporting logs are captured
- [ ] Performance meets SLA (< 200ms API response time)
- [ ] No unhandled exceptions in logs
- [ ] Geofencing & location services work
- [ ] 2FA/biometric auth flows function
- [ ] Database migrations apply cleanly
- [ ] Audit logging captures events

**If issues found:** Fix, rebuild, re-test in staging.

---

## Production Deployment

### 4. Pre-Release Checklist

#### Code & Configuration
- [ ] `lib/src/config/app_config.dart` environment set to `Environment.production`
- [ ] Production API endpoints configured
- [ ] Debug logs disabled (`AppConfig.showDebugLogs` → `false`)
- [ ] Mock data disabled (`AppConfig.useMockData` → `false`)
- [ ] All sensitive data uses secure storage
- [ ] SSL/TLS certificates valid and pinned (if implemented)

#### Signing & Build
- [ ] Android keystore created and backed up securely
- [ ] iOS signing certificates renewed (if expired)
- [ ] Provisioning profiles current
- [ ] Code obfuscation enabled (ProGuard for Android)
- [ ] Symbol files uploaded for crash symbolication

#### Testing & QA
- [ ] All unit tests pass (100% of test suite)
- [ ] Integration tests pass
- [ ] Performance tests meet targets
- [ ] Security scan completed (OWASP Top 10)
- [ ] UAT (User Acceptance Testing) sign-off
- [ ] Load testing completed (>1000 concurrent users)

#### Infrastructure & Monitoring
- [ ] Production database backups configured
- [ ] Crash reporting (Crashlytics/Sentry) operational
- [ ] Performance monitoring setup
- [ ] Uptime monitoring configured
- [ ] Log aggregation working (ELK, DataDog, CloudWatch, etc.)
- [ ] Alert channels configured (Slack, email, PagerDuty)
- [ ] On-call rotation established

#### Documentation & Runbooks
- [ ] Runbook for rollback procedure
- [ ] Runbook for manual hotfix deployment
- [ ] On-call escalation procedures
- [ ] Customer communication plan for outages

### 5. Release Build & Upload

**Option A: Automated via GitHub Actions**

```bash
# Tag a release and push
git tag v1.0.0
git push origin main --tags

# GitHub Actions will:
# 1. Run all tests
# 2. Build Android AAB & APK
# 3. Build iOS app
# 4. Build Web assets
# 5. Upload to Play Store (internal track, draft)
# 6. Prepare for TestFlight
# 7. Upload web build to artifact storage
```

**Option B: Manual Build Locally**

```bash
# Android
flutter build appbundle --release
# Upload android/key.properties before building
# Then upload AAB to Play Console

# iOS
flutter build ios --release
# Use Xcode to archive and export
# Upload to App Store Connect

# Web
flutter build web --release
# Deploy to production CDN
```

### 6. Store Submission

#### Google Play Store

1. Open [Google Play Console](https://play.console.google.com/)
2. Select your app
3. Go to **Release** → **Production**
4. Click **Create new release**
5. Upload the AAB (if not already via CI)
6. Fill in:
   - Release notes (bullet points of new features/fixes)
   - Version number (should auto-match)
   - Device targeting (if applicable)
7. Review privacy policy & content rating
8. Click **Save & review** → **Start rollout to Production**
9. Choose rollout percentage:
   - Recommend: Start at **5%**, increase to **25%**, then **100%** over 24-48 hours
   - Monitor crash rate & user reviews between increases

#### Apple App Store

1. Open [App Store Connect](https://appstoreconnect.apple.com/)
2. Select your app
3. Go to **TestFlight** → Review test results
4. Once confident, go to **App Store** → **Build** section
5. Select the tested build
6. Click **Submit for Review**
7. Fill in:
   - Release notes
   - Demo account credentials (if needed)
   - Any compliance info
8. Click **Add for Review**
9. Apple reviews (1-3 business days)
10. Once approved, go back to **App Store** → **Release** → **Add for sale**

### 7. Post-Release Monitoring (First 24 Hours)

**Critical Metrics to Monitor:**

- [ ] Crash rate (target: < 0.1%)
- [ ] API error rate (target: < 0.5%)
- [ ] Login success rate (target: > 99%)
- [ ] API response time (target: < 200ms p95)
- [ ] User acquisition and session duration (baseline comparison)

**Check Every 1-2 Hours:**

```bash
# Sample monitoring checklist
- Error log dashboard for new exceptions
- Crash reporting service (Crashlytics/Sentry)
- Performance metrics (APM)
- User reviews (App Store / Play Store)
- Support tickets / issues from users
- Database query performance
- Server CPU/memory utilization
```

**If Critical Issue Found:**
1. Immediately page on-call team
2. Check if rollback is necessary (see section 8)
3. If rollback: use Play Store staged rollout to revert or release previous build
4. Post-incident: document issue, root cause, and prevention

### 8. Rollback Procedure

**If a critical bug is discovered post-release:**

1. **Verify the issue is from the new build** (not environment/infrastructure)
2. **Pull the previous stable version** from git tags
3. **Build and upload previous version:**
   ```bash
   git checkout v0.9.0  # or previous stable tag
   flutter build appbundle --release
   # Upload to Play Console (staged rollout, 100%)
   
   # Similar for iOS → App Store Connect
   ```
4. **Notify stakeholders** (via Slack, email)
5. **Post-incident review** within 24 hours

---

## Post-Release (Days 1-7)

### 9. Stabilization Phase

- [ ] Monitor crash rate continuously
- [ ] Address high-priority bugs immediately
- [ ] Communicate with users (in-app notification if major update)
- [ ] Analyze user feedback and ratings
- [ ] Track adoption rate
- [ ] Monitor server resources

### 10. Hotfix Release (if needed)

**If a critical issue discovered:**

1. Create a fix in a hotfix branch
   ```bash
   git checkout -b hotfix/critical-bug v1.0.0
   # Apply fix
   git commit -m "hotfix: critical-bug description"
   ```

2. Build and test
   ```bash
   flutter test
   flutter analyze
   flutter build appbundle --release
   ```

3. Tag and release
   ```bash
   git tag v1.0.1
   git push origin hotfix/critical-bug --tags
   # CI automatically builds and prepares upload
   ```

4. Submit via Play Store / App Store (expedited review)

5. Merge hotfix back to main
   ```bash
   git checkout main
   git merge hotfix/critical-bug
   git push origin main
   ```

---

## Post-Release (Day 7+)

### 11. Release Retrospective

**Hold a retrospective with the team:**

- [ ] What went well?
- [ ] What could be improved?
- [ ] Were all tests adequate?
- [ ] Did monitoring catch issues early?
- [ ] Were runbooks clear?
- [ ] Any infrastructure issues?

**Document findings** and create backlog items for improvements.

### 12. Version Stability

Once stable (> 7 days, < 0.05% crash rate):
- [ ] Mark as "stable" in version control
- [ ] Update release notes as "stable release"
- [ ] Archive old builds (if applicable)
- [ ] Sunset old mobile app versions (if applicable)

---

## Release Frequency & Planning

**Recommended Release Schedule:**
- **Weekly patches**: bug fixes, performance improvements
- **Bi-weekly features**: new functionality (backward compatible)
- **Monthly major releases**: breaking changes, UI overhauls

**Planning Steps:**
1. 1 week before: freeze feature commits, focus on testing
2. 3 days before: finalize release notes, update docs
3. 1 day before: final staging validation
4. Release day: deploy to production, monitor closely
5. 1 week after: retrospective & planning for next release

---

## Communication Plan

### During Development
- Daily standups with the team
- Weekly feature review meetings

### Pre-Release
- Notify customer success team 1 week before
- Prepare customer-facing release notes
- Schedule support team briefing

### Release Day
- Notify stakeholders 30 min before release start
- Post updates to #releases Slack channel
- Update status page

### Post-Release (First 24 Hours)
- Hourly status updates to stakeholders
- Report any critical issues immediately
- Daily standup for incident response

### Resolution
- Post-release retrospective summary
- Customer communication of any issues + fixes

---

## Contacts & Escalation

**On-Call Rotation:** (add your team)
- Primary: [Name] - [Slack/Phone]
- Secondary: [Name] - [Slack/Phone]
- Escalation: [Manager/Lead] - [Slack/Phone]

**Key Services:**
- **Crash Reporting:** [Crashlytics/Sentry Dashboard Link]
- **Performance Monitoring:** [APM Dashboard Link]
- **Log Aggregation:** [Kibana/DataDog/CloudWatch Link]
- **Status Page:** [internal or public status page]

---

## Quick Command Reference

```bash
# Full release workflow
git tag v1.0.0
git push origin main --tags

# CI automatically handles build and upload

# Manual local build (if needed)
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release       # Android
flutter build ios --release --no-codesign # iOS

# Rollback to previous version
git checkout v0.9.0
flutter build appbundle --release
# Upload via Play Console
```

---

## Sign-Off

**Release Manager:** _______________  **Date:** _______________

**QA Lead:** _______________  **Date:** _______________

**Product Owner:** _______________  **Date:** _______________

---

*Last Updated: February 2, 2026*  
*Next Review: [Add quarterly review date]*
