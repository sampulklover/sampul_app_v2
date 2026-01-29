# AI Chat Features Documentation

## Overview
This document covers all AI chat features implemented in the Sampul app, including admin management, resource management, action buttons, and user experience enhancements.

---

## Table of Contents
1. [AI Chat Settings Management](#ai-chat-settings-management)
2. [Resource Management](#resource-management)
3. [Action Buttons System](#action-buttons-system)
4. [Admin UI Enhancements](#admin-ui-enhancements)
5. [User Experience Features](#user-experience-features)
6. [Technical Implementation](#technical-implementation)
7. [Testing Guide](#testing-guide)

---

## AI Chat Settings Management

### Purpose
Allows admins to dynamically manage AI chat behavior without code changes. Settings are stored in the database and applied in real-time.

### Features
- **System Prompt**: Customize AI personality and behavior
- **Max Tokens**: Control response length (100-1200 tokens)
- **Temperature**: Control creativity/consistency (0.0-1.5)
- **Model**: Override default AI model
- **Welcome Message**: Custom initial message for users
- **Resources**: Knowledge base files and reference links
- **Context Resources**: Additional context text for AI

### Database Schema
**Table**: `ai_chat_settings`
- `id` (UUID, Primary Key)
- `system_prompt` (TEXT)
- `max_tokens` (INTEGER, default: 220)
- `temperature` (NUMERIC, default: 0.5)
- `model` (TEXT, nullable)
- `welcome_message` (TEXT)
- `resources` (JSONB, default: [])
- `context_resources` (TEXT, nullable)
- `is_active` (BOOLEAN, default: true)
- `created_by`, `created_at`, `updated_by`, `updated_at`

### Access Control
- **Admin Only**: Settings management screen is only visible to admins
- **RLS Policies**: Row-level security ensures only admins can modify settings
- **Public Read**: All users can read active settings (for AI responses)

### Default Values
- **Max Tokens**: 220 (Medium-Short responses)
- **Temperature**: 0.5 (Balanced creativity)
- **System Prompt**: Pre-configured estate planning assistant prompt

---

## Resource Management

### Purpose
Provide AI with external knowledge sources (documents, links, articles) to enhance response quality and accuracy.

### Resource Types
Resources are stored as JSONB arrays with the following structure:
```json
{
  "url": "https://example.com/article",
  "title": "Estate Planning Guide",
  "description": "Comprehensive guide to estate planning",
  "type": "article"
}
```

### Supported Types
- `link` - Web links/articles
- `pdf` - PDF documents
- `doc` - Word documents
- `article` - Articles/blog posts
- `webpage` - Web pages

### How It Works
1. Admin adds resources through admin settings screen
2. Resources are stored in database as JSONB array
3. When AI responds, resources are formatted and appended to system prompt
4. AI prioritizes information from these resources

### Resource Context Format
```
Knowledge Base Resources (prioritize these sources):
- Estate Planning Guide: https://example.com/article [ARTICLE] - Comprehensive guide
- Legal Requirements: https://example.com/legal [PDF] - Legal requirements for wills
```

---

## Action Buttons System

### Purpose
Automatically detect when AI mentions features and show clickable buttons for quick navigation.

### How It Works

#### Method 1: Structured Markers (Primary)
AI includes action markers in responses using format: `[ACTION:route:label]`

**Format:**
- `[ACTION:route:label]` - Custom label
- `[ACTION:route]` - Uses default label

**Examples:**
- `[ACTION:trust_create:Create Trust Fund]`
- `[ACTION:add_asset:Tambah Aset]`
- `[ACTION:hibah_management]`

**Process:**
1. AI includes markers in response
2. System parses markers and creates buttons
3. Markers are removed from displayed text (hidden from users)
4. Buttons appear below AI message

#### Method 2: Keyword Detection (Fallback)
If AI doesn't use markers, system detects keywords in multiple languages:

**English Keywords:**
- "create trust" → `trust_create`
- "add asset" → `add_asset`
- "view hibah" → `hibah_management`

**Malay Keywords:**
- "cipta amanah" → `trust_create`
- "tambah aset" → `add_asset`
- "lihat hibah" → `hibah_management`

### Supported Routes
| Route | Default Label | Screen |
|-------|--------------|--------|
| `trust_create` | Create Trust Fund | TrustCreateScreen |
| `trust_management` | View Trust Funds | TrustManagementScreen |
| `hibah_management` | View Hibah | HibahManagementScreen |
| `will_management` | View Will | WillManagementScreen |
| `add_asset` | Add Asset | AddAssetScreen |
| `assets_list` | View Assets | AssetsListScreen |
| `add_family` | Add Family Member | AddFamilyMemberScreen |
| `family_list` | View Family | FamilyListScreen |
| `executor_management` | Manage Executors | ExecutorManagementScreen |
| `checklist` | View Checklist | ChecklistScreen |
| `extra_wishes` | Extra Wishes | ExtraWishesScreen |

### Language Support
- **Structured Markers**: Works in any language (AI includes markers)
- **Keyword Detection**: Supports English and Malay
- **Button Labels**: Can be customized in any language

### Implementation Details
- **Detection**: `AiActionDetector.detectActions(message)`
- **Display**: Buttons appear only for AI messages (not user messages)
- **Styling**: Uses primary container color with icons
- **Navigation**: Direct navigation to relevant screens

---

## Admin UI Enhancements

### Dropdown Interface
Replaced text input fields with user-friendly dropdowns for non-technical admins.

#### Response Length (Max Tokens)
| Option | Tokens | Description |
|--------|--------|-------------|
| Short | 100 | Very brief responses |
| Medium-Short | 200 | Concise answers |
| Medium | 300 | Balanced length |
| Medium-Long | 500 | Detailed responses |
| Long | 800 | Comprehensive answers |
| Very Long | 1200 | Extensive explanations |

#### Response Style (Temperature)
| Option | Value | Description |
|--------|-------|-------------|
| Very Consistent | 0.0 | Same response every time |
| Consistent | 0.3 | Mostly the same |
| Balanced | 0.5 | Good balance |
| Creative | 0.7 | More varied responses |
| Very Creative | 1.0 | Highly varied |
| Extremely Creative | 1.5 | Maximum variation |

### Benefits
- No technical knowledge required
- Clear descriptions for each option
- Prevents invalid values
- Better UX for admins

---

## User Experience Features

### Disclaimer
Small disclaimer below chat input field:
- **Text**: "Sampul AI can make mistakes. Check important info."
- **Style**: Centered, small text with info icon
- **Purpose**: Set expectations about AI accuracy

### Welcome Message
- Dynamic welcome message from database
- Customizable by admin
- Shown when users start a new conversation

### Message Features
- **Copy**: Copy message text
- **Regenerate**: Regenerate AI response
- **Action Buttons**: Quick navigation buttons (when relevant)
- **Markdown Support**: Rich text formatting for AI responses

---

## Technical Implementation

### Key Files

#### Models
- `lib/models/ai_chat_settings.dart` - Settings data model
- `lib/models/ai_resource.dart` - Resource data model (within ai_chat_settings.dart)

#### Services
- `lib/services/ai_chat_settings_service.dart` - CRUD operations for settings
- `lib/services/ai_action_detector.dart` - Action button detection
- `lib/services/openrouter_service.dart` - AI API integration

#### Screens
- `lib/screens/admin_ai_settings_screen.dart` - Admin settings UI
- `lib/screens/enhanced_chat_conversation_screen.dart` - Chat interface

#### Database
- `ai_chat_settings_setup.sql` - Database schema and migrations

### Data Flow

#### Settings Loading
```
User opens chat → OpenRouterService.sendMessage()
  → AiChatSettingsService.getActiveSettings()
  → Fetch from Supabase (with 5min cache)
  → Apply settings to API request
```

#### Action Detection
```
AI responds → EnhancedChatConversationScreen receives message
  → AiActionDetector.detectActions(message.content)
  → Parse [ACTION:route:label] markers
  → Create button widgets
  → Display below message
```

#### Resource Context
```
Admin saves settings → Resources stored in database
  → AiChatSettings.getResourcesContext()
  → Format resources as text
  → Append to system prompt
  → Send to AI API
```

### Caching Strategy
- **Settings Cache**: 5 minutes
- **Purpose**: Reduce database queries
- **Invalidation**: On settings update

### Security
- **RLS Policies**: Database-level access control
- **Admin Check**: `AdminUtils.isAdmin()` for UI access
- **Public Read**: Active settings readable by all users
- **Admin Write**: Only admins can modify settings

---

## Testing Guide

### Testing Action Buttons

#### Test Structured Markers
1. Ask AI: "How do I create a trust fund?"
2. Check AI response includes: `[ACTION:trust_create:Create Trust Fund]`
3. Verify button appears below message
4. Verify markers are hidden from display
5. Click button → Should navigate to Trust Create screen

#### Test Keyword Detection (Fallback)
1. Ask AI: "I want to create a trust" (without markers)
2. System should detect keyword "create trust"
3. Button should appear automatically

#### Test Multiple Languages
- **English**: "create trust" → Button appears
- **Malay**: "cipta amanah" → Button appears
- **Custom Label**: `[ACTION:trust_create:Cipta Amanah]` → Custom label shown

### Testing Settings

#### Test Max Tokens
1. Set Max Tokens to 50
2. Ask AI a question
3. Response should be very short (cut off around 50 tokens)
4. Set Max Tokens to 500
5. Ask same question
6. Response should be much longer

#### Test Temperature
1. Set Temperature to 0.0
2. Ask same question multiple times
3. Responses should be nearly identical
4. Set Temperature to 1.5
5. Ask same question multiple times
6. Responses should vary significantly

### Testing Resources
1. Add resource in admin settings
2. Ask AI question related to resource
3. AI should reference resource information
4. Check console logs for resource context

### Debug Checklist
- [ ] Settings load correctly
- [ ] Action buttons appear when expected
- [ ] Markers are hidden from display
- [ ] Navigation works correctly
- [ ] Resources are included in prompts
- [ ] Cache refreshes after updates
- [ ] Admin-only access works
- [ ] Disclaimer displays correctly

---

## Common Issues & Solutions

### Action Buttons Not Appearing
**Problem**: Buttons don't show up
**Solutions**:
1. Check AI response includes `[ACTION:...]` markers
2. Verify route names match exactly
3. Check console for errors
4. Ensure system prompt includes action button instructions

### Settings Not Applying
**Problem**: Changes don't take effect
**Solutions**:
1. Clear cache (wait 5 minutes or restart app)
2. Verify `is_active = true` in database
3. Check console logs for settings values
4. Verify RLS policies allow read access

### Invalid Route Error
**Problem**: Button shows but navigation fails
**Solutions**:
1. Verify route name matches supported routes exactly
2. Check screen imports in enhanced_chat_conversation_screen.dart
3. Verify navigation code handles all routes

---

## Best Practices

### For Admins
1. **Start Conservative**: Use Medium (300 tokens) and Balanced (0.5) initially
2. **Test Changes**: Test settings changes before deploying to production
3. **Monitor Responses**: Check if responses match expectations
4. **Update Resources**: Keep knowledge base resources up to date
5. **Use Action Markers**: Train AI to use structured markers for better UX

### For Developers
1. **Add New Routes**: Update `AiActionDetector` when adding new features
2. **Update Documentation**: Keep this doc updated with changes
3. **Test Thoroughly**: Test in multiple languages
4. **Monitor Performance**: Watch for cache hits/misses
5. **Security First**: Always verify admin access before modifications

---

## Future Enhancements

### Potential Improvements
1. **Action Analytics**: Track which actions are most used
2. **Custom Actions**: Allow admins to define custom action buttons
3. **Multi-language Keywords**: Expand keyword detection to more languages
4. **Action Templates**: Pre-defined action templates for common scenarios
5. **A/B Testing**: Test different settings configurations
6. **Response Feedback**: User feedback on action button usefulness

---

## Version History

### v1.0 (Current)
- ✅ AI Chat Settings Management
- ✅ Resource Management (Knowledge Base)
- ✅ Action Buttons System
- ✅ Dropdown UI for Max Tokens/Temperature
- ✅ Disclaimer Feature
- ✅ Multi-language Support (English/Malay)
- ✅ Admin-only Access Control

---

## Support & Maintenance

### Database Maintenance
- Run `ai_chat_settings_setup.sql` for initial setup
- Script is idempotent (safe to run multiple times)
- Includes RLS policies and indexes

### Code Maintenance
- Settings service handles caching automatically
- Action detector is extensible for new routes
- All settings are stored in database (no hardcoded values)

### Monitoring
- Check console logs for settings application
- Monitor cache hit rates
- Track action button usage (future feature)

---

## Contact & Resources

### Related Documentation
- `AI_RESOURCE_MANAGEMENT.md` - Resource management details
- `ai_chat_settings_setup.sql` - Database schema

### Key Classes
- `AiChatSettings` - Settings model
- `AiResource` - Resource model
- `AiActionDetector` - Action detection service
- `AiChatSettingsService` - Settings CRUD service
- `OpenRouterService` - AI API integration

---

**Last Updated**: 2024
**Maintained By**: Development Team
