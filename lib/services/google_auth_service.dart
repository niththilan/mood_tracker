import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'supabase_config.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? SupabaseConfig.googleWebClientId : null,
    scopes: ['email', 'profile'],
    // Note: serverClientId is not supported on web
  );

  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Sign in with Google using appropriate flow for platform
  static Future<AuthResponse?> signInWithGoogle() async {
    try {
      print('Starting Google Sign-In...');
      print('Running on web: $kIsWeb');

      // For web, use improved web configuration
      if (kIsWeb) {
        return await _signInWithGoogleWeb();
      }

      // For mobile, use standard Google Sign-In
      return await _signInWithGoogleMobile();
    } catch (error) {
      print('Google Sign-In Error: $error');
      throw Exception(_getErrorMessage(error));
    }
  }

  /// Improved Web Google Sign-In flow
  static Future<AuthResponse?> _signInWithGoogleWeb() async {
    print('Using improved web Google Sign-In flow...');

    try {
      // Try silent sign-in first (for returning users)
      print('Attempting silent sign-in...');
      GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();

      if (googleUser == null) {
        // If silent sign-in fails, proceed with interactive sign-in
        print('Silent sign-in failed, starting interactive sign-in...');
        googleUser = await _googleSignIn.signIn();
      }

      if (googleUser == null) {
        print('User cancelled the sign-in');
        return null;
      }

      print('Google user obtained: ${googleUser.email}');

      // Get authentication credentials
      print('Getting authentication details...');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      print('ID Token available: ${googleAuth.idToken != null}');
      print('Access Token available: ${googleAuth.accessToken != null}');

      // Validate that we have the required tokens
      if (googleAuth.idToken == null) {
        print('No ID token received, falling back to Supabase OAuth...');
        return await _signInWithSupabaseOAuth();
      }

      // Sign in to Supabase with Google credentials
      print('Signing in to Supabase with Google credentials...');
      final AuthResponse response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      print('Supabase authentication successful');
      return response;
    } catch (error) {
      print('Web Google Sign-In error: $error');

      // Handle specific error cases
      final errorString = error.toString().toLowerCase();

      if (errorString.contains('popup_closed') ||
          errorString.contains('user_cancelled') ||
          errorString.contains('cancelled')) {
        print('User cancelled sign-in');
        return null;
      }

      // For other errors, try Supabase OAuth as fallback
      if (errorString.contains('network') ||
          errorString.contains('timeout') ||
          errorString.contains('unknown_reason')) {
        print('Trying Supabase OAuth as fallback...');
        return await _signInWithSupabaseOAuth();
      }

      throw error;
    }
  }

  /// Mobile Google Sign-In flow
  static Future<AuthResponse?> _signInWithGoogleMobile() async {
    print('Using mobile Google Sign-In flow...');

    try {
      // Start Google Sign-In
      print('Initiating Google Sign-In...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('User cancelled the sign-in');
        return null;
      }

      print('Google user obtained: ${googleUser.email}');

      // Get authentication details
      print('Getting authentication details...');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      print('ID Token available: ${googleAuth.idToken != null}');
      print('Access Token available: ${googleAuth.accessToken != null}');

      if (googleAuth.idToken == null) {
        throw Exception('No ID token received from Google');
      }

      // Sign in to Supabase
      print('Signing in to Supabase with Google credentials...');
      final AuthResponse response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      print('Supabase authentication successful');
      return response;
    } catch (error) {
      print('Mobile Google Sign-In error: $error');
      throw error;
    }
  }

  /// Supabase OAuth flow (fallback for web)
  static Future<AuthResponse?> _signInWithSupabaseOAuth() async {
    print('Using Supabase OAuth flow...');

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
        print('Supabase OAuth authentication initiated');

        // Wait a bit for the redirect to complete
        await Future.delayed(Duration(milliseconds: 500));

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
      print('Supabase OAuth error: $error');
      throw error;
    }
  }

  /// Get user-friendly error message
  static String _getErrorMessage(dynamic error) {
    String errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('internet')) {
      return 'Network error. Please check your internet connection.';
    } else if (errorString.contains('popup_closed') ||
        errorString.contains('cancelled') ||
        errorString.contains('user_cancelled')) {
      return 'Sign-in was cancelled.';
    } else if (errorString.contains('sign_in_failed')) {
      return 'Google Sign-in failed. Please try again.';
    } else if (errorString.contains('developer_error') ||
        errorString.contains('configuration')) {
      return 'Configuration error. Please contact support.';
    } else if (errorString.contains('invalid_request')) {
      return 'Invalid request. Please check your configuration.';
    } else if (errorString.contains('unknown_reason')) {
      return 'Authentication failed. Please try again.';
    } else {
      return 'Google sign-in failed. Please try again.';
    }
  }

  /// Sign out from both Google and Supabase
  static Future<void> signOut() async {
    try {
      // Sign out from Google
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
        if (kIsWeb) {
          await _googleSignIn.disconnect(); // Clear cached credentials on web
        }
      }

      // Sign out from Supabase
      await _supabase.auth.signOut();

      print('Successfully signed out from Google and Supabase');
    } catch (error) {
      print('Sign out error: $error');
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
      print('Error checking sign-in status: $error');
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
        print('Google Sign-In initialized for web');
      } catch (error) {
        print(
          'Silent sign-in failed (expected if user not previously signed in): $error',
        );
      }
    }
  }
}
