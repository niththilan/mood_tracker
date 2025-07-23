#!/bin/bash

echo "🔍 Debug Google Authentication Issues"
echo "====================================="

# Check if the app is running
echo "📱 App Status:"
if curl -s http://localhost:3001 > /dev/null; then
    echo "✅ App running on http://localhost:3001"
else
    echo "❌ App not running"
    exit 1
fi

echo ""
echo "🌐 Testing Supabase connectivity..."
if curl -s "https://xxasezacvotitccxnpaa.supabase.co/rest/v1/" -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh4YXNlemFjdm90aXRjY3hucGFhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg1ODE3MTIsImV4cCI6MjA2NDE1NzcxMn0.aUygIOPiI1HqFwKifXGYIolzeIQGbpjzGCC861LHRS4" > /dev/null; then
    echo "✅ Supabase API reachable"
else
    echo "❌ Supabase API not reachable"
fi

echo ""
echo "🔧 Next Steps to Fix Google Auth:"
echo ""
echo "1️⃣ SUPABASE DASHBOARD SETUP:"
echo "   → Go to: https://supabase.com/dashboard/project/xxasezacvotitccxnpaa/auth/providers"
echo "   → Enable Google OAuth provider"
echo "   → Add Client ID: 631111437135-iuippmjn73ur1g4thacjmr5lq3k315t0.apps.googleusercontent.com"
echo "   → Add Client Secret: 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"
echo ""
echo "2️⃣ SUPABASE URL CONFIGURATION:"
echo "   → Go to: https://supabase.com/dashboard/project/xxasezacvotitccxnpaa/auth/url-configuration"
echo "   → Add ALL these redirect URLs:"
echo "     • http://localhost:3001"
echo "     • http://localhost:3000" 
echo "     • http://localhost:8080"
echo "     • http://127.0.0.1:3001"
echo "     • http://127.0.0.1:3000"
echo "     • https://xxasezacvotitccxnpaa.supabase.co/auth/v1/callback"
echo ""
echo "3️⃣ GOOGLE CLOUD CONSOLE SETUP:"
echo "   → Go to: https://console.cloud.google.com/apis/credentials"
echo "   → Edit OAuth 2.0 Client: 631111437135-iuippmjn73ur1g4thacjmr5lq3k315t0"
echo "   → Authorized JavaScript origins:"
echo "     • http://localhost:3001"
echo "     • http://localhost:3000"
echo "     • http://localhost:8080"
echo "     • http://127.0.0.1:3001"
echo "     • http://127.0.0.1:3000"
echo "     • https://xxasezacvotitccxnpaa.supabase.co"
echo "   → Authorized redirect URIs:"
echo "     • https://xxasezacvotitccxnpaa.supabase.co/auth/v1/callback"
echo ""
echo "4️⃣ TEST THE FLOW:"
echo "   → Open: http://localhost:3001"
echo "   → Click 'Sign in with Google'"
echo "   → Should redirect to Google OAuth consent"
echo "   → Grant permissions"
echo "   → Should redirect back and sign in"
echo ""
echo "🚨 If still not working after setup, check browser console for errors!"
echo "   → Open Developer Tools (F12)"
echo "   → Check Console tab for error messages"
echo "   → Look for CORS, redirect_uri, or client_id errors"
echo ""
echo "📞 Quick Test Commands:"
echo "   → Test app: open http://localhost:3001"
echo "   → Browser console: F12 → Console tab"
echo "   → Network tab: Monitor OAuth requests"

# Test if Google's OAuth endpoint is reachable
echo ""
echo "🔍 Testing Google OAuth endpoint..."
if curl -s "https://accounts.google.com/.well-known/openid_configuration" > /dev/null; then
    echo "✅ Google OAuth service reachable"
else
    echo "❌ Google OAuth service not reachable (check internet connection)"
fi

echo ""
echo "✨ Once configured, Google Sign-In should work perfectly!"
echo "   The updated code uses proper Supabase OAuth integration."
