#!/bin/bash
# Quick script to run the mood tracker app on Android emulator

echo "🚀 Starting Flutter app on Android emulator..."

# Check if emulator is running
if ! adb devices | grep -q "emulator-5554.*device"; then
    echo "❌ Android emulator not running. Please start the emulator first."
    exit 1
fi

cd "$(dirname "$0")"

# Clean and rebuild
echo "🧹 Cleaning project..."
flutter clean

echo "📦 Getting dependencies..."
flutter pub get

# Build using Gradle directly (more reliable)
echo "🔨 Building APK with Gradle..."
cd android
./gradlew assembleDebug
cd ..

# Check if APK was built successfully
APK_PATH="android/app/build/outputs/flutter-apk/app-debug.apk"
if [ ! -f "$APK_PATH" ]; then
    echo "❌ APK not found at $APK_PATH"
    exit 1
fi

echo "✅ APK built successfully!"

# Install the APK
echo "📱 Installing APK..."
adb -s emulator-5554 install -r "$APK_PATH"

if [ $? -eq 0 ]; then
    echo "✅ Installation successful! Starting app..."
    adb -s emulator-5554 shell am start -n com.example.mood_tracker/.MainActivity
    echo "🎉 App started on Android emulator!"
else
    echo "❌ Failed to install APK on emulator"
    exit 1
fi
