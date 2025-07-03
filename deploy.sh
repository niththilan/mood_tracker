#!/bin/bash

# Flutter Web Deployment Script for Netlify
set -e

echo "🚀 Starting Flutter Web deployment..."

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter first."
    exit 1
fi

# Print Flutter version info
echo "📋 Flutter version info:"
flutter --version

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Analyze code for potential issues (don't fail on warnings)
echo "🔍 Analyzing code..."
flutter analyze --no-fatal-infos || true

# Build for web with optimizations
echo "🏗️ Building Flutter web app..."
flutter build web --release

# Check if build was successful
if [ ! -d "build/web" ]; then
    echo "❌ Build failed - build/web directory not found"
    exit 1
fi

if [ ! -f "build/web/index.html" ]; then
    echo "❌ Build failed - index.html not found"
    exit 1
fi

echo "✅ Build completed successfully!"
echo "📁 Build output is in: build/web"
echo "🌐 Ready for Netlify deployment!"

# Display build info
echo ""
echo "📊 Build Information:"
cd build/web
if [ -f "main.dart.js" ]; then
    echo "Size of main.dart.js: $(ls -lh main.dart.js | awk '{print $5}')"
fi
echo "Total build size: $(du -sh . | awk '{print $1}')"
echo "Files generated: $(ls -la | wc -l) files"
