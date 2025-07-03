import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'supabase_config.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        kIsWeb
            ? SupabaseConfig.googleWebClientId
            : null, // Mobile platforms use google-services.json or iOS config
    scopes: ['email', 'profile'],
    // Add server client ID for web to get ID tokens
    serverClientId: kIsWeb ? SupabaseConfig.googleWebClientId : null,
  );

  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Sign in with Google using appropriate flow for platform
  static Future<AuthResponse?> signInWithGoogle() async {
    try {
      print('🔍 Starting Google Sign-In...');
      print('🌐 Running on web: $kIsWeb');

      // For web, use Google Sign-In package with proper web configuration
      if (kIsWeb) {
        return await _signInWithGoogleSignInWeb();
      }

      // For mobile, use Google Sign-In package
      return await _signInWithGoogleSignInMobile();
    } catch (error) {
      print('❌ Google Sign-In Error: $error');
      throw Exception(_getErrorMessage(error));
    }
  }

  /// Web Google Sign-In flow using GoogleSignIn package
  static Future<AuthResponse?> _signInWithGoogleSignInWeb() async {
    print('🌐 Using web Google Sign-In flow...');

    try {
      // Trigger the Google Sign-In flow
      print('🚀 Initiating Google Sign-In for web...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('❌ User cancelled the sign-in');
        return null;
      }

      print('✅ Google user obtained: ${googleUser.email}');

      // Get the authentication details
      print('🔑 Getting authentication details...');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      print('📄 ID Token available: ${googleAuth.idToken != null}');
      print('🎫 Access Token available: ${googleAuth.accessToken != null}');

      if (googleAuth.idToken == null) {
        throw Exception('No ID token received from Google');
      }

      // Sign in to Supabase with the Google ID token
      print('� Signing in to Supabase with Google credentials...');
      final AuthResponse response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      print('✅ Supabase authentication successful');
      return response;
    } catch (error) {
      print('❌ Web Google Sign-In error: $error');

      // Fallback to Supabase OAuth for web if GoogleSignIn fails
      print('🔄 Trying Supabase OAuth as fallback...');
      return await _signInWithSupabaseOAuth();
    }
  }

  /// Mobile Google Sign-In flow
  static Future<AuthResponse?> _signInWithGoogleSignInMobile() async {
    print('📱 Using mobile Google Sign-In flow...');

    // Trigger the Google Sign-In flow
    print('🚀 Initiating Google Sign-In...');
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      print('❌ User cancelled the sign-in');
      return null;
    }

    print('✅ Google user obtained: ${googleUser.email}');

    // Get the authentication details
    print('🔑 Getting authentication details...');
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    print('📄 ID Token available: ${googleAuth.idToken != null}');
    print('🎫 Access Token available: ${googleAuth.accessToken != null}');

    if (googleAuth.idToken == null) {
      throw Exception('No ID token received from Google');
    }

    // Sign in to Supabase with the Google ID token
    print('🔗 Signing in to Supabase with Google credentials...');
    final AuthResponse response = await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: googleAuth.idToken!,
      accessToken: googleAuth.accessToken,
    );

    print('✅ Supabase authentication successful');
    return response;
  }

  /// Supabase OAuth flow (fallback for web)
  static Future<AuthResponse?> _signInWithSupabaseOAuth() async {
    print('🌐 Using Supabase OAuth flow...');

    try {
      final bool success = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo:
            kIsWeb
                ? '${Uri.base.origin}/auth/callback'
                : SupabaseConfig.oauthCallbackUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      if (success) {
        print('✅ Supabase OAuth authentication initiated');
        // Wait for the auth state change
        final User? user = _supabase.auth.currentUser;
        if (user != null) {
          return AuthResponse(
            user: user,
            session: _supabase.auth.currentSession,
          );
        }
      }

      return null;
    } catch (error) {
      print('❌ Supabase OAuth error: $error');
      throw error;
    }
  }

  /// Get user-friendly error message
  static String _getErrorMessage(dynamic error) {
    String errorString = error.toString();

    if (errorString.contains('network_error')) {
      return 'Network error. Please check your internet connection.';
    } else if (errorString.contains('sign_in_canceled')) {
      return 'Sign-in was cancelled.';
    } else if (errorString.contains('sign_in_failed')) {
      return 'Google Sign-in failed. Please try again.';
    } else if (errorString.contains('developer_error')) {
      return 'Configuration error. Please contact support.';
    } else if (errorString.contains('invalid_request')) {
      return 'Invalid request. Please check your configuration.';
    } else {
      return 'Google sign-in failed: $errorString';
    }
  }

  /// Sign out from both Google and Supabase
  static Future<void> signOut() async {
    try {
      // Sign out from Google
      if (kIsWeb) {
        // For web, we need to handle both GoogleSignIn and Supabase OAuth
        await _googleSignIn.signOut();
        await _googleSignIn.disconnect(); // Clear cached credentials on web
      } else {
        await _googleSignIn.signOut();
      }

      // Sign out from Supabase
      await _supabase.auth.signOut();

      print('✅ Successfully signed out from Google and Supabase');
    } catch (error) {
      print('❌ Sign out error: $error');
      // Don't throw error for sign out failures, just log them
    }
  }

  /// Check if user is currently signed in with Google
  static Future<bool> isSignedIn() async {
    try {
      final isGoogleSignedIn = await _googleSignIn.isSignedIn();
      final isSupabaseSignedIn = _supabase.auth.currentUser != null;

      return isGoogleSignedIn || isSupabaseSignedIn;
    } catch (error) {
      print('❌ Error checking sign-in status: $error');
      return false;
    }
  }

  /// Get current Google user
  static GoogleSignInAccount? getCurrentUser() {
    return _googleSignIn.currentUser;
  }

  /// Initialize Google Sign-In for web (call this early in app lifecycle)
  static Future<void> initializeForWeb() async {
    if (kIsWeb) {
      try {
        await _googleSignIn.signInSilently();
        print('✅ Google Sign-In initialized for web');
      } catch (error) {
        print(
          'ℹ️ Silent sign-in failed (expected if user not previously signed in): $error',
        );
      }
    }
  }
}
