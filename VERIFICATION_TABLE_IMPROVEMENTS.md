# Verification Table Improvements

## Overview

The current `verification` table is functional but missing several important fields for proper verification tracking. This document outlines the improvements and migration steps.

## Current Schema Issues

1. ❌ No `updated_at` timestamp - can't track when status changes
2. ❌ No `didit_session_id` - missing external session reference from Didit API
3. ❌ No `completed_at` - can't track when verification finished
4. ❌ No `expires_at` - can't track session expiration
5. ❌ No `verification_url` - URL is generated but not stored
6. ❌ No `error_message` - can't store failure reasons
7. ❌ No `metadata` - can't store additional Didit response data
8. ❌ No indexes - queries on `uuid` and `status` are slow
9. ✅ Status is `text` - kept flexible to accommodate any Didit status values

## Improved Schema

### New Fields Added

| Field | Type | Description |
|-------|------|-------------|
| `updated_at` | `timestamp with time zone` | Auto-updated when record changes |
| `didit_session_id` | `text` | Session ID from Didit API response |
| `completed_at` | `timestamp with time zone` | When verification completed (verified/rejected) |
| `expires_at` | `timestamp with time zone` | When verification session expires |
| `verification_url` | `text` | URL to complete verification |
| `error_message` | `text` | Error message if verification failed |
| `metadata` | `jsonb` | Additional data from Didit API |

### Status Values

The status field remains as `text` (no constraints) to accommodate any status values from Didit API. Common values include:
- `pending` - Verification session created, waiting for user
- `in_progress` - User has started verification process
- `verified` - Verification completed successfully
- `rejected` - Verification was rejected/failed
- `expired` - Verification session expired
- `failed` - Technical failure during verification
- `cancelled` - User cancelled verification

**Note**: Since Didit may return different status values, we keep it flexible without constraints.

### Indexes Added

1. `idx_verification_uuid` - Fast lookup by user UUID
2. `idx_verification_status` - Fast filtering by status
3. `idx_verification_session_id` - Fast lookup by session ID
4. `idx_verification_didit_session_id` - Fast lookup by Didit session ID
5. `idx_verification_created_at` - Fast sorting by creation date
6. `idx_verification_uuid_status` - Composite index for common queries

### Auto-Update Trigger

A trigger automatically updates `updated_at` whenever a record is modified.

## Migration Steps

1. **Run the migration SQL** (`verification_table_improvements.sql`):
   ```bash
   # In Supabase SQL Editor or via CLI
   psql -f verification_table_improvements.sql
   ```

2. **Update Flutter Model** (`lib/models/verification.dart`):
   - Add new fields to the `Verification` class
   - Update `fromJson` and `toJson` methods

3. **Update Verification Service** (`lib/services/verification_service.dart`):
   - Store `didit_session_id` from API response
   - Store `verification_url` when creating session
   - Set `completed_at` when status changes to verified/rejected
   - Store `error_message` on failures
   - Store additional data in `metadata` field

4. **Update DB_STRUCTURE.md**:
   - Replace the old schema with the new improved schema

## Benefits

✅ **Better Tracking**: Know exactly when verifications are created, updated, and completed  
✅ **External Reference**: Link to Didit's session ID for API calls  
✅ **Error Handling**: Store and display error messages to users  
✅ **Performance**: Indexes make queries much faster  
✅ **Flexibility**: Status field accepts any text value from Didit API  
✅ **Flexibility**: JSONB metadata field for future Didit API changes  
✅ **Audit Trail**: `updated_at` provides full change history  

## Example Usage

### Creating a Verification Session

```dart
final result = await VerificationService.instance.createVerificationSession(
  userData: {'email': 'user@example.com', 'name': 'John Doe'},
);

// Now stores:
// - session_id (internal)
// - didit_session_id (from Didit response)
// - verification_url (from Didit response)
// - expires_at (calculated or from Didit)
// - metadata (full Didit response)
```

### Updating Status

```dart
await VerificationService.instance.updateVerificationStatus(
  sessionId: 'didit_123',
  status: 'verified',
  completedAt: DateTime.now(),
  metadata: {'didit_response': {...}},
);
```

## Backward Compatibility

The migration is **backward compatible**:
- All new fields are nullable or have defaults
- Existing code will continue to work
- Old records will have `NULL` for new fields (which is fine)
- Status values remain the same (`pending`, `verified`, `rejected`)

## Next Steps

1. **Run the migration SQL** (`verification_table_improvements.sql`)
2. **Set up RLS policies** (`verification_rls_policies.sql`) - **REQUIRED** to fix RLS errors
3. Update the Flutter model and service (already done)
4. **Deploy Didit webhook edge function** (see `DIDIT_WEBHOOK_SETUP.md`)
5. Test the verification flow end-to-end
6. Monitor query performance improvements

## Important: RLS Policies

**You must run `verification_rls_policies.sql`** after the migration. Without RLS policies, you'll get errors like:
```
PostgrestException(message: new row violates row-level security policy for table "verification")
```

The policies allow:
- Users to view their own verification records
- Users to create verification records for themselves
- Users to update their own verification records
- Edge functions (with service role) to update any record (for webhooks)

## Architecture Pattern

This follows the same pattern as Stripe integration:
- **`verification` table** = Session/attempt tracking (like Stripe checkout sessions)
- **`accounts.kyc_status`** = User's actual verification status (like `accounts.is_subscribed`)
- **Edge function** = Updates both tables when Didit sends webhook (like `stripe-webhook`)

See `DIDIT_WEBHOOK_SETUP.md` for webhook setup instructions.

