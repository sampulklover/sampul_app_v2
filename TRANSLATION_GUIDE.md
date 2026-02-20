# Translation Guide

This app uses Flutter's built-in internationalization (i18n) support for translations.

## Setup

The translation system is already configured with:
- **English (en)** - Default language
- **Malay (ms)** - Secondary language

## How to Use Translations

### 1. Import the Localizations

In any widget file where you need translations, import:

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
```

### 2. Get the Localizations Instance

In your widget's `build` method:

```dart
@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  
  return Scaffold(
    appBar: AppBar(
      title: Text(l10n.login), // Use l10n.keyName
    ),
    // ...
  );
}
```

### 3. Using Translations

Replace hardcoded strings with translation keys:

**Before:**
```dart
Text('Welcome back')
```

**After:**
```dart
Text(l10n.welcomeBack)
```

### 4. Translations with Parameters

For translations that include dynamic values:

**In ARB file:**
```json
{
  "signInFailedWithError": "Sign in failed: {error}",
  "@signInFailedWithError": {
    "placeholders": {
      "error": {
        "type": "String"
      }
    }
  }
}
```

**In code:**
```dart
Text(l10n.signInFailedWithError(errorMessage))
```

## Adding New Translations

### Step 1: Add to English ARB File

Edit `lib/l10n/app_en.arb` and add your new key:

```json
{
  "myNewKey": "My English Text",
  "@myNewKey": {
    "description": "Description of what this text is for"
  }
}
```

### Step 2: Add to Other Language Files

Add the same key to `lib/l10n/app_ms.arb` with the translated text:

```json
{
  "myNewKey": "Teks Bahasa Melayu Saya"
}
```

### Step 3: Regenerate Localization Files

Run:
```bash
flutter gen-l10n
```

Or the files will be automatically regenerated on the next build.

### Step 4: Use in Code

```dart
final l10n = AppLocalizations.of(context)!;
Text(l10n.myNewKey)
```

## Adding a New Language

1. Create a new ARB file: `lib/l10n/app_<locale>.arb` (e.g., `app_id.arb` for Indonesian)
2. Copy all keys from `app_en.arb` and translate the values
3. Update `main.dart` to include the new locale:

```dart
supportedLocales: const [
  Locale('en', ''), // English
  Locale('ms', ''), // Malay
  Locale('id', ''), // Indonesian (new)
],
```

4. Regenerate: `flutter gen-l10n`

## Current Translation Keys

The following keys are available (see `lib/l10n/app_en.arb` for the full list):

- Authentication: `login`, `welcomeBack`, `signInToContinue`, `email`, `password`, etc.
- Will: `aboutYourWill`, `letsCreateYourWill`, `willDescription`
- Assets: `letsListYourDigitalAssets`, `assetsDescription`
- Trust: `letsSetUpYourFamilyAccount`, `trustDescription`
- Hibah: `letsPlanYourHibahGifts`, `hibahDescription`
- Onboarding: `onboardingTitle1`, `onboardingSubtitle1`, etc.

## Example: Updated Login Screen

See `lib/screens/login_screen.dart` for a complete example of using translations throughout a screen.

## Notes

- Always use `AppLocalizations.of(context)!` to get the localization instance
- The `!` is safe because we've configured the app with supported locales
- Translations are type-safe - you'll get autocomplete and compile-time errors for missing keys
- The app will automatically use the device's language if supported, or fall back to English
