# Didit Redirect URL Configuration

## Updated: Using Deep Link Instead of Web Page

The Didit redirect URL has been updated to use a **deep link** that returns users directly to your app after verification, instead of requiring a web page.

## Configuration

### Default Deep Link
```
sampul://verification/complete
```

This uses the same URL scheme (`sampul://`) that you already have configured for Stripe, so no additional setup is needed!

## How It Works

1. **User starts verification** in your app
2. **Opens Didit verification page** in browser
3. **Completes verification** on Didit
4. **Didit redirects** to `sampul://verification/complete`
5. **App automatically opens** and handles the deep link
6. **Verification status updates** in your database

## Environment Variable

In your `.env` file:

```env
DIDIT_REDIRECT_URL=sampul://verification/complete
```

**Note:** You can customize this URL if needed, but the default works with your existing deep link setup.

## Deep Link Already Configured ✅

Your app already has deep linking set up for:
- ✅ iOS: `ios/Runner/Info.plist` has `sampul` scheme
- ✅ Android: `android/app/src/main/AndroidManifest.xml` has `sampul` scheme
- ✅ Used by Stripe for payment returns

So Didit verification will work automatically!

## Optional: Handle Deep Link in App

If you want to automatically refresh verification status when the app opens from the deep link, you can add this to your `main.dart` or `MainShell`:

```dart
import 'package:uni_links/uni_links.dart';
import 'dart:async';

// In your widget's initState or main
StreamSubscription? _linkSubscription;

void _initDeepLinks() {
  // Handle initial link if app was opened from deep link
  getInitialLink().then((String? initialLink) {
    if (initialLink != null) {
      _handleDeepLink(initialLink);
    }
  });

  // Listen for deep links while app is running
  _linkSubscription = getUriLinksStream().listen(
    (Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri.toString());
      }
    },
    onError: (err) {
      print('Deep link error: $err');
    },
  );
}

void _handleDeepLink(String link) {
  if (link.contains('verification/complete')) {
    // Refresh verification status
    // You can navigate to settings or show a success message
    print('Verification completed!');
    // Optionally: Refresh verification status
    // VerificationService.instance.getUserVerificationStatus();
  }
}

// Don't forget to cancel subscription in dispose
@override
void dispose() {
  _linkSubscription?.cancel();
  super.dispose();
}
```

## Alternative: Use Your Website URL

If you prefer to redirect to a web page first, you can:

1. **Create a page** at `https://sampul.co/verification-complete` that:
   - Shows a success message
   - Has a button to "Open App"
   - Uses deep link: `sampul://verification/complete`

2. **Or use your existing website** and set:
   ```env
   DIDIT_REDIRECT_URL=https://sampul.co/some-existing-page
   ```

## Benefits of Deep Link

✅ **No web page needed** - Direct return to app  
✅ **Better UX** - Seamless flow  
✅ **Already configured** - Uses existing Stripe setup  
✅ **Automatic** - App opens immediately after verification  

## Testing

1. Start verification from Settings
2. Complete verification on Didit
3. App should automatically open
4. Check verification status in Settings

That's it! The deep link approach is simpler and provides a better user experience. 🎉

