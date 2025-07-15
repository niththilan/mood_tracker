#!/bin/bash

# Mood Tracker APK Build Script
# This script ensures reliable APK builds and handles common issues

echo "🚀 Starting Mood Tracker APK Build Process..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the correct directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "pubspec.yaml not found! Please run this script from the project root directory."
    exit 1
fi

# Step 1: Clean previous builds
print_status "Cleaning previous builds..."
flutter clean
if [ $? -ne 0 ]; then
    print_error "Flutter clean failed!"
    exit 1
fi

# Step 2: Get dependencies
print_status "Getting Flutter dependencies..."
flutter pub get
if [ $? -ne 0 ]; then
    print_error "Flutter pub get failed!"
    exit 1
fi

# Step 3: Check Flutter doctor (optional but recommended)
print_status "Checking Flutter environment..."
flutter doctor --verbose | grep -E "(Android|SDK)" || true

# Step 4: Build APK with proper flags
print_status "Building APK (this may take a few minutes)..."
flutter build apk --release --split-per-abi --verbose

# Check if the main build command was successful
if [ $? -eq 0 ]; then
    print_success "APK build completed successfully!"
else
    print_warning "Build command returned non-zero exit code, but checking for APK files..."
fi

# Step 5: Verify APK files exist
print_status "Verifying APK files..."

APK_DIR="./android/app/build/outputs/flutter-apk"
FALLBACK_APK_DIR="./android/app/build/outputs/apk/release"

if [ -d "$APK_DIR" ]; then
    APK_FILES=$(find "$APK_DIR" -name "*.apk" -type f 2>/dev/null)
    if [ -n "$APK_FILES" ]; then
        print_success "APK files found in $APK_DIR:"
        echo "$APK_FILES" | while read -r apk; do
            if [ -f "$apk" ]; then
                size=$(ls -lh "$apk" | awk '{print $5}')
                filename=$(basename "$apk")
                echo "  📱 $filename ($size)"
            fi
        done
    fi
elif [ -d "$FALLBACK_APK_DIR" ]; then
    APK_FILES=$(find "$FALLBACK_APK_DIR" -name "*.apk" -type f 2>/dev/null)
    if [ -n "$APK_FILES" ]; then
        print_success "APK files found in $FALLBACK_APK_DIR:"
        echo "$APK_FILES" | while read -r apk; do
            if [ -f "$apk" ]; then
                size=$(ls -lh "$apk" | awk '{print $5}')
                filename=$(basename "$apk")
                echo "  📱 $filename ($size)"
            fi
        done
    fi
else
    print_error "No APK output directory found!"
    exit 1
fi

# Step 6: Copy APK to convenient location
print_status "Copying APK files to project root for easy access..."
mkdir -p "./build/apk"

# Copy all APK files to build/apk directory
if [ -d "$APK_DIR" ]; then
    cp "$APK_DIR"/*.apk "./build/apk/" 2>/dev/null || true
fi

if [ -d "$FALLBACK_APK_DIR" ]; then
    cp "$FALLBACK_APK_DIR"/*.apk "./build/apk/" 2>/dev/null || true
fi

# Show final results
if [ "$(ls -A ./build/apk 2>/dev/null)" ]; then
    print_success "APK files copied to ./build/apk/"
    print_success "Build completed successfully! 🎉"
    echo ""
    echo "📦 Available APK files:"
    ls -lh ./build/apk/*.apk | awk '{print "  " $9 " (" $5 ")"}'
    echo ""
    echo "💡 Recommended APK for distribution: app-release.apk"
else
    print_error "No APK files could be copied!"
    exit 1
fi

# Step 7: Optional - Show install instructions
echo ""
print_status "To install the APK on your device:"
echo "  1. Enable 'Unknown Sources' in your Android device settings"
echo "  2. Transfer the APK file to your device"
echo "  3. Open the APK file on your device to install"
echo ""
print_status "For Google Play Store upload, use: app-release.apk"
