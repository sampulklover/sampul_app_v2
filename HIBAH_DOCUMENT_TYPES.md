# Hibah Document Types

This document defines the standardized document type keys used across web and mobile platforms.

## Certificate ID Generation

Each hibah submission is assigned a unique certificate ID that follows this format:

### Format
```
CERT-{YEAR}-{9-DIGIT-NUMBER}
```

### Example
```
CERT-2024-847562319
```

### Generation Logic
- **Year**: Current year (e.g., `2024`, `2025`)
- **9-Digit Number**: Generated from microseconds timestamp (`DateTime.now().microsecondsSinceEpoch % 1000000000`), padded with leading zeros if needed

### Implementation
```dart
String _generateCertificateId() {
  final int currentYear = DateTime.now().year;
  final int randomDigits = DateTime.now().microsecondsSinceEpoch.remainder(1000000000);
  final String padded = randomDigits.toString().padLeft(9, '0');
  return 'CERT-$currentYear-$padded';
}
```

### Uniqueness
- The certificate ID has a unique constraint in the database
- If a collision occurs (extremely rare), the system retries up to 5 times with a new ID
- Each certificate ID can contain multiple hibah records (assets)

## Database Storage

In the `hibah_documents` table, the `document_type` column stores **short keys** for easier filtering and querying.

## UI Display

User interfaces display the **full labels** for better readability.

## Document Type Mapping

### Property Documents (Required per asset)

| Key | Label | Required |
|-----|-------|----------|
| `title_deed` | Title Deed / Strata Title | ✅ Yes |
| `assessment_tax` | Assessment Tax / Land Tax | ✅ Yes |
| `sale_agreement` | Sale Agreement / Loan Agreement | ✅ Yes |
| `insurance_policy` | MRTT / MLTT / Takaful / Insurance policy documents | ✅ Yes |

### Identity Documents

| Key | Label | Required |
|-----|-------|----------|
| `beneficiary_nric` | Beneficiaries' NRIC (front & back) | ✅ Yes (if beneficiaries exist) |
| `guardian_nric` | Guardian's NRIC (if beneficiary is under 18 / OKU) | ⚠️ Conditional |

### Supporting Documents

| Key | Label | Required |
|-----|-------|----------|
| `other_supporting` | Any other supporting documents | ❌ Optional |

## File Storage

### Storage Bucket
Files are stored in the **`images`** bucket in Supabase Storage.

### File Path Format
```
{userId}/hibah-documents/{timestamp}-{randomNumber}.{extension}
```

Example:
```
46847b5e-ab58-42c7-bfcc-1efe5f97729c/hibah-documents/1763045058369-710602450.jpeg
```

### Unique Filename Generation
- Timestamp: `Date.now()` (JavaScript) or `DateTime.now().millisecondsSinceEpoch` (Dart)
- Random number: `Math.round(Math.random() * 1e9)` (JavaScript) or `microsecondsSinceEpoch % 1000000000` (Dart)
- Extension: Extracted from original filename

## Usage Examples

### Web (JavaScript)
```javascript
// Generate unique filename
const originalName = file.name;
const fileExtension = originalName.split('.').pop();
const uniqueName = `${Date.now()}-${Math.round(Math.random() * 1e9)}.${fileExtension}`;
const fileName = `${user.id}/hibah-documents/${uniqueName}`;

// Upload to storage
await supabase.storage.from('images').upload(fileName, file);

// Save metadata
const fileMetadata = {
  submission_id: submissionId,
  hibah_group_id: hibahGroup.id,
  file_name: file.name, // Original filename
  file_path: fileName, // Storage path
  file_size: file.size,
  file_type: file.type,
  document_type: 'title_deed', // Use short key
};
```

### Mobile (Dart)
```dart
// Generate unique filename
final String fileExtension = originalName.split('.').last;
final String uniqueName = '${DateTime.now().millisecondsSinceEpoch}-${(DateTime.now().microsecondsSinceEpoch % 1000000000)}.${fileExtension}';
final String key = '${user.id}/hibah-documents/$uniqueName';

// Upload to storage
await storage.from('images').uploadBinary(key, bytes);

// Create metadata request
HibahDocumentRequest(
  documentType: 'title_deed', // Use short key
  fileName: doc.file.name, // Original filename
  filePath: key, // Storage path
  fileSize: doc.file.size,
  fileType: doc.mimeType,
  groupTempId: doc.linkedAssetTempId,
)
```

### Database Query
```sql
-- Easy filtering with short keys
SELECT * FROM hibah_documents 
WHERE document_type = 'title_deed';

-- Get all property documents
SELECT * FROM hibah_documents 
WHERE document_type IN ('title_deed', 'assessment_tax', 'sale_agreement', 'insurance_policy');
```

## File Cleanup

When a hibah submission is deleted, the system automatically:
1. ✅ Fetches all associated document file paths from `hibah_documents` table
2. ✅ Deletes the actual files from the `images` storage bucket
3. ✅ Deletes the database records from `hibah_documents`, `hibah_group`, and `hibah` tables

This ensures no orphaned files remain in storage, keeping the system clean and storage costs optimized.

## Benefits

1. **Easier Database Queries**: Short keys are simpler to filter and index
2. **Consistent Across Platforms**: Same keys used in web and mobile
3. **Better UX**: Users see full descriptive labels
4. **Maintainability**: Changing labels doesn't require database migration
5. **Automatic Cleanup**: Files are automatically deleted when submissions are removed

