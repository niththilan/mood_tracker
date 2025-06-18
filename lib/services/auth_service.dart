import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Stream of auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Current session
  Session? get currentSession => _supabase.auth.currentSession;

  // Current user
  User? get currentUser => _supabase.auth.currentUser;

  // Sign out method
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (error) {
      print('Error signing out: $error');
      rethrow;
    }
  }

  // Check if user is authenticated
  bool get isAuthenticated => currentSession != null;

  // Clear local data on sign out
  Future<void> clearLocalData() async {
    // Clear user-specific data but keep onboarding status
    // Add any other local data clearing logic here if needed
  }
}
