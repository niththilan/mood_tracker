#!/bin/bash

# Production Build Script for MoodFlow Web App
# This creates an optimized production build

echo "🏗️  Building MoodFlow for Production..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

echo "📦 Building optimized production bundle..."

# Build with optimizations
flutter build web --release \
  --dart-define=FLUTTER_WEB_AUTO_DETECT=true \
  --source-maps \
  --tree-shake-icons

if [ $? -eq 0 ]; then
    echo "✅ Production build completed successfully!"
    echo "📁 Files are in: build/web/"
    
    # Find available port for serving
    PORT=4000
    while lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null ; do
        PORT=$((PORT+1))
    done
    
    echo "🌐 Starting production server on port $PORT..."
    echo "🔗 Access your app at: http://localhost:$PORT"
    
    # Serve the production build
    python3 -m http.server $PORT --directory build/web
else
    echo "❌ Build failed. Please check the errors above."
    exit 1
fi
