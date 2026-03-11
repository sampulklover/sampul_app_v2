# Trust Payment Debugging Guide

This guide helps you debug issues when "Add Fund" button shows loading but nothing happens.

## 🔍 Debugging Steps

### 1. Check Flutter App Logs

When you click "Continue to Add Fund", check your Flutter console/logs. You should see logs like:

```
🟢 [TRUST PAYMENT] Starting payment flow...
🟢 [TRUST PAYMENT] Amount: RM 1,000.00
🟢 [TRUST PAYMENT] Trust ID: 123
🟢 [TRUST PAYMENT] Trust Code: TRUST-001
🟢 [TRUST PAYMENT] Step 1: Getting CHIP client ID...
🟡 [TRUST PAYMENT SERVICE] getChipClient called
...
```

**What to look for:**
- If logs stop at a certain step, that's where the error is
- Check for 🔴 (red) error logs
- Note the exact error message

### 2. Check Edge Function Logs

Go to **Supabase Dashboard → Edge Functions → Logs** and select:
- `chip-create-client` 
- `chip-create-payment`

You should see logs like:

```
🟢 [CHIP-CREATE-CLIENT] Request received: POST
🟢 [CHIP-CREATE-CLIENT] Processing POST request
🟢 [CHIP-CREATE-CLIENT] Request body: { email: "user@example.com", userId: "..." }
...
```

**What to look for:**
- Check if the function is being called
- Look for error messages (🔴)
- Check response status codes

### 3. Common Issues & Solutions

#### Issue: "No authenticated user"
**Symptoms:** Logs show "No authenticated user"
**Solution:** 
- Check if user is logged in
- Verify JWT token is being sent in Authorization header

#### Issue: "Edge function error: 404"
**Symptoms:** Logs show "Edge function returned error status: 404"
**Solution:**
- Verify edge functions are deployed: `supabase functions list`
- Check function name matches: `chip-create-client` and `chip-create-payment`
- Redeploy if needed: `supabase functions deploy chip-create-client --project-ref <ref>`

#### Issue: "CHIP_SECRET_KEY not configured"
**Symptoms:** Edge function logs show "CHIP_SECRET_KEY not configured"
**Solution:**
- Go to Supabase Dashboard → Edge Functions → Secrets
- Add/verify `CHIP_SECRET_KEY` and `CHIP_BRAND_ID` are set
- Redeploy functions after adding secrets

#### Issue: "Failed to create CHIP client"
**Symptoms:** CHIP API returns error
**Solution:**
- Check CHIP API credentials are correct
- Verify CHIP account is active
- Check CHIP API response in edge function logs

#### Issue: "No checkout URL received"
**Symptoms:** Payment created but no checkout URL
**Solution:**
- Check CHIP API response in edge function logs
- Verify `checkout_url` field exists in response
- Check if CHIP payment was created successfully

#### Issue: "Unable to open payment page"
**Symptoms:** Checkout URL exists but can't launch
**Solution:**
- Check URL format is valid
- Verify `url_launcher` package is configured
- Check device permissions for opening URLs

### 4. Testing Edge Functions Manually

You can test edge functions directly using curl:

```bash
# Test create-client
curl -X POST https://<project-ref>.functions.supabase.co/chip-create-client \
  -H "Authorization: Bearer <user_jwt>" \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com"}'

# Test create-payment
curl -X POST https://<project-ref>.functions.supabase.co/chip-create-payment \
  -H "Authorization: Bearer <user_jwt>" \
  -H "Content-Type: application/json" \
  -d '{
    "trustId": "123",
    "trustCode": "TRUST-001",
    "userId": "user-uuid",
    "clientId": "chip_customer_id",
    "amount": 1000000,
    "description": "Test Payment"
  }'
```

### 5. Enable Verbose Logging

In Flutter, you can enable more verbose logging by checking:
- Run app in debug mode (not release)
- Check `flutter run` console output
- Use `flutter logs` to see device logs

### 6. Check Network Requests

Use a network inspector to see:
- If edge function requests are being made
- What status codes are returned
- Response bodies

### 7. Verify Configuration

Check these are set correctly:
- ✅ Edge functions deployed
- ✅ Secrets configured (CHIP_SECRET_KEY, CHIP_BRAND_ID, SUPABASE_SERVICE_ROLE_KEY)
- ✅ User is authenticated
- ✅ Trust ID exists and is valid
- ✅ Amount is within limits (max RM 30,000)

## 📋 Debug Checklist

When debugging, check:

- [ ] Flutter app logs show payment flow started
- [ ] Edge function logs show request received
- [ ] User authentication is valid
- [ ] Edge functions are deployed
- [ ] Secrets are configured
- [ ] CHIP API credentials are correct
- [ ] Trust ID is valid
- [ ] Amount is valid (positive, within limits)
- [ ] Network connection is working
- [ ] No errors in Supabase logs

## 🐛 Quick Fixes

1. **Redeploy edge functions** after adding secrets
2. **Restart Flutter app** after code changes
3. **Check Supabase project** is correct
4. **Verify user is logged in** before testing
5. **Check amount** is in cents (e.g., 1000000 = RM 10,000)

## 📞 Getting Help

When reporting issues, include:
1. Flutter app logs (from console)
2. Edge function logs (from Supabase Dashboard)
3. Error messages (exact text)
4. Steps to reproduce
5. What you expected vs what happened
