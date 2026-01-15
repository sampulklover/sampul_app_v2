# Custom Asset Pattern Documentation

This document describes the pattern for allowing users to add custom/manual assets when they can't find what they're looking for in the search results.

## Overview

The custom asset feature allows users to manually add assets that aren't found in the Brandfetch API search results. This provides flexibility and ensures users can add any asset, even if it's not in the database.

## Database Schema

### Column: `is_custom`

A boolean flag in the `digital_assets` table that differentiates custom assets from Brandfetch assets.

```sql
ALTER TABLE public.digital_assets 
ADD COLUMN IF NOT EXISTS is_custom boolean DEFAULT false;
```

**Values:**
- `false` (default): Asset found via Brandfetch API search
- `true`: Asset manually added by user

**Migration:**
See `add_custom_asset_flag.sql` for the complete migration script.

## Implementation Pattern

### 1. State Management

Track whether the selected asset is custom:

```dart
bool _isCustomAsset = false;
```

**When user selects from search results:**
```dart
_isCustomAsset = false; // Brandfetch asset
```

**When user adds custom asset:**
```dart
_isCustomAsset = true; // Custom asset
```

### 2. UI Flow

#### Step 1: Search Interface

Show search field with results:

```
[Search Field: "Search for a platform or service"]
  ↓
[Search Results List]
  - Result 1
  - Result 2
  - Result 3
  ↓
[Add your own asset] ← Show this when:
                      - Search completed (!_isSearching)
                      - Query length >= 3 characters
                      - Regardless of whether results exist
```

#### Step 2: "Add Your Own" Option

Display the option when:
- Search has completed (`!_isSearching`)
- Search query is valid (length >= 3 characters)
- Show regardless of whether results were found

**UI Pattern:**
```dart
if (_showAddCustomOption && !_isSearching)
  ListTile(
    leading: const Icon(Icons.add_circle_outline, color: Colors.blue),
    title: const Text('Add your own asset'),
    subtitle: Text(
      _searchResults.isEmpty
          ? 'Use "${searchQuery}" as the asset name'
          : 'Can\'t find it? Add "${searchQuery}" as custom',
    ),
    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    onTap: () => _showCustomAssetDialog(),
  ),
```

**Key Points:**
- Always visible when search is complete (even with results)
- Different subtitle based on whether results exist
- Clear visual indication it's clickable (icon + arrow)
- Pre-fills search query as default name

#### Step 3: Custom Asset Dialog

When user taps "Add your own asset", show a dialog:

```dart
AlertDialog(
  title: const Text('Add Custom Asset'),
  content: Form(
    child: Column(
      children: [
        TextFormField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Asset Name *',
            hintText: 'e.g., My Custom Platform',
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
        TextFormField(
          controller: urlController,
          decoration: const InputDecoration(
            labelText: 'Website URL (optional)',
            hintText: 'https://example.com',
          ),
          keyboardType: TextInputType.url,
        ),
      ],
    ),
  ),
  actions: [
    TextButton(onPressed: cancel, child: Text('Cancel')),
    ElevatedButton(
      onPressed: () {
        if (form.validate()) {
          // Create custom asset
        }
      },
      child: Text('Add'),
    ),
  ],
)
```

**Fields:**
- **Asset Name** (required): Pre-filled with search query
- **Website URL** (optional): User can add URL if available

### 3. Data Persistence

#### 3.1. Brandfetch Asset Submission

When user selects an asset from Brandfetch search results:

**Step 1: User Selects Asset**
```dart
onTap: () async {
  setState(() {
    _brandInfo = item; // Selected Brandfetch result
    _isCustomAsset = false; // Mark as Brandfetch asset
    _assetNameController.text = item.name;
    _searchResults = []; // Clear results
  });
  
  // Optional: Enrich with detailed Brandfetch data
  try {
    final String domainOrName = item.websiteUrl.isNotEmpty 
        ? item.websiteUrl 
        : item.name;
    final BrandInfo? detailed = await BrandfetchService.instance
        .fetchByDomain(domainOrName);
    
    if (detailed != null) {
      // Merge enriched data with original selection
      final String mergedName = detailed.name.isNotEmpty 
          ? detailed.name 
          : item.name;
      final String mergedWebsite = detailed.websiteUrl.isNotEmpty 
          ? detailed.websiteUrl 
          : item.websiteUrl;
      final String? mergedLogo = detailed.logoUrl ?? item.logoUrl;
      
      setState(() {
        _brandInfo = BrandInfo(
          name: mergedName,
          websiteUrl: mergedWebsite,
          logoUrl: mergedLogo,
        );
      });
    }
  } catch (_) {
    // Keep original selection if enrichment fails
  }
}
```

**Step 2: Submit Brandfetch Asset**
```dart
Future<void> _submit() async {
  // Validation...
  
  final Map<String, dynamic> payload = {
    'uuid': user.id,
    'username': user.userMetadata?['username'] ?? user.email?.split('@').first,
    'email': user.email,
    'declared_value_myr': declaredValue,
    'instructions_after_death': instructions,
    'new_service_platform_name': _brandInfo!.name,
    'is_custom': false, // ← Brandfetch asset
    
    // Include Brandfetch details if available
    if (_brandInfo!.websiteUrl.isNotEmpty) {
      payload['new_service_platform_url'] = _brandInfo!.websiteUrl;
    }
    if ((_brandInfo!.logoUrl ?? '').isNotEmpty) {
      // Strip client ID from Brandfetch CDN URLs before storing
      payload['new_service_platform_logo_url'] = 
          BrandfetchService.instance.stripClientIdFromUrl(_brandInfo!.logoUrl);
    }
    
    // Optional fields
    if (instructions == 'transfer_as_gift') {
      payload['beloved_id'] = _selectedBelovedId;
    }
    if (remarks.isNotEmpty) {
      payload['remarks'] = remarks;
    }
  };
  
  await supabase.from('digital_assets').insert(payload);
}
```

**Key Points for Brandfetch Assets:**
- Set `is_custom: false` (or omit, defaults to false)
- Include `new_service_platform_logo_url` if available
- Include `new_service_platform_url` if available
- **Strip client ID** from Brandfetch logo URLs before storing (prevents expiration issues)
- Optionally enrich asset with detailed Brandfetch API call for better data

#### 3.3. Asset Enrichment (Optional)

When a user selects a Brandfetch asset from search results, you can optionally enrich it with more detailed data:

```dart
// After user selects from search results
try {
  final String domainOrName = selectedItem.websiteUrl.isNotEmpty 
      ? selectedItem.websiteUrl 
      : selectedItem.name;
  
  // Fetch detailed brand information
  final BrandInfo? detailed = await BrandfetchService.instance
      .fetchByDomain(domainOrName);
  
  if (detailed != null) {
    // Merge: prefer detailed data, fallback to search result
    final String mergedName = detailed.name.isNotEmpty 
        ? detailed.name 
        : selectedItem.name;
    final String mergedWebsite = detailed.websiteUrl.isNotEmpty 
        ? detailed.websiteUrl 
        : selectedItem.websiteUrl;
    final String? mergedLogo = detailed.logoUrl ?? selectedItem.logoUrl;
    
    // Update selected asset with enriched data
    setState(() {
      _brandInfo = BrandInfo(
        name: mergedName,
        websiteUrl: mergedWebsite,
        logoUrl: mergedLogo,
      );
    });
  }
} catch (_) {
  // If enrichment fails, keep original search result
  // This is non-critical, so we silently fail
}
```

**Enrichment Benefits:**
- More complete brand information
- Higher quality logos
- Better website URLs
- More accurate brand names

**Enrichment Considerations:**
- Non-blocking: If enrichment fails, use original search result
- Performance: Adds an extra API call, but improves data quality
- User Experience: Happens in background, user doesn't wait

#### 3.2. Custom Asset Submission

When user adds a custom asset:

```dart
final Map<String, dynamic> payload = {
  'uuid': user.id,
  'username': user.userMetadata?['username'] ?? user.email?.split('@').first,
  'email': user.email,
  'declared_value_myr': declaredValue,
  'instructions_after_death': instructions,
  'new_service_platform_name': assetName,
  'new_service_platform_url': websiteUrl, // optional, user-provided
  'new_service_platform_logo_url': null, // Always null for custom
  'is_custom': true, // ← Set flag here
  
  // Optional fields
  if (instructions == 'transfer_as_gift') {
    'beloved_id': _selectedBelovedId,
  },
  if (remarks.isNotEmpty) {
    'remarks': remarks,
  },
};

await supabase.from('digital_assets').insert(payload);
```

**Important:**
- Set `is_custom: true` for custom assets
- Set `is_custom: false` (or omit, defaults to false) for Brandfetch assets
- Custom assets always have `new_service_platform_logo_url: null`
- Brandfetch assets may have logo URL (must strip client ID)

### 4. Custom Asset Object Creation

When user confirms custom asset dialog:

```dart
BrandInfo customAsset = BrandInfo(
  name: nameController.text.trim(),
  websiteUrl: urlController.text.trim(),
  logoUrl: null, // No logo for custom assets
);

setState(() {
  _brandInfo = customAsset;
  _isCustomAsset = true; // Mark as custom
});
```

## Web Implementation Guide

### React/TypeScript Example

```typescript
// State
const [isCustomAsset, setIsCustomAsset] = useState(false);
const [selectedAsset, setSelectedAsset] = useState<BrandInfo | null>(null);
const [showAddCustomOption, setShowAddCustomOption] = useState(false);
const [searchResults, setSearchResults] = useState<BrandInfo[]>([]);
const [isSearching, setIsSearching] = useState(false);

// Search handler
const handleSearch = async (query: string) => {
  if (query.length < 3) {
    setShowAddCustomOption(false);
    return;
  }
  
  setIsSearching(true);
  try {
    const results = await searchBrands(query);
    setSearchResults(results);
    setShowAddCustomOption(true); // Always show option
  } catch (error) {
    setShowAddCustomOption(true); // Show even on error
  } finally {
    setIsSearching(false);
  }
};

// Select Brandfetch asset
const handleSelectBrandfetchAsset = async (item: BrandInfo) => {
  setIsCustomAsset(false);
  setSelectedAsset(item);
  
  // Optional: Enrich with detailed Brandfetch data
  try {
    const domainOrName = item.websiteUrl || item.name;
    const detailed = await fetchBrandByDomain(domainOrName);
    
    if (detailed) {
      // Merge enriched data
      setSelectedAsset({
        name: detailed.name || item.name,
        websiteUrl: detailed.websiteUrl || item.websiteUrl,
        logoUrl: detailed.logoUrl || item.logoUrl,
      });
    }
  } catch (error) {
    // Keep original selection if enrichment fails
    console.error('Failed to enrich asset:', error);
  }
};

// Custom asset creation
const handleAddCustom = async (name: string, url?: string) => {
  setIsCustomAsset(true);
  setSelectedAsset({
    name,
    websiteUrl: url || '',
    logoUrl: null,
  });
  // Continue with form...
};

// Save asset (works for both Brandfetch and custom)
const saveAsset = async (assetData: AssetData) => {
  const payload: any = {
    uuid: user.id,
    username: user.userMetadata?.username || user.email?.split('@')[0],
    email: user.email,
    declared_value_myr: assetData.declaredValue,
    instructions_after_death: assetData.instructions,
    new_service_platform_name: selectedAsset!.name,
    is_custom: isCustomAsset,
  };
  
  // Add Brandfetch-specific fields
  if (!isCustomAsset && selectedAsset) {
    if (selectedAsset.websiteUrl) {
      payload.new_service_platform_url = selectedAsset.websiteUrl;
    }
    if (selectedAsset.logoUrl) {
      // Strip client ID from Brandfetch CDN URLs
      payload.new_service_platform_logo_url = 
          stripClientIdFromUrl(selectedAsset.logoUrl);
    }
  } else if (isCustomAsset && selectedAsset) {
    // Custom asset: only include URL if provided
    if (selectedAsset.websiteUrl) {
      payload.new_service_platform_url = selectedAsset.websiteUrl;
    }
    // logo_url is always null for custom assets
  }
  
  // Optional fields
  if (assetData.instructions === 'transfer_as_gift') {
    payload.beloved_id = assetData.belovedId;
  }
  if (assetData.remarks) {
    payload.remarks = assetData.remarks;
  }
  
  await supabase.from('digital_assets').insert(payload);
};
```

### UI Component Structure

```tsx
<div>
  {/* Search Field */}
  <input
    type="text"
    placeholder="Search for a platform or service"
    onChange={(e) => handleSearch(e.target.value)}
  />
  
  {/* Loading Indicator */}
  {isSearching && <LoadingSpinner />}
  
  {/* Search Results */}
  {searchResults.length > 0 && (
    <ul>
      {searchResults.map((result) => (
        <li key={result.id} onClick={() => selectAsset(result)}>
          {result.name}
        </li>
      ))}
    </ul>
  )}
  
  {/* Add Custom Option */}
  {showAddCustomOption && !isSearching && (
    <div className="add-custom-option" onClick={() => showCustomDialog()}>
      <Icon name="add-circle-outline" />
      <div>
        <h4>Add your own asset</h4>
        <p>
          {searchResults.length === 0
            ? `Use "${searchQuery}" as the asset name`
            : `Can't find it? Add "${searchQuery}" as custom`}
        </p>
      </div>
      <Icon name="arrow-forward" />
    </div>
  )}
</div>
```

## Key Design Principles

### 1. Always Show Option
- Display "Add your own" even when results are found
- Users may not find what they want in the list
- Provides escape hatch for any search scenario

### 2. Pre-fill Search Query
- Use the search query as default asset name
- Saves user time and reduces typing
- User can still edit if needed

### 3. Clear Visual Distinction
- Use icons and styling to make it clear it's a button/action
- Different from search results (list items)
- Consistent across platforms

### 4. Minimal Required Fields
- Only require asset name
- Website URL is optional
- Logo URL is always null for custom assets

### 5. Flag Persistence
- Always set `is_custom` flag when saving
- Use for filtering, analytics, or display purposes
- Maintains data integrity

## Querying Custom Assets

### Get all custom assets:
```sql
SELECT * FROM digital_assets 
WHERE is_custom = true;
```

### Get all Brandfetch assets:
```sql
SELECT * FROM digital_assets 
WHERE is_custom = false;
```

### Count custom vs normal:
```sql
SELECT 
  is_custom,
  COUNT(*) as count
FROM digital_assets
GROUP BY is_custom;
```

## Best Practices

1. **Search Threshold**: Only show "Add your own" option after user types 3+ characters
2. **Debouncing**: Debounce search API calls (600ms recommended)
3. **Caching**: Cache search results to avoid duplicate API calls
4. **Error Handling**: Show "Add your own" option even if search fails
5. **Validation**: Validate asset name is not empty before saving
6. **User Feedback**: Show success/error messages after saving
7. **Consistent UX**: Use same pattern across mobile and web platforms

## Migration Checklist

- [ ] Run SQL migration to add `is_custom` column
- [ ] Update asset creation code to set `is_custom` flag
- [ ] Update UI to show "Add your own" option
- [ ] Implement custom asset dialog/form
- [ ] Test with both custom and Brandfetch assets
- [ ] Update any queries that filter assets
- [ ] Add analytics tracking if needed

## Complete Submission Flow

### Brandfetch Asset Flow

```
1. User searches → Brandfetch API returns results
2. User selects result from list
   ↓
3. Set _isCustomAsset = false
4. Optionally enrich with detailed Brandfetch API call
   ↓
5. User fills form (value, instructions, etc.)
   ↓
6. Submit with payload:
   - is_custom: false
   - new_service_platform_name: from Brandfetch
   - new_service_platform_url: from Brandfetch (if available)
   - new_service_platform_logo_url: from Brandfetch (strip client ID)
   - Other required fields...
```

### Custom Asset Flow

```
1. User searches → No results or can't find desired asset
2. User clicks "Add your own asset"
   ↓
3. Dialog opens with pre-filled name from search query
4. User enters/confirms name and optional URL
   ↓
5. Set _isCustomAsset = true
6. User fills form (value, instructions, etc.)
   ↓
7. Submit with payload:
   - is_custom: true
   - new_service_platform_name: user-provided
   - new_service_platform_url: user-provided (optional)
   - new_service_platform_logo_url: null (always)
   - Other required fields...
```

## Submission Comparison

| Field | Brandfetch Asset | Custom Asset |
|-------|-----------------|--------------|
| `is_custom` | `false` (or omit) | `true` |
| `new_service_platform_name` | From Brandfetch API | User-provided |
| `new_service_platform_url` | From Brandfetch API (if available) | User-provided (optional) |
| `new_service_platform_logo_url` | From Brandfetch API (strip client ID) | `null` (always) |
| Source | Brandfetch search results | User manual entry |
| Enrichment | Optional detailed API call | N/A |
| Logo handling | Strip client ID before storing | Not applicable |

### Common Fields (Both Types)

Both asset types include these fields:
- `uuid` - User ID
- `username` - User's username
- `email` - User's email
- `declared_value_myr` - Asset value (required)
- `instructions_after_death` - Instruction type (required)
- `beloved_id` - Gift recipient (if `transfer_as_gift`)
- `remarks` - Additional notes (optional)

## Brandfetch URL Handling

**Important:** Brandfetch CDN URLs include a client ID parameter (`?c=...`) that can expire. Always strip this before storing:

```dart
// Before storing
String? logoUrl = brandInfo.logoUrl; // "https://cdn.brandfetch.io/...?c=abc123"
String? cleanUrl = stripClientIdFromUrl(logoUrl); // "https://cdn.brandfetch.io/..."

// When displaying
String? displayUrl = addClientIdToUrl(cleanUrl); // Add current client ID for display
```

**Implementation:**
```dart
String? stripClientIdFromUrl(String? url) {
  if (url == null || !url.contains('cdn.brandfetch.io')) return url;
  final uri = Uri.parse(url);
  final params = Map<String, String>.from(uri.queryParameters);
  params.remove('c'); // Remove client ID
  return uri.replace(queryParameters: params.isEmpty ? null : params).toString();
}

String? addClientIdToUrl(String? url) {
  if (url == null || !url.contains('cdn.brandfetch.io')) return url;
  final uri = Uri.parse(url);
  final params = Map<String, String>.from(uri.queryParameters);
  params['c'] = currentClientId; // Add current client ID
  return uri.replace(queryParameters: params).toString();
}
```

## Related Files

- `add_custom_asset_flag.sql` - Database migration
- `lib/screens/add_asset_screen.dart` - Mobile implementation
- `lib/services/brandfetch_service.dart` - Brandfetch API service with URL handling
- `DB_STRUCTURE.md` - Database schema documentation

## Notes

- Custom assets will not have logos (logo_url is null)
- The `is_custom` flag is set at creation time and doesn't change
- Editing an asset doesn't modify the `is_custom` flag
- This pattern can be extended to other asset types (physical assets, etc.)

