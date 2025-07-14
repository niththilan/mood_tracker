#!/bin/bash

# Flutter Web Development Server with Fixed Port
# This ensures Google OAuth works with predictable redirect URLs

echo "🚀 Starting Mood Tracker on fixed port 8080..."
echo "📍 URL: http://localhost:8080"
echo "🔧 Configure Google Cloud Console with: http://localhost:8080"
echo ""

flutter run -d chrome --web-port=8080
