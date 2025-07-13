#!/bin/bash

# Script to fix Supabase redirect loops by clearing browser data
echo "🔧 Fixing Supabase OAuth redirect loops..."

# Kill any running Flutter processes
pkill -f "flutter"
pkill -f "dart"

# Clear browser cache for Chrome (macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "📱 Clearing Chrome cache on macOS..."
    rm -rf ~/Library/Caches/Google/Chrome/Default/Cache
    rm -rf ~/Library/Caches/Google/Chrome/Default/Code\ Cache
    rm -rf ~/Library/Application\ Support/Google/Chrome/Default/Local\ Storage
    rm -rf ~/Library/Application\ Support/Google/Chrome/Default/Session\ Storage
    rm -rf ~/Library/Application\ Support/Google/Chrome/Default/IndexedDB
fi

# Clear Flutter build cache
echo "🧹 Cleaning Flutter build cache..."
flutter clean

# Clear pub cache for Supabase
echo "📦 Clearing pub cache..."
flutter pub cache clean --force

# Get dependencies
echo "📥 Getting dependencies..."
flutter pub get

echo "✅ Cache cleared! Now you can try running your app again."
echo "💡 Run: flutter run -d chrome --web-browser-flag=\"--disable-web-security\""
echo "🌐 This will start Chrome with relaxed security for development."
