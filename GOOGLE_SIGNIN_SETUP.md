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

## What You Need To Do

### 1. Download Google Services Configuration Files

#### For Android:
1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project (the one with Client ID: `720874566167-049e0s4erui477nhvpfivvkr3498nbgb.apps.googleusercontent.com`)
3. Navigate to "APIs & Services" > "Credentials"
4. Download the `google-services.json` file for your Android app
5. Replace the template file at `/android/app/google-services.json` with your actual file

#### For iOS (if you plan to support iOS):
1. In the same Google Cloud Console project
2. Download the `GoogleService-Info.plist` file for your iOS app
3. Add it to `/ios/Runner/GoogleService-Info.plist`

### 2. Update Package Name (Important!)

The current package name is `com.example.mood_tracker`. You should change this to your own unique package name:

#### Android:
1. Update `android/app/build.gradle.kts`:
   ```kotlin
   applicationId = "com.yourcompany.mood_tracker"  // Change this
   ```

2. Update the package name in your Google Cloud Console to match

#### iOS:
1. Open the iOS project in Xcode
2. Update the Bundle Identifier to match your package name

### 3. Add SHA-1 Certificate (Android)

For Android, you need to add your SHA-1 certificate fingerprint to Google Cloud Console:

1. Generate SHA-1 fingerprint:
   ```bash
   # For debug builds
   keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore
   
   # For release builds (when you create a release keystore)
   keytool -list -v -alias your_alias -keystore your_keystore.jks
   ```

2. Add this SHA-1 fingerprint to your Google Cloud Console project

### 4. Configure Supabase

Make sure your Supabase project has Google OAuth configured:

1. Go to your Supabase Dashboard
2. Navigate to Authentication > Providers
3. Enable Google provider
4. Add your Client ID and Client Secret
5. Configure the redirect URL (usually your app's deep link)

## Testing

After completing the setup:

1. Run the app: `flutter run`
2. Try signing in with Google
3. Check that the user profile is created properly
4. Test sign-out functionality

## Troubleshooting

### Common Issues:

1. **"Sign-in failed"**: Check that your SHA-1 certificate is correctly added to Google Cloud Console
2. **"Network error"**: Ensure your `google-services.json` file is valid and placed correctly
3. **"Package name mismatch"**: Make sure package names match between your app and Google Cloud Console
4. **iOS issues**: Ensure the URL scheme in Info.plist matches your Google Client ID

### Debug Steps:

1. Check Flutter console for detailed error messages
2. Verify Google services files are in the correct locations
3. Ensure package names are consistent everywhere
4. Test with a fresh build: `flutter clean && flutter pub get && flutter run`

## Files Modified

- ✅ `lib/services/google_auth_service.dart` (created)
- ✅ `lib/auth_page.dart` (updated with Google Sign-In button)
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
