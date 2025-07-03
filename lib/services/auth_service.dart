import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Stream of auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Current session
  Session? get currentSession => _supabase.auth.currentSession;

  // Current user
  User? get currentUser => _supabase.auth.currentUser;

  // Sign out method
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (error) {
      print('Error signing out: $error');
      rethrow;
    }
  }

  // Check if user is authenticated
  bool get isAuthenticated => currentSession != null;

  // Send password reset email with OTP
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      // Use resetPasswordForEmail to send password reset OTP
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (error) {
      print('Error sending password reset email: $error');
      throw Exception('Failed to send password reset email. Please try again.');
    }
  }

  // Verify OTP and get session for password reset
  Future<AuthResponse> verifyPasswordResetOtp({
    required String email,
    required String token,
  }) async {
    try {
      final AuthResponse response = await _supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.recovery, // Use recovery type for password reset
      );

      if (response.user == null) {
        throw Exception('Invalid or expired verification code');
      }

      return response;
    } catch (error) {
      print('Error verifying OTP: $error');
      throw Exception(
        'Invalid or expired verification code. Please try again.',
      );
    }
  }

  // Update password (used after password reset)
  Future<void> updatePassword(String newPassword) async {
    try {
      final UserResponse response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user == null) {
        throw Exception('Failed to update password');
      }
    } catch (error) {
      print('Error updating password: $error');
      throw Exception('Failed to update password. Please try again.');
    }
  }

  // Clear local data on sign out
  Future<void> clearLocalData() async {
    // Clear user-specific data but keep onboarding status
    // Add any other local data clearing logic here if needed
  }
}
