# Didit Integration - Quick Reference

## 📋 What You Need

From [Didit Console](https://console.didit.me):

1. **API Key** (looks like: `sFTia127939129312`)
   - Found in: Settings → API Keys

2. **Workflow ID** (looks like: `1111111-2222-3333-4444-555555`)
   - Found in: Workflows → Select/Create Workflow

## ⚙️ Configuration

Add to your `.env` file:

```env
DIDIT_CLIENT_ID=sFTia127939129312                    # Your API key
DIDIT_WORKFLOW_ID=1111111-2222-3333-4444-555555      # Your workflow ID
DIDIT_VERIFICATION_URL=https://verification.didit.me
DIDIT_REDIRECT_URL=sampul://verification/complete
```

## 🔑 Key Changes Made

### API Request Format (Per Didit Docs):

**Before (Incorrect):**
```json
{
  "redirect_url": "sampul://verification/complete",
  "email": "user@example.com",
  "name": "User Name"
}
```

**After (Correct):**
```json
{
  "workflow_id": "1111111-2222-3333-4444-555555",
  "vendor_data": "didit_1767426285721_285721",
  "callback": "sampul://verification/complete"
}
```

### Header (Unchanged):
```
x-api-key: YOUR_API_KEY
```

### Endpoint (Unchanged):
```
POST https://verification.didit.me/v2/session/
```

## 🧪 Test

1. Update `.env` with API key and workflow ID
2. Restart app: `flutter run`
3. Click "Identity Verification" in settings
4. Check console for:

```
flutter: 🟢 [DIDIT API] Success!
flutter: 🟢 [DIDIT API] Got session URL: https://verify.didit.me/session/...
```

## 🐛 Troubleshooting

| Error | Cause | Solution |
|-------|-------|----------|
| `403 Forbidden` | Invalid API key | Check API key in Didit Console |
| `400 Bad Request: workflow_id required` | Missing workflow ID | Add `DIDIT_WORKFLOW_ID` to `.env` |
| `404 Not Found` | Invalid workflow ID | Check workflow exists in Didit Console |
| `is_configured: false` | Missing config | Need both API key AND workflow ID |

## 📚 Detailed Documentation

- `DIDIT_WORKFLOW_SETUP.md` - Complete setup guide
- `DIDIT_API_KEY_FIX.md` - Authentication details
- `DIDIT_NEXT_STEPS.md` - Testing guide

## 🔗 API Reference

[Didit Create Session API](https://docs.didit.me/reference/create-session-verification-sessions)

