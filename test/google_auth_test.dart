import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/services/google_auth_service.dart';
import 'package:mood_tracker/services/supabase_config.dart';

void main() {
  group('Google Auth Service Tests', () {
    test('Google Auth configuration should be valid', () {
      // Test that Google client IDs are properly configured
      expect(SupabaseConfig.googleWebClientId, isNotEmpty);
      expect(SupabaseConfig.googleAndroidClientId, isNotEmpty);
      expect(SupabaseConfig.googleIOSClientId, isNotEmpty);

      // Verify web client ID format
      expect(
        SupabaseConfig.googleWebClientId,
        contains('apps.googleusercontent.com'),
      );
    });

    test('GoogleAuthService should initialize without errors', () async {
      // This should not throw an exception
      expect(() => GoogleAuthService.initializeForWeb(), returnsNormally);
    });

    test('isSignedIn should return boolean without errors', () async {
      final result = await GoogleAuthService.isSignedIn();
      expect(result, isA<bool>());
    });
  });
}
