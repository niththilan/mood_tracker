import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

/// Core authentication service for Supabase
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Stream of authentication state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Current session
  Session? get currentSession => _supabase.auth.currentSession;

  /// Current user
  User? get currentUser => _supabase.auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => currentSession != null && currentUser != null;

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (kDebugMode) {
        print('Email sign-in successful for: ${response.user?.email}');
      }

      return response;
    } catch (error) {
      if (kDebugMode) {
        print('Email sign-in error: $error');
      }
      rethrow;
    }
  }

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmailPassword({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: data,
      );

      if (kDebugMode) {
        print('Email sign-up initiated for: $email');
      }

      return response;
    } catch (error) {
      if (kDebugMode) {
        print('Email sign-up error: $error');
      }
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);

      if (kDebugMode) {
        print('Password reset email sent to: $email');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Password reset error: $error');
      }
      rethrow;
    }
  }

  /// Send password reset email (alias for resetPassword)
  Future<void> sendPasswordResetEmail(String email) async {
    return resetPassword(email);
  }

  /// Verify OTP for email confirmation or password reset
  Future<AuthResponse> verifyOTP({
    required String email,
    required String token,
    required OtpType type,
  }) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: type,
      );

      if (kDebugMode) {
        print('OTP verification successful for: $email');
      }

      return response;
    } catch (error) {
      if (kDebugMode) {
        print('OTP verification error: $error');
      }
      rethrow;
    }
  }

  /// Verify password reset OTP (alias for verifyOTP)
  Future<AuthResponse> verifyPasswordResetOtp({
    required String email,
    required String token,
  }) async {
    return verifyOTP(email: email, token: token, type: OtpType.recovery);
  }

  /// Update user password (when authenticated)
  Future<UserResponse> updatePassword(String newPassword) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (kDebugMode) {
        print('Password updated successfully');
      }

      return response;
    } catch (error) {
      if (kDebugMode) {
        print('Password update error: $error');
      }
      rethrow;
    }
  }

  /// Update user profile data
  Future<UserResponse> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(data: data),
      );

      if (kDebugMode) {
        print('Profile updated successfully');
      }

      return response;
    } catch (error) {
      if (kDebugMode) {
        print('Profile update error: $error');
      }
      rethrow;
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();

      if (kDebugMode) {
        print('User signed out successfully');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Sign out error: $error');
      }
      // Don't rethrow sign-out errors as they're not critical
    }
  }

  /// Get user-friendly error message
  String getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('invalid_credentials') ||
        errorString.contains('invalid login credentials')) {
      return 'Invalid email or password. Please try again.';
    } else if (errorString.contains('email_not_confirmed')) {
      return 'Please check your email and confirm your account.';
    } else if (errorString.contains('signup_disabled')) {
      return 'Account registration is currently disabled.';
    } else if (errorString.contains('weak_password')) {
      return 'Password is too weak. Please choose a stronger password.';
    } else if (errorString.contains('email_already_exists') ||
        errorString.contains('user_already_registered')) {
      return 'An account with this email already exists.';
    } else if (errorString.contains('invalid_email')) {
      return 'Please enter a valid email address.';
    } else if (errorString.contains('rate_limit_exceeded')) {
      return 'Too many attempts. Please wait a moment and try again.';
    } else if (errorString.contains('network') ||
        errorString.contains('connection')) {
      return 'Network error. Please check your internet connection.';
    } else if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else {
      return 'An error occurred. Please try again.';
    }
  }

  /// Refresh the current session
  Future<AuthResponse?> refreshSession() async {
    try {
      final response = await _supabase.auth.refreshSession();

      if (kDebugMode) {
        print('Session refreshed successfully');
      }

      return response;
    } catch (error) {
      if (kDebugMode) {
        print('Session refresh error: $error');
      }
      return null;
    }
  }
}
