#!/bin/bash

echo "🔧 Android Google Sign-In Debug Script"
echo "======================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📱 Checking Android Configuration...${NC}"

# Check if android project exists
if [ -d "android" ]; then
    echo -e "${GREEN}✅ Android project found${NC}"
else
    echo -e "${RED}❌ Android project not found${NC}"
    exit 1
fi

# Check google-services.json
if [ -f "android/app/google-services.json" ]; then
    echo -e "${GREEN}✅ google-services.json found${NC}"
    
    # Check if it contains actual values or placeholders
    if grep -q "SHA1_CERTIFICATE_HASH" "android/app/google-services.json"; then
        echo -e "${YELLOW}⚠️  WARNING: google-services.json contains placeholder SHA1_CERTIFICATE_HASH${NC}"
        echo -e "${YELLOW}   You need to add your actual SHA-1 certificate fingerprint${NC}"
    else
        echo -e "${GREEN}✅ google-services.json appears to have real certificate hashes${NC}"
    fi
    
    # Check package name
    if grep -q "com.example.mood_tracker" "android/app/google-services.json"; then
        echo -e "${GREEN}✅ Package name matches: com.example.mood_tracker${NC}"
    else
        echo -e "${RED}❌ Package name mismatch in google-services.json${NC}"
    fi
else
    echo -e "${RED}❌ google-services.json not found${NC}"
fi

# Check AndroidManifest.xml
if [ -f "android/app/src/main/AndroidManifest.xml" ]; then
    echo -e "${GREEN}✅ AndroidManifest.xml found${NC}"
    
    # Check for deep link configuration
    if grep -q "com.moodtracker.app" "android/app/src/main/AndroidManifest.xml"; then
        echo -e "${GREEN}✅ Deep link configuration found${NC}"
    else
        echo -e "${YELLOW}⚠️  Deep link configuration missing${NC}"
    fi
    
    # Check for internet permission
    if grep -q "android.permission.INTERNET" "android/app/src/main/AndroidManifest.xml"; then
        echo -e "${GREEN}✅ Internet permission found${NC}"
    else
        echo -e "${RED}❌ Internet permission missing${NC}"
    fi
else
    echo -e "${RED}❌ AndroidManifest.xml not found${NC}"
fi

# Check build.gradle.kts
if [ -f "android/app/build.gradle.kts" ]; then
    echo -e "${GREEN}✅ build.gradle.kts found${NC}"
    
    # Check for google-services plugin
    if grep -q "com.google.gms.google-services" "android/app/build.gradle.kts"; then
        echo -e "${GREEN}✅ Google Services plugin configured${NC}"
    else
        echo -e "${RED}❌ Google Services plugin missing${NC}"
    fi
else
    echo -e "${RED}❌ build.gradle.kts not found${NC}"
fi

# Check ProGuard rules
if [ -f "android/app/proguard-rules.pro" ]; then
    echo -e "${GREEN}✅ ProGuard rules found${NC}"
else
    echo -e "${YELLOW}⚠️  ProGuard rules not found (recommended for release builds)${NC}"
fi

echo ""
echo -e "${BLUE}🔐 Checking Certificate Configuration...${NC}"

# Check for debug keystore
DEBUG_KEYSTORE="$HOME/.android/debug.keystore"
if [ -f "$DEBUG_KEYSTORE" ]; then
    echo -e "${GREEN}✅ Debug keystore found${NC}"
    echo -e "${BLUE}📋 SHA-1 fingerprint:${NC}"
    keytool -list -v -keystore "$DEBUG_KEYSTORE" -alias androiddebugkey -storepass android -keypass android 2>/dev/null | grep SHA1 | head -1
else
    echo -e "${YELLOW}⚠️  Debug keystore not found. Run 'flutter build apk' to generate it.${NC}"
fi

echo ""
echo -e "${BLUE}📦 Checking Dependencies...${NC}"

# Check pubspec.yaml for google_sign_in
if grep -q "google_sign_in:" "pubspec.yaml"; then
    echo -e "${GREEN}✅ google_sign_in dependency found${NC}"
    grep "google_sign_in:" "pubspec.yaml"
else
    echo -e "${RED}❌ google_sign_in dependency missing${NC}"
fi

echo ""
echo -e "${BLUE}🔧 Next Steps:${NC}"
echo "1. Run './get_sha1.sh' to get your SHA-1 certificate hash"
echo "2. Add the SHA-1 hash to Firebase Console > Project Settings > Your Apps > Android App"
echo "3. Download the updated google-services.json and replace the current one"
echo "4. Test on a real device with Google Play Services installed"
echo "5. Check device logs: 'flutter logs' while testing"

echo ""
echo -e "${BLUE}🐛 Common Issues:${NC}"
echo "• SHA-1 certificate not added to Firebase Console"
echo "• Google Play Services not installed/updated on device"
echo "• Network connectivity issues"
echo "• App not registered in Google Cloud Console"
echo "• Incorrect package name configuration"

echo ""
echo -e "${GREEN}Debug script completed!${NC}"
