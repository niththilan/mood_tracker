import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mood_tracker/services/user_profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('User Profile Service Tests', () {
    setUpAll(() async {
      // Mock SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});

      // Initialize Supabase for testing
      await Supabase.initialize(
        url: 'https://xxasezacvotitccxnpaa.supabase.co',
        anonKey:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh4YXNlemFjdm90aXRjY3hucGFhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg1ODE3MTIsImV4cCI6MjA2NDE1NzcxMn0.aUygIOPiI1HqFwKifXGYIolzeIQGbpjzGCC861LHRS4',
      );
    });

    test(
      'UserProfileService class should be defined and methods should exist',
      () {
        // Test that the UserProfileService class exists and has the expected methods
        expect(UserProfileService.createUserProfile, isA<Function>());
        expect(UserProfileService.getUserProfile, isA<Function>());
        expect(UserProfileService.updateUserProfile, isA<Function>());
      },
    );

    test('Profile data validation should work correctly', () async {
      // Test empty user ID - should return false
      final result1 = await UserProfileService.createUserProfile(
        userId: '',
        name: 'Test',
      );
      expect(result1, isFalse, reason: 'Empty userId should return false');

      // Test empty name - should return false
      final result2 = await UserProfileService.createUserProfile(
        userId: '123e4567-e89b-12d3-a456-426614174000',
        name: '',
      );
      expect(result2, isFalse, reason: 'Empty name should return false');

      // Test whitespace-only name - should return false
      final result3 = await UserProfileService.createUserProfile(
        userId: '123e4567-e89b-12d3-a456-426614174000',
        name: '   ',
      );
      expect(
        result3,
        isFalse,
        reason: 'Whitespace-only name should return false',
      );
    });
  });
}
