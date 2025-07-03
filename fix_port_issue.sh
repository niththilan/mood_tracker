#!/bin/bash

echo "🚨 Google OAuth Port Mismatch Fix"
echo ""
echo "Current Error: redirect_uri_mismatch on port 50958"
echo "Solution: Use fixed port instead of random ports"
echo ""

echo "🛑 Step 1: Stop any running Flutter processes"
echo "Press Ctrl+C in any terminal running Flutter"
echo ""

echo "🚀 Step 2: Run Flutter on fixed port"
echo "Run this command:"
echo "   flutter run -d chrome --web-port=3000"
echo ""

echo "🌐 Step 3: Update Google Cloud Console"
echo ""
echo "1. Go to: https://console.cloud.google.com/"
echo "2. Navigate to: APIs & Services → Credentials"
echo "3. Find: 631111437135-l2a14dgadurrj360mbom28saane8fngu.apps.googleusercontent.com"
echo "4. Click Edit"
echo ""

echo "📍 Step 4: Add JavaScript Origins"
echo "Add these to 'Authorized JavaScript origins':"
echo "   ✓ http://localhost:3000"
echo "   ✓ http://localhost:8080"
echo "   ✓ http://localhost:50958"
echo "   ✓ http://127.0.0.1:3000"
echo "   ✓ http://127.0.0.1:8080"
echo "   ✓ http://127.0.0.1:50958"
echo ""

echo "🔄 Step 5: Add Redirect URIs"
echo "Add these to 'Authorized redirect URIs':"
echo "   ✓ http://localhost:3000/auth/callback"
echo "   ✓ http://localhost:8080/auth/callback"
echo "   ✓ http://localhost:50958/auth/callback"
echo "   ✓ http://127.0.0.1:3000/auth/callback"
echo "   ✓ http://127.0.0.1:8080/auth/callback"
echo "   ✓ http://127.0.0.1:50958/auth/callback"
echo "   ✓ https://xxasezacvotitccxnpaa.supabase.co/auth/v1/callback"
echo ""

echo "💾 Step 6: Save and wait 2-3 minutes"
echo ""

echo "🧪 Step 7: Test the fix"
echo "After updating Google Cloud Console, run:"
echo "   flutter run -d chrome --web-port=3000"
echo ""

echo "⚡ Quick run command:"
echo "flutter run -d chrome --web-port=3000"
echo ""

echo "✅ This will fix the random port issue!"
