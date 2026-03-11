# OneSignal Push Notifications Setup Guide

This guide will help you set up OneSignal push notifications for your Flutter app.

## Prerequisites

1. A OneSignal account (sign up at https://onesignal.com)
2. Your Flutter app configured with Android and iOS platforms

## Step 1: Create OneSignal App

1. Go to https://onesignal.com and sign in (or create an account)
2. Click "New App/Website"
3. Select "Google Android (FCM)" and "Apple iOS (APNs)" as platforms
4. Fill in your app details:
   - **App Name**: Sampul (or your preferred name)
   - **Platform**: Select both Android and iOS
5. Click "Create App"

## Step 2: Configure Android (FCM)

### 2.1 Get Firebase Cloud Messaging (FCM) Server Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (or create a new one)
3. Go to Project Settings (gear icon) > Cloud Messaging
4. Copy the **Server key** (not the Sender ID)

### 2.2 Add FCM to OneSignal

1. In OneSignal dashboard, go to your app settings
2. Navigate to **Settings > Platforms > Google Android (FCM)**
3. Paste your FCM Server Key
4. Click "Save"

### 2.3 Get OneSignal App ID

1. In OneSignal dashboard, go to **Settings > Keys & IDs**
2. Copy your **OneSignal App ID** (it looks like: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)

## Step 3: Configure iOS (APNs)

### 3.1 Generate APNs Auth Key

1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to **Certificates, Identifiers & Profiles > Keys**
3. Click the "+" button to create a new key
4. Enter a name (e.g., "OneSignal Push Key")
5. Check **Apple Push Notifications service (APNs)**
6. Click "Continue"

#### 3.1.1 Configure Key Settings

On the "Configure Key" page, you'll need to set the following:

**Environment Selection:**
- **Recommended**: Select **"Production"** for production apps
- **Alternative**: Select **"Sandbox & Production"** if you need to test with both sandbox and production environments
- **Note**: The environment setting cannot be changed after saving, so choose carefully

**Key Restriction:**
- **Recommended**: Select **"Team Scoped (All Topics)"** - This allows the key to work with all your app's push notification topics
- This setting also cannot be changed after saving

**Important Warnings:**
- ⚠️ The APNs configuration for accessible environment and key restriction type **cannot be changed once saved**
- Make sure you select the correct environment before proceeding
- For production apps, "Production" is the standard choice

7. Click **"Save"** to register the key
8. Download the `.p8` file (you can only download it once - save it securely!)
9. Note the **Key ID** shown on the page (you'll need this for OneSignal)

### 3.2 Add APNs to OneSignal

1. In OneSignal dashboard, go to **Settings > Platforms > Apple iOS (APNs)**
2. Select **APNs Auth Key** method
3. Upload your `.p8` file
4. Enter your **Key ID**
5. Enter your **Team ID** (found in Apple Developer Portal > Membership)
6. Select your **Bundle ID** (must match your iOS app's bundle ID)
7. Click "Save"

### 3.3 Enable Push Notifications in Xcode

1. Open your project in Xcode: `ios/Runner.xcworkspace`
2. Select the **Runner** target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability**
5. Add **Push Notifications**
6. Add **Background Modes** and check **Remote notifications**

## Step 4: Configure Your App

### 4.1 Add OneSignal App ID to Environment

1. Copy `.env.example` to `.env` if you haven't already:
   ```bash
   cp ENV.example .env
   ```

2. Open `.env` and add your OneSignal App ID:
   ```
   ONESIGNAL_APP_ID=your-onesignal-app-id-here
   ```

### 4.2 Install Dependencies

Run the following command to install the OneSignal Flutter SDK:

```bash
flutter pub get
```

## Step 5: Test Notifications

### 5.1 Build and Run Your App

```bash
# For Android
flutter run

# For iOS
flutter run
```

### 5.2 Send a Test Notification

1. In OneSignal dashboard, go to **Messages > New Push**
2. Compose your message
3. Under **Send To**, select **Test Users**
4. Enter your device's player ID (check app logs for "OneSignal: Player ID: ...")
5. Click **Send Message**

Alternatively, you can send to all users or use segments.

## Step 6: Verify Integration

### Check App Logs

When you run your app, you should see logs like:
```
OneSignal: Initialized successfully
OneSignal: Player ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

### Verify Player ID Storage

The app automatically stores the player ID in your Supabase `accounts` table in the `onesignal_player_id` column when a user logs in. The player ID is linked to the user via the `uuid` field in the accounts table.

## Troubleshooting

### Android Issues

1. **Notifications not received on Android:**
   - Verify FCM Server Key is correctly added in OneSignal
   - Check that your app has notification permissions (Android 13+)
   - Verify internet permission is in AndroidManifest.xml (already added)

2. **Build errors:**
   - Run `flutter clean` and `flutter pub get`
   - Make sure your `minSdkVersion` is at least 21 (OneSignal requirement)

### iOS Issues

1. **Notifications not received on iOS:**
   - Verify APNs Auth Key is correctly uploaded in OneSignal
   - Check that Push Notifications capability is enabled in Xcode
   - Ensure your Bundle ID matches in OneSignal and Xcode
   - Test on a real device (push notifications don't work on iOS simulator)

2. **Build errors:**
   - Run `flutter clean` and `flutter pub get`
   - Make sure you're using a real iOS device (not simulator) for testing

### General Issues

1. **OneSignal not initializing:**
   - Check that `ONESIGNAL_APP_ID` is set in your `.env` file
   - Verify the App ID is correct (no extra spaces or quotes)
   - Check app logs for error messages

2. **Player ID not stored:**
   - Verify user is logged in (OneSignal stores player ID after login)
   - Check Supabase connection
   - Verify `accounts` table has `onesignal_player_id` column
   - Ensure user has an account record (OneSignal uses upsert, so it will create if needed)

## Database Schema

Make sure your `accounts` table in Supabase has a column for storing the OneSignal player ID:

```sql
ALTER TABLE accounts 
ADD COLUMN IF NOT EXISTS onesignal_player_id TEXT;
```

The player ID is stored in the `accounts` table, which is linked to users via the `uuid` field. The service uses `upsert` to handle cases where an account record doesn't exist yet.

## Advanced Features

### User Segmentation

You can set user tags for segmentation:

```dart
await OneSignalService.instance.setTags({
  'subscription_type': 'premium',
  'language': 'en',
  'user_type': 'executor'
});
```

### Targeted Notifications

In OneSignal dashboard, you can send notifications to:
- Specific users (by player ID or user ID)
- User segments (based on tags)
- All users

### Notification Handling

The app automatically handles notification clicks. You can customize the behavior in `lib/services/onesignal_service.dart` in the `_handleNotificationData` method.

## Additional Resources

- [OneSignal Flutter SDK Documentation](https://documentation.onesignal.com/docs/flutter-sdk-setup)
- [OneSignal Dashboard](https://app.onesignal.com/)
- [Firebase Console](https://console.firebase.google.com/)
- [Apple Developer Portal](https://developer.apple.com/account/)

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review OneSignal documentation
3. Check app logs for error messages
4. Verify all configuration steps are completed
