#!/bin/bash

# Flutter Web Development Server Runner
# This script runs the Flutter web server on port 3000 to avoid conflicts

echo "🚀 Starting Flutter Web Development Server on port 3000..."
echo "📱 Your MoodFlow app will be available at: http://localhost:3000"
echo ""

cd "$(dirname "$0")"
flutter run -d web-server --web-port 3000

echo ""
echo "✅ Flutter Web Development Server stopped."
