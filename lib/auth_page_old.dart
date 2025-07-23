import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:math' as math;
import 'main.dart';
import 'services/user_profile_service.dart';
import 'services/google_auth_service.dart';
import 'forgot_password_page.dart';

class AuthPage extends StatefulWidget {
  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _emailValid = false;
  bool _passwordValid = false;
  bool _nameValid = false;
  bool _ageValid = false;
  String? _selectedGender;
  late AnimationController _animationController;
  late AnimationController _modeController;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _modeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _particleAnimation;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();

    // Main animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Mode switch animation controller
    _modeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Pulse animation for buttons
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Particle animation controller
    _particleController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    // Setup animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _modeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _modeController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.linear),
    );

    // Start animations
    _animationController.forward();
    _pulseController.repeat(reverse: true);
    _particleController.repeat();

    // Add listeners for real-time validation
    _emailController.addListener(_validateEmailRealTime);
    _passwordController.addListener(_validatePasswordRealTime);
    _nameController.addListener(_validateNameRealTime);
    _ageController.addListener(_validateAgeRealTime);
  }

  void _validateEmailRealTime() {
    final isValid =
        _emailController.text.isNotEmpty &&
        RegExp(
          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
        ).hasMatch(_emailController.text);
    if (isValid != _emailValid) {
      setState(() => _emailValid = isValid);
    }
  }

  void _validatePasswordRealTime() {
    final isValid = _passwordController.text.length >= 6;
    if (isValid != _passwordValid) {
      setState(() => _passwordValid = isValid);
    }
  }

  void _validateNameRealTime() {
    final isValid = _nameController.text.trim().length >= 2;
    if (isValid != _nameValid) {
      setState(() => _nameValid = isValid);
    }
  }

  void _validateAgeRealTime() {
    final age = int.tryParse(_ageController.text);
    final isValid = age != null && age >= 13 && age <= 120;
    if (isValid != _ageValid) {
      setState(() => _ageValid = isValid);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _modeController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'Name must be less than 50 characters';
    }
    return null;
  }

  String? _validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Age is required';
    }
    final age = int.tryParse(value.trim());
    if (age == null) {
      return 'Please enter a valid age';
    }
    if (age < 13) {
      return 'You must be at least 13 years old';
    }
    if (age > 120) {
      return 'Please enter a valid age';
    }
    return null;
  }

  String? _validateGender(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select your gender';
    }
    return null;
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final response = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user != null && mounted) {
        // Ensure user profile exists before navigating
        final existingProfile = await UserProfileService.getUserProfile(
          response.user!.id,
        );

        if (existingProfile == null) {
          // Create a basic profile for existing users who may not have one
          final profileCreated = await UserProfileService.createUserProfile(
            userId: response.user!.id,
            name: response.user!.email?.split('@')[0] ?? 'User',
          );

          if (!profileCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Profile setup incomplete. Please update your profile after login.',
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MoodHomePage()),
        );
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text(error.message)),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } on SocketException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Network error: Please check your internet connection',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        String errorMessage = 'Unexpected error occurred';
        if (error.toString().contains('Failed host lookup')) {
          errorMessage =
              'Network connection error. Please check your internet connection.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final response = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {
          'name': _nameController.text.trim(),
          'age':
              _ageController.text.trim().isNotEmpty
                  ? int.tryParse(_ageController.text.trim())
                  : null,
          'gender': _selectedGender,
        },
      );

      if (response.user != null && mounted) {
        print('Signup successful for user: ${response.user!.id}');
        print('User metadata: ${response.user!.userMetadata}');

        // Wait a moment for the database trigger to create the profile
        await Future.delayed(Duration(milliseconds: 1000));

        // Check if profile was created by trigger and update if needed
        final existingProfile = await UserProfileService.getUserProfile(
          response.user!.id,
        );
        print('Profile created by trigger: $existingProfile');

        bool profileUpdated = false;
        if (existingProfile != null) {
          // Update the profile with additional details if they weren't in metadata
          profileUpdated = await UserProfileService.updateUserProfile(
            userId: response.user!.id,
            name: _nameController.text.trim(),
            age: int.tryParse(_ageController.text.trim()),
            gender: _selectedGender,
          );
          print('Profile updated: $profileUpdated');
        } else {
          // Fallback: create profile if trigger didn't work
          profileUpdated = await UserProfileService.createUserProfile(
            userId: response.user!.id,
            name: _nameController.text.trim(),
            age: int.tryParse(_ageController.text.trim()),
            gender: _selectedGender,
          );
          print('Profile created as fallback: $profileUpdated');
        }

        // Verify the final profile
        if (profileUpdated) {
          final verifyProfile = await UserProfileService.getUserProfile(
            response.user!.id,
          );
          print('Final profile verification: $verifyProfile');

          if (verifyProfile != null &&
              verifyProfile['name'] == _nameController.text.trim()) {
            print(
              'Profile setup successful with correct name: ${verifyProfile['name']}',
            );
          } else {
            print(
              'Warning: Profile name mismatch! Expected: ${_nameController.text.trim()}, Got: ${verifyProfile?['name']}',
            );
          }
        }

        if (profileUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Account created successfully! Check your email for verification link',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          setState(() => _isLogin = true);
        } else {
          // Profile creation failed, show error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.warning, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Account created but profile setup failed. Please try logging in and update your profile.',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          setState(() => _isLogin = true);
        }
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text(error.message)),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } on SocketException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Network error: Please check your internet connection',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        String errorMessage = 'Unexpected error occurred';
        if (error.toString().contains('Failed host lookup')) {
          errorMessage =
              'Network connection error. Please check your internet connection.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final response = await GoogleAuthService.signInWithGoogle();

      // For web, the response might be null as auth is handled by the main app listener
      if (response?.user != null && mounted) {
        final user = response!.user!;
        // Check if user profile exists
        final existingProfile = await UserProfileService.getUserProfile(
          user.id,
        );

        if (existingProfile == null) {
          // Create a basic profile for Google users
          final profileCreated = await UserProfileService.createUserProfile(
            userId: user.id,
            name: user.email?.split('@')[0] ?? 'User',
            age: null, // Can be updated later in profile
            gender: null, // Can be updated later in profile
          );

          if (!profileCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Profile setup incomplete. Please update your profile after login.',
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MoodHomePage()),
        );
      } else if (response == null) {
        // For web OAuth, response might be null - auth will be handled by AuthWrapper
        // Show a loading message and let the main auth listener handle the rest
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.info, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sign-in initiated. Please complete authentication in the popup.',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.blue,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        String errorMessage = 'Google sign-in failed';
        if (error.toString().contains('network')) {
          errorMessage = 'Network error: Please check your internet connection';
        } else if (error.toString().contains('cancelled')) {
          errorMessage = 'Sign-in cancelled';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _testGoogleSignIn() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      print('=== Testing Google Sign-In ===');
      
      // Test the configuration
      final configTest = await GoogleAuthService.testConfiguration();
      print('Configuration test: $configTest');
      
      // Then attempt sign-in
      final result = await GoogleAuthService.signInWithGoogle();
      
      if (result?.user != null) {
        print('✅ Google Sign-In successful!');
        print('User: ${result!.user!.email}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Google Sign-In successful!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        print('⚠️ Google Sign-In returned null - OAuth redirect initiated');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Google Sign-In initiated - check popup or redirect'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }
    } catch (error) {
      print('❌ Google Sign-In error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background with particles
          AnimatedBuilder(
            animation: _particleAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlePainter(_particleAnimation.value),
                size: Size.infinite,
              );
            },
          ),

          // Main content
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  Theme.of(
                    context,
                  ).colorScheme.secondary.withValues(alpha: 0.1),
                  Theme.of(
                    context,
                  ).colorScheme.tertiary.withValues(alpha: 0.05),
                ],
                stops: const [0.0, 0.7, 1.0],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildAuthCard(context),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthCard(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isLoading ? _pulseAnimation.value : 1.0,
          child: Card(
            elevation: _isLoading ? 16 : 12,
            shadowColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.9),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 32),
                      _buildModeToggle(context),
                      const SizedBox(height: 32),
                      _buildFormFields(context),
                      const SizedBox(height: 32),
                      _buildActionButtons(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        // Animated logo with mood indicators
        Hero(
          tag: 'app_logo',
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.rotate(
                angle: value * 0.1,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primaryContainer,
                        Theme.of(context).colorScheme.secondaryContainer,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Icon(
                        Icons.mood,
                        size: 52,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      // Animated mood indicators around the main icon
                      ...List.generate(3, (index) {
                        return Positioned(
                          left: 25 + (index * 8),
                          top: 5,
                          child: AnimatedBuilder(
                            animation: _particleAnimation,
                            builder: (context, child) {
                              final animValue =
                                  (_particleAnimation.value + index * 0.3) %
                                  1.0;
                              return Transform.translate(
                                offset: Offset(
                                  10 * math.sin(animValue * 2 * math.pi),
                                  5 * math.cos(animValue * 2 * math.pi),
                                ),
                                child: Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.6),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        ShaderMask(
          shaderCallback:
              (bounds) => LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ).createShader(bounds),
          child: Text(
            'MoodFlow',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style:
              Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ) ??
              const TextStyle(),
          child: const Text('Track your journey to wellness'),
        ),
      ],
    );
  }

  Widget _buildModeToggle(BuildContext context) {
    return AnimatedBuilder(
      animation: _modeAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Stack(
            children: [
              // Animated background indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: _isLogin ? 4 : null,
                right: _isLogin ? null : 4,
                top: 4,
                bottom: 4,
                width: MediaQuery.of(context).size.width * 0.35,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              // Toggle buttons
              Row(
                children: [
                  Expanded(
                    child: _buildToggleButton(
                      'Sign In',
                      Icons.login,
                      _isLogin,
                      () => _switchMode(true),
                    ),
                  ),
                  Expanded(
                    child: _buildToggleButton(
                      'Sign Up',
                      Icons.person_add,
                      !_isLogin,
                      () => _switchMode(false),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToggleButton(
    String text,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color:
                  isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color:
                    isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _switchMode(bool isLogin) {
    if (_isLogin != isLogin) {
      setState(() => _isLogin = isLogin);
      _modeController.forward().then((_) => _modeController.reverse());
    }
  }

  Widget _buildFormFields(BuildContext context) {
    return Column(
      children: [
        // Email Field with real-time validation
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow:
                _emailValid
                    ? [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: TextFormField(
            controller: _emailController,
            validator: _validateEmail,
            enabled: !_isLoading,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email address',
              prefixIcon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.email_outlined,
                  color:
                      _emailValid
                          ? Colors.green
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              suffixIcon:
                  _emailValid
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color:
                      _emailValid
                          ? Colors.green
                          : Theme.of(context).colorScheme.outline,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Name Field (only for sign up)
        if (!_isLogin) ...[
          AnimatedSlide(
            duration: const Duration(milliseconds: 300),
            offset: _isLogin ? const Offset(0, -1) : Offset.zero,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _isLogin ? 0.0 : 1.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow:
                      _nameValid
                          ? [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                          : null,
                ),
                child: TextFormField(
                  controller: _nameController,
                  validator: _validateName,
                  enabled: !_isLoading,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
                    prefixIcon: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.person_outline,
                        color:
                            _nameValid
                                ? Colors.green
                                : Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    suffixIcon:
                        _nameValid
                            ? const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color:
                            _nameValid
                                ? Colors.green
                                : Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Age Field
          AnimatedSlide(
            duration: const Duration(milliseconds: 300),
            offset: _isLogin ? const Offset(0, -1) : Offset.zero,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _isLogin ? 0.0 : 1.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow:
                      _ageValid
                          ? [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                          : null,
                ),
                child: TextFormField(
                  controller: _ageController,
                  validator: _validateAge,
                  enabled: !_isLoading,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Age',
                    hintText: 'Enter your age',
                    prefixIcon: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.cake_outlined,
                        color:
                            _ageValid
                                ? Colors.green
                                : Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    suffixIcon:
                        _ageValid
                            ? const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color:
                            _ageValid
                                ? Colors.green
                                : Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Gender Field
          AnimatedSlide(
            duration: const Duration(milliseconds: 300),
            offset: _isLogin ? const Offset(0, -1) : Offset.zero,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _isLogin ? 0.0 : 1.0,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: DropdownButtonFormField<String>(
                  value: _selectedGender,
                  validator: _validateGender,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    hintText: 'Select your gender',
                    prefixIcon: Icon(
                      Icons.person_pin_outlined,
                      color:
                          _selectedGender != null
                              ? Colors.green
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    suffixIcon:
                        _selectedGender != null
                            ? const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color:
                            _selectedGender != null
                                ? Colors.green
                                : Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'male',
                      child: SizedBox(
                        width: double.infinity,
                        child: Text('Male', overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'female',
                      child: SizedBox(
                        width: double.infinity,
                        child: Text('Female', overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'non-binary',
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          'Non-binary',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'prefer-not-to-say',
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          'Prefer not to say',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Password Field with strength indicator
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow:
                _passwordValid
                    ? [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: TextFormField(
            controller: _passwordController,
            validator: _validatePassword,
            enabled: !_isLoading,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              prefixIcon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.lock_outlined,
                  color:
                      _passwordValid
                          ? Colors.green
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_passwordValid)
                    const Icon(Icons.check_circle, color: Colors.green),
                  IconButton(
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        key: ValueKey(_obscurePassword),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color:
                      _passwordValid
                          ? Colors.green
                          : Theme.of(context).colorScheme.outline,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
          ),
        ),

        // Password strength indicator
        if (_passwordController.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildPasswordStrengthIndicator(),
        ],

        // Confirm Password Field (only for sign up)
        if (!_isLogin) ...[
          const SizedBox(height: 20),
          AnimatedSlide(
            duration: const Duration(milliseconds: 300),
            offset: _isLogin ? const Offset(0, -1) : Offset.zero,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _isLogin ? 0.0 : 1.0,
              child: TextFormField(
                controller: _confirmPasswordController,
                enabled: !_isLoading,
                obscureText: _obscureConfirmPassword,
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  hintText: 'Re-enter your password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final password = _passwordController.text;
    final strength = _calculatePasswordStrength(password);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Password strength: ',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              strength['label'],
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: strength['color'],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: strength['value'],
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(strength['color']),
        ),
      ],
    );
  }

  Map<String, dynamic> _calculatePasswordStrength(String password) {
    if (password.length < 6) {
      return {'value': 0.2, 'label': 'Weak', 'color': Colors.red};
    } else if (password.length < 8) {
      return {'value': 0.5, 'label': 'Fair', 'color': Colors.orange};
    } else if (password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[0-9]'))) {
      return {'value': 1.0, 'label': 'Strong', 'color': Colors.green};
    } else {
      return {'value': 0.7, 'label': 'Good', 'color': Colors.blue};
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Main Submit Button with enhanced styling
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isLoading ? _pulseAnimation.value : 1.0,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : (_isLogin ? _signIn : _signUp),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child:
                      _isLoading
                          ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _isLogin
                                    ? 'Signing In...'
                                    : 'Creating Account...',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isLogin ? Icons.login : Icons.person_add,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isLogin ? 'Sign In' : 'Create Account',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // Divider with "OR" text
        Row(
          children: [
            Expanded(
              child: Divider(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                thickness: 1,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Google Sign-In Button
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.5),
              width: 1.5,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey[50]!],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoading ? null : _signInWithGoogle,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Google Logo using Unicode
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Center(
                        child: Text(
                          'G',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[600],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isLogin ? 'Sign in with Google' : 'Sign up with Google',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Forgot Password Link (only show in login mode)
        if (_isLogin) ...[
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ForgotPasswordPage(),
                  ),
                );
              },
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Debug button for Google Sign-In testing (all platforms)
        if (kDebugMode) ...[
          Center(
            child: OutlinedButton.icon(
              onPressed: _testGoogleSignIn,
              icon: Icon(
                Icons.bug_report,
                size: 16,
                color: Theme.of(context).colorScheme.secondary,
              ),
              label: Text(
                'Test Google Sign-In',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

// Custom Particle Painter for animated background
class ParticlePainter extends CustomPainter {
  final double animationValue;

  ParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.blue.withValues(alpha: 0.1)
          ..style = PaintingStyle.fill;

    // Generate floating particles
    for (int i = 0; i < 20; i++) {
      final x =
          (size.width * (i / 20)) +
          (50 * math.sin((animationValue * 2 * math.pi) + (i * 0.5)));
      final y =
          (size.height * ((i % 5) / 5)) +
          (30 * math.cos((animationValue * 2 * math.pi) + (i * 0.3)));

      final radius = 2 + (2 * math.sin(animationValue * 2 * math.pi + i));

      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint..color = _getParticleColor(i).withValues(alpha: 0.6),
      );
    }
  }

  Color _getParticleColor(int index) {
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.pink,
      Colors.orange,
      Colors.green,
    ];
    return colors[index % colors.length];
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
