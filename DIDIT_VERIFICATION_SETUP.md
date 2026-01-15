# Didit Verification Integration

This document describes the Didit verification integration setup for the Sampul App.

## Overview

The verification system integrates with Didit's identity verification services to verify user identities. Verification records are stored in the `verification` table in your Supabase database.

## Database Schema

The `verification` table has the following structure:

```sql
CREATE TABLE public.verification (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  service_name text NOT NULL,
  uuid uuid NOT NULL,
  session_id text NOT NULL UNIQUE,
  status text,
  CONSTRAINT verification_pkey PRIMARY KEY (id),
  CONSTRAINT verification_sessions_uuid_fkey FOREIGN KEY (uuid) REFERENCES public.profiles(uuid)
);
```

## Configuration

Add the following environment variables to your `.env` file:

```env
DIDIT_API_BASE_URL=https://api.didit.me
DIDIT_API_KEY=your_api_key_here
DIDIT_API_SECRET=your_api_secret_here  # Optional
DIDIT_WORKFLOW_ID=your_workflow_id_here
DIDIT_REDIRECT_URL=https://sampul.co/verification-complete
```

## Usage

### 1. Create a Verification Session

```dart
import 'package:sampul_app_v2/services/verification_service.dart';

// Create a new verification session
final verification = await VerificationService.instance.createVerificationSession(
  workflowId: 'optional-workflow-id', // Uses default if not provided
  userData: {
    'email': 'user@example.com',
    'name': 'John Doe',
    // Add any other user data to pre-fill the form
  },
);

// The verification object contains:
// - id: Database ID
// - sessionId: Unique session ID for this verification
// - status: Current status (usually 'pending')
// - uuid: User UUID
```

### 2. Get Verification URL

After creating a session, you'll need to get the verification URL from Didit. You can modify the service to return the URL, or call Didit's API directly with the session ID.

### 3. Check Verification Status

```dart
// Get status from Didit API
final status = await VerificationService.instance.getVerificationStatus(
  verification.sessionId,
);

// Sync status with database
final updatedVerification = await VerificationService.instance.syncVerificationStatus(
  verification.sessionId,
);
```

### 4. Get User's Verification History

```dart
// Get all verifications for current user
final verifications = await VerificationService.instance.getUserVerifications();

// Get specific verification by session ID
final verification = await VerificationService.instance.getVerificationBySessionId(
  'session_id_here',
);

// Get verification by database ID
final verification = await VerificationService.instance.getVerificationById(123);
```

### 5. Update Verification Status

```dart
// Update status manually (usually done via webhook)
await VerificationService.instance.updateVerificationStatus(
  'session_id_here',
  'verified', // or 'rejected', 'pending'
);
```

## Status Values

The verification status can be one of:
- `pending` - Verification is in progress
- `verified` - Verification completed successfully
- `rejected` - Verification was rejected/failed

## Webhook Integration

For real-time status updates, set up a webhook in Didit that calls your backend endpoint. The webhook should:

1. Receive the verification status update from Didit
2. Update the database using `updateVerificationStatus()`
3. Optionally notify the user

Example webhook payload structure:
```json
{
  "session_id": "didit_1234567890_123456",
  "status": "verified",
  "timestamp": "2024-01-01T00:00:00Z",
  "data": {
    // Additional verification data
  }
}
```

## Error Handling

The service throws exceptions in the following cases:
- User is not authenticated
- Didit is not properly configured (missing API key or workflow ID)
- API request fails
- Verification session not found

Always wrap calls in try-catch blocks:

```dart
try {
  final verification = await VerificationService.instance.createVerificationSession();
  // Handle success
} catch (e) {
  // Handle error
  print('Verification error: $e');
}
```

## Next Steps

1. Set up your Didit account and get API credentials
2. Create a verification workflow in Didit's dashboard
3. Add environment variables to your `.env` file
4. Implement UI screens for verification flow
5. Set up webhook endpoint for status updates (backend)

## Files Created

- `lib/models/verification.dart` - Verification model
- `lib/services/verification_service.dart` - Verification service with Didit integration
- `lib/config/didit_config.dart` - Didit configuration











