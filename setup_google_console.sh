#!/bin/bash

# Google Cloud Console Quick Setup Script
# This script helps you configure Google OAuth for Flutter web

echo "🚀 Google Cloud Console Setup Helper"
echo "===================================="
echo ""

echo "📝 Current Configuration:"
echo "Web Client ID: 123456789-abcdefghijklmnopqrstuvwxyz123456.apps.googleusercontent.com"
echo "App running on: http://localhost:3000"
echo ""

echo "🔧 Required Google Cloud Console Settings:"
echo ""
echo "1. Authorized JavaScript Origins:"
echo "   - http://localhost:3000"
echo "   - http://localhost:8080"
echo "   - http://localhost:50958"
echo "   - http://127.0.0.1:3000"
echo "   - http://127.0.0.1:8080"
echo ""

echo "2. Authorized Redirect URIs:"
echo "   - http://localhost:3000/auth/callback"
echo "   - http://localhost:8080/auth/callback"
echo "   - http://localhost:50958/auth/callback"
echo "   - http://127.0.0.1:3000/auth/callback"
echo "   - http://127.0.0.1:8080/auth/callback"
echo ""

echo "📋 Steps to Fix:"
echo "1. Go to https://console.cloud.google.com/"
echo "2. Navigate to APIs & Services → Credentials"
echo "3. Edit your OAuth 2.0 client ID"
echo "4. Add the URLs above"
echo "5. Save and wait 5-10 minutes"
echo ""

echo "✅ After updating Google Console, test at:"
echo "   http://localhost:3000"
echo ""

echo "🔄 To run Flutter on fixed port:"
echo "   flutter run -d chrome --web-port=3000"
echo ""

# Check if Flutter is running on port 3000
if lsof -i :3000 &> /dev/null; then
    echo "✅ Flutter is running on port 3000"
else
    echo "❌ Flutter is not running on port 3000"
    echo "   Run: flutter run -d chrome --web-port=3000"
fi

echo ""
echo "🎯 Your app should be available at: http://localhost:3000"
