## Chat Attachments - Feature Documentation

This document explains the multi-file attachments feature added to the AI chat screens, including setup, storage rules, UI/UX behavior, and troubleshooting.

### Overview
- Users can attach multiple images and files to chat messages.
- Images render inline; non-images render as a link that opens externally.
- Each uploaded file is saved as an individual chat message and persisted in history via Supabase.

### Relevant Code
- Upload service: `lib/services/file_upload_service.dart`
  - `FileUploadService.pickMultipleFiles`
  - `FileUploadService.uploadAttachment`
- Main chat screen: `lib/screens/chat_conversation_screen.dart`
  - Attachment flow: `_pickAndSendAttachments`, `_pickImagesFromGallery`, `_captureImageFromCamera`
  - Rendering: `_buildMessageBubble` (branches on `message.messageType`)
- Enhanced chat screen: `lib/screens/enhanced_chat_conversation_screen.dart`
  - Attachment flow: `_pickAndSendAttachments`, `_pickImagesFromGallery`, `_captureImageFromCamera`
  - Rendering: `_buildMessageContent` (branches on `message.messageType`)
- Message model: `lib/models/chat_message.dart`
  - `MessageType` enum includes `text`, `image`, `file`, `system`
- Persistence: `lib/services/chat_service.dart`
  - `saveMessage`, `getMessages`

### Dependencies
Added in `pubspec.yaml`:
- `file_picker`: multi-file picker
- `image_picker`: camera and gallery

Run:
```bash
flutter pub get
```

For iOS, after first install:
```bash
cd ios && pod install
```

### Storage Bucket and Policies (Supabase)
Bucket name: `attachments`

SQL to create the bucket and policies: `attachments_storage_setup.sql` at project root.

Run it in Supabase SQL Editor:
1) Create public bucket (ignore “already exists” error if shown):
```sql
select storage.create_bucket('attachments', true);
```
2) Apply policies in `attachments_storage_setup.sql`.
   - Public read (because the app uses public URLs)
   - Authenticated users can insert/update/delete in `attachments`

Note: We first enable permissive rules to validate flow. You can tighten later to per-user prefixes if needed.

### Storage Path Convention
`userId/conversationId/timestamp-originalFileName`

Example:
`3d03788c-29bb-4664-828d-5e3d71f4cc52/08f6269f-15bc-41af-bcd5-da820237979f/1762854410490-scan.pdf`

The upload service normalizes returned paths from Supabase so URLs look like:
`https://<project>.supabase.co/storage/v1/object/public/attachments/<key>`

### UI/UX Behavior
- Tap the paperclip in either chat screen to open a source chooser:
  - Photos: multi-select gallery images
  - Camera: capture one image
  - Files: pick multiple files of any type
- SnackBars indicate:
  - No selection/cancel
  - Upload start with file counts
  - Success/failure message
- While uploading, the attach button is disabled and shows a progress icon.

### Message Rendering
- `MessageType.text`: existing text/markdown rendering
- `MessageType.image`: `Image.network` with rounded corners
- `MessageType.file`: “Open file” ink link; launches externally (`url_launcher`)

### Error Handling
- If not signed in, upload is blocked with a SnackBar.
- Storage errors bubble up and are shown in a SnackBar.
- If the bucket is missing or policies reject inserts, the SnackBar will show a 403 or related error.

### Platform Notes
- iOS requires camera/photos usage descriptions in `ios/Runner/Info.plist` if not already present:
  - `NSCameraUsageDescription`
  - `NSPhotoLibraryUsageDescription`
  - `NSPhotoLibraryAddUsageDescription`
  Add short, user-friendly strings and rebuild the app.
- Android uses system pickers; no extra manifest changes required for this flow.

### Security Options
- Current setting uses public read for simplicity. If you need private access:
  - Make the bucket private.
  - Replace `getPublicUrl` with signed URLs via `createSignedUrl`.
  - Cache and rotate signed URLs as needed.
  - Adjust RLS to allow only per-user prefixes: `split_part(name, '/', 1) = auth.uid()::text`.

### Troubleshooting
- “Bucket not found”: ensure `attachments` exists (see SQL above).
- 403 “new row violates row-level security policy”:
  - Confirm you are signed in.
  - Ensure the insert policy allows `auth.role() = 'authenticated'` on `bucket_id = 'attachments'`.
- Double “attachments/attachments” in URL:
  - Fixed by normalizing the return path in `FileUploadService.uploadAttachment`.
  - Older uploads may still show the old pattern; new uploads will be correct.

### Future Enhancements
- Progress UI per-file
- Retry and partial failure handling
- Private bucket with signed URLs
- Thumbnail generation for large images


