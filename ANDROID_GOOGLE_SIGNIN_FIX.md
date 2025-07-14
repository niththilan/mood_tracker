# Android Google Sign-In Setup Guide

## 🔧 Fixed Issues

The Google Sign-In for Android has been fixed with the following improvements:

### 1. **Configuration Files Updated**
- ✅ Added ProGuard rules for Google Sign-In
- ✅ Updated AndroidManifest.xml with deep link support
- ✅ Enhanced build.gradle.kts with proper minification

### 2. **Authentication Service Enhanced**
- ✅ Added Android-specific error handling
- ✅ Improved timeout and retry logic
- ✅ Better Google Play Services detection

### 3. **Debugging Tools Added**
- ✅ `debug_android_auth.sh` - Comprehensive configuration checker
- ✅ `get_sha1.sh` - SHA-1 certificate fingerprint extractor
- ✅ Android-specific test cases

## 🚀 Setup Steps

### Step 1: Get SHA-1 Certificate Hash
```bash
./get_sha1.sh
```
This will show your SHA-1 certificate fingerprint needed for Firebase.

### Step 2: Update Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: **mood-tracker-project**
3. Go to **Project Settings** > **Your Apps**
4. Click on your Android app
5. Click **Add Fingerprint**
6. Paste the SHA-1 hash from Step 1
7. Download the updated `google-services.json`

### Step 3: Replace google-services.json
```bash
# Replace the file in your project
cp ~/Downloads/google-services.json android/app/google-services.json
```

### Step 4: Clean and Rebuild
```bash
flutter clean
flutter pub get
flutter build apk
```

### Step 5: Test on Real Device
```bash
flutter run --release
```
**Note:** Test on a real Android device, not an emulator!

## 🐛 Troubleshooting

### Run Diagnostic Script
```bash
./debug_android_auth.sh
```

### Common Issues & Solutions

#### ❌ "Developer Error (Code 10)"
**Cause:** SHA-1 certificate not registered in Firebase
**Solution:** Follow Steps 1-4 above

#### ❌ "Network Error (Code 7)"
**Cause:** Device connectivity or Google Play Services issue
**Solution:**
- Check internet connection
- Update Google Play Services
- Try different network

#### ❌ "Google Play Services Not Available"
**Cause:** Missing or outdated Google Play Services
**Solution:**
- Update Google Play Services from Play Store
- Test on device with Google services
- Avoid Chinese ROMs without Google services

#### ❌ "Package Name Mismatch"
**Cause:** Package name doesn't match Firebase configuration
**Solution:**
- Ensure package name is `com.example.mood_tracker`
- Check AndroidManifest.xml
- Verify google-services.json

## 📱 Testing Checklist

- [ ] Real Android device (not emulator)
- [ ] Google Play Services installed and updated
- [ ] Internet connection available
- [ ] SHA-1 certificate added to Firebase
- [ ] Latest google-services.json file
- [ ] App built in release mode

## 🔍 Debug Commands

```bash
# Check configuration
./debug_android_auth.sh

# Get SHA-1 hash
./get_sha1.sh

# View logs while testing
flutter logs

# Clean build
flutter clean && flutter pub get && flutter build apk

# Test on device
flutter run --release
```

## 📋 File Changes Made

### New Files
- `android/app/proguard-rules.pro` - ProGuard rules for Google Sign-In
- `get_sha1.sh` - SHA-1 certificate extraction script
- `debug_android_auth.sh` - Configuration diagnostic tool
- `test/android_google_auth_test.dart` - Android-specific tests

### Modified Files
- `android/app/build.gradle.kts` - Added ProGuard configuration
- `android/app/src/main/AndroidManifest.xml` - Added deep link support
- `lib/services/google_auth_service.dart` - Enhanced Android error handling

## 🎯 Expected Results

After following this guide:
1. ✅ Google Sign-In works on Android devices
2. ✅ Proper error messages guide users
3. ✅ Fallback to email/password available
4. ✅ Debug tools help identify issues

## 🆘 Support

If issues persist:
1. Run `./debug_android_auth.sh`
2. Check the output for specific issues
3. Use email/password authentication as fallback
4. Verify device has Google Play Services

---

**Note:** Always test on real Android devices with Google Play Services. Emulators may not have proper Google services configured.
