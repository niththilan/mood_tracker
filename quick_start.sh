#!/bin/bash

# Quick Start Script for MoodFlow Web App
# This script optimizes the startup time for development

echo "🚀 Starting MoodFlow in Fast Mode..."

# Kill any existing Flutter processes
pkill -f "flutter run" 2>/dev/null || true
pkill -f "http.server" 2>/dev/null || true

# Find available port
PORT=3000
while lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null ; do
    PORT=$((PORT+1))
done

echo "📱 Starting Flutter web server on port $PORT..."

# Start Flutter in profile mode (faster than debug, but with debugging capabilities)
flutter run -d web-server --web-port $PORT --profile --dart-define=FLUTTER_WEB_AUTO_DETECT=true &

# Wait for server to start
sleep 3

echo "✅ MoodFlow is starting at http://localhost:$PORT"
echo "🔧 Profile mode enables fast hot reload and good performance"
echo "🛑 Press Ctrl+C to stop the development server"

# Keep script running
wait
