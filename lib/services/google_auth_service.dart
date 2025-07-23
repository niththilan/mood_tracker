import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'supabase_config.dart';

/// Google Authentication Service using Supabase OAuth only
class GoogleAuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Initialize Google Sign-In for Supabase OAuth (simplified)
  static Future<void> initialize() async {
    try {
      if (kDebugMode) {
        print('Initializing Google Auth Service for Supabase OAuth...');
        print('Supabase URL: ${SupabaseConfig.supabaseUrl}');
        print('OAuth Callback URL: ${SupabaseConfig.oauthCallbackUrl}');
        print('Platform: ${kIsWeb ? 'Web' : 'Mobile'}');
      }

      // No platform-specific initialization needed for Supabase OAuth
      // All authentication goes through Supabase
      
      if (kDebugMode) {
        print('✅ Google Auth Service initialized successfully');
        print('Ready to use Supabase OAuth for all platforms');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Google Sign-In initialization error: $error');
      }
      // Don't throw the error - let the app continue
    }
  }

  /// Sign in with Google using Supabase OAuth only
  static Future<AuthResponse?> signInWithGoogle() async {
    try {
      if (kDebugMode) {
        print('Starting Supabase Google OAuth...');
        print('Platform: ${kIsWeb ? 'Web' : 'Mobile'}');
        print('Supabase URL: ${SupabaseConfig.supabaseUrl}');
      }

      // Always use Supabase OAuth for all platforms
      return await _signInWithSupabaseOAuth();
    } catch (error) {
      if (kDebugMode) {
        print('Google Sign-In error: $error');
      }
      rethrow;
    }
  }

  /// Web sign-in using Supabase OAuth (universal for all platforms)
  static Future<AuthResponse?> _signInWithSupabaseOAuth() async {
    try {
      if (kDebugMode) {
        print('Using Supabase OAuth for Google Sign-In...');
        print('Redirect URL: ${SupabaseConfig.getRedirectUrl()}');
      }

      // Use Supabase's built-in Google OAuth for all platforms
      final bool success = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: SupabaseConfig.getRedirectUrl(),
        authScreenLaunchMode: LaunchMode.platformDefault,
      );

      if (kDebugMode) {
        print('Supabase OAuth initiated: $success');
      }

      // For OAuth, we don't get an immediate response
      // The user will be redirected and auth state will change when they return
      return null;
    } catch (error) {
      if (kDebugMode) {
        print('Supabase OAuth failed: $error');
      }

      // Provide clear error message to user
      throw Exception(
        'Google Sign-In failed: $error\n\n'
        '💡 Alternative: Use email/password sign-in instead!\n'
        'Email authentication is more reliable.',
      );
    }
  }

  /// Check if user is signed in (through Supabase)
  static Future<bool> isSignedIn() async {
    try {
      return _supabase.auth.currentUser != null;
    } catch (error) {
      if (kDebugMode) {
        print('Error checking sign-in status: $error');
      }
      return false;
    }
  }

  /// Sign out from Supabase (handles all OAuth providers)
  static Future<void> signOut() async {
    try {
      if (kDebugMode) {
        print('Signing out from Supabase...');
      }

      // Sign out from Supabase (handles all OAuth providers including Google)
      await _supabase.auth.signOut();

      if (kDebugMode) {
        print('Supabase sign-out completed');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Sign out error: $error');
      }
      // Don't throw errors for sign-out as it's not critical
    }
  }

  /// Clear all authentication state (Supabase handles all OAuth providers)
  static Future<void> clearAuthState() async {
    try {
      if (kDebugMode) {
        print('Clearing auth state...');
      }

      // Sign out from Supabase with global scope
      await _supabase.auth.signOut(scope: SignOutScope.global);

      if (kDebugMode) {
        print('Auth state cleared');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error clearing auth state: $error');
      }
    }
  }

  /// Force sign out and clear all auth state
  static Future<void> forceSignOut() async {
    try {
      if (kDebugMode) {
        print('Force signing out to clear any stuck auth state...');
      }

      // Sign out from Supabase with global scope
      await _supabase.auth.signOut(scope: SignOutScope.global);

      if (kDebugMode) {
        print('Force sign-out completed');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error during force sign-out: $error');
      }
    }
  }

  /// Test the Google Sign-In configuration
  static Future<Map<String, dynamic>> testConfiguration() async {
    final result = <String, dynamic>{};

    try {
      result['platform'] = kIsWeb ? 'web' : 'mobile';
      result['supabaseUrl'] = SupabaseConfig.supabaseUrl;
      result['callbackUrl'] = SupabaseConfig.oauthCallbackUrl;
      result['redirectUrl'] = SupabaseConfig.getRedirectUrl();
      result['webClientId'] = SupabaseConfig.googleWebClientId;
      result['currentSupabaseUser'] = _supabase.auth.currentUser?.email;
      result['hasSupabaseSession'] = _supabase.auth.currentSession != null;
    } catch (error) {
      result['error'] = error.toString();
    }

    return result;
  }

  static Future testIOSConfiguration() async {}
}
