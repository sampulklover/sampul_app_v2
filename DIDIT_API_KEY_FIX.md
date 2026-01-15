# Didit API Authentication Fix

## Problem Identified

Based on console logs and [Didit API documentation](https://docs.didit.me/reference/create-session-verification-sessions), the issue was:

### Console Output Analysis
```
flutter: 🟡 [DIDIT API] Trying endpoint: https://verification.didit.me/v2/session/ (method: verification_v2)
flutter: 🟡 [DIDIT API] X-Client-Id/X-Client-Secret - Status: 403
flutter: 🟡 [DIDIT API] X-Client-Id/X-Client-Secret - Body: {"detail":"You do not have permission to perform this action."}
```

**The endpoint is correct**, but the **authentication method was wrong**.

## Root Cause

The app was using `X-Client-Id` and `X-Client-Secret` headers (or Basic Auth), but according to the [Didit API documentation](https://docs.didit.me/reference/create-session-verification-sessions), the correct authentication method is:

```
x-api-key: YOUR_API_KEY
```

## Solution

### 1. Updated `lib/config/didit_config.dart`

Changed from Client ID/Secret authentication to API key authentication:

```dart
/// Didit Client ID (matches NEXT_PUBLIC_DIDIT_CLIENT_ID from website)
/// For API calls, this is used as the API key
static String get clientId => dotenv.env['DIDIT_CLIENT_ID'] ?? 
                               dotenv.env['NEXT_PUBLIC_DIDIT_CLIENT_ID'] ?? 
                               dotenv.env['DIDIT_API_KEY'] ?? '';

/// Didit API Key (same as Client ID for most cases)
static String get apiKey => dotenv.env['DIDIT_API_KEY'] ?? 
                            dotenv.env['DIDIT_CLIENT_ID'] ?? 
                            dotenv.env['NEXT_PUBLIC_DIDIT_CLIENT_ID'] ?? '';

/// Check if Didit is properly configured
static bool get isConfigured => apiKey.isNotEmpty;
```

### 2. Updated `lib/services/verification_service.dart`

Simplified the API call to use only the documented `x-api-key` authentication:

```dart
Future<String> _createDiditVerificationLink({
  required String sessionId,
  Map<String, dynamic>? userData,
}) async {
  print('🟡 [DIDIT API] Creating verification session...');
  print('🟡 [DIDIT API] Using endpoint: ${DiditConfig.verificationUrl}/v2/session/');
  
  // Build request body for Didit v2 API
  // Per documentation: https://docs.didit.me/reference/create-session-verification-sessions
  final Map<String, dynamic> requestBody = {
    'redirect_url': DiditConfig.redirectUrl,
    if (userData != null) ...userData, // Spread user data directly
  };
  
  // Use x-api-key authentication (per Didit docs)
  final Map<String, String> headers = {
    'Content-Type': 'application/json',
    'x-api-key': DiditConfig.apiKey,
  };
  
  try {
    final String url = '${DiditConfig.verificationUrl}/v2/session/';
    print('🟡 [DIDIT API] Making POST request to: $url');
    
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(requestBody),
    );

    print('🟡 [DIDIT API] Response status: ${response.statusCode}');
    print('🟡 [DIDIT API] Response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('🟢 [DIDIT API] Success!');
      final Map<String, dynamic> data = jsonDecode(response.body);
      
      // Extract session URL from response
      final String? sessionUrl = data['url'] as String? ?? 
                                 data['session_url'] as String? ??
                                 data['verification_url'] as String?;
      
      if (sessionUrl != null) {
        print('🟢 [DIDIT API] Got session URL: $sessionUrl');
        return sessionUrl;
      }
      
      // If no URL in response, construct it from session ID
      final String? sessionId = data['id'] as String? ?? 
                               data['session_id'] as String?;
      if (sessionId != null) {
        final constructedUrl = '${DiditConfig.verificationUrl}/$sessionId';
        print('🟢 [DIDIT API] Constructed URL from session ID: $constructedUrl');
        return constructedUrl;
      }
      
      throw Exception('No verification URL in response: ${response.body}');
    } else {
      throw Exception(
        'Failed to create verification session: ${response.statusCode} - ${response.body}'
      );
    }
  } catch (e, stackTrace) {
    print('🔴 [DIDIT API] Exception occurred: $e');
    print('🔴 [DIDIT API] Stack trace: $stackTrace');
    throw Exception('Error creating Didit verification session: $e');
  }
}
```

### 3. Updated `.ENV.example`

Added clarification that `DIDIT_CLIENT_ID` is the API key:

```env
# Didit Verification Configuration (matches website format)
# Get your API key from https://console.didit.me
# Note: DIDIT_CLIENT_ID is your API key (used in x-api-key header)
DIDIT_URL=https://apx.didit.me
DIDIT_VERIFICATION_URL=https://verification.didit.me
DIDIT_CLIENT_ID=your_api_key_here
DIDIT_CLIENT_SECRET=
DIDIT_WEBHOOK_SECRET_KEY=
DIDIT_REDIRECT_URL=sampul://verification/complete
```

## Configuration

### Your `.env` File Should Look Like:

```env
DIDIT_URL=https://apx.didit.me
DIDIT_VERIFICATION_URL=https://verification.didit.me
DIDIT_CLIENT_ID=sFTia127939129312  # This is your API key
DIDIT_CLIENT_SECRET=5P6jMWqu-ID_P7nWsdaihbchasbdcasdc  # May not be needed
DIDIT_WEBHOOK_SECRET_KEY=your_webhook_secret  # For webhook validation
DIDIT_REDIRECT_URL=sampul://verification/complete
```

**Important**: The `DIDIT_CLIENT_ID` value is what gets sent in the `x-api-key` header. This matches how your website uses `NEXT_PUBLIC_DIDIT_CLIENT_ID`.

## API Endpoint

According to [Didit's documentation](https://docs.didit.me/reference/create-session-verification-sessions), the correct endpoint is:

```
POST https://verification.didit.me/v2/session/
```

**Headers:**
```
Content-Type: application/json
x-api-key: YOUR_API_KEY
```

**Request Body:**
```json
{
  "redirect_url": "sampul://verification/complete",
  "email": "user@example.com",
  "name": "User Name",
  "phone": "1234567890"
}
```

**Response:**
```json
{
  "id": "session_id",
  "url": "https://verification.didit.me/session_id",
  ...
}
```

## Testing

1. **Update your `.env` file** with your actual API key in `DIDIT_CLIENT_ID`
2. **Restart the app** to load the new environment variables
3. **Click "Identity Verification"** button
4. **Check console logs** - you should see:
   ```
   flutter: 🟡 [DIDIT API] Making POST request to: https://verification.didit.me/v2/session/
   flutter: 🟡 [DIDIT API] Response status: 200
   flutter: 🟢 [DIDIT API] Success!
   flutter: 🟢 [DIDIT API] Got session URL: https://verification.didit.me/...
   ```

## Expected Flow

1. User clicks "Identity Verification" in settings
2. App creates a session via Didit API
3. App receives a verification URL
4. User is redirected to Didit's verification page (in external browser or WebView)
5. User completes verification
6. Didit redirects back to `sampul://verification/complete`
7. App handles the deep link and updates verification status

## Troubleshooting

### If you still get 403 errors:

1. **Check your API key** - Make sure `DIDIT_CLIENT_ID` in `.env` matches your API key from [Didit Console](https://console.didit.me)
2. **Restart the app** - Environment variables are loaded at startup
3. **Check Didit Console** - Make sure your API key has the right permissions

### If you get 404 errors:

The endpoint should be correct now (`https://verification.didit.me/v2/session/`), but if you still get 404:
- Check if Didit has updated their API
- Refer to the latest [Didit API documentation](https://docs.didit.me/reference/introduction)

## References

- [Didit Create Session API](https://docs.didit.me/reference/create-session-verification-sessions)
- [Didit iOS & Android Integration](https://docs.didit.me/reference/ios-android)
- [Didit API Authentication](https://docs.didit.me/reference/api-authentication)

