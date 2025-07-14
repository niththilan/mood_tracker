import 'package:flutter/foundation.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://xxasezacvotitccxnpaa.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh4YXNlemFjdm90aXRjY3hucGFhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg1ODE3MTIsImV4cCI6MjA2NDE1NzcxMn0.aUygIOPiI1HqFwKifXGYIolzeIQGbpjzGCC861LHRS4';

  // Google OAuth Configuration
  static const String googleWebClientId =
      '631111437135-bvvu4b15elvmctbclkbmag856kke0nmq.apps.googleusercontent.com';
  static const String googleWebClientSecret =
      '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';
  static const String googleAndroidClientId =
      '631111437135-234lcguj55v09qd7415e7ohr2p55b58j.apps.googleusercontent.com';
  static const String googleIOSClientId =
      '631111437135-jg42a9hahfchrrfhva4mbb0bddaq5g5f.apps.googleusercontent.com'; // OAuth Callback URLs - these MUST match your Google Cloud Console settings
  static const String oauthCallbackUrl =
      'https://xxasezacvotitccxnpaa.supabase.co/auth/v1/callback';

  // Fixed localhost development URLs for Google OAuth
  static const String localhostRedirectUrl = 'http://localhost:8080';
  static const String localhostCallbackUrl =
      'http://localhost:8080/auth/callback';

  // Local development callback (if needed)
  static String get webRedirectUrl {
    // Always use fixed localhost:8080 for development
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host == 'localhost' || host == '127.0.0.1') {
        return localhostRedirectUrl;
      }
    }
    return oauthCallbackUrl;
  }

  // Get the appropriate redirect URL based on environment
  static String getRedirectUrl() {
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host == 'localhost' || host == '127.0.0.1') {
        // Use fixed localhost URL for development
        return localhostCallbackUrl;
      }
      // For production web, use Supabase callback
      return oauthCallbackUrl;
    } else {
      // For mobile, use deep linking
      return 'com.moodtracker.app://auth';
    }
  }

  // Get the current app URL
  static String getCurrentUrl() {
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host == 'localhost' || host == '127.0.0.1') {
        return localhostRedirectUrl;
      }
    }
    return 'https://your-production-domain.com';
  }
}
