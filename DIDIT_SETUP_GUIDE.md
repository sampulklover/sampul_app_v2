# Didit Verification Setup Guide

This is a step-by-step guide to get Didit verification working in your Sampul app.

## Step 1: Create a Didit Account

1. Go to [https://didit.me](https://didit.me)
2. Sign up for an account (or log in if you already have one)
3. Complete the onboarding process

## Step 2: Get Your API Credentials

1. Log in to your Didit Business Console
2. Navigate to **Settings** → **API Keys** (or **Developers** → **API**)
3. Create a new API key or copy your existing one
4. Save this key - you'll need it for your `.env` file

**Note:** The API key format is usually a long string like: `sk_live_xxxxx` or `sk_test_xxxxx`

## Step 3: Create a Verification Workflow

1. In the Didit dashboard, go to **Workflows** or **Verification Workflows**
2. Click **Create New Workflow** or use a template
3. Configure your workflow:
   - **Name**: Give it a descriptive name (e.g., "Sampul Identity Verification")
   - **Type**: Select the verification type (ID Verification, KYC, etc.)
   - **Steps**: Configure what documents/information you need
   - **Settings**: Configure redirect URLs and other settings
4. **Save the Workflow ID** - you'll need this for your `.env` file

**Workflow ID** is usually found in the workflow URL or settings page. It might look like: `wf_xxxxx` or a UUID.

## Step 4: Configure Your Environment Variables

1. Open your `.env` file in the project root (create it if it doesn't exist)
2. Add the following Didit configuration:

```env
# Didit Verification Configuration
DIDIT_API_BASE_URL=https://api.didit.me
DIDIT_API_KEY=your_api_key_here
DIDIT_API_SECRET=your_api_secret_here
DIDIT_WORKFLOW_ID=your_workflow_id_here
DIDIT_REDIRECT_URL=https://sampul.co/verification-complete
```

**Important:**
- Replace `your_api_key_here` with your actual Didit API key
- Replace `your_workflow_id_here` with your workflow ID
- `DIDIT_API_SECRET` is optional - only add if Didit requires it
- `DIDIT_REDIRECT_URL` should be a URL where users are redirected after verification
- Make sure `.env` is in your `.gitignore` file!

## Step 5: Verify Database Table Exists

Make sure your Supabase database has the `verification` table. Run this SQL in your Supabase SQL editor if it doesn't exist:

```sql
CREATE TABLE IF NOT EXISTS public.verification (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  service_name text NOT NULL,
  uuid uuid NOT NULL,
  session_id text NOT NULL UNIQUE,
  status text,
  CONSTRAINT verification_pkey PRIMARY KEY (id),
  CONSTRAINT verification_sessions_uuid_fkey FOREIGN KEY (uuid) REFERENCES public.profiles(uuid)
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_verification_uuid ON public.verification(uuid);
CREATE INDEX IF NOT EXISTS idx_verification_session_id ON public.verification(session_id);
CREATE INDEX IF NOT EXISTS idx_verification_status ON public.verification(status);
```

## Step 6: Test the Integration

### Option A: Test via Settings Screen

1. Run your app: `flutter run`
2. Log in to your account
3. Go to **Settings**
4. Scroll to the **Account** section
5. You should see **Identity Verification** tile
6. Tap on it to start verification
7. The app will:
   - Create a verification session
   - Open Didit's verification page in your browser
   - Store the session in your database

### Option B: Test Programmatically

You can also test in your code:

```dart
import 'package:sampul_app_v2/services/verification_service.dart';

// Check if user is verified
final isVerified = await VerificationService.instance.isUserVerified();
print('User verified: $isVerified');

// Get verification status
final status = await VerificationService.instance.getUserVerificationStatus();
print('Verification status: $status');

// Create a new verification session
try {
  final result = await VerificationService.instance.createVerificationSession(
    userData: {
      'email': 'user@example.com',
      'name': 'John Doe',
    },
  );
  
  final verification = result['verification'] as Verification;
  final url = result['url'] as String;
  
  print('Session ID: ${verification.sessionId}');
  print('Verification URL: $url');
  
  // Open URL in browser
  // Use url_launcher package to open the URL
} catch (e) {
  print('Error: $e');
}
```

## Step 7: Handle Verification Status Updates

### Option A: Polling (Simple but not recommended for production)

Periodically check verification status:

```dart
// Check status every 30 seconds
Timer.periodic(Duration(seconds: 30), (timer) async {
  final verifications = await VerificationService.instance.getUserVerifications();
  for (final verification in verifications) {
    if (verification.status == 'pending') {
      await VerificationService.instance.syncVerificationStatus(verification.sessionId);
    }
  }
});
```

### Option B: Webhooks (Recommended for production)

1. Set up a webhook endpoint in your backend
2. Configure the webhook URL in Didit dashboard
3. When Didit sends a status update, update your database:

```dart
// In your webhook handler
final sessionId = webhookData['session_id'];
final status = webhookData['status']; // 'verified', 'rejected', etc.

await VerificationService.instance.updateVerificationStatus(
  sessionId,
  status,
);
```

## Step 8: Verify Everything Works

1. **Check Configuration:**
   ```dart
   import 'package:sampul_app_v2/config/didit_config.dart';
   
   print('Is configured: ${DiditConfig.isConfigured}');
   print('API Base URL: ${DiditConfig.apiBaseUrl}');
   ```

2. **Check Database:**
   - Go to Supabase dashboard
   - Check the `verification` table
   - You should see records when you create verification sessions

3. **Test Full Flow:**
   - Create a verification session
   - Complete verification on Didit
   - Check that status updates in your database

## Troubleshooting

### "Didit is not properly configured"
- Check that all required environment variables are set in `.env`
- Make sure `.env` file is in the project root
- Restart your app after adding environment variables

### "Failed to create verification link"
- Verify your API key is correct
- Check that your workflow ID exists
- Ensure your Didit account is active
- Check Didit API documentation for any changes

### "Verification URL not found in response"
- Check Didit API response format
- Verify the API endpoint is correct
- Check Didit API documentation for the correct response structure

### Verification status not updating
- Check webhook configuration in Didit
- Verify webhook endpoint is accessible
- Check database permissions
- Ensure session IDs match

### Database errors
- Verify the `verification` table exists
- Check foreign key constraints
- Ensure user UUID exists in `profiles` table
- Check RLS policies if enabled

## Next Steps

1. ✅ Set up Didit account and get credentials
2. ✅ Create verification workflow
3. ✅ Configure environment variables
4. ✅ Test verification flow
5. ⬜ Set up webhooks for real-time updates
6. ⬜ Add verification status checks throughout your app
7. ⬜ Implement verification requirements for sensitive features
8. ⬜ Add analytics/tracking for verification completion rates

## Useful Resources

- [Didit Documentation](https://docs.didit.me)
- [Didit API Reference](https://docs.didit.me/reference)
- [Didit Workflows Guide](https://docs.didit.me/reference/workflows-dashboard)

## Support

If you encounter issues:
1. Check Didit's status page
2. Review Didit API documentation
3. Check your app logs for detailed error messages
4. Verify all environment variables are correct
5. Test API calls directly using curl or Postman


