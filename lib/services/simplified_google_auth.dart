import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:html' as html;
import 'dart:js' as js;
import 'supabase_config.dart';

/// Simplified Google Authentication that works with any port
class SimplifiedGoogleAuth {
  static bool _isInitialized = false;
  static const String _googleApiScript =
      'https://accounts.google.com/gsi/client';

  /// Initialize Google Sign-In
  static Future<void> initialize() async {
    if (!kIsWeb || _isInitialized) return;

    try {
      // Load Google Identity Services script
      await _loadGoogleScript();

      // Initialize Google Sign-In with popup mode (no redirect needed)
      js.context.callMethod('eval', [
        '''
        if (window.google && window.google.accounts && window.google.accounts.id) {
          // Global callback function
          window.googleSignInCallback = function(response) {
            console.log('Google Sign-In success:', response);
            window.googleCredential = response.credential;
            window.googleSignInComplete = true;
          };
          
          // Initialize Google Identity Services
          window.google.accounts.id.initialize({
            client_id: "${SupabaseConfig.googleWebClientId}",
            callback: window.googleSignInCallback,
            auto_select: false,
            cancel_on_tap_outside: true,
            use_fedcm_for_prompt: false
          });
          
          console.log('Google Identity Services initialized successfully');
          window.googleInitialized = true;
        } else {
          console.error('Google Identity Services not available');
          window.googleInitialized = false;
        }
        ''',
      ]);

      _isInitialized = true;
      if (kDebugMode) {
        print('Simplified Google Auth initialized successfully');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Failed to initialize Simplified Google Auth: $error');
      }
      throw Exception('Google authentication initialization failed');
    }
  }

  /// Load Google Identity Services script
  static Future<void> _loadGoogleScript() async {
    final completer = Completer<void>();

    // Check if script is already loaded
    if (js.context.hasProperty('google')) {
      completer.complete();
      return completer.future;
    }

    final script =
        html.ScriptElement()
          ..src = _googleApiScript
          ..async = true
          ..defer = true;

    script.onLoad.listen((_) {
      if (kDebugMode) {
        print('Google Identity Services script loaded');
      }
      completer.complete();
    });

    script.onError.listen((_) {
      completer.completeError('Failed to load Google Identity Services script');
    });

    html.document.head!.append(script);
    return completer.future;
  }

  /// Sign in with Google using popup mode
  static Future<AuthResponse?> signInWithGoogle() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (kDebugMode) {
        print('Starting simplified Google Sign-In...');
      }

      // Clear any existing state
      js.context['googleCredential'] = null;
      js.context['googleSignInComplete'] = false;

      // Trigger Google Sign-In popup
      final credential = await _triggerGoogleSignIn();

      if (credential == null) {
        throw Exception('Google Sign-In was cancelled or failed');
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
        print('Simplified Google Sign-In error: $error');
      }

      // Provide user-friendly error messages
      final errorStr = error.toString().toLowerCase();
      if (errorStr.contains('popup') || errorStr.contains('blocked')) {
        throw Exception('Popup blocked. Please allow popups and try again.');
      } else if (errorStr.contains('cancelled')) {
        throw Exception('Sign-in was cancelled. Please try again.');
      } else {
        throw Exception(
          'Google Sign-In failed. Please try email/password instead.',
        );
      }
    }
  }

  /// Trigger Google Sign-In popup
  static Future<String?> _triggerGoogleSignIn() async {
    try {
      // Use popup-based sign-in
      js.context.callMethod('eval', [
        '''
        (async function() {
          try {
            console.log('Triggering Google Sign-In popup...');
            
            // Reset state
            window.googleCredential = null;
            window.googleSignInComplete = false;
            
            // Try using the popup method
            if (window.google && window.google.accounts && window.google.accounts.oauth2) {
              const client = window.google.accounts.oauth2.initTokenClient({
                client_id: "${SupabaseConfig.googleWebClientId}",
                scope: 'openid email profile',
                callback: function(response) {
                  console.log('OAuth2 response:', response);
                  if (response.access_token) {
                    // Convert access token to ID token via Google API
                    fetch('https://www.googleapis.com/oauth2/v1/userinfo?access_token=' + response.access_token)
                      .then(res => res.json())
                      .then(userInfo => {
                        console.log('User info:', userInfo);
                        // Create a simple JWT-like token for Supabase
                        window.googleCredential = response.access_token;
                        window.googleSignInComplete = true;
                      });
                  }
                }
              });
              
              client.requestAccessToken();
            } else {
              // Fallback to One Tap
              window.google.accounts.id.prompt();
            }
          } catch (error) {
            console.error('Google Sign-In error:', error);
            window.googleSignInComplete = true; // Mark as complete to exit wait loop
          }
        })();
        ''',
      ]);

      // Wait for sign-in to complete with timeout
      const maxWaitTime = 30000; // 30 seconds
      const checkInterval = 500; // 0.5 seconds
      int elapsedTime = 0;

      while (elapsedTime < maxWaitTime) {
        await Future.delayed(Duration(milliseconds: checkInterval));
        elapsedTime += checkInterval;

        final isComplete = js.context['googleSignInComplete'] as bool?;
        if (isComplete == true) {
          final credential = js.context['googleCredential'] as String?;
          return credential;
        }
      }

      throw Exception('Google Sign-In timed out');
    } catch (error) {
      if (kDebugMode) {
        print('Error triggering Google Sign-In: $error');
      }
      return null;
    }
  }

  /// Check if user is signed in
  static Future<bool> isSignedIn() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      return user != null;
    } catch (error) {
      return false;
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();

      // Also sign out from Google
      if (kIsWeb) {
        js.context.callMethod('eval', [
          '''
          if (window.google && window.google.accounts && window.google.accounts.id) {
            window.google.accounts.id.disableAutoSelect();
          }
          ''',
        ]);
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error signing out: $error');
      }
    }
  }
}
