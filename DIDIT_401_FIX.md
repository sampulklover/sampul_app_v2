# Fix 401 Unauthorized Error for Didit Webhook

## What 401 Means

A `401 Unauthorized` error means **Supabase is blocking the request before it reaches your function code**. This happens when JWT verification is enabled, but webhooks from Didit don't have JWT tokens (they're external services).

## Quick Fix (2 Steps)

### Step 1: Disable JWT Verification in Dashboard

1. Go to **Supabase Dashboard**
2. Navigate to **Edge Functions** → **didit-webhook**
3. Click on **Details** tab
4. Find **"Verify JWT"** setting
5. **Turn it OFF** (uncheck it)
6. **Save** the changes

### Step 2: Redeploy Function

Run this command (replace `<YOUR_PROJECT_REF>` with your actual project ref, e.g., `rfzblaianldrfwdqdijl`):

```bash
supabase functions deploy didit-webhook --project-ref rfzblaianldrfwdqdijl --no-verify-jwt
```

## How to Verify It's Fixed

After redeploying:

1. **Check the logs** in Supabase Dashboard → Edge Functions → didit-webhook → Logs
2. **You should see**:
   ```
   🚀 [DIDIT WEBHOOK] Function invoked
   🚀 [DIDIT WEBHOOK] Method: POST
   ```
3. **If you see these logs**, the function is working! ✅
4. **If you still see 401 with no logs**, JWT verification is still enabled

## Alternative: Check via Supabase CLI

You can also check the function configuration:

```bash
supabase functions list --project-ref rfzblaianldrfwdqdijl
```

Look for `didit-webhook` and check if JWT verification is disabled.

## Why This Happens

- **Webhooks are external** - Didit sends requests without Supabase JWT tokens
- **JWT verification blocks** - Supabase rejects requests without valid JWT
- **Solution** - Disable JWT verification for webhook functions (same as Stripe webhook)

## Important Notes

- ✅ **Safe to disable JWT** for webhook functions (you verify signatures instead)
- ✅ **Keep JWT enabled** for other functions that users call directly
- ✅ **Use signature verification** (implement later) for security

