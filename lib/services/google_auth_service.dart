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
          // Add server client ID for Android/iOS token validation
          serverClientId:
              Platform.isAndroid
                  ? SupabaseConfig.googleWebClientId
                  : SupabaseConfig.googleWebClientId,
          // Force account selection to avoid cached token issues
          forceCodeForRefreshToken: true,
        );

        if (kDebugMode) {
          print('Google Sign-In initialized for mobile platform');
          print('Client ID: $clientId');
          print('Server Client ID: ${SupabaseConfig.googleWebClientId}');
          print('Platform: ${Platform.operatingSystem}');
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

  /// Sign in with Google using Supabase OAuth
  static Future<AuthResponse?> signInWithGoogle() async {
    try {
      if (kDebugMode) {
        print('Starting Supabase Google OAuth...');
        print('Platform: ${kIsWeb ? 'Web' : 'Mobile'}');
        print('Supabase URL: ${SupabaseConfig.supabaseUrl}');
      }

      if (kIsWeb) {
        // Use Supabase OAuth for web
        return await _signInWithSupabaseOAuth();
      } else {
        // Use Google Sign-In plugin for mobile, then authenticate with Supabase
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
  static Future<AuthResponse?> _signInWithSupabaseOAuth() async {
    try {
      if (kDebugMode) {
        print('Using Supabase OAuth for Google Sign-In...');
        print('Redirect URL: ${SupabaseConfig.getRedirectUrl()}');
      }

      // Use Supabase's built-in Google OAuth
      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: SupabaseConfig.getRedirectUrl(),
        authScreenLaunchMode: LaunchMode.platformDefault,
      );

      if (kDebugMode) {
        print('Supabase OAuth initiated successfully');
        print('Response: $response');
      }

      return null; // OAuth redirect handled by Supabase
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
        print('Platform: ${Platform.operatingSystem}');
      }

      // Clear any existing sign-in state first
      try {
        await _googleSignIn!.signOut();
        await Future.delayed(Duration(milliseconds: 500));
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
        throw Exception(
          'No ID token received from Google. Please try again.',
        );
      }

      if (kDebugMode) {
        print('Google tokens obtained successfully');
        print('ID Token length: ${googleAuth.idToken?.length ?? 0}');
        print('Access Token length: ${googleAuth.accessToken?.length ?? 0}');
        print('Authenticating with Supabase...');
      }

      // Sign in to Supabase with the Google ID token
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
        print('Error type: ${error.runtimeType}');
      }

      final errorString = error.toString().toLowerCase();

      if (errorString.contains('sign_in_canceled') ||
          errorString.contains('user_canceled') ||
          errorString.contains('cancelled') ||
          errorString.contains('user_cancelled')) {
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
          'Google Sign-In configuration error. Please restart the app and try again.',
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
        // Android-specific error handling
        if (!kIsWeb && Platform.isAndroid) {
          final androidSolution = _getAndroidErrorSolution(errorString);
          throw Exception('$androidSolution\n\nOriginal error: $error');
        } else {
          throw Exception(
            'Google sign-in failed: ${error.toString()}. Please try again or use email/password instead.',
          );
        }
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

  /// Android-specific error handling and debugging
  static String _getAndroidErrorSolution(String error) {
    final errorLower = error.toLowerCase();

    if (errorLower.contains('developer_error') || errorLower.contains('10')) {
      return '''
🔧 ANDROID FIX: Developer Error (Code 10)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
This usually means your app's SHA-1 certificate fingerprint 
is not registered in the Google Cloud Console.

IMMEDIATE STEPS:
1. Run: ./get_sha1.sh
2. Copy the SHA-1 fingerprint
3. Go to: Firebase Console > Project Settings > Your Apps
4. Click on Android app > Add Fingerprint
5. Download new google-services.json
6. Replace android/app/google-services.json
7. Clean and rebuild: flutter clean && flutter build apk

📱 Test on a real device, not emulator!
''';
    }

    if (errorLower.contains('network_error') || errorLower.contains('7')) {
      return '''
🌐 ANDROID FIX: Network Error (Code 7)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Check your network connection and device settings.

STEPS TO TRY:
1. Ensure device has internet connection
2. Check if Google Play Services is updated
3. Try on different network (WiFi vs Mobile)
4. Clear Google Play Services cache
5. Restart device and try again
''';
    }

    if (errorLower.contains('sign_in_required') || errorLower.contains('4')) {
      return '''
🔐 ANDROID FIX: Sign-in Required (Code 4)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
The user needs to sign in again.

STEPS:
1. Clear app data/cache
2. Sign out completely and try again
3. Check Google account is added to device
''';
    }

    if (errorLower.contains('play_services') ||
        errorLower.contains('resolution_required')) {
      return '''
🔧 ANDROID FIX: Google Play Services Issue
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Google Play Services needs to be updated or is not available.

STEPS:
1. Update Google Play Services from Play Store
2. Restart device
3. Test on a different device
4. Ensure device has Google services (not Chinese ROMs)
''';
    }

    return '''
🔧 ANDROID GENERAL TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Run: ./debug_android_auth.sh
2. Check SHA-1 certificate is registered
3. Verify google-services.json is up to date
4. Test on real device with Google Play Services
5. Check app logs: flutter logs

For immediate help, use email/password sign-in instead!
''';
  }
}
