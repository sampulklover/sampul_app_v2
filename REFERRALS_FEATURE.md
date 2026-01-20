## Referrals / Affiliate Feature

This repo includes a simple **referral (affiliate) system**:

- Users get a **referral code** they can share
- New users can **apply a referral code** during onboarding
- The app records **who referred whom** in Supabase

This is designed to work for **mobile now** and a **website later** by using Supabase **Edge Functions** (HTTP) instead of Postgres RPC for the main flows.

---

## Components

### Database (Supabase)
Created by `affiliate_setup.sql`:

- `public.affiliate_codes`
  - `code` (PK)
  - `owner_id` (auth user id, unique)
  - One code per user

- `public.affiliate_referrals`
  - `referrer_id` (auth user id)
  - `referred_id` (auth user id, unique)
  - `code` (FK to `affiliate_codes.code`)
  - One referral per referred user

RLS is enabled and *select-only* policies are included:
- Users can read their own `affiliate_codes`
- Users can read referrals where they are either the referrer or referred

> Inserts are performed by Edge Functions using the service role key.

---

### Edge Functions (Supabase)

#### `claim-referral`
Path: `supabase/functions/claim-referral/index.ts`

- **Purpose**: Claim a referral code for the current logged-in user
- **Request**: `POST { "code": "ABC123" }`
- **Auth**: `Authorization: Bearer <user_jwt>`
- **Behavior**:
  - Validates code exists
  - Prevents self-referral
  - Inserts into `affiliate_referrals` (one per referred user)
  - If user already has a referrer, it returns `200` with `{ claimed:false, reason:"already_referred" }` (idempotent UX)

#### `my-affiliate-code`
Path: `supabase/functions/my-affiliate-code/index.ts`

- **Purpose**: Get or create the current user's referral code
- **Request**: `GET` or `POST`
- **Auth**: `Authorization: Bearer <user_jwt>`
- **Behavior**:
  - Returns existing code from `affiliate_codes` for the user
  - Otherwise creates a new random code and stores it

---

## App (Flutter) behavior

### Where users apply a referral code
Screen: `lib/screens/onboarding_flow_screen.dart`

- A **Referral code** card appears as part of onboarding (styled like other steps)
- Tapping opens a modal
- The modal:
  - validates input
  - calls `AffiliateService.claimReferralCodeNow()`
  - shows **inline success/error** inside the modal (so it’s visible without closing)

### Referral dashboard
Screen: `lib/screens/referral_dashboard_screen.dart`

- Shows:
  - user's code (copy)
  - referrals count
  - recent referrals list (formatted timestamps)

Entry point:
- Settings → Preferences → **Referrals**

### Client logic + caching
Service: `lib/services/affiliate_service.dart`

- Stores a pending referral code locally (`pending_referral_code`)
- Claims via Edge Function `claim-referral`
- Maps server errors to **friendly user messages**
- Caches “my code” per-user in `SharedPreferences` (key includes user id) so it won’t leak between accounts

Logout cleanup:
- `AuthController.signOut()` clears cached affiliate data for the previous user.

---

## Setup / Deployment

### 1) Run SQL
In Supabase SQL editor run:

- `affiliate_setup.sql`

### 2) Deploy Edge Functions

```bash
supabase functions deploy claim-referral
supabase functions deploy my-affiliate-code
```

---

## Website (future) developer reference

The web app should reuse the same Edge Functions. The only requirements are:
- The user is authenticated with Supabase Auth
- You send the user’s JWT in the `Authorization` header

### Edge Function URLs

Hosted projects:
- `my-affiliate-code`: `https://<project-ref>.functions.supabase.co/my-affiliate-code`
- `claim-referral`: `https://<project-ref>.functions.supabase.co/claim-referral`

Local dev (Supabase CLI):
- `http://localhost:54321/functions/v1/my-affiliate-code`
- `http://localhost:54321/functions/v1/claim-referral`

### Example (web) — get or create my code

```ts
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY)

const { data: { session } } = await supabase.auth.getSession()
const token = session?.access_token

const res = await fetch(`${SUPABASE_FUNCTIONS_URL}/my-affiliate-code`, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`,
  },
})

const body = await res.json()
console.log(body.code) // "ABC123..."
```

### Example (web) — claim a referral code

```ts
const res = await fetch(`${SUPABASE_FUNCTIONS_URL}/claim-referral`, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`,
  },
  body: JSON.stringify({ code: 'ABC123' }),
})

const body = await res.json()
// Possible responses:
// - { claimed: true, code: "ABC123" }
// - { claimed: false, reason: "already_referred" }
// - { error: "code_not_found" } (non-2xx)
```

### Recommended web UX

- **Onboarding flow**: optional “Referral code” step (after login)
  - Same as mobile: let users enter a code during onboarding and claim it while authenticated
- **Settings / Profile**: dedicated “Referrals” page
  - Show code + copy/share
  - Show referrals list

## Testing (end-to-end)

### Create a referrer code (User A)
- Sign in as **User A**
- Open **Settings → Referrals**
- The dashboard will fetch/create and display **User A’s code**

### Apply the code (User B)
- Sign out, sign in as **User B**
- Open onboarding → **Referral code** → enter **User A’s code** → Apply
- Should show success in the modal

### Verify in Supabase
- `affiliate_codes` contains one row for User A (and for User B once they open referrals dashboard)
- `affiliate_referrals` contains a row where:
  - `referrer_id = User A`
  - `referred_id = User B`

---

## Notes / Future improvements

- Add “share link” (deep link + code parameter) for better UX (reduce manual typing)
- Add rewards/commission logic (ledger table, payout status, payout provider integration)
- Add anti-abuse protections (rate limiting, device fingerprinting, cooldown windows, duplicate-account checks)
- Improve referral dashboard details (optional: masked referred user info, conversion status, totals)
- Add admin reporting (top referrers, fraud review queue, export)

