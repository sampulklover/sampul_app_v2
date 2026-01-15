# Didit Quick Start Checklist

Use this checklist to quickly set up Didit verification:

## ✅ Pre-Setup Checklist

- [ ] Didit account created and logged in
- [ ] API key obtained from Didit dashboard
- [ ] Verification workflow created in Didit
- [ ] Workflow ID copied
- [ ] `.env` file exists in project root
- [ ] `.env` is in `.gitignore` (already done ✓)

## ✅ Configuration Steps

1. **Add to `.env` file:**
   ```env
   DIDIT_API_BASE_URL=https://api.didit.me
   DIDIT_API_KEY=your_actual_api_key_here
   DIDIT_WORKFLOW_ID=your_actual_workflow_id_here
   DIDIT_REDIRECT_URL=https://sampul.co/verification-complete
   ```

2. **Verify database table exists:**
   - Go to Supabase SQL Editor
   - Run the SQL from `DIDIT_SETUP_GUIDE.md` Step 5
   - Or check if `verification` table already exists

3. **Test configuration:**
   - Run: `flutter run`
   - Go to Settings → Identity Verification
   - Try to start verification

## ✅ Testing Checklist

- [ ] App loads without errors
- [ ] Settings screen shows "Identity Verification" tile
- [ ] Tapping verification creates a session
- [ ] Verification URL opens in browser
- [ ] Database shows new verification record
- [ ] Status updates correctly after verification

## 🚨 Common Issues & Quick Fixes

| Issue | Quick Fix |
|-------|-----------|
| "Didit is not properly configured" | Check `.env` file has all required variables |
| "Failed to create verification link" | Verify API key and workflow ID are correct |
| Verification not showing in settings | Restart app after adding `.env` variables |
| Database errors | Check `verification` table exists and has correct schema |

## 📝 Next Steps After Setup

1. Test the full verification flow
2. Set up webhooks for real-time status updates
3. Add verification requirements to sensitive features
4. Monitor verification completion rates

For detailed instructions, see `DIDIT_SETUP_GUIDE.md`


