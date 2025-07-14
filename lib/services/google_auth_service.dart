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
        final clientId = _getClientId();
        if (clientId == null || clientId.isEmpty) {
          throw Exception('No client ID available for mobile platform');
        }

        _googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile', 'openid'],
          clientId: clientId,
          // Add server client ID for iOS if available
          serverClientId: kIsWeb ? null : SupabaseConfig.googleWebClientId,
        );

        if (kDebugMode) {
          print('Google Sign-In initialized for mobile platform');
          print('Client ID: $clientId');
          print('Server Client ID: ${SupabaseConfig.googleWebClientId}');
        }

        // Test the configuration
        try {
          final isSignedIn = await _googleSignIn!.isSignedIn();
          if (kDebugMode) {
            print('Initial sign-in status: $isSignedIn');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Could not check initial sign-in status: $e');
          }
        }

        // Try silent sign-in to restore previous session (only if user was signed in before)
        try {
          final silentUser = await _googleSignIn!.signInSilently();
          if (silentUser != null && kDebugMode) {
            print('Silent sign-in successful: ${silentUser.email}');
          }
        } catch (e) {
          // Silent sign-in failure is expected if user hasn't signed in before
          if (kDebugMode) {
            print('Silent sign-in not available (normal for first use): $e');
          }
        }
      } else {
        // Web platform uses Supabase OAuth directly
        if (kDebugMode) {
          print('Web platform detected - using Supabase OAuth');
          print('Web Client ID: ${SupabaseConfig.googleWebClientId}');
          print('Supabase URL: ${SupabaseConfig.supabaseUrl}');
        }
      }
    } catch (error) {
      if (kDebugMode) {
        print('Google Sign-In initialization error: $error');
      }
      // Don't throw the error - let the app continue but log the issue
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

  /// Web sign-in using Supabase OAuth with controlled redirect
  static Future<AuthResponse?> _signInWeb() async {
    try {
      if (kDebugMode) {
        print('Initiating web OAuth flow...');
        print(
          'Using Supabase OAuth with NO redirectTo to prevent redirect loops',
        );
      }

      // Clear any existing auth state to prevent redirect loops
      await _clearWebAuthState();

      // Use Supabase OAuth WITHOUT redirectTo parameter to prevent redirect loops
      // This lets Supabase handle the redirect automatically and prevents custom scheme errors
      final bool success = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        // No redirectTo parameter - this is key to preventing redirect loops
        authScreenLaunchMode: LaunchMode.externalApplication,
        queryParams: {'access_type': 'offline', 'prompt': 'select_account'},
      );

      if (!success) {
        throw Exception('Failed to initiate OAuth flow');
      }

      if (kDebugMode) {
        print('OAuth flow initiated successfully');
        print('Waiting for auth state change...');
      }

      // For web, the auth state change will be handled by the auth listener
      return null;
    } catch (error) {
      if (kDebugMode) {
        print('Web OAuth error: $error');
        print('Trying alternative method...');
      }

      // Try alternative approach if the main method fails
      return await _fallbackWebAuth();
    }
  }

  /// Clear web authentication state to prevent redirect loops
  static Future<void> _clearWebAuthState() async {
    try {
      if (kIsWeb) {
        // Clear any existing Supabase session
        await _supabase.auth.signOut(scope: SignOutScope.local);

        if (kDebugMode) {
          print('Cleared existing web auth state');
        }
      }
    } catch (error) {
      // Ignore errors here as clearing state is not critical
      if (kDebugMode) {
        print('Note: Could not clear auth state: $error');
      }
    }
  }

  /// Fallback web authentication method using inAppWebView
  static Future<AuthResponse?> _fallbackWebAuth() async {
    try {
      if (kDebugMode) {
        print('Attempting fallback OAuth method...');
      }

      // Clear state again before fallback
      await _clearWebAuthState();

      // Wait a moment to ensure state is cleared
      await Future.delayed(Duration(milliseconds: 500));

      // Try with inAppWebView but still no redirectTo to avoid loops
      final bool success = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        authScreenLaunchMode: LaunchMode.inAppWebView,
        queryParams: {
          'access_type': 'offline',
          'prompt': 'consent', // Force consent screen to reset any cached state
        },
      );

      if (!success) {
        throw Exception('All OAuth methods failed');
      }

      if (kDebugMode) {
        print('Fallback OAuth initiated successfully');
      }

      return null;
    } catch (error) {
      if (kDebugMode) {
        print('Fallback OAuth error: $error');
      }

      final errorMessage = error.toString().toLowerCase();

      // Handle specific OAuth errors with helpful messages
      if (errorMessage.contains('popup_blocked')) {
        throw Exception(
          'Popup was blocked. Please allow popups and try again.',
        );
      } else if (errorMessage.contains('popup_closed')) {
        throw Exception('Sign-in was cancelled.');
      } else if (errorMessage.contains('too_many_redirects') ||
          errorMessage.contains('redirect_uri_mismatch') ||
          errorMessage.contains('custom scheme') ||
          errorMessage.contains('redirect_uri') ||
          errorMessage.contains('invalid_request') ||
          errorMessage.contains('web client')) {
        throw Exception(
          'Google OAuth configuration issue detected.\n\n'
          'This domain is not authorized in Google Cloud Console.\n'
          'Please use email/password sign-in as an alternative.\n\n'
          'The app works perfectly with email authentication!',
        );
      } else {
        throw Exception(
          'Google sign-in failed. Please try email/password instead.',
        );
      }
    }
  }

  /// Mobile sign-in using Google Sign-In plugin
  static Future<AuthResponse?> _signInMobile() async {
    if (_googleSignIn == null) {
      await initialize(); // Try to initialize if not done yet
      if (_googleSignIn == null) {
        throw Exception(
          'Google Sign-In could not be initialized for mobile platform',
        );
      }
    }

    try {
      if (kDebugMode) {
        print('Starting mobile Google Sign-In...');
        print('Client ID: ${_getClientId()}');
      }

      // Clear any existing sign-in state first
      try {
        await _googleSignIn!.signOut();
        await Future.delayed(Duration(milliseconds: 500)); // Brief pause
      } catch (e) {
        // Ignore sign out errors
        if (kDebugMode) {
          print('Note: Could not clear existing state: $e');
        }
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
        print('Getting authentication details...');
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null) {
        if (kDebugMode) {
          print('No ID token received - attempting to refresh...');
        }

        // Try to refresh the authentication
        try {
          await googleUser.clearAuthCache();
          final refreshedAuth = await googleUser.authentication;
          if (refreshedAuth.idToken == null) {
            throw Exception('Unable to obtain ID token from Google');
          }
          if (kDebugMode) {
            print('Successfully refreshed authentication');
          }
        } catch (refreshError) {
          throw Exception(
            'No valid ID token received from Google. Please try again.',
          );
        }
      }

      if (kDebugMode) {
        print('Google tokens obtained successfully');
        print('Authenticating with Supabase...');
      }

      // Sign in to Supabase with retry logic
      AuthResponse? response;
      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries) {
        try {
          response = await _supabase.auth.signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: googleAuth.idToken!,
            accessToken: googleAuth.accessToken,
          );
          break; // Success, exit retry loop
        } catch (supabaseError) {
          retryCount++;
          if (retryCount >= maxRetries) {
            throw Exception(
              'Failed to authenticate with Supabase after $maxRetries attempts: $supabaseError',
            );
          }

          if (kDebugMode) {
            print(
              'Supabase auth attempt $retryCount failed, retrying in 1 second...',
            );
          }
          await Future.delayed(Duration(seconds: 1));
        }
      }

      if (response == null) {
        throw Exception('Authentication failed - no response from Supabase');
      }

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
          errorString.contains('user_canceled') ||
          errorString.contains('cancelled')) {
        return null; // User cancelled
      } else if (errorString.contains('network_error') ||
          errorString.contains('network error')) {
        throw Exception(
          'Network error. Please check your internet connection and try again.',
        );
      } else if (errorString.contains('sign_in_failed')) {
        throw Exception(
          'Google Sign-In failed. Please check your account and try again.',
        );
      } else if (errorString.contains('invalid_client') ||
          errorString.contains('configuration')) {
        throw Exception(
          'Google Sign-In configuration error. Please contact support.',
        );
      } else if (errorString.contains('id token')) {
        throw Exception(
          'Authentication token error. Please try signing in again.',
        );
      } else if (errorString.contains('supabase')) {
        throw Exception(
          'Server authentication error. Please try again or use email/password.',
        );
      } else {
        throw Exception(
          'Google sign-in failed. Please try again or use email/password instead.',
        );
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

  /// Clear browser storage and cookies to prevent redirect loops (web only)
  static Future<void> clearBrowserState() async {
    if (kIsWeb) {
      try {
        // Clear local auth state
        await _supabase.auth.signOut(scope: SignOutScope.local);

        if (kDebugMode) {
          print('Browser auth state cleared to prevent redirect loops');
        }
      } catch (error) {
        if (kDebugMode) {
          print('Note: Could not clear browser state: $error');
        }
      }
    }
  }

  /// Force sign out and clear all auth state (useful for fixing stuck states)
  static Future<void> forceSignOut() async {
    try {
      if (kDebugMode) {
        print('Force signing out to clear any stuck auth state...');
      }

      // Clear browser state first if on web
      if (kIsWeb) {
        await clearBrowserState();
      }

      // Sign out from Supabase with global scope
      await _supabase.auth.signOut(scope: SignOutScope.global);

      // Disconnect from Google (mobile only)
      if (!kIsWeb && _googleSignIn != null) {
        await _googleSignIn!.disconnect();
      }

      if (kDebugMode) {
        print('Force sign-out completed');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error during force sign-out: $error');
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
