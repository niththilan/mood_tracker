import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'dart:async';
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
      await debugGoogleSignIn(); // Add debug info

      AuthResponse? response;

      // Use appropriate flow based on platform
      if (kIsWeb) {
        print('Using simplified web OAuth flow...');
        response = await _signInWithSupabaseOAuthSimple();
      } else {
        print('Using mobile Google Sign-In flow...');
        response = await _signInWithGoogleMobile();
      }

      if (response != null) {
        print('=== Google Sign-In Successful ===');
        print('User: ${response.user?.email}');
        print('Session: ${response.session != null ? 'Valid' : 'Invalid'}');
      } else {
        print('=== Google Sign-In Initiated (web) or Cancelled ===');
      }

      return response;
    } catch (error) {
      print('=== Google Sign-In Error ===');
      print('Error type: ${error.runtimeType}');
      print('Error message: $error');
      print('=== End Error ===');

      // Don't wrap the error if it's already a user-friendly message
      if (error is Exception) {
        rethrow;
      }

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
      // Check if already signed in and try to use existing session
      GoogleSignInAccount? googleUser = _googleSignIn!.currentUser;

      if (googleUser == null) {
        // Try silent sign-in first
        print('Attempting silent sign-in...');
        try {
          googleUser = await _googleSignIn!.signInSilently();
        } catch (silentError) {
          print('Silent sign-in failed: $silentError');
        }
      }

      if (googleUser == null) {
        // Start interactive Google Sign-In with timeout
        print('Initiating interactive Google Sign-In...');
        googleUser = await _googleSignIn!.signIn().timeout(
          Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Google Sign-In timed out. Please try again.');
          },
        );
      }

      if (googleUser == null) {
        print('User cancelled the sign-in');
        return null;
      }

      print('Google user obtained: ${googleUser.email}');

      // Get authentication details with retry mechanism
      print('Getting authentication details...');
      GoogleSignInAuthentication? googleAuth;

      for (int i = 0; i < 3; i++) {
        try {
          googleAuth = await googleUser.authentication.timeout(
            Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Authentication timeout');
            },
          );
          break;
        } catch (e) {
          print('Authentication attempt ${i + 1} failed: $e');
          if (i == 2) rethrow;
          await Future.delayed(Duration(seconds: 1));
        }
      }

      if (googleAuth == null) {
        throw Exception('Failed to get authentication details');
      }

      print('ID Token available: ${googleAuth.idToken != null}');
      print('Access Token available: ${googleAuth.accessToken != null}');

      if (googleAuth.idToken == null) {
        throw Exception(
          'No ID token received from Google. Please check your configuration.',
        );
      }

      // Sign in to Supabase with better error handling
      print('Signing in to Supabase with Google credentials...');
      try {
        final AuthResponse response = await _supabase.auth
            .signInWithIdToken(
              provider: OAuthProvider.google,
              idToken: googleAuth.idToken!,
              accessToken: googleAuth.accessToken,
            )
            .timeout(
              Duration(seconds: 30),
              onTimeout: () {
                throw Exception('Supabase authentication timed out');
              },
            );

        print('Supabase authentication successful');
        print('User ID: ${response.user?.id}');
        print('User email: ${response.user?.email}');

        return response;
      } catch (supabaseError) {
        print('Supabase authentication error: $supabaseError');

        // Provide specific error messages for common Supabase issues
        String errorMsg = supabaseError.toString().toLowerCase();
        if (errorMsg.contains('invalid_token') || errorMsg.contains('jwt')) {
          throw Exception('Invalid Google token. Please try signing in again.');
        } else if (errorMsg.contains('timeout')) {
          throw Exception(
            'Authentication service timed out. Please try again.',
          );
        } else if (errorMsg.contains('network')) {
          throw Exception(
            'Network error during authentication. Please check your connection.',
          );
        }

        throw Exception(
          'Authentication failed: ${_getErrorMessage(supabaseError)}',
        );
      }
    } catch (error) {
      print('Mobile Google Sign-In error: $error');

      // Enhanced error handling for different platforms and scenarios
      String errorString = error.toString().toLowerCase();

      if (errorString.contains('sign_in_canceled') ||
          errorString.contains('user_canceled') ||
          errorString.contains('cancelled')) {
        return null; // User cancelled, not an error
      }

      if (errorString.contains('network_error') ||
          errorString.contains('network')) {
        throw Exception(
          'Network error. Please check your internet connection and try again.',
        );
      }

      if (errorString.contains('sign_in_failed') ||
          errorString.contains('developer_error')) {
        throw Exception(
          'Google Sign-In configuration error. Please check your setup.',
        );
      }

      if (errorString.contains('timeout')) {
        throw Exception('Sign-in timed out. Please try again.');
      }

      // Platform-specific error handling
      if (!kIsWeb) {
        try {
          if (Platform.isIOS) {
            print('iOS-specific error handling...');
            if (errorString.contains('keychainpassworditem') ||
                errorString.contains('keychain')) {
              throw Exception(
                'Keychain error on iOS. Please restart the app and try again.',
              );
            } else if (errorString.contains('uiapplicationdelegate')) {
              throw Exception(
                'iOS app configuration error. Please contact support.',
              );
            } else if (errorString.contains('invalid_client')) {
              throw Exception(
                'Invalid iOS client configuration. Please check Google Sign-In setup.',
              );
            } else if (errorString.contains('sign_in_required')) {
              throw Exception(
                'Please sign in to Google first.',
              );
            } else if (errorString.contains('permission_denied')) {
              throw Exception(
                'Permission denied. Please check app permissions in iOS Settings.',
              );
            } else if (errorString.contains('configuration_not_found')) {
              throw Exception(
                'Google configuration file not found. Please check GoogleService-Info.plist.',
              );
            }
          } else if (Platform.isAndroid) {
            print('Android-specific error handling...');
            if (errorString.contains('resolution_required')) {
              throw Exception(
                'Google Play Services update required. Please update and try again.',
              );
            } else if (errorString.contains('api_not_connected')) {
              throw Exception(
                'Google Play Services connection failed. Please try again.',
              );
            }
          }
        } catch (platformError) {
          print('Platform check failed: $platformError');
        }
      }

      throw Exception(_getErrorMessage(error));
    }
  }

  /// Supabase OAuth flow (for web platforms)
  static Future<AuthResponse?> _signInWithSupabaseOAuth() async {
    print('Using Supabase OAuth flow for web...');

    try {
      // Check if user is already authenticated
      final currentSession = _supabase.auth.currentSession;
      if (currentSession?.user != null) {
        print('User already authenticated, returning existing session');
        return AuthResponse(
          session: currentSession,
          user: currentSession!.user,
        );
      }

      // Create a completer to wait for the authentication result
      final completer = Completer<AuthResponse?>();
      late StreamSubscription authSubscription;

      // Set up auth state listener BEFORE initiating OAuth
      authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
        print(
          'Auth state change: ${data.event}, session: ${data.session != null}',
        );

        // Complete on successful sign-in
        if (data.event == AuthChangeEvent.signedIn && data.session != null) {
          if (!completer.isCompleted) {
            print('OAuth sign-in successful, completing...');
            authSubscription.cancel();
            completer.complete(
              AuthResponse(session: data.session, user: data.session!.user),
            );
          }
        }

        // Handle token refresh events as well (user might already be signed in)
        if (data.event == AuthChangeEvent.tokenRefreshed &&
            data.session != null) {
          if (!completer.isCompleted) {
            print('Token refreshed, user was already signed in, completing...');
            authSubscription.cancel();
            completer.complete(
              AuthResponse(session: data.session, user: data.session!.user),
            );
          }
        }
      });

      // Set timeout
      final timeoutTimer = Timer(Duration(seconds: 60), () {
        if (!completer.isCompleted) {
          print('OAuth timeout reached');
          authSubscription.cancel();
          completer.completeError(Exception('OAuth sign-in timed out'));
        }
      });

      // Initiate OAuth flow
      print('Initiating OAuth flow...');
      final bool success = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : SupabaseConfig.oauthCallbackUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      if (!success) {
        authSubscription.cancel();
        timeoutTimer.cancel();
        throw Exception('Failed to initiate OAuth flow');
      }

      print('OAuth flow initiated successfully, waiting for completion...');

      // Wait for the OAuth flow to complete
      try {
        final result = await completer.future;
        timeoutTimer.cancel();
        return result;
      } catch (e) {
        authSubscription.cancel();
        timeoutTimer.cancel();
        rethrow;
      }
    } catch (error) {
      print('Supabase OAuth error: $error');

      // Provide more specific error messages
      String errorMessage = error.toString().toLowerCase();
      if (errorMessage.contains('popup_blocked')) {
        throw Exception(
          'Popup was blocked. Please allow popups and try again.',
        );
      } else if (errorMessage.contains('redirect_uri')) {
        throw Exception('OAuth configuration error. Please check your setup.');
      } else if (errorMessage.contains('network')) {
        throw Exception(
          'Network error. Please check your internet connection.',
        );
      } else if (errorMessage.contains('timeout')) {
        throw Exception('Sign-in timed out. Please try again.');
      }

      throw Exception(
        'OAuth authentication failed: ${_getErrorMessage(error)}',
      );
    }
  }

  /// Debug method to check Google Sign-In configuration and state
  static Future<void> debugGoogleSignIn() async {
    print('=== Google Sign-In Debug Info ===');
    print('Platform: ${kIsWeb ? 'Web' : 'Mobile'}');
    print('Client ID: ${_getClientId() ?? 'Platform-specific'}');
    print('Supabase URL: ${SupabaseConfig.supabaseUrl}');
    print('Current Supabase session: ${_supabase.auth.currentSession != null}');

    if (kIsWeb) {
      print('Web Client ID: ${SupabaseConfig.googleWebClientId}');
      print('OAuth Callback URL: ${SupabaseConfig.oauthCallbackUrl}');
    } else {
      print('Google Sign-In instance: ${_googleSignIn != null}');
      if (_googleSignIn != null) {
        try {
          final isSignedIn = await _googleSignIn!.isSignedIn();
          final currentUser = _googleSignIn!.currentUser;
          print('Mobile signed in: $isSignedIn');
          print('Current user: ${currentUser?.email}');
        } catch (e) {
          print('Error checking mobile sign-in status: $e');
        }
      }
    }
    print('=== End Debug Info ===');
  }

  /// Simplified web OAuth with better error handling and redirect loop prevention
  static Future<AuthResponse?> _signInWithSupabaseOAuthSimple() async {
    print('Using simplified Supabase OAuth flow...');

    try {
      // Check if we're already signed in to prevent unnecessary redirects
      final currentSession = _supabase.auth.currentSession;
      if (currentSession?.user != null) {
        print('User already authenticated, returning existing session');
        return AuthResponse(
          session: currentSession,
          user: currentSession!.user,
        );
      }

      // Clear any existing auth state to prevent conflicts
      print('Clearing any existing auth state...');
      try {
        await _supabase.auth.signOut(scope: SignOutScope.local);
      } catch (e) {
        print('Failed to clear existing auth state (this is OK): $e');
      }

      // For web, initiate OAuth and return immediately
      // The main app's auth listener will handle the response
      print('Initiating OAuth with Google...');
      final bool success = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : SupabaseConfig.oauthCallbackUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
        queryParams: {
          'access_type': 'offline',
          'prompt': 'consent', // Force consent screen to avoid cached redirects
        },
      );

      if (!success) {
        throw Exception('Failed to initiate OAuth flow');
      }

      print(
        'OAuth initiated successfully - auth state will be handled by main app listener',
      );

      // Return null - the auth state change will be handled by AuthWrapper
      // This prevents race conditions and is more reliable
      return null;
    } catch (error) {
      print('Simple OAuth error: $error');

      String errorMessage = error.toString().toLowerCase();
      if (errorMessage.contains('popup_blocked')) {
        throw Exception(
          'Popup was blocked. Please allow popups and try again.',
        );
      } else if (errorMessage.contains('redirect_uri')) {
        throw Exception('OAuth configuration error. Please check your setup.');
      } else if (errorMessage.contains('network')) {
        throw Exception(
          'Network error. Please check your internet connection.',
        );
      } else if (errorMessage.contains('too_many_redirects')) {
        throw Exception(
          'Redirect loop detected. Please clear your browser cache and try again.',
        );
      }

      throw Exception(
        'OAuth authentication failed: ${_getErrorMessage(error)}',
      );
    }
  }

  /// Clear OAuth state to fix redirect loops (especially useful for web)
  static Future<void> clearOAuthState() async {
    try {
      print('Clearing OAuth state...');
      
      // Sign out from Supabase with global scope to clear all sessions
      await _supabase.auth.signOut(scope: SignOutScope.global);
      
      // For mobile, also clear Google Sign-In
      if (_googleSignIn != null && await _googleSignIn!.isSignedIn()) {
        await _googleSignIn!.signOut();
        await _googleSignIn!.disconnect();
      }
      
      print('OAuth state cleared successfully');
    } catch (error) {
      print('Error clearing OAuth state: $error');
      // Don't throw error, as this is a cleanup operation
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
    try {
      if (kIsWeb) {
        print('Web platform detected - using Supabase OAuth flow');
        print('Web client ID: ${SupabaseConfig.googleWebClientId}');
        // For web, initialization is handled by Supabase
        // Just verify the configuration
        if (SupabaseConfig.googleWebClientId.isEmpty) {
          print('WARNING: Web client ID is not configured');
        }
      } else if (_googleSignIn != null) {
        print('Initializing Google Sign-In for mobile platform...');
        print('Client ID: ${_getClientId() ?? "Using platform configuration"}');

        try {
          // Try silent sign-in to restore previous session
          final GoogleSignInAccount? account =
              await _googleSignIn!.signInSilently();
          if (account != null) {
            print('Silent sign-in successful for: ${account.email}');
          } else {
            print('No previous sign-in session found');
          }
        } catch (silentError) {
          print(
            'Silent sign-in failed (expected if user not previously signed in): $silentError',
          );
        }

        print('Google Sign-In initialized for mobile');
      }
    } catch (error) {
      print('Google Sign-In initialization error: $error');
      // Don't throw error during initialization
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

  /// Test iOS Google Sign-In configuration
  static Future<bool> testIOSConfiguration() async {
    if (kIsWeb || _googleSignIn == null) {
      return false;
    }

    try {
      if (Platform.isIOS) {
        print('Testing iOS Google Sign-In configuration...');
        
        // Check if GoogleService-Info.plist is properly configured
        final isSignedIn = await _googleSignIn!.isSignedIn();
        print('iOS Google Sign-In state: ${isSignedIn ? 'Signed In' : 'Not Signed In'}');
        
        // Try to get current user
        final currentUser = _googleSignIn!.currentUser;
        if (currentUser != null) {
          print('Current iOS user: ${currentUser.email}');
          
          // Test authentication
          try {
            final auth = await currentUser.authentication;
            print('iOS auth tokens available: ${auth.idToken != null && auth.accessToken != null}');
          } catch (authError) {
            print('iOS auth token error: $authError');
            return false;
          }
        }
        
        print('iOS Google Sign-In configuration test passed');
        return true;
      }
    } catch (error) {
      print('iOS configuration test failed: $error');
      return false;
    }
    
    return false;
  }
}
