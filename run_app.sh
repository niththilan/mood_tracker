#!/bin/bash

# Mood Tracker App Runner Script
# This script ensures the app runs in the emulator without APK location errors

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print functions
print_info() {
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

echo -e "${BLUE}🚀 Starting Mood Tracker App in Emulator...${NC}"

# Check if we're in the correct directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "pubspec.yaml not found! Please run this script from the project root directory."
    exit 1
fi

# Check if emulator is running
print_info "Checking for running emulator..."
EMULATOR_ID=$(adb devices | grep "emulator" | cut -f1 | head -n1)

if [ -z "$EMULATOR_ID" ]; then
    print_error "No emulator found! Please start an Android emulator first."
    print_info "You can start one with: flutter emulators --launch <emulator_name>"
    exit 1
fi

print_success "Found emulator: $EMULATOR_ID"

# Build the APK using our build script
print_info "Building APK..."
if ! ./build_apk.sh; then
    print_error "APK build failed!"
    exit 1
fi

# Install the APK
print_info "Installing APK to emulator..."
if [ -f "build/apk/app-debug.apk" ]; then
    if adb -s "$EMULATOR_ID" install -r build/apk/app-debug.apk; then
        print_success "Debug APK installed successfully!"
    else
        print_error "Failed to install debug APK!"
        exit 1
    fi
else
    print_error "Debug APK not found at build/apk/app-debug.apk"
    exit 1
fi

# Start the app
print_info "Starting the app..."
if adb -s "$EMULATOR_ID" shell am start -n com.example.mood_tracker/.MainActivity; then
    print_success "App started successfully! 🎉"
    print_info "The Mood Tracker app should now be running in the emulator."
else
    print_error "Failed to start the app!"
    exit 1
fi

# Optional: Show logs
print_info "To view app logs, run: adb -s $EMULATOR_ID logcat -s flutter"
