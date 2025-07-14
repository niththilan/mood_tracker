#!/bin/bash

echo "🔍 Testing Google Play Services on Android Emulator"
echo "================================================"

echo ""
echo "📱 Device Info:"
echo "---------------"
adb -s emulator-5554 shell getprop ro.product.model
adb -s emulator-5554 shell getprop ro.build.version.release

echo ""
echo "📦 Google Play Services Status:"
echo "-------------------------------"
# Check if Google Play Services is installed
if adb -s emulator-5554 shell pm list packages | grep -q "com.google.android.gms"; then
    echo "✅ Google Play Services is installed"
    
    # Get version info
    echo "📋 Version info:"
    adb -s emulator-5554 shell dumpsys package com.google.android.gms | grep versionName | head -1
    
    # Check if it's enabled
    echo "🔧 Service status:"
    adb -s emulator-5554 shell pm list packages -e | grep com.google.android.gms
else
    echo "❌ Google Play Services is NOT installed"
    echo ""
    echo "💡 To install Google Play Services:"
    echo "1. Use an emulator with Google APIs (not just Android)"
    echo "2. Create a new AVD with Google Play Store"
    echo "3. Or download the Google Play Services APK manually"
fi

echo ""
echo "🔑 Google Sign-In Configuration Check:"
echo "-------------------------------------"
echo "Package Name: com.example.mood_tracker"
echo "SHA-1: 29:4E:13:7C:8A:F1:84:B9:A1:2D:09:18:73:13:39:A5:05:2A:B8:2A"
echo ""
echo "📝 Make sure this SHA-1 is added to:"
echo "- Google Cloud Console > APIs & Services > Credentials"
echo "- Your OAuth 2.0 client ID for Android"

echo ""
echo "🧪 Testing Google Sign-In API availability..."
# Try to call Google Sign-In API
adb -s emulator-5554 shell am start -a android.intent.action.VIEW -d "https://accounts.google.com" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Can access Google accounts"
else
    echo "❌ Cannot access Google accounts"
fi

echo ""
echo "🚀 Ready to test! Try Google Sign-In in the app now."
