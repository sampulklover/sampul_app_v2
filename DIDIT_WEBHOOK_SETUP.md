# Didit Webhook Setup Guide

This guide explains how to set up the Didit webhook edge function to automatically update verification status in both the `verification` table (session tracking) and `accounts.kyc_status` (user verification status).

## Overview

The `verification` table tracks individual verification sessions/attempts, while `accounts.kyc_status` stores the user's actual verification status. The webhook edge function updates both:

1. **`verification` table** - Updates session status, completed_at, error_message, metadata
2. **`accounts.kyc_status`** - Updates user's actual verification status (verified/rejected/pending/expired)

This follows the same pattern as the Stripe webhook integration.

## Architecture

```
Didit API → Webhook → Edge Function → Database
                              ├─→ verification table (session tracking)
                              └─→ accounts.kyc_status (user status)
```

## Setup Steps

### 0. Set Up RLS Policies (Required)

**IMPORTANT**: Before using the verification table, you must set up Row Level Security policies:

1. Run `verification_rls_policies.sql` in your Supabase SQL Editor
2. This allows users to create/view/update their own verification records
3. Edge functions use service role key, so they bypass RLS (as intended)

Without RLS policies, you'll get errors like:
```
PostgrestException: new row violates row-level security policy for table "verification"
```

### 1. Deploy Edge Function

Deploy the `didit-webhook` function to Supabase:

```bash
supabase functions deploy didit-webhook --project-ref <YOUR_PROJECT_REF> --no-verify-jwt
```

> **Note**: Use `--no-verify-jwt` because webhooks come from external services (Didit), not authenticated users.

### 2. Set Supabase Secrets

In Supabase Dashboard → **Edge Functions → Secrets**, add:

- `DIDIT_WEBHOOK_SECRET_KEY` - Your Didit webhook secret key (from Didit Console → App Settings → API & Webhooks)
- `SUPABASE_SERVICE_ROLE_KEY` - Your Supabase service role key (for bypassing RLS)

Or via CLI:

```bash
supabase secrets set DIDIT_WEBHOOK_SECRET_KEY=your_webhook_secret SUPABASE_SERVICE_ROLE_KEY=service_role_...
```

### 3. Configure Didit Webhook

1. Go to **Didit Console** → **App Settings** → **API & Webhooks** tab
2. Set **Webhook URL** to your edge function URL:
   ```
   https://<YOUR_PROJECT_REF>.supabase.co/functions/v1/didit-webhook
   ```
3. Set **Webhook Version** (v2.0 recommended)
4. Copy the **Webhook Secret Key** and add it to Supabase secrets (step 2)

### 4. Webhook Events

The function handles Didit webhook events. Adjust the event types based on Didit's documentation:

- `verification.completed` - Verification completed successfully
- `verification.rejected` - Verification was rejected
- `verification.failed` - Verification failed
- `verification.expired` - Verification session expired
- `verification.status_changed` - Status changed

## Status Mapping

The function maps Didit status values to your database:

| Didit Status | verification.status | accounts.kyc_status |
|-------------|---------------------|---------------------|
| `approved` | `approved` | `approved` |
| `declined` | `declined` | `declined` |
| `accepted` | `accepted` | `accepted` |
| `rejected` | `rejected` | `rejected` |
| `pending`, `in_progress`, `processing`, `not started` | `pending` | `pending` |
| `expired` | `expired` | `expired` |
| `cancelled`, `canceled` | `cancelled` | (no change) |

**Note**: 
- `verification.status` stores the original Didit status (flexible text field)
- `accounts.kyc_status` uses standard values: `approved`, `pending`, `accepted`, `rejected`, `declined` (text field, not enum)

## Webhook Payload Structure

The function expects Didit webhook payload to include:

```json
{
  "type": "verification.completed",
  "session_id": "didit_session_123",
  "status": "verified",
  "user_id": "uuid-here",
  "vendor_data": "didit_1234567890_123456",
  "error_message": null,
  "metadata": { ... }
}
```

**Important**: Adjust the field names in `index.ts` based on Didit's actual webhook payload structure.

## Security

### Webhook Signature Verification

Currently, the function has a placeholder for signature verification. **You must implement this** based on Didit's documentation:

```typescript
// TODO: Implement signature verification
// if (!verifySignature(body, signature, webhookSecret)) {
//   return new Response("Invalid signature", { status: 401 });
// }
```

Check Didit's webhook documentation for:
- Signature header name (e.g., `x-didit-signature`, `x-signature`)
- Signature algorithm (HMAC-SHA256, etc.)
- How to verify the signature

## Testing

### 1. Test Webhook Locally

```bash
# Start Supabase locally
supabase start

# Serve function locally
supabase functions serve didit-webhook

# Test with curl
curl -X POST http://localhost:54321/functions/v1/didit-webhook \
  -H "Content-Type: application/json" \
  -H "x-didit-signature: test" \
  -d '{
    "type": "verification.completed",
    "session_id": "test_session",
    "status": "verified",
    "vendor_data": "didit_1234567890_123456",
    "user_id": "your-user-uuid"
  }'
```

### 2. Test with Didit

1. Create a verification session in your app
2. Complete the verification in Didit
3. Check Supabase logs for webhook events
4. Verify:
   - `verification` table updated with status
   - `accounts.kyc_status` updated

## Troubleshooting

### 401 Unauthorized Error

If you see `401` errors with `execution_id: null` and very short execution times (<100ms), this usually means Supabase is rejecting the request **before** it reaches your function code.

**Most Common Causes:**

1. **Function NOT deployed with `--no-verify-jwt` flag** (MOST LIKELY):
   ```bash
   # Check current deployment settings in Supabase Dashboard
   # Then redeploy with the flag:
   supabase functions deploy didit-webhook --project-ref <YOUR_REF> --no-verify-jwt
   ```

2. **Check function configuration in Supabase Dashboard**:
   - Go to Edge Functions → didit-webhook → Details
   - Verify "Verify JWT" is **DISABLED** (unchecked)
   - If it's enabled, disable it and redeploy

3. **Check Supabase secrets are set**:
   - Go to Supabase Dashboard → Edge Functions → Secrets
   - Verify `SUPABASE_URL` is set (should be your project URL)
   - Verify `SUPABASE_SERVICE_ROLE_KEY` is set (from Project Settings → API)
   - `DIDIT_WEBHOOK_SECRET_KEY` is optional (for signature verification)

4. **Check function logs** in Supabase Dashboard → Edge Functions → Logs
   - If you see console.log messages starting with `🚀 [DIDIT WEBHOOK]`, the function is running
   - If you see NO logs at all, Supabase is blocking the request before function execution
   - Look for error messages about missing environment variables

5. **Redeploy the function** after fixing configuration:
   ```bash
   supabase functions deploy didit-webhook --project-ref <YOUR_REF> --no-verify-jwt
   ```

**Quick Test:**
After redeploying, check the logs. You should see:
```
🚀 [DIDIT WEBHOOK] Function invoked
🚀 [DIDIT WEBHOOK] Method: POST
```

If you don't see these logs, Supabase is still blocking the request.

### Webhook Not Receiving Events

1. **Check Didit Console** - Verify webhook URL is correct
2. **Check Supabase Logs** - Edge Functions → Logs
3. **Verify Secrets** - Ensure `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are set
4. **Check Function URL** - Must be publicly accessible

### Status Not Updating

1. **Check verification record exists** - Webhook needs `session_id` or `vendor_data` to find record
2. **Check user UUID** - Must match `verification.uuid`
3. **Check accounts row exists** - Function creates it if missing
4. **Check kyc_status enum values** - Adjust in `index.ts` if your enum values differ

### Signature Verification Failing

1. **Check webhook secret** - Must match Didit Console
2. **Check signature header** - Adjust header name in `index.ts`
3. **Implement verification** - Add proper signature verification logic

## Manual Status Update (Alternative)

If webhooks aren't working, you can manually sync status:

```typescript
// In your Flutter app or another edge function
const { data } = await supabase
  .functions
  .invoke('sync-verification-status', {
    body: { session_id: 'didit_123' }
  });
```

## Next Steps

1. ✅ Deploy edge function
2. ✅ Set Supabase secrets
3. ✅ Configure Didit webhook URL
4. ✅ Test with a real verification
5. ✅ Implement signature verification (security)
6. ✅ Adjust status mappings based on Didit's actual values
7. ✅ Adjust webhook payload parsing based on Didit's format

## Related Files

- `supabase/functions/didit-webhook/index.ts` - Edge function code
- `lib/services/verification_service.dart` - Flutter service (creates sessions)
- `verification_table_improvements.sql` - Database schema
- `STRIPE_SUPABASE_SETUP.md` - Reference for similar pattern

