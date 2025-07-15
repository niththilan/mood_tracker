#!/bin/bash
# Test Google Sign-In on Android emulator

echo "🔍 Testing Google Sign-In configuration..."

# Check if Google Services JSON is configured correctly
echo "✅ Google Services JSON:"
if [ -f "android/app/google-services.json" ]; then
    echo "   ✓ google-services.json exists"
    # Extract package name from google-services.json
    PACKAGE_NAME=$(grep '"package_name"' android/app/google-services.json | head -1 | cut -d'"' -f4)
    echo "   ✓ Package name: $PACKAGE_NAME"
    
    # Extract client ID
    CLIENT_ID=$(grep '"client_id"' android/app/google-services.json | head -1 | cut -d'"' -f4)
    echo "   ✓ Client ID: $CLIENT_ID"
    
    # Extract SHA-1
    SHA1=$(grep '"certificate_hash"' android/app/google-services.json | head -1 | cut -d'"' -f4)
    echo "   ✓ Certificate hash: $SHA1"
else
    echo "   ❌ google-services.json not found"
fi

# Check current debug keystore SHA-1
echo ""
echo "✅ Debug Keystore SHA-1:"
if [ -f "$HOME/.android/debug.keystore" ]; then
    CURRENT_SHA1=$(keytool -list -v -keystore "$HOME/.android/debug.keystore" -alias androiddebugkey -storepass android -keypass android 2>/dev/null | grep "SHA1:" | cut -d' ' -f2)
    echo "   ✓ Current SHA-1: $CURRENT_SHA1"
    
    # Compare with google-services.json
    if [ "$SHA1" = "$CURRENT_SHA1" ]; then
        echo "   ✅ SHA-1 matches google-services.json"
    else
        echo "   ❌ SHA-1 mismatch!"
        echo "   Expected: $SHA1"
        echo "   Actual:   $CURRENT_SHA1"
    fi
else
    echo "   ❌ Debug keystore not found"
fi

# Check if Google Play Services is available on emulator
echo ""
echo "✅ Google Play Services on emulator:"
adb shell pm list packages | grep -q "com.google.android.gms"
if [ $? -eq 0 ]; then
    echo "   ✓ Google Play Services installed"
    
    # Check version
    VERSION=$(adb shell dumpsys package com.google.android.gms | grep versionName | head -1)
    echo "   ✓ $VERSION"
else
    echo "   ❌ Google Play Services not installed"
    echo "   💡 Solution: Use an emulator with Google Play Services"
fi

# Test if the app can access Google Sign-In
echo ""
echo "✅ Testing app Google Sign-In access:"
adb shell am start -n com.example.mood_tracker/.MainActivity
sleep 3

# Check if there are any Google Sign-In related logs
echo ""
echo "✅ Recent Google Sign-In logs:"
adb logcat -d | grep -i "google\|sign\|oauth" | tail -10

echo ""
echo "🔧 Common fixes for Google Sign-In issues:"
echo "1. Make sure SHA-1 certificate fingerprint is added to Google Cloud Console"
echo "2. Enable Google Sign-In API in Google Cloud Console"
echo "3. Use an emulator with Google Play Services"
echo "4. Check that package name matches exactly"
echo "5. Ensure google-services.json is up to date"
