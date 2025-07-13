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

      // Verify specific client IDs match your provided values
      expect(
        SupabaseConfig.googleWebClientId,
        equals(
          '631111437135-bvvu4b15elvmctbclkbmag856kke0nmq.apps.googleusercontent.com',
        ),
      );
      expect(
        SupabaseConfig.googleAndroidClientId,
        equals(
          '631111437135-234lcguj55v09qd7415e7ohr2p55b58j.apps.googleusercontent.com',
        ),
      );
      expect(
        SupabaseConfig.googleIOSClientId,
        equals(
          '631111437135-jg42a9hahfchrrfhva4mbb0bddaq5g5f.apps.googleusercontent.com',
        ),
      );

      // Verify web client ID format
      expect(
        SupabaseConfig.googleWebClientId,
        contains('apps.googleusercontent.com'),
      );

      // Verify callback URL
      expect(
        SupabaseConfig.oauthCallbackUrl,
        equals('https://xxasezacvotitccxnpaa.supabase.co/auth/v1/callback'),
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

    test('Client IDs should have correct format', () {
      final webClientId = SupabaseConfig.googleWebClientId;
      final androidClientId = SupabaseConfig.googleAndroidClientId;
      final iosClientId = SupabaseConfig.googleIOSClientId;

      // All should start with the same project number
      expect(webClientId.startsWith('631111437135-'), isTrue);
      expect(androidClientId.startsWith('631111437135-'), isTrue);
      expect(iosClientId.startsWith('631111437135-'), isTrue);

      // All should end with .apps.googleusercontent.com
      expect(webClientId.endsWith('.apps.googleusercontent.com'), isTrue);
      expect(androidClientId.endsWith('.apps.googleusercontent.com'), isTrue);
      expect(iosClientId.endsWith('.apps.googleusercontent.com'), isTrue);
    });
  });
}
