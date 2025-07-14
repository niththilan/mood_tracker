#!/bin/bash
# Quick script to run the mood tracker app on Android emulator

echo "Building debug APK..."
cd "$(dirname "$0")"
flutter build apk --debug

if [ $? -eq 0 ]; then
    echo "Build successful! Installing on emulator..."
    adb -s emulator-5554 install -r android/app/build/outputs/flutter-apk/app-debug.apk
    
    if [ $? -eq 0 ]; then
        echo "Installation successful! Starting app..."
        adb -s emulator-5554 shell am start -n com.example.mood_tracker/.MainActivity
        echo "App started on Android emulator!"
    else
        echo "Failed to install APK on emulator"
    fi
else
    echo "Build failed"
fi
