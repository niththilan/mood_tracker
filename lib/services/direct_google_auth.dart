import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:html' as html;
import 'dart:js' as js;
import 'supabase_config.dart';

/// Direct Google Authentication for Web
/// This bypasses Supabase OAuth and uses Google's JavaScript API directly
class DirectGoogleAuth {
  static bool _isInitialized = false;
  static const String _googleApiScript =
      'https://accounts.google.com/gsi/client';

  /// Initialize Google Sign-In for web
  static Future<void> initialize() async {
    if (!kIsWeb || _isInitialized) return;

    try {
      // Load Google Identity Services
      await _loadGoogleScript();

      // Initialize Google Sign-In
      js.context.callMethod('eval', [
        '''
        if (window.google && window.google.accounts && window.google.accounts.id) {
          // Define the callback function globally
          window.handleCredentialResponse = function(response) {
            console.log('Google credential received:', response);
            window.googleCredentialResponse = response;
          };
          
          // Initialize with proper client ID
          window.google.accounts.id.initialize({
            client_id: "${SupabaseConfig.googleWebClientId}",
            callback: window.handleCredentialResponse,
            auto_select: false,
            cancel_on_tap_outside: true
          });
          
          console.log('Google Identity Services initialized with client ID: ${SupabaseConfig.googleWebClientId}');
        } else {
          console.error('Google Identity Services not available');
          throw new Error('Google Identity Services not loaded');
        }
      ''',
      ]);

      _isInitialized = true;

      if (kDebugMode) {
        print('Direct Google Auth initialized successfully');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Failed to initialize Direct Google Auth: $error');
      }
    }
  }

  /// Load Google Script
  static Future<void> _loadGoogleScript() async {
    final completer = Completer<void>();

    // Check if script is already loaded
    if (html.document.querySelector('script[src="$_googleApiScript"]') !=
        null) {
      completer.complete();
      return completer.future;
    }

    final script =
        html.ScriptElement()
          ..src = _googleApiScript
          ..async = true
          ..defer = true;

    script.onLoad.listen((_) => completer.complete());
    script.onError.listen(
      (_) => completer.completeError('Failed to load Google script'),
    );

    html.document.head!.append(script);

    return completer.future;
  }

  /// Sign in with Google using direct method
  static Future<AuthResponse?> signInWithGoogle() async {
    if (!kIsWeb) {
      throw Exception('Direct Google Auth is only available on web');
    }

    if (!_isInitialized) {
      await initialize();
    }

    try {
      if (kDebugMode) {
        print('Starting direct Google Sign-In...');
      }

      // Clear any existing credential response
      js.context['googleCredentialResponse'] = null;

      // Create a more reliable sign-in approach
      final credential = await _performDirectSignIn();

      if (credential == null) {
        throw Exception(
          'No credential received from Google. Please try again or use email/password sign-in.',
        );
      }

      if (kDebugMode) {
        print('Google credential received, signing into Supabase...');
      }

      // Sign in to Supabase with the ID token
      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: credential,
      );

      if (kDebugMode) {
        print('Supabase sign-in successful: ${response.user?.email}');
      }

      return response;
    } catch (error) {
      if (kDebugMode) {
        print('Direct Google Sign-In error: $error');
      }

      // Provide more specific error messages
      final errorStr = error.toString().toLowerCase();
      if (errorStr.contains('popup_blocked') || errorStr.contains('blocked')) {
        throw Exception(
          'Popup blocked. Please allow popups for this site and try again.',
        );
      } else if (errorStr.contains('network') ||
          errorStr.contains('connection')) {
        throw Exception(
          'Network error. Please check your internet connection.',
        );
      } else if (errorStr.contains('timeout') ||
          errorStr.contains('no credential')) {
        throw Exception(
          'Sign-in timed out. Please try again or use email/password.',
        );
      } else if (errorStr.contains('redirect_uri_mismatch')) {
        throw Exception(
          'Google OAuth configuration issue. Please use email/password sign-in instead.',
        );
      } else {
        throw Exception(
          'Google sign-in failed. Please try email/password instead.',
        );
      }
    }
  }

  /// Perform direct sign-in with improved method
  static Future<String?> _performDirectSignIn() async {
    try {
      // Set up a promise-based approach for better reliability
      js.context.callMethod('eval', [
        '''
        (async function() {
          try {
            if (!window.google || !window.google.accounts || !window.google.accounts.id) {
              throw new Error('Google Identity Services not available');
            }

            console.log('Setting up Google Sign-In...');

            // Set up the callback with promise resolution
            window.directSignInCallback = function(response) {
              console.log('Direct sign-in credential received:', response);
              window.directSignInResult = response.credential;
              window.directSignInComplete = true;
            };

            // Re-initialize with the direct callback
            window.google.accounts.id.initialize({
              client_id: "${SupabaseConfig.googleWebClientId}",
              callback: window.directSignInCallback,
              auto_select: false,
              cancel_on_tap_outside: false
            });

            // Method 1: Try One Tap prompt
            console.log('Trying One Tap prompt...');
            window.google.accounts.id.prompt((notification) => {
              console.log('One Tap notification:', notification);
              if (notification.isNotDisplayed() || notification.isSkippedMoment()) {
                console.log('One Tap not available, trying button method...');
                
                // Method 2: Create and auto-click button
                setTimeout(() => {
                  try {
                    const container = document.createElement('div');
                    container.style.position = 'fixed';
                    container.style.left = '-9999px';
                    container.style.top = '-9999px';
                    document.body.appendChild(container);

                    window.google.accounts.id.renderButton(container, {
                      theme: "outline",
                      size: "large",
                      type: "standard",
                      text: "signin_with",
                      shape: "rectangular"
                    });

                    // Auto-click after a short delay
                    setTimeout(() => {
                      const button = container.querySelector('[role="button"]');
                      if (button) {
                        console.log('Auto-clicking Google Sign-In button...');
                        button.click();
                      } else {
                        console.log('Button not found, trying alternative approach...');
                        // Method 3: Direct prompt call
                        window.google.accounts.id.prompt();
                      }
                    }, 100);
                  } catch (e) {
                    console.error('Button method error:', e);
                  }
                }, 100);
              }
            });

          } catch (error) {
            console.error('Direct sign-in setup error:', error);
            window.directSignInError = error.message;
            window.directSignInComplete = true;
          }
        })();
      ''',
      ]);

      // Wait for the sign-in to complete with a reasonable timeout
      var attempts = 0;
      const maxAttempts = 150; // 15 seconds total

      while (attempts < maxAttempts) {
        await Future.delayed(Duration(milliseconds: 100));

        final isComplete = js.context['directSignInComplete'];
        if (isComplete == true) {
          final result = js.context['directSignInResult'];
          final error = js.context['directSignInError'];

          // Clean up
          js.context['directSignInComplete'] = null;
          js.context['directSignInResult'] = null;
          js.context['directSignInError'] = null;

          if (error != null) {
            throw Exception('Google Sign-In error: $error');
          }

          if (result != null) {
            return result.toString();
          }
          break;
        }

        attempts++;
      }

      return null; // Timeout
    } catch (error) {
      if (kDebugMode) {
        print('Direct sign-in performance error: $error');
      }
      return null;
    }
  }

  /// Show Google Sign-In button
  static void showSignInButton(String containerId) {
    if (!kIsWeb || !_isInitialized) return;

    js.context.callMethod('eval', [
      '''
      window.google.accounts.id.renderButton(
        document.getElementById("$containerId"),
        {
          theme: "outline",
          size: "large",
          text: "sign_in_with",
          shape: "rectangular",
          logo_alignment: "left"
        }
      );
    ''',
    ]);
  }
}
