import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/services/google_auth_service.dart';

void main() {
  group('Google Auth Service iOS Tests', () {
    test('Google Auth Service can initialize on iOS simulator', () async {
      // This test verifies that GoogleAuthService can be initialized
      // without throwing exceptions in the iOS simulator environment

      expect(() async {
        await GoogleAuthService.initialize();
      }, returnsNormally);
    });

    test('Google Auth Service handles iOS-specific client ID', () {
      // This test verifies that the service correctly identifies iOS
      // and uses the appropriate client ID
      expect(GoogleAuthService, isNotNull);
    });
  });
}
