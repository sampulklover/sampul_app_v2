# Didit API Integration Notes

## API Endpoints Used

### 1. Create Verification Link
**Endpoint:** `POST /api/v1/verification-links`

**Request Body:**
```json
{
  "workflow_id": "your_workflow_id",
  "session_id": "unique_session_id",
  "redirect_url": "https://sampul.co/verification-complete",
  "user_data": {
    "email": "user@example.com",
    "name": "John Doe",
    "phone": "+1234567890"
  }
}
```

**Response:**
```json
{
  "verification_url": "https://verify.didit.me/...",
  "session_id": "unique_session_id",
  "status": "pending"
}
```

### 2. Get Verification Status
**Endpoint:** `GET /api/v1/verification-sessions/{session_id}`

**Response:**
```json
{
  "session_id": "unique_session_id",
  "status": "verified", // or "pending", "rejected"
  "created_at": "2024-01-01T00:00:00Z",
  "completed_at": "2024-01-01T00:05:00Z"
}
```

## Authentication

All API requests use Bearer token authentication:
```
Authorization: Bearer {your_api_key}
```

## Important Notes

1. **API Base URL:** The default is `https://api.didit.me` but may vary based on your Didit plan/region
2. **Response Format:** Didit may return different field names. The service checks for both `verification_url` and `url`
3. **Session ID:** Must be unique. Our service generates it as: `didit_{timestamp}_{random}`
4. **Error Handling:** Always wrap API calls in try-catch blocks

## Testing API Calls

You can test the API directly using curl:

```bash
# Create verification link
curl -X POST https://api.didit.me/api/v1/verification-links \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "workflow_id": "YOUR_WORKFLOW_ID",
    "session_id": "test_session_123",
    "redirect_url": "https://sampul.co/verification-complete"
  }'

# Get verification status
curl -X GET https://api.didit.me/api/v1/verification-sessions/test_session_123 \
  -H "Authorization: Bearer YOUR_API_KEY"
```

## Webhook Configuration

When setting up webhooks in Didit:

1. **Webhook URL:** Your backend endpoint (e.g., `https://api.sampul.co/webhooks/didit`)
2. **Events to subscribe:** 
   - `verification.completed`
   - `verification.rejected`
   - `verification.failed`

3. **Webhook Payload Example:**
```json
{
  "event": "verification.completed",
  "session_id": "didit_1234567890_123456",
  "status": "verified",
  "timestamp": "2024-01-01T00:00:00Z",
  "data": {
    "user_id": "user_uuid",
    "verification_data": {}
  }
}
```

## Status Mapping

Didit status → Our database status:
- `completed`, `verified`, `approved` → `verified`
- `rejected`, `failed`, `declined` → `rejected`
- `pending`, `in_progress`, `processing` → `pending`

## Rate Limits

Check Didit's documentation for rate limits. Common limits:
- Free tier: ~100 requests/day
- Paid tiers: Higher limits

## Troubleshooting API Issues

1. **401 Unauthorized:**
   - Check API key is correct
   - Verify API key hasn't expired
   - Check if API key has required permissions

2. **404 Not Found:**
   - Verify workflow ID exists
   - Check API endpoint URL is correct
   - Ensure you're using the right API version

3. **400 Bad Request:**
   - Check request body format
   - Verify all required fields are present
   - Check field value formats (dates, emails, etc.)

4. **500 Server Error:**
   - Didit service may be down
   - Check Didit status page
   - Retry after a few seconds

## Debugging Tips

1. **Enable logging in your app:**
   ```dart
   // Add this to see API requests/responses
   print('Didit API Request: $requestBody');
   print('Didit API Response: ${response.body}');
   ```

2. **Check configuration:**
   ```dart
   final status = VerificationService.instance.getConfigurationStatus();
   print('Config status: $status');
   ```

3. **Test connectivity:**
   ```dart
   final isWorking = await VerificationService.instance.testConfiguration();
   print('Didit API working: $isWorking');
   ```

## Updating API Integration

If Didit updates their API:

1. Check [Didit API Changelog](https://docs.didit.me/changelog)
2. Update endpoint URLs in `verification_service.dart`
3. Update request/response parsing
4. Test thoroughly before deploying


