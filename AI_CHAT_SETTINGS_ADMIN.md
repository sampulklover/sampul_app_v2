# AI Chat Settings Admin Feature

## Overview
This feature allows administrators to manage AI chat settings for Sampul AI, enabling them to customize system prompts, welcome messages, and AI parameters (temperature, max tokens, model) directly from the app or website.

## Implementation

### Database Setup
1. **Table**: `ai_chat_settings`
   - Stores AI chat configuration settings
   - Includes system prompt, max tokens, temperature, model, welcome message
   - Supports multiple settings with active/inactive status
   - SQL migration file: `ai_chat_settings_setup.sql`

### Components Created

#### 1. Model (`lib/models/ai_chat_settings.dart`)
   - Data model for AI chat settings
   - Includes JSON serialization/deserialization

#### 2. Service (`lib/services/ai_chat_settings_service.dart`)
   - Manages fetching and updating AI chat settings
   - Caches active settings for performance (5-minute cache)
   - Provides methods for:
     - Getting active settings (for app usage)
     - Getting all settings (admin only)
     - Creating new settings (admin only)
     - Updating settings (admin only)
     - Deleting settings (admin only)

#### 3. Admin Utility (`lib/utils/admin_utils.dart`)
   - Checks if current user is an admin
   - Queries the `roles` table to verify admin status

#### 4. Admin Screen (`lib/screens/admin_ai_settings_screen.dart`)
   - Full-featured admin interface for managing AI settings
   - Form fields for:
     - System Prompt (multi-line text)
     - Welcome Message (multi-line text)
     - Max Tokens (1-4000)
     - Temperature (0-2)
     - Model (optional, overrides environment default)
   - Shows active settings status
   - Only accessible to admin users

### Updated Components

#### 1. OpenRouter Service (`lib/services/openrouter_service.dart`)
   - Now uses dynamic settings from database instead of hardcoded values
   - Fetches active settings for each request
   - Falls back to environment variables if database settings unavailable

#### 2. Chat Screens
   - `enhanced_chat_conversation_screen.dart`: Uses dynamic welcome message
   - `main_shell.dart`: Uses dynamic welcome message when creating AI conversation
   - `chat_list_screen.dart`: Uses dynamic welcome message when creating AI conversation

#### 3. Settings Screen (`lib/screens/settings_screen.dart`)
   - Added "AI Chat Settings" menu item (admin only)
   - Checks admin status on load
   - Only shows admin menu to users with admin role

## Security

### Row Level Security (RLS)
- **Public Read**: Anyone can read active settings (needed for app functionality)
- **Admin Only**: Only admins can:
  - Read all settings (including inactive)
  - Create new settings
  - Update settings
  - Delete settings

### Admin Verification
- Uses `roles` table to verify admin status
- Admin check performed both in database (RLS) and app (AdminUtils)
- Non-admin users cannot access admin screens

## Usage

### For Admins (In App)
1. Open Settings screen
2. Navigate to "Preferences" section
3. Tap "AI Chat Settings" (only visible to admins)
4. Edit settings as needed:
   - System Prompt: Defines AI personality and behavior
   - Welcome Message: Initial message shown to users
   - Max Tokens: Response length limit (1-4000)
   - Temperature: Creativity level (0-2, higher = more creative)
   - Model: Optional model override
5. Tap "Save Settings" to apply changes

### For Website (Future Implementation)
- The same database table and service can be used
- Website admin panel can call the same Supabase endpoints
- Settings are shared between app and website

## Database Migration

To set up the database, run the SQL migration:
```sql
-- Run: ai_chat_settings_setup.sql
```

This will:
1. Create the `ai_chat_settings` table
2. Set up RLS policies
3. Insert default settings
4. Create triggers for automatic timestamp updates

## Testing

### Admin Access
1. Ensure your user has `role = 'admin'` in the `roles` table
2. Open Settings screen
3. Verify "AI Chat Settings" appears in Preferences section
4. Open and test editing settings

### Non-Admin Access
1. Use a non-admin account
2. Verify "AI Chat Settings" does NOT appear in Settings
3. Verify direct navigation to admin screen shows access denied

### Settings Application
1. Change welcome message as admin
2. Create new AI conversation
3. Verify new welcome message appears
4. Send a message to AI
5. Verify AI uses new system prompt

## Notes

- Settings are cached for 5 minutes for performance
- Only one active setting should exist at a time
- Changes take effect immediately for new conversations
- Existing conversations may still use old welcome messages (stored in database)
- Model override is optional - if not set, uses `OPENROUTER_MODEL` from environment

## Future Enhancements

- Version history for settings changes
- A/B testing support (multiple active settings)
- Preview mode for testing settings before activation
- Analytics on settings performance
- Bulk settings management
- Settings templates/presets
