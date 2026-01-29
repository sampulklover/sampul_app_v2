# AI Resource Management Feature

## Overview
This feature allows administrators to manage reference links, knowledge base files, and context resources that the AI should prioritize when answering user questions. This follows common industry practices for managing AI/chatbot systems.

## Features Added

### 1. Reference Links
- **Purpose**: Links to documentation, articles, or online resources that the AI should prioritize
- **Fields**:
  - URL (required)
  - Title (required)
  - Description (optional)
- **Usage**: AI will be instructed to prioritize these sources when answering questions

### 2. Knowledge Base Files
- **Purpose**: Documents, PDFs, or files containing important information
- **Fields**:
  - URL (required)
  - Title (required)
  - Type (optional, e.g., 'pdf', 'doc', 'webpage')
  - Description (optional)
- **Usage**: AI will reference these files when providing information

### 3. Context Resources
- **Purpose**: Additional context text that helps the AI understand domain-specific information
- **Format**: Free-form text field
- **Usage**: Provides background information, guidelines, or important context

## Database Changes

### New Columns in `ai_chat_settings` Table
```sql
reference_links JSONB DEFAULT '[]'::jsonb
knowledge_base_files JSONB DEFAULT '[]'::jsonb
context_resources TEXT
```

### Data Structure

**Reference Links** (JSONB array):
```json
[
  {
    "url": "https://example.com/article",
    "title": "Estate Planning Guide",
    "description": "Comprehensive guide to estate planning"
  }
]
```

**Knowledge Base Files** (JSONB array):
```json
[
  {
    "url": "https://example.com/document.pdf",
    "title": "Legal Requirements",
    "type": "pdf",
    "description": "Legal requirements for wills"
  }
]
```

## Implementation Details

### Model Updates
- Added `ReferenceLink` class with URL, title, and description
- Added `KnowledgeBaseFile` class with URL, title, type, and description
- Added `getResourcesContext()` method to format resources for AI prompts

### Service Updates
- `createSettings()` and `updateSettings()` now accept resource parameters
- Resources are stored as JSONB arrays in Supabase

### OpenRouter Service Updates
- System prompt is enhanced with resources context
- Resources are automatically included in AI prompts
- Format: Resources are appended to system prompt with clear sections

### Admin UI Updates
- **Reference Links Section**: 
  - Add/Edit/Delete reference links
  - Shows list of all reference links
  - Form validation for required fields
  
- **Knowledge Base Files Section**:
  - Add/Edit/Delete knowledge base files
  - Shows list with file type badges
  - Form validation for required fields
  
- **Context Resources Section**:
  - Multi-line text field for additional context
  - Optional field

## How It Works

1. **Admin adds resources** through the admin settings screen
2. **Resources are stored** in the database as JSONB arrays
3. **When AI responds**, the system:
   - Fetches active settings from database
   - Formats resources using `getResourcesContext()`
   - Appends resources to system prompt
   - AI receives enhanced prompt with resource context

### Example Enhanced Prompt

```
[Original System Prompt]

Reference Links (prioritize these sources):
- Estate Planning Guide: https://example.com/article - Comprehensive guide to estate planning
- Legal Requirements: https://example.com/legal - Legal requirements for wills

Knowledge Base Files:
- Legal Requirements Guide (https://example.com/document.pdf) [PDF] - Legal requirements for wills

Additional Context:
When discussing wills, always mention the importance of legal verification.
Ensure users understand the difference between hibah and wasiat.
```

## Common Industry Practices Implemented

1. **Resource Prioritization**: AI is explicitly told to prioritize certain sources
2. **Knowledge Base Integration**: Structured way to reference important documents
3. **Context Enhancement**: Additional domain-specific context for better responses
4. **Admin Management**: Easy-to-use interface for managing resources
5. **Dynamic Updates**: Changes take effect immediately without code deployment

## Usage Examples

### Adding a Reference Link
1. Go to Settings → AI Chat Settings (admin only)
2. Scroll to "Resource Management" section
3. Click "+" button in Reference Links card
4. Fill in:
   - Title: "Malaysian Estate Law"
   - URL: "https://example.com/malaysian-law"
   - Description: "Official Malaysian estate planning laws"
5. Save

### Adding a Knowledge Base File
1. In Knowledge Base Files section, click "+"
2. Fill in:
   - Title: "Will Template"
   - URL: "https://example.com/template.pdf"
   - Type: "pdf"
   - Description: "Standard will template"
3. Save

### Adding Context Resources
1. Scroll to "Additional Context Resources"
2. Enter text like:
   ```
   Important: Always remind users that wills must be verified.
   Hibah is different from wasiat - hibah is immediate transfer.
   Users should consult with legal professionals for complex cases.
   ```
3. Save

## Benefits

1. **Better AI Responses**: AI has access to prioritized resources
2. **Easy Updates**: Admins can update resources without code changes
3. **Structured Management**: Clear organization of reference materials
4. **Scalable**: Can add unlimited resources
5. **Website Compatible**: Same database structure works for web admin panel

## Future Enhancements

- Resource validation (check if URLs are accessible)
- Resource categories/tags
- Resource usage analytics
- Bulk import/export
- Resource versioning
- Preview resources in admin panel
- Test resources before activation
