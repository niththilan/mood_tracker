import 'package:flutter/foundation.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://xxasezacvotitccxnpaa.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh4YXNlemFjdm90aXRjY3hucGFhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg1ODE3MTIsImV4cCI6MjA2NDE1NzcxMn0.aUygIOPiI1HqFwKifXGYIolzeIQGbpjzGCC861LHRS4';

  // Google OAuth Configuration
  static const String googleWebClientId =
      '631111437135-iuippmjn73ur1g4thacjmr5lq3k315t0.apps.googleusercontent.com';
  static const String googleWebClientSecret =
      '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';
  static const String googleAndroidClientId =
      '631111437135-76ojbi40r925em3sinj9igoel5f4do1i.apps.googleusercontent.com';
  static const String googleIOSClientId =
      '631111437135-5iajfi8mlc0olt9bla8tqhic6sior22j.apps.googleusercontent.com';

  // OAuth Callback URLs - these MUST match your Google Cloud Console settings
  static const String oauthCallbackUrl =
      'https://xxasezacvotitccxnpaa.supabase.co/auth/v1/callback';

  // Dynamic localhost URL for development (detects current port)
  static String get localhostUrl {
    if (kIsWeb) {
      final currentUrl = Uri.base;
      return '${currentUrl.scheme}://${currentUrl.host}:${currentUrl.port}';
    }
    return 'http://localhost:3000'; // fallback for non-web
  }

  // Get the appropriate redirect URL based on environment
  static String getRedirectUrl() {
    if (kIsWeb) {
      final currentUrl = Uri.base;
      final host = currentUrl.host;
      
      if (host == 'localhost' || host == '127.0.0.1') {
        // Use dynamic localhost URL for development
        return localhostUrl;
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
        // Use dynamic localhost URL for development
        return localhostUrl;
      }
    }
    return 'https://your-production-domain.com';
  }
}
