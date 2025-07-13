import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles OAuth redirects to prevent infinite loops
class AuthRedirectHandler {
  static bool _isHandlingRedirect = false;
  static DateTime? _lastRedirectHandled;
  static const int _redirectCooldownMs = 5000; // 5 second cooldown

  /// Check if we should handle this auth state change
  static bool shouldHandleAuthChange(AuthChangeEvent event) {
    final now = DateTime.now();
    
    // If we're already handling a redirect, skip
    if (_isHandlingRedirect) {
      if (kDebugMode) {
        print('AuthRedirectHandler: Already handling redirect, skipping...');
      }
      return false;
    }

    // If we recently handled a redirect, add cooldown to prevent loops
    if (_lastRedirectHandled != null) {
      final timeSinceLastRedirect = now.difference(_lastRedirectHandled!).inMilliseconds;
      if (timeSinceLastRedirect < _redirectCooldownMs) {
        if (kDebugMode) {
          print('AuthRedirectHandler: Cooldown active, skipping (${timeSinceLastRedirect}ms ago)...');
        }
        return false;
      }
    }

    return true;
  }

  /// Mark that we're starting to handle a redirect
  static void startHandling() {
    _isHandlingRedirect = true;
    _lastRedirectHandled = DateTime.now();
    if (kDebugMode) {
      print('AuthRedirectHandler: Started handling redirect at ${_lastRedirectHandled}');
    }
  }

  /// Mark that we're done handling a redirect
  static void finishHandling() {
    _isHandlingRedirect = false;
    if (kDebugMode) {
      print('AuthRedirectHandler: Finished handling redirect');
    }
  }

  /// Reset the handler state (useful for testing or forced resets)
  static void reset() {
    _isHandlingRedirect = false;
    _lastRedirectHandled = null;
    if (kDebugMode) {
      print('AuthRedirectHandler: Reset state');
    }
  }

  /// Clear browser data for web to fix redirect loops
  static Future<void> clearWebData() async {
    if (kIsWeb) {
      try {
        // Clear Supabase session data
        await Supabase.instance.client.auth.signOut(scope: SignOutScope.global);
        if (kDebugMode) {
          print('AuthRedirectHandler: Cleared web session data');
        }
      } catch (e) {
        if (kDebugMode) {
          print('AuthRedirectHandler: Error clearing web data: $e');
        }
      }
    }
  }
}
