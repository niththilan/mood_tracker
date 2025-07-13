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
      print('Platform: ${kIsWeb ? 'Web' : 'Mobile'}');
      print(
        'Client ID: ${_getClientId() ?? 'Platform-specific (from config files)'}',
      );
      print('Supabase URL: ${SupabaseConfig.supabaseUrl}');

      AuthResponse? response;

      // Use appropriate flow based on platform
      if (kIsWeb) {
        print('Using web OAuth flow...');
        response = await _signInWithSupabaseOAuth();
      } else {
        print('Using mobile Google Sign-In flow...');
        response = await _signInWithGoogleMobile();
      }

      if (response != null) {
        print('=== Google Sign-In Successful ===');
        print('User: ${response.user?.email}');
        print('Session: ${response.session != null ? 'Valid' : 'Invalid'}');
      } else {
        print('=== Google Sign-In Cancelled or Failed ===');
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
                'Keychain error. Please restart the app and try again.',
              );
            } else if (errorString.contains('uiapplicationdelegate')) {
              throw Exception(
                'App configuration error. Please contact support.',
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
      // For web, use Supabase OAuth with popup mode for better UX
      final bool success = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : SupabaseConfig.oauthCallbackUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      if (!success) {
        throw Exception('Failed to initiate OAuth flow');
      }

      print('OAuth flow initiated successfully');

      // For web, we need to wait for the auth state change
      // Create a completer to wait for the authentication result
      final completer = Completer<AuthResponse?>();

      // Set up a temporary listener for auth state changes
      late StreamSubscription authSubscription;

      // Set a timeout for the OAuth flow
      Timer(Duration(seconds: 60), () {
        if (!completer.isCompleted) {
          authSubscription.cancel();
          completer.completeError(Exception('OAuth sign-in timed out'));
        }
      });

      authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
        // Only complete if we get a successful sign-in event
        if (data.event == AuthChangeEvent.signedIn && data.session != null) {
          if (!completer.isCompleted) {
            authSubscription.cancel();
            completer.complete(
              AuthResponse(session: data.session, user: data.session!.user),
            );
          }
        }
      });

      // Wait for the OAuth flow to complete
      return await completer.future;
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
}
