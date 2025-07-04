#!/bin/bash

# Fix Flutter build issue by ensuring APK is in the expected location
echo "Fixing Flutter build directory structure..."

# Create the expected build directory structure if it doesn't exist
mkdir -p build/app/outputs/flutter-apk/

# Copy the APK to the expected location
if [ -f "android/app/build/outputs/flutter-apk/app-debug.apk" ]; then
    cp android/app/build/outputs/flutter-apk/app-debug.apk build/app/outputs/flutter-apk/
    echo "Copied debug APK to expected location"
fi

if [ -f "android/app/build/outputs/apk/debug/app-debug.apk" ]; then
    cp android/app/build/outputs/apk/debug/app-debug.apk build/app/outputs/apk/debug/
    mkdir -p build/app/outputs/apk/debug/
    cp android/app/build/outputs/apk/debug/app-debug.apk build/app/outputs/apk/debug/
    echo "Copied debug APK to standard location"
fi

echo "Build directory fix completed!"
