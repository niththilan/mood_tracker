#!/bin/bash

# Test Google Authentication Setup
echo "🧪 Testing Google Authentication Setup..."
echo "======================================"

# Check if required files exist
echo "📁 Checking required files..."
files=(
    "lib/services/google_auth_service.dart"
    "lib/services/supabase_config.dart"
    "android/app/google-services.json"
    "ios/Runner/GoogleService-Info.plist"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file exists"
    else
        echo "❌ $file missing"
    fi
done

echo ""

# Check Supabase configuration
echo "🔧 Checking Supabase configuration..."
grep -q "googleWebClientId" lib/services/supabase_config.dart && echo "✅ Google Web Client ID configured" || echo "❌ Google Web Client ID missing"
grep -q "googleAndroidClientId" lib/services/supabase_config.dart && echo "✅ Google Android Client ID configured" || echo "❌ Google Android Client ID missing"
grep -q "googleIOSClientId" lib/services/supabase_config.dart && echo "✅ Google iOS Client ID configured" || echo "❌ Google iOS Client ID missing"

echo ""

# Check Google Auth Service
echo "🔑 Checking Google Auth Service..."
grep -q "signInWithOAuth" lib/services/google_auth_service.dart && echo "✅ Supabase OAuth integration found" || echo "❌ Supabase OAuth integration missing"
grep -q "signInWithIdToken" lib/services/google_auth_service.dart && echo "✅ Mobile ID token auth found" || echo "❌ Mobile ID token auth missing"

echo ""

# Test web server
echo "🌐 Testing web server..."
if curl -s http://localhost:3000 > /dev/null; then
    echo "✅ Web server is running on localhost:3000"
else
    echo "❌ Web server not running. Start with: flutter run -d web-server --web-port 3000"
fi

echo ""

# Instructions
echo "📝 Next Steps:"
echo "1. Open http://localhost:3000 in your browser"
echo "2. Click 'Sign in with Google' button"
echo "3. Complete OAuth flow in popup/redirect"
echo "4. Verify authentication successful"
echo ""
echo "🔍 For mobile testing:"
echo "1. Run: flutter run -d <device>"
echo "2. Test Google Sign-In on device"
echo ""
echo "📚 See GOOGLE_AUTH_SUPABASE_SETUP.md for detailed configuration"
