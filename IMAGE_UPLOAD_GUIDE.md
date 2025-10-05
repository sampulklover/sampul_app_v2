# Image Upload Feature Guide

This guide explains the image upload functionality implemented in the app.

## Overview

The app now supports uploading profile pictures from both camera and gallery. Images are stored in Supabase storage and automatically displayed throughout the app.

## Features

### ✅ **What's Implemented:**

1. **Image Selection**
   - Choose from camera or photo gallery
   - Image validation (file size, format)
   - Automatic image compression and resizing

2. **Upload Process**
   - Direct upload to Supabase storage
   - Progress indicators during upload
   - Error handling and user feedback

3. **Image Display**
   - Automatic URL construction
   - Fallback to default icons
   - Consistent display across all screens

## How It Works

### 1. **Image Selection**
- User taps camera icon or "Change Photo" button
- Dialog appears with options: Camera or Gallery
- Image picker opens with appropriate source

### 2. **Image Processing**
- Selected image is validated (max 5MB, supported formats)
- Image is automatically resized to 1024x1024 pixels
- Quality is compressed to 85% for optimal file size

### 3. **Upload to Supabase**
- Image is uploaded to `images` bucket in Supabase storage
- Path format: `{userId}/avatar/profile/{timestamp}-{hash}.{extension}`
- Example: `46847b5e-ab58-42c7-bfcc-1efe5f97729c/avatar/profile/1753477993914-653184335.png`

### 4. **URL Construction**
- Full URL: `https://rfzblaianldrfwdqdijl.supabase.co/storage/v1/object/public/images/{path}`
- Automatically handled by `SupabaseConfig.getFullImageUrl()`

## File Structure

```
lib/
├── services/
│   └── image_upload_service.dart    # Image upload logic
├── screens/
│   └── edit_profile_screen.dart     # Upload UI
└── config/
    └── supabase_config.dart         # URL configuration
```

## Permissions

### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs access to camera to take profile pictures.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to photo library to select profile pictures.</string>
```

## Dependencies

```yaml
dependencies:
  image_picker: ^1.0.7      # Image selection
  path_provider: ^2.1.2     # File system access
  supabase_flutter: ^2.8.0  # Storage upload
```

## Usage Example

```dart
// Pick and upload image
final ImageUploadService uploadService = ImageUploadService();

// Pick image from gallery
final File? image = await uploadService.pickImage(source: ImageSource.gallery);

// Upload to Supabase
final String imagePath = await uploadService.uploadProfileImage(
  imageFile: image!,
  userId: currentUser.id,
);

// Get public URL
final String publicUrl = uploadService.getPublicUrl(imagePath);
```

## Error Handling

The system handles various error scenarios:

- **Invalid file format**: Shows error message
- **File too large**: Validates 5MB limit
- **Upload failure**: Shows error with retry option
- **Network issues**: Graceful error handling
- **Permission denied**: Guides user to enable permissions

## Storage Structure

```
Supabase Storage Bucket: "images"
├── {userId}/
│   └── avatar/
│       └── profile/
│           ├── 1753477993914-123456789.png
│           ├── 1753477993915-987654321.jpg
│           └── ...
```

## Security

- Images are stored in public bucket for easy access
- File names include timestamps and user ID hashes
- Automatic file validation prevents malicious uploads
- User can only upload to their own folder structure

## Future Enhancements

Potential improvements for the future:

1. **Image Editing**: Crop, rotate, filters
2. **Multiple Images**: Support for multiple profile pictures
3. **Image Compression**: More advanced compression options
4. **Cloud Storage**: Integration with other cloud providers
5. **Image Caching**: Local caching for better performance
