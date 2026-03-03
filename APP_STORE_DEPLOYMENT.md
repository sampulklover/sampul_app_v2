# App Store Deployment Guide

This guide walks you through the complete process of uploading your Flutter app to the Apple App Store.

## Prerequisites

- ✅ Apple Developer Program account (already have)
- ✅ macOS with Xcode installed
- ✅ Flutter project configured and tested
- ✅ App icons and launch screen assets ready

---

## Step 1: Prepare Your Flutter iOS Project

### 1.1 Update Version and Build Number

In `pubspec.yaml`, ensure your version is set correctly:

```yaml
version: 1.0.0+1
```

Format: `version_name+build_number`
- `1.0.0` = Version name (what users see)
- `1` = Build number (must increment for each upload)

**Important:** Each App Store upload requires a unique, incrementing build number.

### 1.2 Configure Bundle Identifier

1. Open your project in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. In Xcode:
   - Select the **Runner** project in the left sidebar
   - Select the **Runner** target
   - Go to **Signing & Capabilities** tab (not General tab)
   - Find **Bundle Identifier** field at the top
   - Set **Bundle Identifier** (e.g., `com.yourcompany.sampulapp`)
   
   **Note:** 
   - In modern Xcode versions, the Bundle Identifier is **editable in the "Signing & Capabilities" tab**, not the General tab
   - The General tab may show the bundle ID, but it's read-only there
   - This Bundle ID must match exactly what you'll use in App Store Connect and Apple Developer portal

#### Changing Bundle Identifier

**⚠️ Important Considerations:**

- **Before First Upload**: You can change the bundle ID freely before your first App Store upload
- **After Upload**: Once you've uploaded a build to App Store Connect, changing the bundle ID creates a **new app** (you cannot change it for an existing app)
- **Best Practice**: Choose your final bundle ID before the first upload

**How to Change Bundle ID:**

**Method 1: Using Xcode (Recommended)**

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** project → **Runner** target
3. Go to **Signing & Capabilities** tab (this is where you can edit it)
4. Change **Bundle Identifier** field to your desired ID (e.g., `com.yourcompany.sampulapp`)
5. If using automatic signing, Xcode will update provisioning profiles automatically
6. Also update **RunnerTests** target bundle ID:
   - Select **RunnerTests** target
   - Go to **Signing & Capabilities** tab
   - Change bundle ID to `YOUR_BUNDLE_ID.RunnerTests`

**Method 2: Manual Edit (Advanced)**

If you need to change it manually in the project file:

1. The bundle ID is stored in `ios/Runner.xcodeproj/project.pbxproj`
2. Search for `PRODUCT_BUNDLE_IDENTIFIER` and replace all occurrences
3. Also check `ios/Runner/Info.plist` for any hardcoded bundle ID references
4. Update URL schemes in `Info.plist` if they reference the old bundle ID

**Current Bundle ID:** Your project currently uses `com.sampul.app`

**Recommended Format:** `com.yourcompany.appname` (e.g., `com.sampul.app` or `com.yourcompany.sampul`)

### 1.3 Verify App Icons and Launch Screen

- Ensure app icons are configured in `ios/Runner/Assets.xcassets/AppIcon.appiconset`
- Verify launch screen is set up correctly (not blank)
- Test on a physical device before archiving

---

## Step 2: Set Up App ID and Provisioning Profiles

### 2.1 Create App ID (Apple Developer Portal)

1. Go to [Apple Developer Portal](https://developer.apple.com/account)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click **Identifiers** → **+** (plus button)
4. Select **App IDs** → **App**
5. Fill in:
   - **Description**: Your app name
   - **Bundle ID**: Use the same Bundle ID as in Xcode (or create a new one)
   - **Capabilities**: Enable any needed capabilities:
     - Push Notifications (if using OneSignal)
     - Sign In with Apple (if applicable)
     - Associated Domains (if using deep linking)
     - etc.
6. Click **Continue** → **Register**

### 2.2 Create Provisioning Profiles

#### Option A: Automatic Signing (Recommended)

If you use automatic signing in Xcode:
1. In Xcode, go to **Signing & Capabilities** tab
2. Select your **Team** (your Apple Developer account)
3. Check **Automatically manage signing**
4. Xcode will create profiles automatically

#### Option B: Manual Provisioning Profiles

1. In Apple Developer Portal → **Profiles**
2. Click **+** to create:
   - **iOS App Development** (for testing)
   - **App Store** (Distribution) - **Required for App Store upload**
3. Select your App ID
4. Select your distribution certificate (or create one if needed)
5. Download and double-click to install in Xcode

---

## Step 3: Create App in App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click **My Apps** → **+** → **New App**
3. Fill in:
   - **Platform**: iOS
   - **Name**: Your app name (as it will appear in App Store)
   - **Primary Language**: e.g., English
   - **Bundle ID**: Select the one you created in Step 2.1
   - **SKU**: Internal identifier (e.g., `sampulapp-v1`)
   - **User Access**: Full Access (usually)
4. Click **Create**

### 3.1 Complete App Information

After creating the app, fill in required information:

- **App Information**:
  - Subtitle (optional)
  - Category (Primary and Secondary)
  - Age Rating (complete questionnaire)
  
- **App Privacy**:
  - Complete privacy questionnaire (required)
  - Describe data collection practices
  
- **App Review Information**:
  - Contact information
  - Demo account (if login required)
  - Notes for reviewers

---

## Step 4: Configure Signing & Build for Release

### 4.1 Prepare Flutter Build

First, ensure your Flutter project is ready:

```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build iOS release (prepares Xcode project)
flutter build ios --release
```

### 4.2 Configure Xcode Signing

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** project → **Runner** target
3. Go to **Signing & Capabilities** tab:
   - Select your **Team**
   - Ensure **Bundle Identifier** matches App Store Connect
   - Choose:
     - ✅ **Automatically manage signing** (recommended), OR
     - Select your **App Store** provisioning profile manually
4. Go to **Build Settings**:
   - Verify **iOS Deployment Target** (e.g., iOS 12.0 or higher)

---

## Step 5: Archive and Upload Build

### 5.1 Create Archive

1. In Xcode, select **Any iOS Device (arm64)** as the run destination (NOT a simulator)
2. Go to **Product** → **Archive**
3. Wait for archive to complete (Xcode Organizer will open automatically)

### 5.2 Distribute to App Store Connect

1. In the **Organizer** window, select your archive
2. Click **Distribute App**
3. Choose:
   - **App Store Connect** → **Upload**
   - Click **Next**
4. Select distribution options:
   - ✅ **Rebuild from bitcode** (if applicable for your Xcode version)
   - ✅ **Include bitcode** (if required)
   - Click **Next**
5. Review signing options (usually automatic is fine)
6. Click **Upload**
7. Wait for upload to complete (may take several minutes)

**Alternative Method:** You can also export an `.ipa` file and upload via Apple's **Transporter** app, but Xcode upload is simpler.

### 5.3 Verify Upload

1. Go to App Store Connect → Your App
2. Navigate to **TestFlight** tab
3. Your build should appear (processing takes 10-30 minutes)
4. Wait for status to change from "Processing" to "Ready to Submit"

---

## Step 6: Configure App Store Listing

Once your build is processed and ready:

### 6.1 App Store Information

1. In App Store Connect → Your App → **App Store** tab
2. Fill in required sections:

   **App Information:**
   - Subtitle (optional)
   - Category
   - Age rating
   
   **Pricing and Availability:**
   - Price tier
   - Availability (countries)
   
   **App Privacy:**
   - Complete privacy questionnaire

### 6.2 Version Information

1. Click **+ Version** or select version
2. Fill in:
   - **What's New in This Version** (release notes)
   - **Description** (app description)
   - **Keywords** (comma-separated, for search)
   - **Support URL** (required)
   - **Marketing URL** (optional)
   - **Promotional Text** (optional, shown above description)

### 6.3 Screenshots (Required)

Upload screenshots for all required device sizes:
- **6.7" Display** (iPhone 14 Pro Max, 15 Pro Max)
- **6.5" Display** (iPhone 11 Pro Max, XS Max)
- **6.1" Display** (iPhone 14 Pro, 15 Pro, 13 Pro, 12 Pro)
- **5.5" Display** (iPhone 8 Plus, 7 Plus, 6s Plus)

**Tips:**
- Screenshots must be actual app screenshots (no placeholders)
- First screenshot is most important (appears in search results)
- Can use same screenshots for multiple sizes if needed

### 6.4 App Preview Videos (Optional)

You can upload short videos (15-30 seconds) showcasing your app.

### 6.5 Select Build

1. In the version page, scroll to **Build** section
2. Click **+** next to Build
3. Select your uploaded build
4. Click **Done**

---

## Step 7: Submit for Review

### 7.1 Final Checks

Before submitting, ensure:
- ✅ All required fields are filled
- ✅ Screenshots uploaded for all required sizes
- ✅ Build is selected and ready
- ✅ Age rating completed
- ✅ Privacy questionnaire completed
- ✅ No warnings or errors in App Store Connect

### 7.2 Submit

1. Scroll to top of version page
2. Click **Add for Review** or **Submit for Review**
3. Answer any export compliance questions (if applicable)
4. Confirm submission

### 7.3 Review Process

- **Initial Review**: Usually 1-3 business days
- **Status Updates**: Check App Store Connect for status
- **Possible Outcomes**:
  - ✅ **Approved**: App goes live (or scheduled release)
  - ⚠️ **Rejected**: Review feedback provided, fix issues and resubmit
  - 🔄 **In Review**: Still being reviewed

---

## Step 8: TestFlight (Optional but Recommended)

Before public release, test with TestFlight:

### 8.1 Internal Testing

1. After build is processed, go to **TestFlight** tab
2. Add **Internal Testers**:
   - Up to 100 users from your App Store Connect team
   - They'll receive email invites
   - No review required

### 8.2 External Testing (Optional)

1. Create **External Testing Group**
2. Add testers (up to 10,000)
3. Requires brief App Review (usually 24-48 hours)
4. Great for beta testing before public release

---

## Common Issues and Solutions

### Issue: "No accounts with App Store Connect access"

**Solution:** Ensure you're signed in with an Apple ID that has App Store Connect access, and your team is selected in Xcode.

### Issue: "Bundle ID mismatch"

**Solution:** Ensure Bundle ID in Xcode, Apple Developer Portal, and App Store Connect all match exactly.

### Issue: "Failed Registering Bundle Identifier" / "No profiles for [bundle ID] were found"

**Symptoms:**
- Error: "The app identifier 'com.sampul.app' cannot be registered to your development team because it is not available"
- Error: "Xcode couldn't find any iOS App Development provisioning profiles matching '[bundle ID]'"
- App exists in App Store Connect but Xcode can't register it

**Root Cause:** The bundle ID exists in App Store Connect, but the **App ID** hasn't been created in the **Apple Developer Portal** for your team, OR there's a team/account mismatch.

**Solution Steps:**

1. **Verify Team in Xcode:**
   - In Xcode → **Signing & Capabilities** tab
   - Check that the correct **Team** is selected (should match your App Store Connect account)
   - If wrong team is selected, change it to the correct one

2. **Create App ID in Apple Developer Portal:**
   - Go to [Apple Developer Portal](https://developer.apple.com/account)
   - Navigate to **Certificates, Identifiers & Profiles**
   - Click **Identifiers** → **+** (plus button)
   - Select **App IDs** → **App**
   - Choose **App** (not App Clip or other)
   - Fill in:
     - **Description**: Your app name (e.g., "Sampul App")
     - **Bundle ID**: Select **Explicit** and enter `com.sampul.app` (must match exactly)
   - Enable required **Capabilities**:
     - Push Notifications (if using OneSignal)
     - Sign In with Apple (if applicable)
     - Associated Domains (if using deep linking)
     - Any other capabilities your app needs
   - Click **Continue** → **Register**

3. **Wait a few minutes** for the App ID to propagate

4. **Return to Xcode:**
   - Go back to **Signing & Capabilities** tab
   - Click **Try Again** button (if shown)
   - Or uncheck and recheck **Automatically manage signing**
   - Xcode should now be able to create provisioning profiles

5. **If still not working:**
   - Clean build folder: **Product** → **Clean Build Folder** (Shift+Cmd+K)
   - Close and reopen Xcode
   - Try again

**Important:** The bundle ID must be registered as an **App ID** in the Developer Portal before Xcode can create provisioning profiles for it, even if the app already exists in App Store Connect.

### Issue: "Invalid provisioning profile"

**Solution:** 
- Use automatic signing, OR
- Create new App Store distribution profile in Developer Portal
- Download and install in Xcode

### Issue: "Missing compliance"

**Solution:** Answer export compliance questions in App Store Connect when submitting.

### Issue: Build processing fails

**Solution:**
- Check build logs in App Store Connect
- Ensure all required capabilities are enabled
- Verify signing certificates are valid

---

## Version Updates for Future Archives

**Important:** Every time you create a new archive and upload to App Store Connect, you **MUST** update the version number in `pubspec.yaml`.

### Understanding Version Numbers

The version format is: `version_name+build_number`

Example: `1.0.0+1`
- `1.0.0` = **Version Name** (what users see in App Store)
- `1` = **Build Number** (must be unique and incrementing)

### What to Update

#### ✅ **Build Number (REQUIRED for every upload)**
- **MUST increment** for every new archive/upload
- Can be any number, but must be **higher** than previous uploads
- Apple rejects uploads with duplicate or lower build numbers

#### ⚠️ **Version Name (Optional, but recommended)**
- Update when you want users to see a new version
- Follow semantic versioning: `MAJOR.MINOR.PATCH`
  - **Major** (1.0.0 → 2.0.0): Breaking changes, major features
  - **Minor** (1.0.0 → 1.1.0): New features, backward compatible
  - **Patch** (1.0.0 → 1.0.1): Bug fixes, small improvements

### Examples for Future Releases

**Current version:** `1.0.0+1`

**For next TestFlight build (same version, just testing):**
```yaml
version: 1.0.0+2  # Same version name, increment build number
```

**For bug fix release:**
```yaml
version: 1.0.1+3  # Increment patch version, increment build number
```

**For new feature release:**
```yaml
version: 1.1.0+4  # Increment minor version, increment build number
```

**For major update:**
```yaml
version: 2.0.0+5  # Increment major version, increment build number
```

**For multiple TestFlight builds before release:**
```yaml
# Build 1 for testing
version: 1.0.0+2

# Build 2 for testing (after fixes)
version: 1.0.0+3

# Final release
version: 1.0.1+4  # Update version name for release
```

### Step-by-Step for Future Archives

1. **Update version in `pubspec.yaml`:**
   ```yaml
   version: 1.0.1+2  # Always increment build number (+2, +3, +4, etc.)
   ```

2. **Clean and rebuild:**
   ```bash
   flutter clean
   flutter pub get
   flutter build ios --release
   ```

3. **Archive in Xcode:**
   - Open `ios/Runner.xcworkspace`
   - Product → Archive
   - Distribute App → App Store Connect → Upload

4. **Update App Store Connect:**
   - Add release notes in "What's New" section
   - Submit for review (or add to TestFlight)

### Important Rules

- ✅ **Build number must always increase** (1 → 2 → 3 → 4...)
- ✅ **Build numbers are unique** - can't reuse a number
- ✅ **Version name can stay the same** for multiple TestFlight builds
- ✅ **Version name should change** when releasing to users
- ❌ **Never decrease build number** - Apple will reject it
- ❌ **Never reuse build number** - even if you delete a build

### Quick Reference

| Scenario | Version Name | Build Number | Example |
|----------|-------------|--------------|---------|
| First upload | 1.0.0 | 1 | `1.0.0+1` |
| TestFlight test | 1.0.0 | 2 | `1.0.0+2` |
| Bug fix release | 1.0.1 | 3 | `1.0.1+3` |
| New feature | 1.1.0 | 4 | `1.1.0+4` |
| Major update | 2.0.0 | 5 | `2.0.0+5` |

---

## Useful Links

- [Apple Developer Portal](https://developer.apple.com/account)
- [App Store Connect](https://appstoreconnect.apple.com)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)
- [Xcode Documentation](https://developer.apple.com/documentation/xcode)

---

## Checklist

Before submitting, verify:

- [ ] Version and build number updated in `pubspec.yaml`
- [ ] Bundle ID configured correctly in Xcode
- [ ] App ID created in Apple Developer Portal
- [ ] Provisioning profile configured (automatic or manual)
- [ ] App created in App Store Connect
- [ ] App information completed (privacy, age rating, etc.)
- [ ] Build archived and uploaded successfully
- [ ] Build processed and ready in App Store Connect
- [ ] Screenshots uploaded for all required device sizes
- [ ] App description, keywords, and support URL filled
- [ ] Build selected in version information
- [ ] All warnings resolved
- [ ] Ready to submit for review

---

## Notes

- **Processing Time**: Builds typically take 10-30 minutes to process after upload
- **Review Time**: Initial review usually takes 1-3 business days
- **Rejections**: Common reasons include missing privacy information, incomplete metadata, or guideline violations
- **Updates**: You can update app information without uploading a new build
- **TestFlight**: Use TestFlight to test builds before public release

Good luck with your App Store submission! 🚀
