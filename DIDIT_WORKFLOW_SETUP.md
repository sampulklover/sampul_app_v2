# Didit Verification - Updated Configuration (Based on Official API Docs)

## 🎯 Key Finding from Documentation

According to the [Didit Create Session API documentation](https://docs.didit.me/reference/create-session-verification-sessions), the API requires:

### Required Parameters:
- **`workflow_id`** (string, required) - The verification workflow to use from your Didit Console
- **Header: `x-api-key`** (string, required) - Your API key for authentication

### Optional Parameters:
- **`vendor_data`** (string, optional) - A unique identifier for the user/vendor (for session tracking)
- **`callback`** (string, optional) - URL to redirect user after verification completes

### API Response:
The response includes:
```json
{
  "session_id": "1111111-2222-3333-4444-5555555555555",
  "session_number": 1234,
  "session_token": "abcdef123456",
  "vendor_data": "user-123",
  "metadata": {
    "user_type": "premium",
    "account_id": "ABC123"
  },
  "status": "Not Started",
  "workflow_id": "1111111-2222-3333-4444-5555555555555",
  "callback": "https://example.com/verification/callback",
  "url": "https://verify.didit.me/session/abcdef123456"
}
```

The **`url`** field contains the verification link to show to the user.

## ✅ What's Been Updated

### 1. Added Workflow ID Support

**`lib/config/didit_config.dart`:**
```dart
/// Didit Workflow ID (required for creating verification sessions)
/// Get this from your Didit Console under Workflows
static String get workflowId => dotenv.env['DIDIT_WORKFLOW_ID'] ?? 
                                dotenv.env['NEXT_PUBLIC_DIDIT_WORKFLOW_ID'] ?? '';

/// Check if Didit is properly configured
/// Requires both API key and workflow ID
static bool get isConfigured => apiKey.isNotEmpty && workflowId.isNotEmpty;
```

### 2. Updated API Request Body

**`lib/services/verification_service.dart`:**
```dart
// Build request body for Didit v2 API
// Per documentation: https://docs.didit.me/reference/create-session-verification-sessions
// Required: workflow_id
// Optional: vendor_data (unique identifier for vendor/user)
// Optional: callback (redirect URL)
final Map<String, dynamic> requestBody = {
  'workflow_id': DiditConfig.workflowId,
  'vendor_data': sessionId, // Use our session ID as vendor_data for tracking
  'callback': DiditConfig.redirectUrl,
};
```

### 3. Updated `.ENV.example`

```env
# Didit Verification Configuration (matches website format)
# Get your API key and Workflow ID from https://console.didit.me
# Note: DIDIT_CLIENT_ID is your API key (used in x-api-key header)
# DIDIT_WORKFLOW_ID is required - get it from Workflows page in Didit Console
DIDIT_URL=https://apx.didit.me
DIDIT_VERIFICATION_URL=https://verification.didit.me
DIDIT_CLIENT_ID=your_api_key_here
DIDIT_WORKFLOW_ID=your_workflow_id_here
DIDIT_CLIENT_SECRET=
DIDIT_WEBHOOK_SECRET_KEY=
DIDIT_REDIRECT_URL=sampul://verification/complete
```

## 🔧 Configuration Steps

### Step 1: Get Your API Key

1. Go to [Didit Console](https://console.didit.me)
2. Navigate to **Settings** → **API Keys** (or similar)
3. Copy your API key (it should look like: `sFTia127939129312`)

### Step 2: Get Your Workflow ID

1. In Didit Console, go to **Workflows**
2. Either create a new workflow or use an existing one
3. Copy the **workflow_id** (it should look like a UUID: `1111111-2222-3333-4444-5555555555555`)

The workflow determines what verification steps the user goes through (e.g., ID verification, liveness check, face match, etc.)

### Step 3: Update Your `.env` File

```env
DIDIT_CLIENT_ID=sFTia127939129312              # Your API key
DIDIT_WORKFLOW_ID=1111111-2222-3333-4444-555555  # Your workflow ID
DIDIT_VERIFICATION_URL=https://verification.didit.me
DIDIT_REDIRECT_URL=sampul://verification/complete
```

### Step 4: Restart the App

```bash
# Hot reload won't work for .env changes
# Stop the app and run again:
flutter run
```

## 🧪 Testing

1. **Click "Identity Verification"** in the app settings
2. **Check console logs**

### Expected Success Output:

```
flutter: 🟡 [DIDIT API] Creating verification session...
flutter: 🟡 [DIDIT API] Using endpoint: https://verification.didit.me/v2/session/
flutter: 🟡 [DIDIT API] API Key: sFTia...
flutter: 🟡 [DIDIT API] Workflow ID: 1111111-2222-3333-4444-555555
flutter: 🟡 [DIDIT API] Request body: {
  workflow_id: 1111111-2222-3333-4444-555555,
  vendor_data: didit_1767426285721_285721,
  callback: sampul://verification/complete
}
flutter: 🟡 [DIDIT API] Response status: 201
flutter: 🟢 [DIDIT API] Success!
flutter: 🟢 [DIDIT API] Got session URL: https://verify.didit.me/session/abcdef123456
```

### If You Get Error:

#### 403 Forbidden:
```json
{"detail":"You do not have permission to perform this action."}
```
**Solution:** 
- Check your API key is correct
- Make sure the API key has the right permissions in Didit Console

#### 400 Bad Request:
```json
{"workflow_id":["This field is required."]}
```
**Solution:**
- You're missing `DIDIT_WORKFLOW_ID` in your `.env` file
- Go to Didit Console → Workflows to get your workflow ID

#### 404 Not Found:
```json
{"detail":"Not found."}
```
**Solution:**
- The workflow ID doesn't exist
- Check if the workflow is active in Didit Console

## 📱 Complete Verification Flow

1. ✅ User clicks "Identity Verification" 
2. ✅ App creates session with Didit API (sends `workflow_id`, `vendor_data`, `callback`)
3. ✅ Didit returns session URL
4. ✅ App opens session URL in external browser
5. 👤 User completes verification on Didit's website
6. ✅ Didit redirects to `sampul://verification/complete`
7. ✅ App handles deep link
8. ✅ App updates verification status in database
9. ✅ Settings screen shows "Verified" badge

## 🔗 Webhook Configuration (Optional)

If you want real-time updates when verification status changes, configure webhooks:

1. Go to Didit Console → **Webhooks**
2. Add your webhook URL (e.g., `https://yourdomain.com/api/didit-webhook`)
3. Copy the **Webhook Secret Key**
4. Add to `.env`:
   ```env
   DIDIT_WEBHOOK_SECRET_KEY=your_webhook_secret
   ```
5. Implement webhook handler in your backend to validate and process events

## 📚 References

- [Didit Create Session API](https://docs.didit.me/reference/create-session-verification-sessions)
- [Didit Workflows Documentation](https://docs.didit.me/reference/workflows)
- [Didit iOS & Android Integration](https://docs.didit.me/reference/ios-android)
- [Didit API Authentication](https://docs.didit.me/reference/api-authentication)

## ✅ Final Checklist

- [ ] Got API key from Didit Console
- [ ] Created/selected a workflow in Didit Console
- [ ] Got workflow ID from Didit Console
- [ ] Updated `.env` with `DIDIT_CLIENT_ID` (API key)
- [ ] Updated `.env` with `DIDIT_WORKFLOW_ID`
- [ ] Restarted the app (not just hot reload)
- [ ] Clicked "Identity Verification" button
- [ ] Checked console for success (status 201)
- [ ] Verified session URL is generated
- [ ] Tested opening the verification URL
- [ ] Confirmed deep link redirect works

---

**Last Updated**: January 2025, based on Didit API v2 documentation

