#!/bin/bash

# Build APK Script for Mood Tracker
# This script fixes the issue where Flutter can't find the generated APK

set -e

echo "🔧 Building Mood Tracker APK..."

# Clean previous builds
echo "📦 Cleaning previous builds..."
flutter clean
cd android && ./gradlew clean && cd ..

echo "🏗️  Building release APK..."
# Build using gradle directly to avoid Flutter's path issues
cd android && ./gradlew assembleRelease

# Check if APK was created
if [ -f "app/build/outputs/apk/release/app-release.apk" ]; then
    echo "✅ APK built successfully!"
    
    # Create Flutter's expected directory structure
    mkdir -p ../build/app/outputs/flutter-apk
    
    # Copy APK to Flutter's expected location
    cp app/build/outputs/apk/release/app-release.apk ../build/app/outputs/flutter-apk/
    
    # Also copy to a convenient location
    cp app/build/outputs/apk/release/app-release.apk ../mood_tracker_release.apk
    
    echo "📱 APK copied to:"
    echo "   - build/app/outputs/flutter-apk/app-release.apk"
    echo "   - mood_tracker_release.apk"
    
    # Get APK info
    echo "📊 APK Info:"
    ls -lh app/build/outputs/apk/release/app-release.apk
    
else
    echo "❌ APK build failed!"
    exit 1
fi

cd ..

echo "🎉 Build completed successfully!"
echo "You can install the APK with: adb install mood_tracker_release.apk"
