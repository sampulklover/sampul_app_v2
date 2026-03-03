# Google Sign-In Setup Guide for Supabase

Complete step-by-step guide to configure Google Sign-In with Supabase authentication in your Flutter app.

## 📱 Your App Configuration

- **Android Package Name**: `com.example.sampul_app_v2`
- **iOS Bundle ID**: `com.sampul.app`
- **Supabase Project URL**: `https://rfzblaianldrfwdqdijl.supabase.co`
- **Supabase Project Reference**: `rfzblaianldrfwdqdijl`

---

## 🔧 Step 1: Google Cloud Console Setup

### 1.1 Create or Select Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Note your **Project ID** (you'll need it later)

### 1.2 Enable Required APIs

1. Go to **APIs & Services** → **Library**
2. Search for and enable:
   - **Google Sign-In API** (required)
   - **Google Identity Services API** (recommended)

> **Note**: Google+ API is deprecated and not needed for modern Google Sign-In.

### 1.3 Configure OAuth Consent Screen

1. Go to **APIs & Services** → **OAuth consent screen**
2. Choose **External** (unless you have a Google Workspace)
3. Fill in required information:
   - **App name**: Sampul (or your app name)
   - **User support email**: Your email
   - **Developer contact information**: Your email
4. Click **Save and Continue**
5. Add scopes (if needed):
   - `email`
   - `profile`
   - `openid`
6. Click **Save and Continue**
7. Add test users (optional for development)
8. Review and submit

### 1.4 Create OAuth 2.0 Credentials

You need to create **three** OAuth clients: Web (for Supabase), Android, and iOS.

#### 1.4.1 Web Application (for Supabase)

1. Go to **APIs & Services** → **Credentials**
2. Click **Create Credentials** → **OAuth 2.0 Client ID**
3. Choose **Web application**
4. **Name**: `Sampul App Web`
5. **Authorized redirect URIs**: Add this exact URL:
   ```
   https://rfzblaianldrfwdqdijl.supabase.co/auth/v1/callback
   ```
6. Click **Create**
7. **⚠️ IMPORTANT**: Copy and save:
   - **Client ID** (you'll need this for Supabase)
   - **Client Secret** (you'll need this for Supabase)

#### 1.4.2 Android Application

1. Click **Create Credentials** → **OAuth 2.0 Client ID** again
2. Choose **Android**
3. **Name**: `Sampul App Android`
4. **Package name**: `com.example.sampul_app_v2`
5. **SHA-1 certificate fingerprint**: 
   
   Get your SHA-1 fingerprint by running:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
   
   Or use the provided script:
   ```bash
   ./get_sha1.sh
   ```
   
   Look for the line that says `SHA1:` and copy the fingerprint (format: `XX:XX:XX:XX:...`)
   
   **Example**: `CD:D6:2F:C9:C2:D5:C3:5B:90:E7:F5:0C:43:8B:77:8E:67:F0:DB:75`
   
   > **Note**: For release builds, you'll need to add the SHA-1 from your release keystore as well.

6. Click **Create**
7. **Copy the Client ID** (save it, but you don't need to configure it in the app - it's automatic)

#### 1.4.3 iOS Application

1. Click **Create Credentials** → **OAuth 2.0 Client ID** again
2. Choose **iOS**
3. **Name**: `Sampul App iOS`
4. **Bundle ID**: `com.sampul.app`
5. Click **Create**
6. **Copy the Client ID** - this is your **REVERSED_CLIENT_ID** for iOS configuration

---

## 🔧 Step 2: Supabase Configuration

### 2.1 Configure Google Provider

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project: `rfzblaianldrfwdqdijl`
3. Navigate to **Authentication** → **Providers**
4. Find **Google** in the list and click **Configure**
5. **Enable Google provider**: Toggle the switch to **ON**
6. **Client ID (for OAuth)**: Paste your **Web Application Client ID** from Step 1.4.1
7. **Client Secret (for OAuth)**: Paste your **Web Application Client Secret** from Step 1.4.1
8. Click **Save**

### 2.2 Configure Redirect URLs

1. In Supabase Dashboard, go to **Authentication** → **URL Configuration**
2. **Site URL**: `https://rfzblaianldrfwdqdijl.supabase.co`
3. **Redirect URLs**: Add these exact URLs (one per line):
   ```
   com.example.sampul_app_v2://login-callback/
   com.sampul.app://login-callback/
   ```
4. Click **Save**

---

## 🔧 Step 3: iOS Configuration

### 3.1 Update Info.plist

1. Open `ios/Runner/Info.plist` in your project
2. Find the section with `YOUR_REVERSED_CLIENT_ID` (around line 32)
3. Replace `YOUR_REVERSED_CLIENT_ID` with your **iOS Client ID** from Step 1.4.3

**Example:**
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>REVERSED_CLIENT_ID</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>123456789-abcdefghijklmnop.apps.googleusercontent.com</string>
        </array>
    </dict>
    <!-- ... other URL schemes ... -->
</array>
```

> **Note**: The iOS Client ID from Google Cloud Console is already in reversed format, so use it directly.

---

## 🔧 Step 4: Android Configuration

Android configuration is **automatic**! The `google_sign_in` plugin will automatically use the SHA-1 fingerprint and package name you configured in Google Cloud Console.

**No additional configuration needed** in your Android project files.

---

## 🧪 Step 5: Testing

### 5.1 Test the Integration

1. **Run your app**:
   ```bash
   flutter run
   ```

2. **Test Google Sign-In**:
   - Tap the "Continue with Google" button
   - Complete the Google Sign-In flow
   - Verify you're redirected back to the app
   - Check that you're authenticated in the app

### 5.2 Verify Authentication

1. Check Supabase Dashboard → **Authentication** → **Users**
2. You should see your Google account listed as a user
3. The user should have `google` as the authentication provider

---

## 🐛 Troubleshooting

### Common Issues and Solutions

#### 1. "Sign in failed: Google authentication failed"

**Possible causes:**
- Google OAuth not properly configured in Supabase
- Incorrect Client ID or Client Secret in Supabase
- OAuth consent screen not configured

**Solutions:**
- Verify Client ID and Client Secret are correct in Supabase
- Check that Google provider is enabled in Supabase
- Ensure OAuth consent screen is configured in Google Cloud Console

#### 2. "Sign in failed: Invalid client" (Android)

**Possible causes:**
- SHA-1 fingerprint mismatch
- Package name mismatch
- OAuth client not created for Android

**Solutions:**
- Verify SHA-1 fingerprint matches your debug keystore
- Check package name is exactly `com.example.sampul_app_v2`
- Ensure Android OAuth client exists in Google Cloud Console
- For release builds, add release keystore SHA-1 to Google Cloud Console

#### 3. iOS redirect not working

**Possible causes:**
- REVERSED_CLIENT_ID not set in Info.plist
- Bundle ID mismatch
- URL scheme not configured correctly

**Solutions:**
- Verify Info.plist has the correct iOS Client ID
- Check bundle ID matches `com.sampul.app`
- Ensure URL scheme format is correct in Info.plist

#### 4. "User cancelled"

This is **normal** - it means the user cancelled the Google Sign-In flow. Your app should handle this gracefully (it already does).

#### 5. Check Supabase Logs

1. Go to Supabase Dashboard → **Logs** → **Auth**
2. Look for error messages related to Google Sign-In
3. Check for any authentication failures

#### 6. Verify Redirect URLs

- Ensure redirect URLs in Supabase match exactly:
  - `com.example.sampul_app_v2://login-callback/`
  - `com.sampul.app://login-callback/`
- No trailing slashes or typos

---

## 📋 Setup Checklist

Use this checklist to ensure everything is configured:

### Google Cloud Console
- [ ] Project created/selected
- [ ] Google Sign-In API enabled
- [ ] OAuth consent screen configured
- [ ] Web OAuth client created with Supabase callback URL
- [ ] Android OAuth client created with correct package name and SHA-1
- [ ] iOS OAuth client created with correct bundle ID
- [ ] All Client IDs and Secrets saved securely

### Supabase
- [ ] Google provider enabled
- [ ] Web Client ID configured in Supabase
- [ ] Web Client Secret configured in Supabase
- [ ] Redirect URLs configured (Android and iOS)

### iOS
- [ ] Info.plist updated with iOS Client ID (REVERSED_CLIENT_ID)

### Android
- [ ] SHA-1 fingerprint added to Google Cloud Console
- [ ] Package name matches in Google Cloud Console

### Testing
- [ ] App runs without errors
- [ ] Google Sign-In button works
- [ ] User can complete Google Sign-In flow
- [ ] User is authenticated in the app
- [ ] User appears in Supabase Users table

---

## 🎯 How It Works

Your app uses the following flow:

1. **User taps "Continue with Google"**
2. **Google Sign-In SDK** handles the OAuth flow
3. **Google returns** an ID token and access token
4. **App sends tokens** to Supabase via `signInWithIdToken()`
5. **Supabase validates** the tokens with Google
6. **Supabase creates/updates** the user in your database
7. **User is authenticated** and can use the app

This is the **modern, secure approach** recommended by both Google and Supabase.

---

## 📚 Additional Resources

- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
- [Google OAuth 2.0 Documentation](https://developers.google.com/identity/protocols/oauth2)

---

## ✅ Current Status

Your Flutter app is **already configured** with:
- ✅ Google Sign-In plugin (`google_sign_in: ^6.2.1`)
- ✅ Supabase integration (`supabase_flutter: ^2.8.0`)
- ✅ Authentication controller with Google Sign-In method
- ✅ Error handling and user management
- ✅ OneSignal integration after authentication

**You just need to complete the Google Cloud Console and Supabase configuration steps above!**

Once configured, your users will be able to sign in with their Google accounts seamlessly! 🚀
