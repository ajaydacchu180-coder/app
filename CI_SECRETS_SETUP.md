# CI/CD Secrets & Configuration Guide

This guide explains how to set up GitHub Secrets for automated builds and deployments.

## Overview
The CI/CD pipeline (`.github/workflows/release-build.yml`) requires several secrets to build and deploy release artifacts. Below are the required secrets and how to generate them.

---

## 1. Android Play Store Upload

### Required Secrets

#### `ANDROID_KEYSTORE_BASE64`
**Purpose:** Base64-encoded Android signing keystore file

**How to create:**

1. **Generate a keystore locally** (one-time, save it securely):
```bash
keytool -genkey -v -keystore release-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias enterprise_attendance_key \
  -keypass YOUR_KEY_PASSWORD \
  -storepass YOUR_STORE_PASSWORD
```

2. **Convert keystore to Base64:**
```bash
cat release-keystore.jks | base64 > keystore.base64
```

3. **Add to GitHub Secrets:**
   - Go to your GitHub repo → **Settings** → **Secrets and variables** → **Actions**
   - Click **New repository secret**
   - Name: `ANDROID_KEYSTORE_BASE64`
   - Value: paste the output from step 2 (the entire base64 string)

#### `ANDROID_KEYSTORE_PASSWORD`
**Value:** The keystore password you set when creating the keystore

#### `ANDROID_KEY_ALIAS`
**Value:** `enterprise_attendance_key` (or whatever alias you chose)

#### `ANDROID_KEY_PASSWORD`
**Value:** The key password you set when creating the keystore

---

## 2. Google Play Store Service Account

### Required Secret

#### `PLAY_STORE_JSON_KEY`
**Purpose:** Google Play Store service account JSON key (for automated uploads)

**How to create:**

1. **Create a Google Cloud Service Account:**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create or select a project
   - Navigate to **Service Accounts** → **Create Service Account**
   - Name: `enterprise-attendance-ci`
   - Grant role: **Editor** (or more restrictive: Service Account User)

2. **Create & download a JSON key:**
   - In Service Accounts, click the newly created account
   - Go to **Keys** tab → **Add Key** → **Create new key**
   - Choose **JSON**
   - A JSON file will download

3. **Add to GitHub Secrets:**
   - Go to your GitHub repo → **Settings** → **Secrets and variables** → **Actions**
   - Click **New repository secret**
   - Name: `PLAY_STORE_JSON_KEY`
   - Value: paste the entire JSON file content

---

## 3. Apple App Store / TestFlight Upload

### Required Secrets

#### `APPSTORE_ISSUER_ID`
**Purpose:** Apple App Store Connect Issuer ID (for app signing)

**How to get:**
1. Log in to [App Store Connect](https://appstoreconnect.apple.com/)
2. Go to **Users and Access** → **Integrations** → **App Store Connect API**
3. Create a new API key with role **App Manager**
4. Copy the **Issuer ID**

#### `APPSTORE_API_KEY_ID`
**Purpose:** Apple API Key ID

**How to get:**
1. In App Store Connect API section, copy the **Key ID** of your created key

#### `APPSTORE_API_PRIVATE_KEY`
**Purpose:** Apple API private key (PEM format)

**How to get:**
1. Download the private key file from App Store Connect (`.p8` file)
2. Open it in a text editor and copy the entire content (including `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----`)
3. Add to GitHub Secrets

---

## 4. GitHub Actions Setup

### Required Environment Variables (already in workflow)

These are defined in `.github/workflows/release-build.yml`:

- `FLUTTER_VERSION`: Set to your target Flutter version (e.g., `3.16.0`)
- `JAVA_VERSION`: Set to `11` for Android builds

---

## 5. Triggering the CI Pipeline

### Automatic Trigger

The pipeline runs automatically on:
- **Push to `main` branch**
- **Push of tags** matching `v*` (e.g., `v1.0.0`, `v1.0.1`)
- **Manual dispatch** from GitHub Actions tab

### Manual Trigger

1. Go to your GitHub repo
2. Click **Actions** tab
3. Click **Release Build & Deploy**
4. Click **Run workflow** → choose branch → **Run workflow**

### Typical Release Flow

```bash
# 1. Update version in pubspec.yaml
# Example: version: 1.0.0+1

# 2. Commit changes
git add -A
git commit -m "chore: release v1.0.0"

# 3. Create and push a git tag
git tag v1.0.0
git push origin main --tags

# GitHub Actions will automatically:
# - Analyze & test
# - Build Android AAB/APK
# - Build iOS app
# - Build Web assets
# - Upload to Play Store (internal track, draft)
# - Upload to TestFlight (beta)
```

---

## 6. Post-Build Steps

### For Android (Play Store)

1. **Internal Testing Track (automated via CI):**
   - Review the draft release in [Google Play Console](https://play.console.google.com/)
   - Test the build on real devices
   - Promote to closed testing track when verified

2. **Production Release (manual step):**
   - In Play Console, promote from internal/closed testing → **Production**
   - Fill in release notes
   - Review policy compliance
   - Submit for review

### For iOS (App Store)

1. **TestFlight Beta (automated via CI):**
   - Check [App Store Connect](https://appstoreconnect.apple.com/) → **TestFlight**
   - Invite internal testers
   - Test on real devices (minimum 24 hours before App Store submission)

2. **App Store Release (manual step):**
   - In App Store Connect, go to **Builds** → select tested build
   - Click **Submit for Review** → fill details → **Submit**
   - Apple reviews (typically 1-3 days)
   - Once approved, select build for release and submit for distribution

---

## 7. Troubleshooting CI Failures

### Android Build Fails: "keystore not found"
- Ensure `ANDROID_KEYSTORE_BASE64` is set correctly
- Check that `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` match

### Play Store Upload Fails: "Invalid service account"
- Verify `PLAY_STORE_JSON_KEY` is the full JSON content (not just a portion)
- Ensure the service account has **Editor** or **App Manager** role in Google Cloud

### iOS Build Fails: "Provisioning profile not found"
- iOS signing in CI requires Xcode Cloud or a more complex setup
- Alternative: manually sign and upload from a macOS machine with Xcode

### Tests Fail in CI
- Ensure all tests pass locally: `flutter test`
- Check that test fixtures and mocks match your environment

---

## 8. Local Keystore Backup

**IMPORTANT:** Keep your Android keystore file safe!

```bash
# Store securely (e.g., password manager, encrypted drive)
# DO NOT commit to git
# DO NOT share publicly

# If lost, you cannot update the app on Play Store with a new keystore
# You must create a new app bundle ID
```

---

## 9. Updating Secrets

To rotate or update a secret:

1. Go to repo → **Settings** → **Secrets and variables** → **Actions**
2. Click the secret to update
3. Click **Update**
4. Paste the new value
5. Click **Update secret**

Next CI run will use the updated value.

---

## 10. Security Best Practices

✅ **Do:**
- Store keystore passwords in a secure password manager
- Rotate API keys periodically
- Use service account keys with minimal required permissions
- Enable branch protection rules to require CI to pass before merging
- Review CI logs for sensitive data leaks

❌ **Don't:**
- Commit `key.properties` or keystores to git (they're in `.gitignore`)
- Share secrets via email or chat
- Use the same password for multiple systems
- Expose secrets in CI logs (use `::add-mask::` in GitHub Actions)

---

## 11. Next Steps

1. **Set up all secrets** listed above in your GitHub repo
2. **Test a release build locally** (optional but recommended):
   ```bash
   flutter build appbundle --release
   ```
3. **Trigger a test CI run** by pushing a tag or using manual dispatch
4. **Monitor the CI logs** for errors
5. **Review the generated artifacts** (AAB, APK, etc.)
6. **Upload to Play Console** (internal testing first) and **App Store Connect** (TestFlight)
7. **Test on real devices** before promoting to production

---

For questions or issues, refer to:
- [Flutter Build Release Documentation](https://flutter.dev/docs/deployment/android-release)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
