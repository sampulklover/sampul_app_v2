# Fix 401 Unauthorized for CHIP Payment Redirect

## Problem

When CHIP redirects to the payment redirect URL, you see:
```json
{"code":401,"message":"Missing authorization header"}
```

This happens because the redirect function requires JWT authentication, but browsers (after CHIP redirects) don't have Supabase JWT tokens.

## Solution

The `chip-payment-redirect` function must be **public** (no JWT verification) because it's accessed from a browser.

### Method 1: Deploy with `--no-verify-jwt` Flag (Recommended)

Redeploy the function with the `--no-verify-jwt` flag:

```bash
supabase functions deploy chip-payment-redirect --project-ref rfzblaianldrfwdqdijl --no-verify-jwt
```

Replace `rfzblaianldrfwdqdijl` with your actual project ref.

### Method 2: Disable JWT in Dashboard

If you already deployed, you can disable JWT verification in the dashboard:

1. Go to **Supabase Dashboard**
2. Navigate to **Edge Functions** → **chip-payment-redirect**
3. Click on **Details** tab
4. Find **"Verify JWT"** setting
5. **Turn it OFF** (uncheck it)
6. **Save** the changes

### Verify It's Fixed

After deploying or disabling JWT:

1. **Test the redirect URL directly in a browser**:
   ```
   https://rfzblaianldrfwdqdijl.supabase.co/functions/v1/chip-payment-redirect?status=success
   ```

2. **You should see**:
   - A loading page with "Redirecting to app..."
   - The page should redirect to `sampul://trust?payment=success`
   - **No 401 error**

3. **Check the logs** in Supabase Dashboard → Edge Functions → chip-payment-redirect → Logs
   - You should see function execution logs
   - If you see NO logs, JWT verification is still enabled

## Why This Happens

- **Redirect function is accessed from browser** - After CHIP payment, the browser redirects to the function URL
- **Browsers don't have JWT tokens** - Only authenticated Supabase requests have JWT tokens
- **Solution** - Make the redirect function public (no JWT verification required)

## Security Note

✅ **Safe to disable JWT** for redirect functions because:
- They only serve static HTML pages
- They don't access sensitive data
- They just redirect to deep links
- No authentication needed for public redirect pages

## Related Functions

These functions should also be deployed with `--no-verify-jwt`:
- ✅ `chip-webhook` - Receives webhooks from CHIP (external service)
- ✅ `chip-payment-redirect` - Serves redirect pages (public access)

These functions require JWT (keep JWT enabled):
- ✅ `chip-create-client` - Creates CHIP customer (user must be authenticated)
- ✅ `chip-create-payment` - Creates payment session (user must be authenticated)

## Deep Link Not Opening App?

If the redirect page loads but the app doesn't open:

### iOS Safari
- **iOS Safari blocks automatic deep link redirects** for security
- **Solution**: User must **tap the "Open Sampul App" button** on the redirect page
- This is a security feature of iOS - automatic redirects are blocked

### Android
- Android Chrome may auto-redirect, but the button ensures it works
- If auto-redirect doesn't work, user should tap the button

### Verify Deep Link Configuration

Make sure deep links are configured in your app:

**iOS (`ios/Runner/Info.plist`):**
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>sampul</string>
    </array>
  </dict>
</array>
```

**Android (`android/app/src/main/AndroidManifest.xml`):**
```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <category android:name="android.intent.category.BROWSABLE"/>
  <data android:scheme="sampul"/>
</intent-filter>
```

### How It Works

1. CHIP redirects to redirect function URL
2. Redirect function serves HTML page with prominent button
3. **User taps "Open Sampul App" button** (required on iOS)
4. Deep link opens app: `sampul://trust?payment=success`
5. App detects resume and checks payment status
6. App shows payment status modal
