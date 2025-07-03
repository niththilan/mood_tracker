# Google Sign-In Setup for Mood Tracker

This document explains how to complete the Google Sign-In setup for your Mood Tracker app.

## What's Already Done

✅ **Code Implementation**
- Added Google Sign-In service (`lib/services/google_auth_service.dart`)
- Updated AuthPage with Google Sign-In button
- Added proper sign-out handling for Google users
- Updated pubspec.yaml with required dependencies
- Configured Android build files
- Updated iOS Info.plist with URL scheme

## Current Issues Found

❌ **Missing iOS Configuration**: GoogleService-Info.plist not found
❌ **Package Name Mismatch**: Android uses `com.example.mood_tracker` vs iOS uses `com.example.moodTracker`
⚠️ **SHA-1 Certificate**: Your debug SHA-1 is `8C:54:B8:B6:27:94:C8:97:77:51:60:4A:21:D1:EB:3F:1F:00:0D:C5`

## What You Need To Do

### 1. Fix Package Name Consistency

The package names between Android and iOS don't match. Choose one format and update both:

#### Option A: Keep Android format (recommended)
1. Update iOS bundle identifier in Xcode:
   - Open `ios/Runner.xcodeproj` in Xcode
   - Select the Runner target
   - Change Bundle Identifier to `com.example.mood_tracker`

#### Option B: Update Android to match iOS
1. Update `android/app/build.gradle.kts`:
   ```kotlin
   applicationId = "com.example.moodTracker"
   ```

### 2. Add SHA-1 Certificate to Google Cloud Console

Your debug SHA-1 fingerprint: `8C:54:B8:B6:27:94:C8:97:77:51:60:4A:21:D1:EB:3F:1F:00:0D:C5`

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Navigate to "APIs & Services" > "Credentials"
4. Click on your Android OAuth 2.0 client ID
5. Add the SHA-1 certificate fingerprint above

### 3. Download and Add iOS Configuration

1. In Google Cloud Console, create an iOS OAuth client ID
2. Download `GoogleService-Info.plist`
3. Add it to `ios/Runner/GoogleService-Info.plist`

### 4. Test the Configuration

After making these changes:

```bash
# Clean and rebuild
flutter clean
flutter pub get

# Test on Android
flutter run -d android

# Test on iOS (if available)
flutter run -d ios
```

## Common Error Messages and Solutions

### "Developer Error" or "Sign-in Failed"
- **Cause**: SHA-1 certificate not added to Google Cloud Console
- **Solution**: Add your SHA-1 fingerprint to the Google Cloud Console

### "Network Error"
- **Cause**: Invalid `google-services.json` or missing internet permission
- **Solution**: Re-download `google-services.json` from Google Cloud Console

### "Configuration Error"
- **Cause**: Package name mismatch between app and Google Cloud Console
- **Solution**: Ensure package names match exactly

### iOS "URL Scheme Error"
- **Cause**: Missing or incorrect `GoogleService-Info.plist`
- **Solution**: Add the correct plist file to the iOS project

## Debugging Steps

1. **Check Configuration Files**:
   ```bash
   # Run this script to check your configuration
   ./debug_google_signin.sh
   ```

2. **Enable Verbose Logging**:
   The Google Auth service now includes detailed logging. Check the console output when testing.

3. **Test with Different Accounts**:
   Try signing in with different Google accounts to isolate account-specific issues.

4. **Verify Supabase Configuration**:
   - Go to your Supabase Dashboard
   - Navigate to Authentication > Providers
   - Ensure Google provider is enabled
   - Check that Client ID and Secret are correctly configured

## Next Steps

After completing the setup above, Google Sign-in should work properly. The enhanced error logging will help identify any remaining issues.

## Support

If you continue to have issues:
1. Check the Flutter console output for detailed error messages
2. Verify all configuration files are in place
3. Ensure SHA-1 certificates are added to Google Cloud Console
4. Test with a fresh `flutter clean && flutter pub get`
- ✅ `lib/main.dart` (updated sign-out logic)
- ✅ `pubspec.yaml` (added dependencies)
- ✅ `android/build.gradle.kts` (added Google services plugin)
- ✅ `android/app/build.gradle.kts` (added Google services plugin)
- ✅ `android/app/google-services.json` (template - needs your actual file)
- ✅ `ios/Runner/Info.plist` (added URL scheme)

## Next Steps

1. Replace the template `google-services.json` with your actual file
2. Update package names to your own
3. Add SHA-1 certificates to Google Cloud Console
4. Test the implementation
5. Configure Supabase Google OAuth if not already done

The Google Sign-In should work seamlessly with your existing Supabase authentication once these steps are completed!
