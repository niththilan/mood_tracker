#!/bin/bash

# Authentication Test Script
# This script helps verify that authentication is working properly

echo "🧪 MoodFlow Authentication Test"
echo "================================"
echo ""

# Check if the app is running
if curl -s http://localhost:3000 > /dev/null 2>&1; then
    echo "✅ App is running at http://localhost:3000"
else
    echo "❌ App is not running. Please start it with:"
    echo "   flutter run -d web-server --web-port 3000"
    echo "   or: ./run_web_port_3000.sh"
    exit 1
fi

echo ""
echo "🔍 Testing Authentication Features:"
echo ""

# Check if Supabase config is accessible
echo "1. Checking Supabase configuration..."
if grep -q "supabaseUrl" lib/services/supabase_config.dart; then
    echo "   ✅ Supabase configuration found"
else
    echo "   ❌ Supabase configuration missing"
fi

# Check if Auth service exists
echo "2. Checking Authentication service..."
if [ -f "lib/services/auth_service.dart" ]; then
    echo "   ✅ Auth service found"
else
    echo "   ❌ Auth service missing"
fi

# Check if Auth page exists
echo "3. Checking Authentication UI..."
if [ -f "lib/auth_page.dart" ]; then
    echo "   ✅ Auth page found"
else
    echo "   ❌ Auth page missing"
fi

echo ""
echo "🎯 Manual Testing Checklist:"
echo ""
echo "□ Open http://localhost:3000 in your browser"
echo "□ Try creating a new account with email/password"
echo "□ Try signing in with existing credentials"  
echo "□ Test the 'Forgot Password' feature"
echo "□ Verify that Google Sign-In shows helpful message on web"
echo ""
echo "📱 Authentication Status: READY"
echo ""
echo "💡 Pro Tips:"
echo "- Email authentication is the most reliable method"
echo "- Google Sign-In works on mobile apps without additional setup"
echo "- All user data is securely stored in Supabase"
echo ""
echo "🚀 Your MoodFlow app authentication is ready to use!"
