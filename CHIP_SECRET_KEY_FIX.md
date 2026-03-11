# Fix CHIP Secret Key Error

## 🔴 Error
```
Incorrect secret_key
authentication_failed
```

This means the `CHIP_SECRET_KEY` in your Supabase Edge Functions secrets is either:
- Not set
- Incorrect/expired
- Wrong format

## ✅ Solution

### Step 1: Get Your CHIP Secret Key

1. Go to [CHIP Dashboard](https://dashboard.chip-in.asia/)
2. Navigate to **Settings → API Keys**
3. Copy your **Secret Key** (starts with something like `sk_` or similar)
4. Also copy your **Brand ID**

### Step 2: Set Secrets in Supabase

**Option A: Via Supabase Dashboard**
1. Go to your Supabase project
2. Navigate to **Edge Functions → Secrets**
3. Add or update:
   - `CHIP_SECRET_KEY` = your CHIP secret key
   - `CHIP_BRAND_ID` = your CHIP brand ID
4. Click **Save**

**Option B: Via Supabase CLI**
```bash
supabase secrets set \
  CHIP_SECRET_KEY=your_chip_secret_key_here \
  CHIP_BRAND_ID=your_chip_brand_id_here \
  --project-ref <your-project-ref>
```

### Step 3: Redeploy Edge Functions

**Important:** After setting secrets, you MUST redeploy the functions for them to pick up the new secrets:

```bash
supabase functions deploy chip-create-client --project-ref <your-project-ref>
supabase functions deploy chip-create-payment --project-ref <your-project-ref>
```

### Step 4: Verify

1. Check edge function logs after redeploying
2. You should see logs like:
   ```
   🟢 [CHIP-CREATE-PAYMENT] CHIP credentials found
   🟢 [CHIP-CREATE-PAYMENT] CHIP_SECRET_KEY length: XX
   🟢 [CHIP-CREATE-PAYMENT] CHIP_SECRET_KEY starts with: sk_...
   ```

## 🔍 Troubleshooting

### If secret key still doesn't work:

1. **Check key format:**
   - Make sure there are no extra spaces
   - Don't include quotes when setting via CLI
   - Verify the key is complete (not truncated)

2. **Verify key is active:**
   - Check in CHIP Dashboard that the key is active
   - Some keys might be test vs production keys

3. **Check environment:**
   - Make sure you're using the correct key for your environment (test/production)
   - Test keys won't work in production and vice versa

4. **Compare with web implementation:**
   - If your web app works, compare the secret key format
   - Make sure you're using the same key

### Common Mistakes:

- ❌ Setting secret in `.env` file (doesn't work for edge functions)
- ❌ Forgetting to redeploy after setting secrets
- ❌ Using wrong project/environment
- ❌ Copying key with extra whitespace
- ❌ Using expired/revoked key

## 📝 Quick Checklist

- [ ] Got CHIP Secret Key from CHIP Dashboard
- [ ] Got CHIP Brand ID from CHIP Dashboard
- [ ] Set `CHIP_SECRET_KEY` in Supabase Edge Functions Secrets
- [ ] Set `CHIP_BRAND_ID` in Supabase Edge Functions Secrets
- [ ] Redeployed `chip-create-client` function
- [ ] Redeployed `chip-create-payment` function
- [ ] Tested again and checked logs

## 🧪 Test After Fix

After setting secrets and redeploying, try adding a fund again. Check:
1. Edge function logs show "CHIP credentials found"
2. No "authentication_failed" errors
3. Payment creation succeeds
