# Debug Google Sign-in Issues Script

echo "🔍 Debugging Google Sign-in Issues..."
echo ""

# Check if google-services.json exists and is valid
echo "📱 Checking Android Configuration:"
if [ -f "android/app/google-services.json" ]; then
    echo "✅ google-services.json exists"
    # Check if it's not just a template
    if grep -q "REPLACE_WITH_YOUR_ACTUAL_PROJECT_ID" "android/app/google-services.json"; then
        echo "❌ google-services.json is still a template - needs actual configuration"
    else
        echo "✅ google-services.json appears to be configured"
    fi
else
    echo "❌ google-services.json missing"
fi

# Check SHA-1 fingerprint
echo ""
echo "🔑 Debug SHA-1 Fingerprint:"
echo "Run this command to get your debug SHA-1:"
echo "keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android -keypass android"

# Check iOS configuration
echo ""
echo "🍎 Checking iOS Configuration:"
if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    echo "✅ GoogleService-Info.plist exists"
else
    echo "❌ GoogleService-Info.plist missing"
fi

# Check package name consistency
echo ""
echo "📦 Checking Package Names:"
echo "Android package name in build.gradle.kts:"
grep "applicationId" android/app/build.gradle.kts

echo ""
echo "iOS bundle identifier in project.pbxproj:"
grep "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj | head -1

echo ""
echo "🔧 Next Steps:"
echo "1. Get proper google-services.json from Google Cloud Console"
echo "2. Add SHA-1 fingerprint to Google Cloud Console"  
echo "3. Ensure package names match between app and Google Console"
echo "4. For iOS: Add GoogleService-Info.plist"
echo "5. Update Supabase Auth settings with correct OAuth URLs"
