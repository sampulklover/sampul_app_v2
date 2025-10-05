# Supabase Setup Guide

This guide will help you set up Supabase for your Flutter app.

## 1. Create a Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Sign up or log in to your account
3. Click "New Project"
4. Choose your organization
5. Enter project details:
   - Name: `sampul_app_v2` (or your preferred name)
   - Database Password: Choose a strong password
   - Region: Choose the closest region to your users
6. Click "Create new project"

## 2. Get Your Project Credentials

1. In your Supabase dashboard, go to **Settings** → **API**
2. Copy the following values:
   - **Project URL** (looks like: `https://your-project-id.supabase.co`)
   - **anon public** key (starts with `eyJ...`)

## 3. Configure Your Flutter App

1. Open `lib/config/supabase_config.dart`
2. Replace the placeholder values with your actual credentials:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://your-project-id.supabase.co';
  static const String supabaseAnonKey = 'eyJ...your-actual-anon-key';
}
```

## 4. Set Up Authentication (Optional)

If you want to use Google Sign-In:

1. In your Supabase dashboard, go to **Authentication** → **Providers**
2. Enable **Google** provider
3. Add your Google OAuth credentials:
   - Client ID
   - Client Secret
4. Add your app's redirect URLs

## 5. Create Database Tables (Optional)

You can create tables in the Supabase dashboard:

1. Go to **Table Editor**
2. Click "Create a new table"
3. Example table for user profiles:

```sql
CREATE TABLE user_profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## 6. Install Dependencies

Run the following command in your project directory:

```bash
flutter pub get
```

## 7. Test the Integration

The app is now configured to use Supabase! You can:

- Sign up new users with email/password
- Sign in existing users
- Use Google Sign-In (if configured)
- Store and retrieve data from your database
- Use Supabase Storage for files

## Security Notes

- Never commit your actual Supabase credentials to version control
- Consider using environment variables for production
- The `anon` key is safe to use in client-side code
- Use Row Level Security (RLS) policies in Supabase for data protection

## Next Steps

- Set up Row Level Security policies in Supabase
- Create your database schema
- Implement your app's specific features using Supabase
- Test authentication flows
- Set up proper error handling
