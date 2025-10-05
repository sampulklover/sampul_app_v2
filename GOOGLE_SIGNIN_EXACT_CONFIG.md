# Google Sign-In Exact Configuration for Your App

## 📱 Your App Details
- **Android Package Name**: `com.example.sampul_app_v2`
- **iOS Bundle ID**: `com.example.sampulAppV2`
- **Supabase Project URL**: `https://rfzblaianldrfwdqdijl.supabase.co`

## 🔧 Step 1: Google Cloud Console Setup

### 1.1 Create OAuth 2.0 Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Go to **APIs & Services** → **Credentials**
4. Click **Create Credentials** → **OAuth 2.0 Client IDs**

### 1.2 Web Application (for Supabase)
1. Choose **Web application**
2. **Name**: `Sampul App Web`
3. **Authorized redirect URIs**:
   ```
   https://rfzblaianldrfwdqdijl.supabase.co/auth/v1/callback
   ```
4. Click **Create**
5. **Copy the Client ID and Client Secret** - you'll need these for Supabase

### 1.3 Android Application
1. Click **Create Credentials** → **OAuth 2.0 Client IDs** again
2. Choose **Android**
3. **Name**: `Sampul App Android`
4. **Package name**: `com.example.sampul_app_v2`
5. **SHA-1 certificate fingerprint**: Run this command to get it:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
6. Click **Create**
7. **Copy the Client ID**

### 1.4 iOS Application
1. Click **Create Credentials** → **OAuth 2.0 Client IDs** again
2. Choose **iOS**
3. **Name**: `Sampul App iOS`
4. **Bundle ID**: `com.example.sampulAppV2`
5. Click **Create**
6. **Copy the Client ID** (this will be your REVERSED_CLIENT_ID)

## 🔧 Step 2: Supabase Configuration

### 2.1 Configure Google Provider
1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project: `rfzblaianldrfwdqdijl`
3. Go to **Authentication** → **Providers**
4. Find **Google** and click **Configure**
5. **Enable Google provider**: Toggle ON
6. **Client ID**: Paste your Web Application Client ID from Step 1.2
7. **Client Secret**: Paste your Web Application Client Secret from Step 1.2
8. Click **Save**

### 2.2 Configure Redirect URLs
1. In Supabase Dashboard, go to **Authentication** → **URL Configuration**
2. **Site URL**: `https://rfzblaianldrfwdqdijl.supabase.co`
3. **Redirect URLs**: Add these:
   ```
   com.example.sampul_app_v2://login-callback/
   com.example.sampulAppV2://login-callback/
   ```

## 🔧 Step 3: Update iOS Configuration

After getting your iOS Client ID from Step 1.4, update your `ios/Runner/Info.plist`:

1. Replace `YOUR_REVERSED_CLIENT_ID` with your iOS Client ID
2. The iOS Client ID should look like: `123456789-abcdefghijklmnop.apps.googleusercontent.com`

Example:
```xml
<string>123456789-abcdefghijklmnop.apps.googleusercontent.com</string>
```

## 🔧 Step 4: Get SHA-1 Fingerprint

Run this command in your terminal to get the SHA-1 fingerprint for Android:

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Look for the line that says:
```
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

Copy this SHA-1 fingerprint and use it in Step 1.3.

## 🧪 Step 5: Test the Integration

1. **Run your app**: `flutter run`
2. **Tap "Continue with Google"**
3. **Complete the Google Sign-In flow**
4. **Verify you're redirected to the main app**

## 🐛 Troubleshooting

### If Google Sign-In fails:

1. **Check Supabase logs**:
   - Go to Supabase Dashboard → **Logs** → **Auth**
   - Look for any error messages

2. **Verify SHA-1 fingerprint**:
   - Make sure the SHA-1 in Google Cloud Console matches your debug keystore
   - For release builds, you'll need the release keystore SHA-1

3. **Check package names**:
   - Android: `com.example.sampul_app_v2`
   - iOS: `com.example.sampulAppV2`

4. **Verify redirect URLs**:
   - Make sure they're exactly as specified above

## 📋 Checklist

- [ ] Google Cloud Console project created
- [ ] Web OAuth client created with Supabase callback URL
- [ ] Android OAuth client created with correct package name and SHA-1
- [ ] iOS OAuth client created with correct bundle ID
- [ ] Supabase Google provider configured with Client ID and Secret
- [ ] Supabase redirect URLs configured
- [ ] iOS Info.plist updated with REVERSED_CLIENT_ID
- [ ] App tested with Google Sign-In

## 🎯 Current Status

Your Flutter app is ready for Google Sign-In! You just need to:
1. Complete the Google Cloud Console setup
2. Configure Supabase with your OAuth credentials
3. Update the iOS Info.plist with your Client ID
4. Test the integration

Once configured, your users will be able to sign in with Google seamlessly! 🚀
