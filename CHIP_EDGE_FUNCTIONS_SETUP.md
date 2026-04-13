# CHIP Edge Functions Setup Guide

This guide explains how to deploy and configure the CHIP payment edge functions for the Flutter app.

## 📁 Edge Functions Created

The following edge functions have been created in `supabase/functions/`:

1. **`chip-create-client`** - Get or create CHIP customer ID
2. **`chip-create-payment`** - Create payment session with CHIP
3. **`chip-webhook`** - Handle CHIP webhook callbacks (updates payment status)
4. **`chip-payment-redirect`** - Serves HTML redirect pages that redirect to deep links

**Note**: The `success_callback` required by CHIP API is pointed to the webhook function. The redirect URLs use `chip-payment-redirect` which serves a simple success page. Users manually return to the app, and the app automatically detects resume and checks payment status via webhooks. This approach is more reliable than deep links.

## 🚀 Deployment

### Prerequisites

1. Install Supabase CLI:
   ```bash
   npm i -g supabase
   ```

2. Login to Supabase:
   ```bash
   supabase login
   ```

3. Link your project (if not already linked):
   ```bash
   supabase link --project-ref <your-project-ref>
   ```

### Deploy Functions

Deploy all CHIP edge functions:

```bash
# Deploy create client function
supabase functions deploy chip-create-client --project-ref <your-project-ref>

# Deploy create payment function
supabase functions deploy chip-create-payment --project-ref <your-project-ref>

# Deploy webhook handler (no JWT verification for webhooks)
supabase functions deploy chip-webhook --project-ref <your-project-ref> --no-verify-jwt

# Deploy redirect handler (no JWT verification - public redirect pages)
supabase functions deploy chip-payment-redirect --project-ref <your-project-ref> --no-verify-jwt
```

## 🔐 Configure Secrets

Set the following secrets in Supabase Dashboard → Edge Functions → Secrets:

```bash
# Required secrets (Hibah + Wasiat — main CHIP merchant)
CHIP_SECRET_KEY=your_chip_secret_key
CHIP_BRAND_ID=your_chip_brand_id

# Required for Trust payments only (separate CHIP merchant)
CHIP_TRUST_SECRET_KEY=your_trust_chip_secret_key
CHIP_TRUST_BRAND_ID=your_trust_chip_brand_id

SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

**Note:** The edge function uses `SUPABASE_URL` as a placeholder for redirect URLs. CHIP API requires HTTP/HTTPS URLs for validation, but we don't actually need to serve pages there because:
- All payment status updates are handled via webhooks
- The redirect URLs are just placeholders for CHIP's validation
- No website required - fully mobile-first approach

Or use CLI:

```bash
supabase secrets set \
  CHIP_SECRET_KEY=your_chip_secret_key \
  CHIP_BRAND_ID=your_chip_brand_id \
  SUPABASE_SERVICE_ROLE_KEY=your_service_role_key \
  NEXT_PUBLIC_HOST=https://your-domain.com
```

## 🔗 Configure CHIP Webhook

Configure the **same** webhook URL on **each** CHIP merchant you use (main merchant for Hibah/Wasiat, trust merchant for Trust):

1. Go to that merchant’s CHIP Dashboard → Settings → Webhooks
2. Add a new webhook endpoint:
   - **URL**: `https://<your-project-ref>.functions.supabase.co/chip-webhook`
   - **Events**: Select payment status events (e.g., `payment.paid`, `payment.failed`, etc.)
3. Save the webhook configuration

## 📋 Function Details

### `chip-create-client`

**Purpose**: Get or create CHIP customer ID for the authenticated user

**Request**:
```json
POST /functions/v1/chip-create-client
Authorization: Bearer <user_jwt>
Content-Type: application/json

{
  "email": "user@example.com",
  "chipAccount": "main"
}
```

Optional `"chipAccount": "trust"` uses `CHIP_TRUST_SECRET_KEY` and stores the ID in `accounts.chip_trust_customer_id` (Trust payments only).

**Response**:
```json
{
  "data": {
    "id": "chip_customer_id_12345"
  }
}
```

**Behavior**:
- **main** (default): checks `chip_customer_id`; creates with `CHIP_SECRET_KEY` if missing
- **trust**: checks `chip_trust_customer_id`; creates with `CHIP_TRUST_SECRET_KEY` if missing
- Returns the CHIP customer ID for that merchant

### `chip-create-payment`

**Purpose**: Create a payment session with CHIP gateway

**Request**:
```json
POST /functions/v1/chip-create-payment
Authorization: Bearer <user_jwt>
Content-Type: application/json

{
  "trustId": "123",
  "trustCode": "TRUST-001",
  "userId": "user-uuid",
  "clientId": "chip_customer_id",
  "amount": 1000000,
  "description": "Payment for Trust TRUST-001",
  "successUrl": "sampul://trust?payment=success",
  "failureUrl": "sampul://trust?payment=failed"
}
```

**Response**:
```json
{
  "data": {
    "id": "chip_payment_id",
    "checkout_url": "https://gate.chip-in.asia/checkout/...",
    "status": "pending_charge",
    "client_id": "chip_customer_id"
  }
}
```

**Behavior**:
1. Creates payment record in `trust_payments` table with status `'initiated'`
2. Calls CHIP API to create purchase
3. Updates `trust_payments` record with `chip_payment_id` and status
4. Returns checkout URL for redirect

### `chip-webhook`

**Purpose**: Receive payment status updates from CHIP

**Request** (from CHIP):
```json
POST /functions/v1/chip-webhook
Content-Type: application/json

{
  "id": "chip_payment_id",
  "status": "paid",
  ...
}
```

**Response**:
```json
{
  "message": "Webhook processed successfully",
  "type": "trust_payment",
  "status": "paid"
}
```

**Behavior**:
- Finds payment record in `trust_payments` or `hibah_payments` table by `chip_payment_id`
- Updates payment `status` and `updated_at` timestamp
- Returns 200 OK

**Note**: This function is deployed with `--no-verify-jwt` flag because webhooks come from CHIP, not from authenticated users.

**Note on `success_callback`**: CHIP API requires a `success_callback` URL in the payment creation payload. Instead of creating a separate dummy endpoint, we point it to the `chip-webhook` function, which already handles all payment status updates. This reduces the number of functions while still satisfying CHIP's API requirements.

## 🧪 Testing

### Test Create Client

```bash
curl -X POST https://<project-ref>.functions.supabase.co/chip-create-client \
  -H "Authorization: Bearer <user_jwt>" \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com"}'
```

### Test Create Payment

```bash
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

### Test Webhook (from CHIP Dashboard)

CHIP will automatically send webhooks when payment status changes. You can also test manually:

```bash
curl -X POST https://<project-ref>.functions.supabase.co/chip-webhook \
  -H "Content-Type: application/json" \
  -d '{
    "id": "chip_payment_id",
    "status": "paid"
  }'
```

## 🔍 Monitoring

Check edge function logs in Supabase Dashboard:
- Go to **Edge Functions** → Select function → **Logs**
- Monitor for errors and webhook deliveries

## 📝 Notes

- All functions use **service role key** to bypass RLS when needed
- `chip-create-client` and `chip-create-payment` require user authentication (JWT)
- `chip-webhook` and `chip-success-callback` are public (no JWT verification)
- Amounts are in **cents** (integers) - e.g., 1000000 = RM 10,000.00
- **Redirect URLs**: CHIP API requires HTTP/HTTPS URLs, so we use `chip-payment-redirect` function that serves a simple success page. Users close the browser and return to the app manually. The app automatically detects resume and checks payment status. All payment status updates are handled via webhooks for reliability. This approach avoids deep link issues and works consistently across all platforms.

## 🐛 Troubleshooting

### Function not found
- Ensure functions are deployed: `supabase functions list`
- Check project ref matches your Supabase project

### Authentication errors
- Verify JWT token is valid and not expired
- Check that user exists in Supabase Auth

### CHIP API errors
- Verify `CHIP_SECRET_KEY` and `CHIP_BRAND_ID` are correct
- Check CHIP dashboard for API key status
- Review CHIP API response in function logs

### Webhook not receiving updates
- Verify webhook URL in CHIP dashboard matches deployed function URL
- Check function logs for incoming requests
- Ensure webhook is enabled in CHIP dashboard

## 🔄 Migration from Web API

These edge functions replace the Next.js API routes:
- `chip/create-client.js` → `chip-create-client`
- `chip/create-payment.js` → `chip-create-payment`
- `chip/hooks.js` → `chip-webhook`
- `chip/success-callback.js` → `chip-success-callback`

The Flutter app calls these edge functions via `SupabaseClient.functions.invoke()`.
