import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Firebase Authentication Service with Google Sign-In integration
/// This service handles Firebase authentication and syncs with Supabase
class FirebaseAuthService {
  static final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  static final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;
  static GoogleSignIn? _googleSignIn;

  /// Initialize Firebase Auth Service
  static Future<void> initialize() async {
    try {
      if (kDebugMode) {
        print('Initializing Firebase Auth Service...');
      }

      // Configure Google Sign-In
      if (kIsWeb) {
        // For web, Google Sign-In will be configured automatically by Firebase
        if (kDebugMode) {
          print('Web platform: Google Sign-In configured automatically');
        }
      } else {
        // For mobile platforms
        _googleSignIn = GoogleSignIn(
          scopes: [
            'email',
            'profile',
          ],
        );
      }

      // Set up auth state listener
      _firebaseAuth.authStateChanges().listen((firebase_auth.User? user) {
        if (kDebugMode) {
          print('Firebase auth state changed: ${user?.email ?? 'No user'}');
        }
      });

      if (kDebugMode) {
        print('✅ Firebase Auth Service initialized successfully');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Firebase Auth Service initialization error: $error');
      }
      rethrow;
    }
  }

  /// Sign in with Google using Firebase Auth
  static Future<firebase_auth.UserCredential?> signInWithGoogle() async {
    try {
      if (kDebugMode) {
        print('Starting Firebase Google Sign-In...');
      }

      firebase_auth.UserCredential userCredential;

      if (kIsWeb) {
        // Web sign-in
        userCredential = await _signInWithGoogleWeb();
      } else {
        // Mobile sign-in
        userCredential = await _signInWithGoogleMobile();
      }

      if (kDebugMode) {
        print('✅ Firebase Google Sign-In successful: ${userCredential.user?.email}');
      }

      // Sync with Supabase after successful Firebase authentication
      await _syncWithSupabase(userCredential.user!);

      return userCredential;
    } catch (error) {
      if (kDebugMode) {
        print('❌ Firebase Google Sign-In error: $error');
      }
      rethrow;
    }
  }

  /// Web Google Sign-In
  static Future<firebase_auth.UserCredential> _signInWithGoogleWeb() async {
    final firebase_auth.GoogleAuthProvider googleProvider = firebase_auth.GoogleAuthProvider();
    
    // Add required scopes
    googleProvider.addScope('email');
    googleProvider.addScope('profile');

    return await _firebaseAuth.signInWithPopup(googleProvider);
  }

  /// Mobile Google Sign-In
  static Future<firebase_auth.UserCredential> _signInWithGoogleMobile() async {
    if (_googleSignIn == null) {
      throw Exception('Google Sign-In not initialized for mobile');
    }

    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
    if (googleUser == null) {
      throw Exception('Google Sign-In was cancelled by user');
    }

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Create a new credential
    final credential = firebase_auth.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Once signed in, return the UserCredential
    return await _firebaseAuth.signInWithCredential(credential);
  }

  /// Sync Firebase user with Supabase
  static Future<void> _syncWithSupabase(firebase_auth.User firebaseUser) async {
    try {
      if (kDebugMode) {
        print('Syncing Firebase user with Supabase...');
      }

      // Get Firebase ID token
      final String? idToken = await firebaseUser.getIdToken();
      if (idToken == null) {
        throw Exception('Failed to get Firebase ID token');
      }

      // Sign in to Supabase using the Firebase ID token
      final supabase.AuthResponse response = await _supabase.auth.signInWithIdToken(
        provider: supabase.OAuthProvider.google,
        idToken: idToken,
        accessToken: firebaseUser.refreshToken,
      );

      if (response.user != null) {
        if (kDebugMode) {
          print('✅ Successfully synced with Supabase: ${response.user!.email}');
        }
      } else {
        throw Exception('Failed to sync with Supabase');
      }
    } catch (error) {
      if (kDebugMode) {
        print('❌ Error syncing with Supabase: $error');
      }
      // Don't throw here as Firebase auth succeeded
      // The app can still work with Firebase-only auth
    }
  }

  /// Get current Firebase user
  static firebase_auth.User? get currentUser => _firebaseAuth.currentUser;

  /// Check if user is signed in
  static bool get isSignedIn => _firebaseAuth.currentUser != null;

  /// Sign out from both Firebase and Supabase
  static Future<void> signOut() async {
    try {
      if (kDebugMode) {
        print('Signing out from Firebase and Supabase...');
      }

      // Sign out from Google Sign-In if on mobile
      if (!kIsWeb && _googleSignIn != null) {
        await _googleSignIn!.signOut();
      }

      // Sign out from Firebase
      await _firebaseAuth.signOut();

      // Sign out from Supabase
      try {
        await _supabase.auth.signOut();
      } catch (error) {
        if (kDebugMode) {
          print('Supabase sign-out error (non-critical): $error');
        }
      }

      if (kDebugMode) {
        print('✅ Sign-out completed');
      }
    } catch (error) {
      if (kDebugMode) {
        print('❌ Sign-out error: $error');
      }
      rethrow;
    }
  }

  /// Get user display name
  static String? get userDisplayName {
    final user = _firebaseAuth.currentUser;
    return user?.displayName ?? user?.email?.split('@')[0];
  }

  /// Get user email
  static String? get userEmail => _firebaseAuth.currentUser?.email;

  /// Get user photo URL
  static String? get userPhotoUrl => _firebaseAuth.currentUser?.photoURL;

  /// Listen to auth state changes
  static Stream<firebase_auth.User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Get Firebase ID token for API calls
  static Future<String?> getIdToken() async {
    return await _firebaseAuth.currentUser?.getIdToken();
  }

  /// Refresh Firebase token
  static Future<void> refreshToken() async {
    await _firebaseAuth.currentUser?.getIdToken(true);
  }

  /// Delete user account
  static Future<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.delete();
        if (kDebugMode) {
          print('✅ Firebase account deleted');
        }
      }
    } catch (error) {
      if (kDebugMode) {
        print('❌ Error deleting Firebase account: $error');
      }
      rethrow;
    }
  }

  /// Test Firebase configuration
  static Future<Map<String, dynamic>> testConfiguration() async {
    final result = <String, dynamic>{};

    try {
      result['platform'] = kIsWeb ? 'web' : 'mobile';
      result['firebaseUser'] = _firebaseAuth.currentUser?.email;
      result['isSignedIn'] = isSignedIn;
      result['userDisplayName'] = userDisplayName;
      result['userEmail'] = userEmail;
      result['googleSignInAvailable'] = _googleSignIn != null || kIsWeb;
      
      if (!kIsWeb && _googleSignIn != null) {
        result['googleSignInInitialized'] = true;
        final currentGoogleUser = await _googleSignIn!.signInSilently();
        result['googleCurrentUser'] = currentGoogleUser?.email;
      }
    } catch (error) {
      result['error'] = error.toString();
    }

    return result;
  }
}
