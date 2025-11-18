# Android & iOS Permissions Setup

## Android Configuration

### Step 1: Update AndroidManifest.xml

File: `android/app/src/main/AndroidManifest.xml`

Add these permissions **inside the `<manifest>` tag** (before `<application>`):

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- Add these permissions -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.INTERNET" />
    
    <application>
        <!-- rest of config -->
    </application>
</manifest>
```

### Step 2: Update build.gradle (if needed)

File: `android/app/build.gradle.kts`

Ensure `compileSdk` is at least 33:

```kotlin
android {
    compileSdk = 34  // or higher
    
    defaultConfig {
        minSdk = 21
        targetSdk = 34
    }
}
```

### Step 3: Request Runtime Permissions

The `image_picker` package automatically requests runtime permissions when the user tries to access camera/gallery. However, you can also add this to your code if you want to request upfront:

```dart
import 'package:permission_handler/permission_handler.dart';

// Request camera permission
final status = await Permission.camera.request();
if (status.isDenied) {
    // Handle denied
}
```

---

## iOS Configuration

### Step 1: Update Info.plist

File: `ios/Runner/Info.plist`

Add these keys (open with Xcode or text editor):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Add these keys -->
    <key>NSCameraUsageDescription</key>
    <string>We need camera access to capture food photos for calorie analysis</string>
    
    <key>NSPhotoLibraryUsageDescription</key>
    <string>We need access to your photo library to select food images for calorie analysis</string>
    
    <key>NSPhotoLibraryAddUsageDescription</key>
    <string>We need permission to save photos</string>
    
    <!-- Rest of plist -->
</dict>
</plist>
```

### Step 2: Set Minimum iOS Version

File: `ios/Podfile`

Ensure minimum deployment target is at least 11.0:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_CAMERA=1',
        'PERMISSION_PHOTOS=1',
      ]
    end
  end
end
```

### Step 3: Update Xcode Project (Optional)

Open in Xcode:
```bash
open ios/Runner.xcworkspace
```

Verify in **Runner > Targets > Runner > Build Settings**:
- Minimum Deployment: 11.0 or higher
- Camera & Photo Library permissions are listed in Info tab

---

## Windows Configuration

Windows doesn't require special permissions for camera/gallery access. The permissions are handled by the OS dialog that appears automatically.

---

## Web Configuration

For web deployment, ensure your server:
1. Serves over HTTPS (required for camera access)
2. Has proper CORS headers
3. Handles image uploads securely

---

## Testing Permissions

### Android
```bash
flutter run
# App will request permissions on first camera/gallery access
# Check Settings > Apps > CalTrack > Permissions
```

### iOS
```bash
flutter run
# App will show iOS permission dialog on first access
# User must tap "Allow" for camera/photo library
```

### Reset Permissions (for testing)

**Android:**
```bash
adb shell pm reset-permissions
```

**iOS:**
```bash
# Settings > General > Reset > Reset Location & Privacy
```

---

## Troubleshooting

### "Camera permission denied"
- ✅ Check device settings for app permissions
- ✅ Ensure AndroidManifest.xml has camera permission
- ✅ For iOS, verify Info.plist has NSCameraUsageDescription
- ✅ Try uninstalling and reinstalling app

### "Gallery/Photos not accessible"
- ✅ Grant STORAGE permission on Android
- ✅ Grant NSPhotoLibraryUsageDescription on iOS
- ✅ Check if device actually has photos/gallery app

### "Permission dialog doesn't appear"
- ✅ Permissions must be requested in code or automatically by package
- ✅ Some Android versions grant permissions at install time
- ✅ Restart app if dialog doesn't appear

### Image picker opens but app crashes
- ✅ Update flutter, image_picker, and other packages
- ✅ Run `flutter clean && flutter pub get`
- ✅ Check logs: `flutter logs`

---

## Required Packages

These are automatically added to `pubspec.yaml`:

```yaml
dependencies:
  image_picker: ^1.0.0
  permission_handler: ^11.0.1
  google_generative_ai: ^0.4.7
```

Run:
```bash
flutter pub get
```

---

## Summary Checklist

- [ ] Add permissions to `android/app/src/main/AndroidManifest.xml`
- [ ] Add keys to `ios/Runner/Info.plist`
- [ ] Verify compileSdk/minimum OS versions
- [ ] Run `flutter pub get`
- [ ] Run `flutter clean` if issues persist
- [ ] Test camera access: tap "Scan Food" > Camera button
- [ ] Test gallery access: tap "Scan Food" > Gallery button
- [ ] Verify permissions dialog appears
- [ ] Check device Settings > Permissions for app

---

**Done!** Your app is ready to use the camera and photo library for food image recognition.
