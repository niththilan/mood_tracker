import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
        window.google.accounts.id.initialize({
          client_id: "${SupabaseConfig.googleWebClientId}",
          callback: handleCredentialResponse,
          auto_select: false,
          cancel_on_tap_outside: true
        });
        
        window.handleCredentialResponse = function(response) {
          window.googleCredentialResponse = response;
        };
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

      // Trigger Google Sign-In popup
      js.context.callMethod('eval', [
        '''
        window.google.accounts.id.prompt((notification) => {
          if (notification.isNotDisplayed() || notification.isSkippedMoment()) {
            // Fallback to click-triggered sign-in
            window.google.accounts.id.renderButton(
              document.createElement('div'),
              { theme: "outline", size: "large" }
            );
          }
        });
      ''',
      ]);

      // Wait for credential response
      final credential = await _waitForCredential();

      if (credential == null) {
        throw Exception('No credential received');
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
        print('Supabase sign-in successful');
      }

      return response;
    } catch (error) {
      if (kDebugMode) {
        print('Direct Google Sign-In error: $error');
      }
      rethrow;
    }
  }

  /// Wait for Google credential response
  static Future<String?> _waitForCredential() async {
    final completer = Completer<String?>();

    // Set up a timer to check for credential
    Timer.periodic(Duration(milliseconds: 100), (timer) {
      final response = js.context['googleCredentialResponse'];

      if (response != null) {
        timer.cancel();
        final credential = response['credential'];

        // Clear the response
        js.context['googleCredentialResponse'] = null;

        completer.complete(credential);
      }
    });

    // Timeout after 30 seconds
    Timer(Duration(seconds: 30), () {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    });

    return completer.future;
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
