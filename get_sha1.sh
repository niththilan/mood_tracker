#!/bin/bash
# Script to get SHA-1 certificate hash for Google Sign-In configuration

echo "🔐 Getting SHA-1 Certificate Hash for Google Sign-In"
echo "=================================================="

# Get the debug keystore path
DEBUG_KEYSTORE="$HOME/.android/debug.keystore"

if [ -f "$DEBUG_KEYSTORE" ]; then
    echo "✅ Debug keystore found at: $DEBUG_KEYSTORE"
    echo ""
    echo "📋 SHA-1 Certificate Hash (for development):"
    echo "---------------------------------------------"
    keytool -list -v -keystore "$DEBUG_KEYSTORE" -alias androiddebugkey -storepass android -keypass android | grep SHA1
    echo ""
    echo "📝 Instructions:"
    echo "1. Copy the SHA1 hash above"
    echo "2. Go to Firebase Console > Project Settings > Your Apps > Android App"
    echo "3. Add this SHA1 fingerprint"
    echo "4. Download the updated google-services.json file"
    echo "5. Replace the existing google-services.json in android/app/"
    echo ""
    echo "🔧 For production release, you'll also need to add the SHA1 from your release keystore"
else
    echo "❌ Debug keystore not found!"
    echo "Please run 'flutter build apk' first to generate the debug keystore"
fi

echo ""
echo "📱 Application ID: com.example.mood_tracker"
echo "🌐 Package Name: com.example.mood_tracker"
echo ""
echo "🔗 Also ensure these URLs are configured in Google Cloud Console:"
echo "   - Deep Link: com.moodtracker.app://auth"
echo "   - Supabase Callback: https://xxasezacvotitccxnpaa.supabase.co/auth/v1/callback"
