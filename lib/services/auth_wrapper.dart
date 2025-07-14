import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

/// Wrapper widget that handles authentication state changes
class AuthWrapper extends StatefulWidget {
  final Widget Function(BuildContext context) authenticatedBuilder;
  final Widget Function(BuildContext context) unauthenticatedBuilder;
  final Widget Function(BuildContext context)? loadingBuilder;

  const AuthWrapper({
    Key? key,
    required this.authenticatedBuilder,
    required this.unauthenticatedBuilder,
    this.loadingBuilder,
  }) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late final SupabaseClient _supabase;
  late final StreamSubscription<AuthState> _authSubscription;
  bool _isLoading = true;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _currentUser = _supabase.auth.currentUser;

    // Set initial loading state
    if (_currentUser != null) {
      _isLoading = false;
    }

    // Listen to auth state changes
    _authSubscription = _supabase.auth.onAuthStateChange.listen(
      _onAuthStateChange,
      onError: (error) {
        if (kDebugMode) {
          print('Auth state error: $error');
        }
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      },
    );

    // Set loading to false after a short delay if no auth state change occurs
    Timer(const Duration(seconds: 2), () {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _onAuthStateChange(AuthState authState) {
    if (kDebugMode) {
      print('Auth state changed: ${authState.event}');
      print('User: ${authState.session?.user.email ?? 'None'}');
    }

    if (mounted) {
      setState(() {
        _currentUser = authState.session?.user;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.loadingBuilder?.call(context) ??
          const Center(child: CircularProgressIndicator());
    }

    if (_currentUser != null) {
      return widget.authenticatedBuilder(context);
    } else {
      return widget.unauthenticatedBuilder(context);
    }
  }
}
