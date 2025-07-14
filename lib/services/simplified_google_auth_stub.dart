import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Stub for SimplifiedGoogleAuth - only used on non-web platforms
class SimplifiedGoogleAuth {
  static Future<AuthResponse?> signInWithGoogle() async {
    if (kDebugMode) {
      print('SimplifiedGoogleAuth stub called on non-web platform');
    }
    throw UnsupportedError(
      'SimplifiedGoogleAuth is only available on web platforms',
    );
  }
}
