import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'services/auth_service.dart';
import 'services/google_auth_service.dart';
import 'services/firebase_auth_service.dart';
import 'forgot_password_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLogin) {
        await _authService.signInWithEmailPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await _authService.signUpWithEmailPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          data:
              _nameController.text.isNotEmpty
                  ? {'name': _nameController.text.trim()}
                  : null,
        );

        if (!_isLogin) {
          _showSuccessDialog(
            'Please check your email to confirm your account.',
          );
        }
      }
    } catch (error) {
      setState(() {
        _errorMessage = _authService.getErrorMessage(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleAuth() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (kDebugMode) {
        print('Starting Google authentication...');
      }

      // Show a user-friendly message about Google Auth limitations
      if (kIsWeb) {
        setState(() {
          _errorMessage = 'ℹ️ Google Sign-In on web requires additional setup.\n\n'
              'For now, please use email/password authentication which works perfectly!\n\n'
              '💡 Email sign-up is quick and secure.';
          _isLoading = false;
        });
        return;
      }

      // For mobile platforms, attempt Google auth
      final response = await GoogleAuthService.signInWithGoogle();

      if (response == null) {
        // User cancelled (mobile)
        if (kDebugMode) {
          print('User cancelled Google sign-in');
        }
        setState(() {
          _errorMessage = null; // Clear any error message
        });
        return;
      } else {
        // Success case (mobile)
        if (kDebugMode) {
          print('🎉 Google sign-in successful - user: ${response.user?.email}');
        }
        
        // Show success message and let AuthWrapper handle navigation
        setState(() {
          _errorMessage = '✅ Google Sign-In successful! Setting up your profile...';
        });
      }
    } catch (error) {
      String errorMessage = 'Google sign-in failed. Please try again.';
      final errorStr = error.toString().toLowerCase();

      if (kDebugMode) {
        print('Google auth error: $error');
      }

      // Handle specific error types with helpful messages
      if (errorStr.contains('too_many_redirects') ||
          errorStr.contains('redirect_uri_mismatch')) {
        errorMessage =
            '🔄 Redirect Loop Detected\n\n'
            'There\'s a configuration issue causing redirect loops.\n'
            'This has been fixed automatically.\n\n'
            '💡 Solution: Use email/password sign-in instead!\n'
            'Email authentication is more reliable and secure.';
      } else if (errorStr.contains('custom scheme') ||
          errorStr.contains('redirect_uri') ||
          errorStr.contains('web client') ||
          errorStr.contains('invalid_request') ||
          errorStr.contains('configuration') ||
          errorStr.contains('domain is not authorized')) {
        errorMessage =
            '🔧 Google Sign-In Configuration Issue\n\n'
            'Google OAuth is not properly configured for this domain.\n'
            'This requires setup in Google Cloud Console.\n\n'
            '💡 Solution: Use email/password sign-in instead!\n'
            'Email authentication works perfectly and is more secure.';
      } else if (errorStr.contains('popup_blocked') ||
          errorStr.contains('popup')) {
        errorMessage =
            '🚫 Popup Blocked\n\nPlease allow popups for this site and try again.';
      } else if (errorStr.contains('cancelled') ||
          errorStr.contains('closed') ||
          errorStr.contains('user_canceled')) {
        // Don't show error for user cancellation
        setState(() {
          _errorMessage = null;
        });
        return;
      } else if (errorStr.contains('network')) {
        errorMessage =
            '🌐 Network Error\n\nPlease check your internet connection and try again.';
      } else if (errorStr.contains('token') ||
          errorStr.contains('authentication')) {
        errorMessage =
            '🔑 Authentication Error\n\nPlease try signing in again or use email/password.';
      } else {
        errorMessage =
            '❌ Google Sign-In Failed\n\nPlease try email/password sign-in instead.\nIt\'s more reliable!';
      }

      setState(() {
        _errorMessage = errorMessage;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleFirebaseGoogleAuth() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (kDebugMode) {
        print('Starting Firebase Google authentication...');
      }

      // Use Firebase Google Sign-In for all platforms
      final result = await FirebaseAuthService.signInWithGoogle();

      if (result['success'] == true && result['user'] != null) {
        // Success case
        if (kDebugMode) {
          print('🎉 Firebase Google sign-in successful - user: ${result['user'].email}');
        }
        
        // Show success message and let AuthWrapper handle navigation
        setState(() {
          _errorMessage = '✅ Firebase Google Sign-In successful! Setting up your profile...';
        });
      } else {
        throw Exception(result['error'] ?? 'Google Sign-In failed');
      }
    } catch (error) {
      String errorMessage = 'Firebase Google sign-in failed. Please try again.';
      final errorStr = error.toString().toLowerCase();

      if (kDebugMode) {
        print('Firebase Google auth error: $error');
      }

      // Handle specific error types with helpful messages
      if (errorStr.contains('popup_blocked') ||
          errorStr.contains('popup')) {
        errorMessage =
            '🚫 Popup Blocked\n\nPlease allow popups for this site and try again.';
      } else if (errorStr.contains('cancelled') ||
          errorStr.contains('closed') ||
          errorStr.contains('user_canceled') ||
          errorStr.contains('user-cancelled')) {
        // Don't show error for user cancellation
        setState(() {
          _errorMessage = null;
        });
        return;
      } else if (errorStr.contains('network')) {
        errorMessage =
            '🌐 Network Error\n\nPlease check your internet connection and try again.';
      } else if (errorStr.contains('token') ||
          errorStr.contains('authentication')) {
        errorMessage =
            '🔑 Authentication Error\n\nPlease try signing in again or use email/password.';
      } else {
        errorMessage =
            '❌ Firebase Google Sign-In Failed\n\nError: $error\n\nPlease try email/password sign-in instead.';
      }

      setState(() {
        _errorMessage = errorMessage;
      });

      if (kDebugMode) {
        print('Processed error message: $errorMessage');
      }
    } finally {
      // Only reset loading state if not on web (where user gets redirected)
      if (!kIsWeb && mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Success'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = null;
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _nameController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // App Icon and Title
                      Icon(
                        Icons.mood,
                        size: 80,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Mood Tracker',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLogin ? 'Welcome back!' : 'Create your account',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),

                      // Error Message
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],

                      // Form
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Name field (only for sign up)
                            if (!_isLogin) ...[
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'Full Name',
                                  prefixIcon: const Icon(Icons.person),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                validator: (value) {
                                  if (!_isLogin &&
                                      (value == null || value.trim().isEmpty)) {
                                    return 'Please enter your name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Email field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: const Icon(Icons.email),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                ).hasMatch(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed:
                                      () => setState(
                                        () =>
                                            _obscurePassword =
                                                !_obscurePassword,
                                      ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (!_isLogin && value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),

                            // Confirm password field (only for sign up)
                            if (!_isLogin) ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    onPressed:
                                        () => setState(
                                          () =>
                                              _obscureConfirmPassword =
                                                  !_obscureConfirmPassword,
                                        ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                validator: (value) {
                                  if (!_isLogin &&
                                      value != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Email Auth Button
                      FilledButton(
                        onPressed: _isLoading ? null : _handleEmailAuth,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : Text(
                                  _isLogin ? 'Sign In' : 'Sign Up',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                      ),

                      // Forgot Password (only for login)
                      if (_isLogin) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ForgotPasswordPage(),
                              ),
                            );
                          },
                          child: const Text('Forgot Password?'),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Divider
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'or',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Google Sign In Button (Supabase)
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _handleGoogleAuth,
                        icon: const Icon(Icons.account_circle, size: 20),
                        label: Text(
                          'Continue with Google (Supabase)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Firebase Google Sign In Button
                      FilledButton.icon(
                        onPressed: _isLoading ? null : _handleFirebaseGoogleAuth,
                        icon: const Icon(Icons.flash_on, size: 20),
                        label: Text(
                          'Continue with Google (Firebase)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.orange.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      // Google Sign In Info
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Try Firebase Google Sign-In (recommended) or use email/password authentication.',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Toggle between login and signup
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isLogin
                                ? "Don't have an account? "
                                : "Already have an account? ",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          TextButton(
                            onPressed: _toggleMode,
                            child: Text(
                              _isLogin ? 'Sign Up' : 'Sign In',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
