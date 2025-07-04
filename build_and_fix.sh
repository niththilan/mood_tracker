#!/bin/bash

echo "Creating Flutter build directory structure..."

# Create the main build directory structure that Flutter expects
mkdir -p build/app/outputs/flutter-apk
mkdir -p build/app/outputs/apk/debug
mkdir -p build/app/outputs/apk/release

# Function to copy APK if it exists
copy_apk() {
    local source="$1"
    local dest="$2"
    if [ -f "$source" ]; then
        cp "$source" "$dest"
        echo "Copied $(basename $source) to $dest"
        return 0
    fi
    return 1
}

# Build the APK first
echo "Building debug APK..."
cd android && ./gradlew assembleDebug

if [ $? -eq 0 ]; then
    echo "Build successful! Copying APKs to expected locations..."
    
    # Copy from gradle output to flutter expected locations
    copy_apk "app/build/outputs/apk/debug/app-debug.apk" "../build/app/outputs/apk/debug/app-debug.apk"
    copy_apk "app/build/outputs/flutter-apk/app-debug.apk" "../build/app/outputs/flutter-apk/app-debug.apk"
    copy_apk "app/build/outputs/apk/release/app-release.apk" "../build/app/outputs/apk/release/app-release.apk"
    copy_apk "app/build/outputs/flutter-apk/app-release.apk" "../build/app/outputs/flutter-apk/app-release.apk"
    
    echo "APK files are now in the correct Flutter build directory structure!"
else
    echo "Build failed!"
    exit 1
fi
