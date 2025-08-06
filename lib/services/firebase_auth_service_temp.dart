import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
// import 'package:google_sign_in/google_sign_in.dart'; // Temporarily disabled
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Firebase Authentication Service (Simplified - Google Sign-In disabled)
/// This service handles basic Firebase authentication
class FirebaseAuthService {
  static final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  static final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;

  /// Initialize Firebase Auth Service
  static Future<void> initialize() async {
    try {
      if (kDebugMode) {
        print('Initializing Firebase Auth Service (Google Sign-In disabled)...');
      }

      // Basic Firebase initialization without Google Sign-In
      final currentUser = _firebaseAuth.currentUser;
      if (kDebugMode) {
        print('Firebase current user: ${currentUser?.email ?? 'None'}');
      }

      if (kDebugMode) {
        print('Firebase Auth Service initialized successfully (basic mode)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Firebase Auth Service: $e');
      }
      rethrow;
    }
  }

  /// Sign in with email and password
  static Future<Map<String, dynamic>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        return {
          'success': true,
          'user': credential.user,
          'method': 'email',
        };
      }

      return {
        'success': false,
        'error': 'Authentication failed',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Sign in with Google (disabled - returns error)
  static Future<Map<String, dynamic>> signInWithGoogle() async {
    return {
      'success': false,
      'error': 'Google Sign-In temporarily disabled due to dependency conflicts',
    };
  }

  /// Check if Google Sign-In is available (always false in this mode)
  static Future<bool> isGoogleSignInAvailable() async {
    return false;
  }

  /// Sign out from Firebase
  static Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      if (kDebugMode) {
        print('Firebase sign out successful');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error signing out from Firebase: $e');
      }
    }
  }

  /// Get current Firebase user
  static firebase_auth.User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  /// Get Firebase Auth diagnostic information
  static Future<Map<String, dynamic>> getDiagnosticInfo() async {
    final Map<String, dynamic> result = {};
    
    try {
      final currentUser = _firebaseAuth.currentUser;
      result['currentUser'] = currentUser?.email;
      result['isSignedIn'] = currentUser != null;
      result['googleSignInAvailable'] = false; // Disabled
      result['googleSignInError'] = 'Google Sign-In temporarily disabled';
      
      result['status'] = 'Firebase Auth Service running (Google Sign-In disabled)';
    } catch (e) {
      result['error'] = e.toString();
      result['status'] = 'Error getting diagnostic info';
    }
    
    return result;
  }
}
