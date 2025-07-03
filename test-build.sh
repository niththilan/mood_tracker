#!/bin/bash

# Test deployment script
echo "🧪 Testing Flutter web deployment..."

# Build the app
flutter clean
flutter pub get
flutter build web --release

# Check if build was successful
if [ -d "build/web" ] && [ -f "build/web/index.html" ]; then
    echo "✅ Build successful!"
    echo "📄 Generated files:"
    ls -la build/web/
    echo ""
    echo "📏 Build size:"
    du -sh build/web/
else
    echo "❌ Build failed!"
    exit 1
fi
