# Trust Payment Implementation Summary

This document summarizes the trust payment feature implementation for the Flutter app.

## ✅ Completed Implementation

### 1. Models
- **`lib/models/trust_payment.dart`**: TrustPayment model with helper methods for formatting and status checking
- **`lib/models/trust.dart`**: Updated to include `trustPayments` list and helper methods:
  - `totalPaidInCents`: Calculate total paid amount
  - `remainingInCents`: Calculate remaining amount to reach minimum
  - `progressPercentage`: Calculate progress (0-100%)

### 2. Configuration
- **`lib/config/chip_config.dart`**: CHIP payment gateway configuration
  - Edge function names: `chip-create-client`, `chip-create-payment`
  - Payment constants: `minTrustAmount` (RM 100,000), `maxTransactionAmount` (RM 30,000)
- **`lib/config/trust_constants.dart`**: Added payment constants

### 3. Services
- **`lib/services/trust_payment_service.dart`**: Service for handling CHIP payments
  - `getChipClient()`: Get or create CHIP customer ID
  - `createPayment()`: Create payment session with CHIP
  - `getPaymentHistory()`: Get payment history for a trust
  - `getPaymentById()`: Get specific payment
  - `getPaymentByChipId()`: Get payment by CHIP payment ID
- **`lib/services/trust_service.dart`**: Updated to fetch trust with payment data
  - `getTrustWithPayments()`: Get trust including payment history

### 4. UI Components
- **`lib/widgets/trust_payment_form_modal.dart`**: Payment form modal
  - Progress bar showing trust completion
  - Amount input with validation
  - Payment limits information
  - Fee structure (collapsible)
  
- **`lib/widgets/trust_payment_history_modal.dart`**: Payment history modal
  - List of all payments with status badges
  - Total paid and remaining amount
  - Payment details (date, reference ID, amount, status)
  
- **`lib/widgets/payment_status_modal.dart`**: Payment status modal
  - Success/failure states
  - Appropriate icons and messages

### 5. Screen Updates
- **`lib/screens/trust_dashboard_screen.dart`**: Updated to include payment section
  - Payment progress display
  - "Make Payment" button
  - "History" button
  - Auto-refresh after payment initiation

## 🔧 Required Edge Functions

You need to create the following Supabase Edge Functions:

### 1. `chip-create-client` (POST)
**Purpose**: Get or create CHIP customer ID for the user

**Request Body**:
```json
{
  "email": "user@example.com"
}
```

**Response**:
```json
{
  "data": {
    "id": "chip_customer_id_12345"
  }
}
```

**Implementation Notes**:
- Check if user already has `chip_customer_id` in `accounts` table
- If exists, return existing ID
- If not, create new CHIP client via CHIP API
- Store in `accounts` table
- Use CHIP API: `POST https://gate.chip-in.asia/api/v1/clients/`

### 2. `chip-create-payment` (POST)
**Purpose**: Create a payment session with CHIP gateway

**Request Body**:
```json
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

**Implementation Flow**:
1. Create payment record in `trust_payments` table with status `'initiated'`
2. Call CHIP API to create purchase:
   - **Base URL**: `https://gate.chip-in.asia/api/v1/purchases/`
   - **Method**: POST
   - **Headers**:
     - `Content-Type: application/json`
     - `Authorization: Bearer {CHIP_SECRET_KEY}`
   - **Body**:
     ```json
     {
       "brand_id": "{CHIP_BRAND_ID}",
       "client_id": "{clientId}",
       "success_callback": "{baseUrl}/api/chip/hooks",
       "success_redirect": "{successUrl}",
       "failure_redirect": "{failureUrl}",
       "send_receipt": true,
       "purchase": {
         "amount": 1000000,
         "products": [
           {
             "name": "Payment for Trust TRUST-001",
             "price": 1000000
           }
         ]
       }
     }
     ```
3. Update `trust_payments` record with `chip_payment_id` and status
4. Return checkout URL

### 3. Webhook Handler (Optional - for server-side status updates)
**Endpoint**: `/api/chip/hooks` (POST)
**Purpose**: Receive payment status updates from CHIP

**Implementation**:
1. Extract `id` (chip_payment_id) from webhook payload
2. Find payment record in `trust_payments` table
3. Update `status` and `updated_at` fields
4. Return 200 OK

**Note**: Mobile app can poll payment status or use real-time subscriptions instead of webhooks.

## 📋 Environment Variables

Add to your Supabase Edge Functions secrets:
- `CHIP_SECRET_KEY`: Your CHIP API secret key
- `CHIP_BRAND_ID`: Your CHIP brand ID
- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY`: Service role key for database access

## 🔗 Deep Link Configuration

Deep links are already configured for the app:
- **Success URL**: `sampul://trust?payment=success`
- **Failure URL**: `sampul://trust?payment=failed`

The app will automatically open when CHIP redirects after payment. You can optionally add deep link handling in `main.dart` to show payment status modal automatically.

## 📱 Payment Flow

1. User taps "Make Payment" on trust dashboard
2. Payment form modal opens
3. User enters payment amount (validated: max RM 30,000)
4. User clicks "Continue to Payment"
5. App calls `getChipClient()` edge function
6. App calls `createPayment()` edge function
7. Backend creates payment record and calls CHIP API
8. App opens CHIP checkout URL in external browser
9. User completes payment on CHIP gateway
10. CHIP redirects to success/failure URL
11. App opens automatically (via deep link)
12. User can manually refresh trust dashboard to see updated payment status

## 🧪 Testing

1. Create a trust in the app
2. Navigate to trust dashboard
3. Tap "Make Payment"
4. Enter an amount (e.g., RM 1,000)
5. Complete payment on CHIP gateway
6. Return to app and check payment history
7. Verify progress bar updates

## 📝 Notes

- Amounts are stored in **cents** (integers) - always convert for display
- Minimum trust amount: **RM 100,000** (cumulative across payments)
- Maximum per transaction: **RM 30,000**
- Payment statuses: `initiated`, `pending_charge`, `paid`, `settled`, `cleared`, `failed`, `error`, `expired`, `cancelled`, `refunded`, `chargeback`
- The app uses polling/refresh to check payment status (webhooks are optional)

## 🚀 Next Steps

1. Create the edge functions (`chip-create-client` and `chip-create-payment`)
2. Configure CHIP API credentials in Supabase Edge Functions secrets
3. Test the payment flow end-to-end
4. (Optional) Add deep link handling in `main.dart` to show payment status modal automatically
5. (Optional) Implement real-time subscriptions for automatic payment status updates
