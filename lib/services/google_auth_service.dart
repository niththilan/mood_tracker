import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'supabase_config.dart';

class GoogleAuthService {
  // Only initialize GoogleSignIn for mobile platforms
  static final GoogleSignIn? _googleSignIn =
      kIsWeb
          ? null
          : GoogleSignIn(
            scopes: ['email', 'profile'],
            // For iOS, explicitly set the client ID
            clientId: _getClientId(),
          );

  /// Get the appropriate client ID for the current platform
  static String? _getClientId() {
    if (kIsWeb) {
      return SupabaseConfig.googleWebClientId;
    } else {
      // For iOS, use the iOS client ID
      // For Android, return null to use the configuration from strings.xml
      try {
        if (Platform.isIOS) {
          return SupabaseConfig.googleIOSClientId;
        } else {
          // Android uses configuration from strings.xml
          return null;
        }
      } catch (e) {
        // Fallback for when Platform isn't available
        return SupabaseConfig.googleIOSClientId;
      }
    }
  }

  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Sign in with Google using appropriate flow for platform
  static Future<AuthResponse?> signInWithGoogle() async {
    try {
      print('=== Starting Google Sign-In ===');
      print('Platform: ${kIsWeb ? 'Web' : 'Mobile'}');
      print(
        'Client ID: ${_getClientId() ?? 'Platform-specific (from config files)'}',
      );
      print('Supabase URL: ${SupabaseConfig.supabaseUrl}');
      print('OAuth Callback URL: ${SupabaseConfig.oauthCallbackUrl}');

      // For web, use Supabase OAuth flow to avoid redirect_uri_mismatch
      if (kIsWeb) {
        return await _signInWithSupabaseOAuth();
      }

      // For mobile, use standard Google Sign-In
      return await _signInWithGoogleMobile();
    } catch (error) {
      print('=== Google Sign-In Error ===');
      print('Error type: ${error.runtimeType}');
      print('Error message: $error');
      print('=== End Error ===');
      throw Exception(_getErrorMessage(error));
    }
  }

  /// Mobile Google Sign-In flow
  static Future<AuthResponse?> _signInWithGoogleMobile() async {
    print('Using mobile Google Sign-In flow...');

    if (_googleSignIn == null) {
      throw Exception('Google Sign-In not available on this platform');
    }

    try {
      // Check if already signed in and sign out to force fresh login
      if (await _googleSignIn!.isSignedIn()) {
        print('User already signed in, signing out to force fresh login...');
        await _googleSignIn!.signOut();
      }

      // Start Google Sign-In
      print('Initiating Google Sign-In...');
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();

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

      // Special handling for iOS errors
      if (!kIsWeb) {
        try {
          if (Platform.isIOS) {
            print('iOS-specific error handling...');
            String errorString = error.toString().toLowerCase();
            if (errorString.contains('keychainpassworditem') ||
                errorString.contains('keychain')) {
              throw Exception(
                'Keychain error. Please restart the app and try again.',
              );
            } else if (errorString.contains('network')) {
              throw Exception(
                'Network error. Please check your internet connection.',
              );
            } else if (errorString.contains('sign_in_failed')) {
              throw Exception(
                'Google Sign-In failed. Please check your configuration.',
              );
            }
          }
        } catch (platformError) {
          // Fallback if Platform check fails
          print('Platform check failed: $platformError');
        }
      }

      throw error;
    }
  }

  /// Supabase OAuth flow (fallback for web)
  static Future<AuthResponse?> _signInWithSupabaseOAuth() async {
    print('Using Supabase OAuth flow...');
    print('Using Supabase callback URL to avoid redirect_uri_mismatch');

    try {
      // Always use Supabase callback URL for web to match Google Cloud Console configuration
      final redirectUrl = SupabaseConfig.oauthCallbackUrl;
      print('Redirect URL: $redirectUrl');

      final bool success = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      if (success) {
        print('Supabase OAuth authentication initiated');

        // Wait a bit for the redirect to complete
        await Future.delayed(Duration(milliseconds: 1000));

        final User? user = _supabase.auth.currentUser;
        if (user != null) {
          print('User authenticated successfully: ${user.email}');
          return AuthResponse(
            user: user,
            session: _supabase.auth.currentSession,
          );
        } else {
          print('Waiting for authentication to complete...');
          // Try waiting a bit longer for the callback
          await Future.delayed(Duration(milliseconds: 2000));
          final User? delayedUser = _supabase.auth.currentUser;
          if (delayedUser != null) {
            print('User authenticated after delay: ${delayedUser.email}');
            return AuthResponse(
              user: delayedUser,
              session: _supabase.auth.currentSession,
            );
          }
        }
      }

      print('OAuth authentication failed or user cancelled');
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
      // Sign out from Google (only on mobile)
      if (_googleSignIn != null && await _googleSignIn!.isSignedIn()) {
        await _googleSignIn!.signOut();
        if (kIsWeb) {
          await _googleSignIn!.disconnect(); // Clear cached credentials on web
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
      final isGoogleSignedIn =
          _googleSignIn != null && await _googleSignIn!.isSignedIn();
      final isSupabaseSignedIn = _supabase.auth.currentUser != null;

      return isGoogleSignedIn || isSupabaseSignedIn;
    } catch (error) {
      print('Error checking sign-in status: $error');
      return false;
    }
  }

  /// Get current Google user
  static GoogleSignInAccount? getCurrentUser() {
    return _googleSignIn?.currentUser;
  }

  /// Initialize Google Sign-In for web (call this early in app lifecycle)
  static Future<void> initializeForWeb() async {
    if (kIsWeb) {
      // On web, we don't use GoogleSignIn package, so no initialization needed
      print('Web platform detected - using Supabase OAuth flow only');
    } else if (_googleSignIn != null) {
      try {
        print('Initializing Google Sign-In for mobile platform...');
        print('Client ID: ${_getClientId() ?? "Using platform configuration"}');
        await _googleSignIn!.signInSilently();
        print('Google Sign-In initialized for mobile');
      } catch (error) {
        print(
          'Silent sign-in failed (expected if user not previously signed in): $error',
        );
      }
    }
  }

  /// Initialize Google Sign-In specifically for iOS
  static Future<void> initializeForIOS() async {
    if (!kIsWeb) {
      try {
        if (Platform.isIOS && _googleSignIn != null) {
          print('Initializing Google Sign-In for iOS...');
          print('iOS Client ID: ${SupabaseConfig.googleIOSClientId}');
          // Attempt silent sign-in to restore previous session
          await _googleSignIn!.signInSilently();
          print('iOS Google Sign-In initialized successfully');
        }
      } catch (error) {
        print('iOS Google Sign-In initialization failed: $error');
        // This is expected if user hasn't signed in before
      }
    }
  }
}
