# Google Sign-In Setup Guide

This guide will help you configure Google Sign-In to work with Supabase in your Flutter app.

## 🔧 Step 1: Google Cloud Console Setup

### 1.1 Create/Select Project
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Note your **Project ID**

### 1.2 Enable Google+ API
1. Go to **APIs & Services** → **Library**
2. Search for "Google+ API" and enable it
3. Also enable "Google Sign-In API" if available

### 1.3 Create OAuth 2.0 Credentials
1. Go to **APIs & Services** → **Credentials**
2. Click **Create Credentials** → **OAuth 2.0 Client IDs**
3. Choose **Web application** for the first credential
4. Add these **Authorized redirect URIs**:
   ```
   https://rfzblaianldrfwdqdijl.supabase.co/auth/v1/callback
   ```
5. Click **Create** and note the **Client ID** and **Client Secret**

### 1.4 Create Android OAuth Client
1. Click **Create Credentials** → **OAuth 2.0 Client IDs** again
2. Choose **Android**
3. **Package name**: `com.example.sampul_app_v2` (or your actual package name)
4. **SHA-1 certificate fingerprint**: Get this by running:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
5. Click **Create** and note the **Client ID**

### 1.5 Create iOS OAuth Client
1. Click **Create Credentials** → **OAuth 2.0 Client IDs** again
2. Choose **iOS**
3. **Bundle ID**: `com.example.sampulAppV2` (or your actual bundle ID)
4. Click **Create** and note the **Client ID**

## 🔧 Step 2: Supabase Configuration

### 2.1 Configure Google Provider
1. Go to your [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project: `rfzblaianldrfwdqdijl`
3. Go to **Authentication** → **Providers**
4. Find **Google** and click **Configure**
5. Enable Google provider
6. Enter your **Client ID** and **Client Secret** from Step 1.3
7. Click **Save**

### 2.2 Configure Redirect URLs
1. In Supabase Dashboard, go to **Authentication** → **URL Configuration**
2. Add your app's redirect URLs:
   ```
   com.example.sampul_app_v2://login-callback/
   com.example.sampulAppV2://login-callback/
   ```

## 🔧 Step 3: Flutter App Configuration

### 3.1 Android Configuration
The Android configuration is already set up in your project. The `google_sign_in` plugin will automatically use the SHA-1 fingerprint.

### 3.2 iOS Configuration
Add the following to your `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>REVERSED_CLIENT_ID</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

Replace `YOUR_REVERSED_CLIENT_ID` with your iOS OAuth client ID from Step 1.5.

## 🔧 Step 4: Test the Integration

1. **Run your app**
2. **Tap "Continue with Google"**
3. **Complete the Google Sign-In flow**
4. **Verify you're redirected to the main app**

## 🐛 Troubleshooting

### Common Issues:

1. **"Sign in failed: Google authentication failed"**
   - Check that Google OAuth is properly configured in Supabase
   - Verify Client ID and Client Secret are correct

2. **"Sign in failed: Invalid client"**
   - Check that the SHA-1 fingerprint matches your debug keystore
   - Verify the package name matches your Android app

3. **iOS redirect issues**
   - Ensure the URL scheme is properly configured in Info.plist
   - Check that the bundle ID matches your iOS OAuth client

4. **"User cancelled"**
   - This is normal if the user cancels the Google Sign-In flow
   - The app should handle this gracefully

## 📱 Current Status

Your Flutter app is already configured with:
- ✅ Google Sign-In plugin
- ✅ Supabase integration
- ✅ Authentication flow
- ✅ Error handling

You just need to complete the Google Cloud Console and Supabase configuration steps above.

## 🎯 Next Steps

1. Complete the Google Cloud Console setup
2. Configure Supabase with your Google OAuth credentials
3. Test the Google Sign-In flow
4. Deploy and test on both iOS and Android devices

Once configured, your users will be able to sign in with their Google accounts seamlessly! 🚀
