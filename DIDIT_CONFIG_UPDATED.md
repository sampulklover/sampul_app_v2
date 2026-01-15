# Didit Configuration Updated

The Didit configuration has been updated to match your website's format. Now both your website and Flutter app use the same environment variable names.

## Updated Environment Variables

Your `.env` file should now use these variables (same as your website):

```env
# Didit Verification Configuration
DIDIT_URL=https://apx.didit.me
DIDIT_VERIFICATION_URL=https://verification.didit.me
DIDIT_CLIENT_ID=sF67127939129312
DIDIT_CLIENT_SECRET=5P6jMWqu-ID_P7nWsdaihbchasbdcasdc
DIDIT_WEBHOOK_SECRET_KEY=
DIDIT_REDIRECT_URL=https://sampul.co/verification-complete
```

**Note:** The Flutter app also supports the `NEXT_PUBLIC_` prefix format for compatibility:
- `NEXT_PUBLIC_DIDIT_URL` → `DIDIT_URL`
- `NEXT_PUBLIC_DIDIT_VERIFICATION_URL` → `DIDIT_VERIFICATION_URL`
- `NEXT_PUBLIC_DIDIT_CLIENT_ID` → `DIDIT_CLIENT_ID`

## What Changed

### Before (Old Format)
- Used `DIDIT_API_KEY` and `DIDIT_API_SECRET`
- Required `DIDIT_WORKFLOW_ID`
- Used Bearer token authentication

### After (New Format - Matches Website)
- Uses `DIDIT_CLIENT_ID` and `DIDIT_CLIENT_SECRET`
- No workflow ID required (handled by Didit)
- Uses Client ID/Secret authentication (OAuth-style)
- Supports both header-based and Basic Auth authentication

## Configuration Details

### Authentication Methods

The app now tries two authentication methods:

1. **Header-based** (Primary):
   ```
   X-Client-Id: {clientId}
   X-Client-Secret: {clientSecret}
   ```

2. **Basic Auth** (Fallback):
   ```
   Authorization: Basic {base64(clientId:clientSecret)}
   ```

### API Endpoints

- **API Base URL**: `DIDIT_URL` (default: `https://apx.didit.me`)
- **Verification URL**: `DIDIT_VERIFICATION_URL` (default: `https://verification.didit.me`)

## Quick Setup

1. **Copy your website's Didit credentials** to your Flutter app's `.env` file:
   ```env
   DIDIT_URL=https://apx.didit.me
   DIDIT_VERIFICATION_URL=https://verification.didit.me
   DIDIT_CLIENT_ID=sF67127939129312
   DIDIT_CLIENT_SECRET=5P6jMWqu-ID_P7nWsdaihbchasbdcasdc
   DIDIT_WEBHOOK_SECRET_KEY=
   DIDIT_REDIRECT_URL=https://sampul.co/verification-complete
   ```

2. **Restart your app** to load the new environment variables

3. **Test it:**
   - Go to Settings → Identity Verification
   - Tap to start verification
   - Should work with your existing Didit account!

## Benefits

✅ **Consistent Configuration**: Same env vars as your website  
✅ **No Workflow ID Needed**: Simplified setup  
✅ **Multiple Auth Methods**: Tries different auth formats automatically  
✅ **Easy Migration**: Just copy your website's credentials  

## Testing

You can verify your configuration is working:

```dart
import 'package:sampul_app_v2/services/verification_service.dart';
import 'package:sampul_app_v2/config/didit_config.dart';

// Check configuration
print('Is configured: ${DiditConfig.isConfigured}');
print('Client ID: ${DiditConfig.clientId}');
print('API URL: ${DiditConfig.apiBaseUrl}');

// Get detailed status
final status = VerificationService.instance.getConfigurationStatus();
print('Config status: $status');
```

## Troubleshooting

### "Didit is not properly configured"
- ✅ Make sure `DIDIT_CLIENT_ID` and `DIDIT_CLIENT_SECRET` are set
- ✅ Check for typos in variable names
- ✅ Restart app after updating `.env`

### Authentication errors
- The app automatically tries both auth methods
- Check that your Client ID and Secret are correct
- Verify they match your website's credentials

### API errors
- Verify `DIDIT_URL` matches your website's `NEXT_PUBLIC_DIDIT_URL`
- Check that `DIDIT_VERIFICATION_URL` is correct
- Ensure your Didit account is active

## Files Updated

- ✅ `lib/config/didit_config.dart` - Updated to use Client ID/Secret
- ✅ `lib/services/verification_service.dart` - Updated API calls
- ✅ `ENV.example` - Updated with new variable names
- ✅ Settings screen - Already compatible (no changes needed)

## Next Steps

1. Add your Didit credentials to `.env`
2. Test the verification flow
3. Set up webhooks if needed (using `DIDIT_WEBHOOK_SECRET_KEY`)

That's it! Your Flutter app now uses the same Didit configuration as your website. 🎉

