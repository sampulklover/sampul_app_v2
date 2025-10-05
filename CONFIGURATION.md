# Configuration Guide

This guide explains how to configure your Supabase URLs and other settings in the app.

## Supabase Configuration

All Supabase-related configuration is centralized in `lib/config/supabase_config.dart`.

### Quick Setup

1. Open `lib/config/supabase_config.dart`
2. Update the following values with your Supabase project details:

```dart
/// Your Supabase project URL
static const String supabaseUrl = 'https://your-project.supabase.co';

/// Your Supabase anonymous key
static const String supabaseAnonKey = 'your-anon-key-here';
```

### Where to Find Your Supabase Credentials

1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select your project
3. Go to **Settings** → **API**
4. Copy the following:
   - **Project URL** → Use for `supabaseUrl`
   - **anon public** key → Use for `supabaseAnonKey`

### Storage URLs

The storage URL is automatically generated from your `supabaseUrl`:
- **Storage URL**: `{supabaseUrl}/storage/v1/object/public`
- **Example**: `https://your-project.supabase.co/storage/v1/object/public`

### Image URL Construction

The app automatically constructs full image URLs from storage paths:

**Input (from database):**
```
46847b5e-ab58-42c7-bfcc-1efe5f97729c/avatar/profile/1753477993914-653184335.png
```

**Output (full URL):**
```
https://your-project.supabase.co/storage/v1/object/public/images/46847b5e-ab58-42c7-bfcc-1efe5f97729c/avatar/profile/1753477993914-653184335.png
```

### Environment Variables (Optional)

For production apps, you can use environment variables:

1. Create a `.env` file in your project root:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

2. Update `lib/config/supabase_config.dart` to use environment variables:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? 'https://your-project.supabase.co';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? 'your-fallback-key';
  
  static String get storageUrl => '$supabaseUrl/storage/v1/object/public';
}
```

3. Load the environment in `main.dart`:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  // ... rest of your main function
}
```

### Security Notes

- **Never commit** your `.env` file to version control
- Add `.env` to your `.gitignore` file
- Use different keys for development and production
- Consider using Supabase's Row Level Security (RLS) for additional protection

### Troubleshooting

**Images not loading?**
- Check that your `supabaseUrl` is correct
- Verify the storage bucket is set to public
- Ensure the image path in the database is correct

**Authentication issues?**
- Verify your `supabaseAnonKey` is correct
- Check that your Supabase project is active
- Ensure your authentication settings are configured properly
