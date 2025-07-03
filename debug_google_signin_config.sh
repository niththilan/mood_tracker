#!/bin/bash

# Debug Google Sign-In Configuration
echo "=== Google Sign-In Configuration Debug ==="
echo ""

echo "1. Checking Supabase Configuration..."
echo "   - Supabase URL: https://xxasezacvotitccxnpaa.supabase.co"
echo "   - OAuth Callback URL: https://xxasezacvotitccxnpaa.supabase.co/auth/v1/callback"
echo ""

echo "2. Checking Google OAuth Client IDs..."
echo "   - Web Client ID: 631111437135-l2a14dgadurrj360mbom28saane8fngu.apps.googleusercontent.com"
echo "   - iOS Client ID: 631111437135-2d8044eqftkl17cut2ofhbc0t1g6p8pe.apps.googleusercontent.com"
echo "   - Android Client ID: 631111437135-1hsnu14039cna6pkm0g7vue1vh71freq.apps.googleusercontent.com"
echo ""

echo "3. Checking configuration files..."
echo "   - lib/services/supabase_config.dart: Updated ✓"
echo "   - web/index.html: Updated ✓"
echo "   - android/app/src/main/res/values/strings.xml: Updated ✓"
echo "   - ios/Runner/Info.plist: Updated ✓"
echo ""

echo "4. Testing configuration validity..."
echo "   - Web Client ID format: $(echo '631111437135-l2a14dgadurrj360mbom28saane8fngu.apps.googleusercontent.com' | grep -E '^[0-9]+-[a-z0-9]+\.apps\.googleusercontent\.com$' && echo 'Valid ✓' || echo 'Invalid ✗')"
echo "   - iOS Client ID format: $(echo '631111437135-2d8044eqftkl17cut2ofhbc0t1g6p8pe.apps.googleusercontent.com' | grep -E '^[0-9]+-[a-z0-9]+\.apps\.googleusercontent\.com$' && echo 'Valid ✓' || echo 'Invalid ✗')"
echo "   - Android Client ID format: $(echo '631111437135-1hsnu14039cna6pkm0g7vue1vh71freq.apps.googleusercontent.com' | grep -E '^[0-9]+-[a-z0-9]+\.apps\.googleusercontent\.com$' && echo 'Valid ✓' || echo 'Invalid ✗')"
echo ""

echo "5. Build and test recommendations..."
echo "   - For Web: Run 'flutter run -d chrome' and test Google Sign-In"
echo "   - For Android: Run 'flutter run -d android' and test Google Sign-In"
echo "   - For iOS: Run 'flutter run -d ios' and test Google Sign-In"
echo ""

echo "6. Next steps if issues occur..."
echo "   - Check Google Cloud Console OAuth 2.0 configuration"
echo "   - Verify Supabase Authentication provider setup"
echo "   - Check browser console for web-specific errors"
echo "   - Verify Android SHA1 fingerprint matches Google Console"
echo "   - Ensure iOS bundle identifier matches Google Console"
echo ""

echo "=== Configuration Update Complete ==="
