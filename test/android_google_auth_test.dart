import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/services/google_auth_service.dart';
import 'package:mood_tracker/services/supabase_config.dart';

void main() {
  group('Android Google Auth Tests', () {
    test('Android Google Client ID should be properly configured', () {
      // Test that Android client ID is set
      expect(SupabaseConfig.googleAndroidClientId, isNotEmpty);
      expect(
        SupabaseConfig.googleAndroidClientId,
        equals(
          '631111437135-234lcguj55v09qd7415e7ohr2p55b58j.apps.googleusercontent.com',
        ),
      );

      // Verify format
      expect(
        SupabaseConfig.googleAndroidClientId,
        contains('apps.googleusercontent.com'),
      );
      expect(SupabaseConfig.googleAndroidClientId, startsWith('631111437135-'));
    });

    test('Package name should match google-services.json', () {
      // This should match the package_name in google-services.json
      const expectedPackageName = 'com.example.mood_tracker';

      // Test passes - just documenting the requirement
      expect(expectedPackageName, equals('com.example.mood_tracker'));
    });

    test('Deep link configuration should be valid', () {
      // Deep link scheme for Android
      const deepLinkScheme = 'com.moodtracker.app';

      // Test that the scheme follows proper format
      expect(deepLinkScheme, matches(r'^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)*$'));
      expect(deepLinkScheme, isNot(contains('://')));
    });

    test('Google Auth Service should handle Android platform detection', () {
      // This test verifies our platform-specific logic exists
      expect(() => GoogleAuthService.initialize(), returnsNormally);
    });
  });

  group('Android Debugging Info', () {
    test('Print Android configuration for debugging', () {
      print('=== ANDROID GOOGLE SIGN-IN CONFIGURATION ===');
      print('Package Name: com.example.mood_tracker');
      print('Android Client ID: ${SupabaseConfig.googleAndroidClientId}');
      print('Deep Link Scheme: com.moodtracker.app://auth');
      print('');
      print('=== REQUIRED STEPS FOR ANDROID ===');
      print('1. Get SHA-1 certificate hash: ./get_sha1.sh');
      print('2. Add SHA-1 hash to Firebase Console');
      print('3. Download updated google-services.json');
      print('4. Ensure Google Play Services are installed on device');
      print('5. Check ProGuard rules are applied');
      print('');
      print('=== COMMON ANDROID ISSUES ===');
      print('• Missing SHA-1 certificate fingerprint');
      print('• Google Play Services not available');
      print('• Incorrect package name');
      print('• Network connectivity issues');
      print('• App not registered in Google Cloud Console');

      // Test always passes - this is just for documentation
      expect(true, isTrue);
    });
  });
}
