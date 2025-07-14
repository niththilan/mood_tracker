import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'dart:async';
import 'supabase_config.dart';

/// Google Authentication Service for all platforms
class GoogleAuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Platform-specific Google Sign-In instance
  static GoogleSignIn? _googleSignIn;

  /// Initialize Google Sign-In for the current platform
  static Future<void> initialize() async {
    try {
      if (!kIsWeb) {
        // Mobile platforms (iOS/Android)
        _googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
          clientId: _getClientId(),
        );

        if (kDebugMode) {
          print('Google Sign-In initialized for mobile platform');
          print('Client ID: ${_getClientId()}');
        }

        // Try silent sign-in to restore previous session
        try {
          await _googleSignIn!.signInSilently();
        } catch (e) {
          // Silent sign-in failure is expected if user hasn't signed in before
          if (kDebugMode) {
            print('Silent sign-in not available: $e');
          }
        }
      } else {
        // Web platform uses Supabase OAuth directly
        if (kDebugMode) {
          print('Web platform detected - using Supabase OAuth');
          print('Web Client ID: ${SupabaseConfig.googleWebClientId}');
        }
      }
    } catch (error) {
      if (kDebugMode) {
        print('Google Sign-In initialization error: $error');
      }
    }
  }

  /// Get platform-specific client ID
  static String? _getClientId() {
    if (kIsWeb) {
      return SupabaseConfig.googleWebClientId;
    } else {
      try {
        if (Platform.isIOS) {
          return SupabaseConfig.googleIOSClientId;
        } else if (Platform.isAndroid) {
          return SupabaseConfig.googleAndroidClientId;
        }
      } catch (e) {
        // Platform detection failed, use iOS as fallback
        return SupabaseConfig.googleIOSClientId;
      }
    }
    return null;
  }

  /// Sign in with Google
  static Future<AuthResponse?> signInWithGoogle() async {
    try {
      if (kDebugMode) {
        print('Starting Google Sign-In...');
        print('Platform: ${kIsWeb ? 'Web' : 'Mobile'}');
        print('Client ID: ${_getClientId()}');
      }

      if (kIsWeb) {
        return await _signInWeb();
      } else {
        return await _signInMobile();
      }
    } catch (error) {
      if (kDebugMode) {
        print('Google Sign-In error: $error');
      }
      rethrow;
    }
  }

  /// Web sign-in using Supabase OAuth
  static Future<AuthResponse?> _signInWeb() async {
    try {
      if (kDebugMode) {
        print('Initiating web OAuth flow...');
      }

      final bool success = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: SupabaseConfig.oauthCallbackUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
        queryParams: {'access_type': 'offline', 'prompt': 'select_account'},
      );

      if (!success) {
        throw Exception('Failed to initiate OAuth flow');
      }

      if (kDebugMode) {
        print('OAuth flow initiated successfully');
      }

      // For web, the auth state change will be handled by the auth listener
      return null;
    } catch (error) {
      if (kDebugMode) {
        print('Web OAuth error: $error');
      }

      final errorMessage = error.toString().toLowerCase();
      if (errorMessage.contains('popup_blocked')) {
        throw Exception(
          'Popup was blocked. Please allow popups and try again.',
        );
      } else if (errorMessage.contains('popup_closed')) {
        throw Exception('Sign-in was cancelled.');
      } else {
        throw Exception('Google sign-in failed. Please try again.');
      }
    }
  }

  /// Mobile sign-in using Google Sign-In plugin
  static Future<AuthResponse?> _signInMobile() async {
    if (_googleSignIn == null) {
      throw Exception('Google Sign-In not initialized for mobile platform');
    }

    try {
      if (kDebugMode) {
        print('Starting mobile Google Sign-In...');
      }

      // Sign in with Google
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();

      if (googleUser == null) {
        if (kDebugMode) {
          print('User cancelled Google Sign-In');
        }
        return null; // User cancelled
      }

      if (kDebugMode) {
        print('Google user obtained: ${googleUser.email}');
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception('No ID token received from Google');
      }

      if (kDebugMode) {
        print('Google tokens obtained successfully');
      }

      // Sign in to Supabase
      final AuthResponse response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      if (kDebugMode) {
        print('Supabase sign-in successful: ${response.user?.email}');
      }

      return response;
    } catch (error) {
      if (kDebugMode) {
        print('Mobile Google Sign-In error: $error');
      }

      final errorString = error.toString().toLowerCase();

      if (errorString.contains('sign_in_canceled') ||
          errorString.contains('user_canceled')) {
        return null; // User cancelled
      } else if (errorString.contains('network_error')) {
        throw Exception('Network error. Please check your connection.');
      } else if (errorString.contains('sign_in_failed')) {
        throw Exception('Google Sign-In failed. Please try again.');
      } else if (errorString.contains('invalid_client')) {
        throw Exception('Google Sign-In configuration error.');
      } else {
        throw Exception('Google sign-in failed. Please try again.');
      }
    }
  }

  /// Check if user is signed in with Google
  static Future<bool> isSignedIn() async {
    try {
      if (kIsWeb) {
        return _supabase.auth.currentUser != null;
      } else {
        return _googleSignIn != null && await _googleSignIn!.isSignedIn();
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error checking sign-in status: $error');
      }
      return false;
    }
  }

  /// Sign out from Google
  static Future<void> signOut() async {
    try {
      if (kDebugMode) {
        print('Signing out from Google...');
      }

      // Sign out from Supabase
      await _supabase.auth.signOut();

      // Sign out from Google (mobile only)
      if (!kIsWeb && _googleSignIn != null) {
        await _googleSignIn!.signOut();
      }

      if (kDebugMode) {
        print('Google sign-out completed');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Sign out error: $error');
      }
      // Don't throw errors for sign-out as it's not critical
    }
  }

  /// Clear all Google authentication state
  static Future<void> clearAuthState() async {
    try {
      if (kDebugMode) {
        print('Clearing Google auth state...');
      }

      // Sign out from Supabase with global scope
      await _supabase.auth.signOut(scope: SignOutScope.global);

      // Disconnect from Google (mobile only)
      if (!kIsWeb && _googleSignIn != null) {
        await _googleSignIn!.disconnect();
      }

      if (kDebugMode) {
        print('Google auth state cleared');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error clearing auth state: $error');
      }
    }
  }

  /// Get current Google user (mobile only)
  static GoogleSignInAccount? getCurrentUser() {
    if (!kIsWeb && _googleSignIn != null) {
      return _googleSignIn!.currentUser;
    }
    return null;
  }

  /// Test the Google Sign-In configuration
  static Future<Map<String, dynamic>> testConfiguration() async {
    final result = <String, dynamic>{};

    try {
      result['platform'] = kIsWeb ? 'web' : 'mobile';
      result['clientId'] = _getClientId();
      result['supabaseUrl'] = SupabaseConfig.supabaseUrl;
      result['callbackUrl'] = SupabaseConfig.oauthCallbackUrl;

      if (kIsWeb) {
        result['webClientId'] = SupabaseConfig.googleWebClientId;
        result['isSupabaseInitialized'] =
            true; // Supabase.instance.client is never null
      } else {
        result['googleSignInInitialized'] = _googleSignIn != null;
        if (_googleSignIn != null) {
          result['isSignedIn'] = await _googleSignIn!.isSignedIn();
          result['currentUser'] = _googleSignIn!.currentUser?.email;
        }
      }

      result['currentSupabaseUser'] = _supabase.auth.currentUser?.email;
      result['hasSupabaseSession'] = _supabase.auth.currentSession != null;
    } catch (error) {
      result['error'] = error.toString();
    }

    return result;
  }

  /// Test iOS Google Sign-In configuration (legacy method for compatibility)
  static Future<bool> testIOSConfiguration() async {
    try {
      final config = await testConfiguration();
      return config['error'] == null && config['platform'] != 'web';
    } catch (error) {
      if (kDebugMode) {
        print('iOS configuration test error: $error');
      }
      return false;
    }
  }

  /// Initialize for web (legacy method for compatibility)
  static Future<void> initializeForWeb() async {
    return initialize();
  }
}
