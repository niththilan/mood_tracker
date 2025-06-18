import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Auth Page Validation Tests', () {
    setUp(() {
      // Note: These validation functions are extracted for testing purposes
      // They mirror the actual validation logic used in AuthPage
    });

    test('Age validation should work correctly', () {
      // Test valid ages
      expect(_validateAge('18'), isNull);
      expect(_validateAge('25'), isNull);
      expect(_validateAge('65'), isNull);

      // Test invalid ages
      expect(_validateAge('12'), isNotNull); // Too young
      expect(_validateAge('121'), isNotNull); // Too old
      expect(_validateAge('abc'), isNotNull); // Not a number
      expect(_validateAge(''), isNotNull); // Empty
    });

    test('Gender validation should work correctly', () {
      // Test valid gender selections
      expect(_validateGender('male'), isNull);
      expect(_validateGender('female'), isNull);
      expect(_validateGender('non-binary'), isNull);
      expect(_validateGender('prefer-not-to-say'), isNull);

      // Test invalid gender selection
      expect(_validateGender(null), isNotNull);
      expect(_validateGender(''), isNotNull);
    });

    test('Name validation should work correctly', () {
      // Test valid names
      expect(_validateName('John Doe'), isNull);
      expect(_validateName('Alice Smith'), isNull);

      // Test invalid names
      expect(_validateName('A'), isNotNull); // Too short
      expect(_validateName(''), isNotNull); // Empty
      expect(_validateName('A' * 51), isNotNull); // Too long
    });
  });
}

// Mock validation functions for testing
// (In the actual implementation, these would be extracted to a service)
String? _validateAge(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Age is required';
  }
  final age = int.tryParse(value.trim());
  if (age == null) {
    return 'Please enter a valid age';
  }
  if (age < 13) {
    return 'You must be at least 13 years old';
  }
  if (age > 120) {
    return 'Please enter a valid age';
  }
  return null;
}

String? _validateGender(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please select your gender';
  }
  return null;
}

String? _validateName(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Name is required';
  }
  if (value.trim().length < 2) {
    return 'Name must be at least 2 characters';
  }
  if (value.trim().length > 50) {
    return 'Name must be less than 50 characters';
  }
  return null;
}
