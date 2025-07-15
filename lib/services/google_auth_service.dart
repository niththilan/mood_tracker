import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'dart:async';
import 'supabase_config.dart';
// Conditional import for web-only simplified auth
import 'simplified_google_auth.dart'
    if (dart.library.io) 'simplified_google_auth_stub.dart';

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

  /// Sign in with Google
  static Future<AuthResponse?> signInWithGoogle() async {
    try {
      if (kDebugMode) {
        print('Starting Google Sign-In...');
        print('Platform: ${kIsWeb ? 'Web' : 'Mobile'}');
        print('Client ID: ${_getClientId()}');
      }

      if (kIsWeb) {
        // Use direct Google Auth for web to bypass redirect issues
        return await _signInWebDirect();
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

  /// Web sign-in using simplified Google Identity Services
  static Future<AuthResponse?> _signInWebDirect() async {
    try {
      if (kDebugMode) {
        print('Using simplified Google Identity Services for web...');
      }

      // Use the simplified Google auth (works with any port)
      if (kIsWeb) {
        return await SimplifiedGoogleAuth.signInWithGoogle();
      } else {
        throw UnsupportedError(
          'Web authentication not available on mobile platforms',
        );
      }
    } catch (error) {
      if (kDebugMode) {
        print('Simplified Google Auth failed: $error');
      }

      // Provide clear error message to user
      throw Exception(
        'Google Sign-In failed: $error\n\n'
        '💡 Alternative: Use email/password sign-in instead!\n'
        'Email authentication is more reliable.',
      );
    }
  }

  /// Fallback web sign-in using Supabase OAuth

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
        print('Package Name: com.example.mood_tracker');
      }

      // Android-specific: Clear any existing sign-in state first
      try {
        await _googleSignIn!.signOut();
        await Future.delayed(
          Duration(milliseconds: Platform.isAndroid ? 2000 : 1000),
        ); // Longer pause for Android to clear state properly
      } catch (e) {
        // Ignore sign out errors
        if (kDebugMode) {
          print('Note: Could not clear existing state: $e');
        }
      }

      // Android-specific: Clear cache and disconnect completely
      if (Platform.isAndroid) {
        try {
          await _googleSignIn!.disconnect();
          await Future.delayed(Duration(milliseconds: 500));
          if (kDebugMode) {
            print('Android: Disconnected from Google to ensure fresh auth');
          }
        } catch (e) {
          if (kDebugMode) {
            print(
              'Android: Could not disconnect (normal if not previously connected): $e',
            );
          }
        }
      }

      // iOS-specific: Disconnect completely to ensure fresh authentication
      if (Platform.isIOS) {
        try {
          await _googleSignIn!.disconnect();
          await Future.delayed(Duration(milliseconds: 500));
          if (kDebugMode) {
            print('iOS: Disconnected from Google to ensure fresh auth');
          }
        } catch (e) {
          if (kDebugMode) {
            print(
              'iOS: Could not disconnect (normal if not previously connected): $e',
            );
          }
        }
      }

      // Android-specific: Check for Play Services availability
      if (Platform.isAndroid) {
        try {
          // Try to check if Google Play Services are available
          final canAccessGoogleSignIn = await _googleSignIn!.canAccessScopes([
            'email',
          ]);
          if (kDebugMode) {
            print(
              'Android: Can access Google Sign-In scopes: $canAccessGoogleSignIn',
            );
          }

          // If we can't access scopes, provide helpful error
          if (!canAccessGoogleSignIn) {
            throw Exception(
              'Google Play Services not available or not configured properly',
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print('Android: Google Play Services check failed: $e');
          }

          // For Android emulators, let's provide more specific error handling
          final errorString = e.toString().toLowerCase();
          if (errorString.contains('developer_error') ||
              errorString.contains('api_not_available') ||
              errorString.contains('sign_in_failed') ||
              errorString.contains('play services') ||
              errorString.contains('not available')) {
            throw Exception(
              'Google Sign-In setup issue on Android:\n\n'
              '🔧 For Android Emulator:\n'
              '1. Make sure you\'re using an emulator with Google Play Services\n'
              '2. Check that SHA-1 fingerprint is correctly configured in Google Cloud Console\n'
              '3. Verify that the google-services.json file is up to date\n'
              '4. Make sure Google Sign-In API is enabled in Google Cloud Console\n\n'
              '💡 Current configuration:\n'
              '- Package: com.example.mood_tracker\n'
              '- SHA-1: 29:4E:13:7C:8A:F1:84:B9:A1:2D:09:18:73:13:39:A5:05:2A:B8:2A\n'
              '- Client ID: ${SupabaseConfig.googleAndroidClientId}\n\n'
              'Error details: $e',
            );
          }
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

      // Get authentication details with retry for iOS
      GoogleSignInAuthentication? googleAuth;
      int authRetries = 0;
      const maxAuthRetries = 3;

      while (authRetries < maxAuthRetries) {
        try {
          googleAuth = await googleUser.authentication;
          break;
        } catch (e) {
          authRetries++;
          if (authRetries >= maxAuthRetries) {
            throw Exception(
              'Failed to get authentication details after $maxAuthRetries attempts: $e',
            );
          }
          if (kDebugMode) {
            print('Auth attempt $authRetries failed, retrying...: $e');
          }
          await Future.delayed(Duration(seconds: 1));
        }
      }

      if (googleAuth == null) {
        throw Exception('Failed to obtain authentication details');
      }

      if (googleAuth.idToken == null) {
        if (kDebugMode) {
          print('No ID token received - attempting to refresh...');
        }

        // Try to refresh the authentication
        try {
          await googleUser.clearAuthCache();
          await Future.delayed(Duration(milliseconds: 500));
          final refreshedAuth = await googleUser.authentication;
          if (refreshedAuth.idToken == null) {
            throw Exception(
              'Unable to obtain ID token from Google after refresh',
            );
          }
          googleAuth = refreshedAuth;
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
        print('ID Token length: ${googleAuth.idToken?.length ?? 0}');
        print('Access Token length: ${googleAuth.accessToken?.length ?? 0}');
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
              'Supabase auth attempt $retryCount failed, retrying in 2 seconds...: $supabaseError',
            );
          }
          await Future.delayed(Duration(seconds: 2));
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
      } else if (errorString.contains('popup_closed_by_user') ||
          errorString.contains('popup_blocked')) {
        throw Exception(
          'Sign-in popup was blocked or closed. Please try again.',
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
