import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'services/user_profile_service.dart';
import 'services/theme_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;

  bool _isLoading = true;
  bool _isSaving = false;
  String _selectedAvatar = '😊';
  String _selectedColor = '#4CAF50';
  String? _selectedGender;

  late AnimationController _animationController;
  late AnimationController _saveAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _saveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
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

    _loadUserProfile();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _saveAnimationController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      print('No current user found');
      setState(() => _isLoading = false);
      return;
    }

    print('Loading profile for user: $userId');
    setState(() => _isLoading = true);

    final profile = await UserProfileService.getUserProfile(userId);

    if (profile != null) {
      print('Profile loaded successfully: $profile');
      setState(() {
        _nameController.text = profile['name'] ?? '';
        _ageController.text = profile['age']?.toString() ?? '';
        _selectedGender = profile['gender'];
        _selectedAvatar = profile['avatar_emoji'] ?? '😊';
        _selectedColor = profile['color'] ?? '#4CAF50';
        _isLoading = false;
      });
    } else {
      print(
        'No profile found - this should not happen for properly registered users',
      );
      // Show an error message and allow user to manually create their profile
      setState(() {
        _nameController.text = '';
        _ageController.text = '';
        _selectedGender = null;
        _selectedAvatar = '😊';
        _selectedColor = '#4CAF50';
        _isLoading = false;
      });

      // Show a message to the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.info, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Please set up your profile information below.'),
                ),
              ],
            ),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }

    _animationController.forward();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isSaving = true);
    _saveAnimationController.forward();

    // First check if profile exists
    final existingProfile = await UserProfileService.getUserProfile(userId);
    bool success = false;

    if (existingProfile != null) {
      // Update existing profile
      success = await UserProfileService.updateUserProfile(
        userId: userId,
        name: _nameController.text.trim(),
        age:
            _ageController.text.trim().isNotEmpty
                ? int.tryParse(_ageController.text.trim())
                : null,
        gender: _selectedGender,
        avatarEmoji: _selectedAvatar,
        color: _selectedColor,
      );
    } else {
      // Create new profile
      success = await UserProfileService.createUserProfile(
        userId: userId,
        name: _nameController.text.trim(),
        age:
            _ageController.text.trim().isNotEmpty
                ? int.tryParse(_ageController.text.trim())
                : null,
        gender: _selectedGender,
        avatarEmoji: _selectedAvatar,
        color: _selectedColor,
      );
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Profile ${existingProfile != null ? 'updated' : 'created'} successfully!',
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

      // Reload profile to get updated data
      await _loadUserProfile();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Failed to update profile. Please try again.'),
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

    setState(() => _isSaving = false);
    _saveAnimationController.reverse();
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
      return null; // Age is optional
    }
    final age = int.tryParse(value.trim());
    if (age == null) {
      return 'Please enter a valid age';
    }
    if (age < 13) {
      return 'Age must be at least 13';
    }
    if (age > 120) {
      return 'Please enter a valid age';
    }
    return null;
  }

  Color _hexToColor(String hex) {
    final hexValue = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexValue', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading profile...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
              : AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildProfileForm(),
                    ),
                  );
                },
              ),
    );
  }

  Widget _buildProfileForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar Preview
            _buildAvatarPreview(),
            SizedBox(height: 24),

            // Profile Info Display
            _buildProfileInfoDisplay(),
            SizedBox(height: 32),

            // Edit Profile Section Header
            Text(
              'Edit Profile',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),

            // Name Field
            _buildNameField(),
            SizedBox(height: 24),

            // Age Field
            _buildAgeField(),
            SizedBox(height: 24),

            // Gender Field
            _buildGenderField(),
            SizedBox(height: 24),

            // Avatar Selection
            _buildAvatarSelection(),
            SizedBox(height: 24),

            // Color Selection
            _buildColorSelection(),
            SizedBox(height: 24),

            // Theme Settings
            _buildThemeSettings(),
            SizedBox(height: 32),

            // Save Button
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPreview() {
    return Hero(
      tag: 'profile_avatar',
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: _hexToColor(_selectedColor),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _hexToColor(_selectedColor).withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Center(
          child: Text(_selectedAvatar, style: TextStyle(fontSize: 48)),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow:
            _nameController.text.isNotEmpty
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
        enabled: !_isSaving,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: 'Display Name',
          hintText: 'Enter your display name',
          prefixIcon: Icon(
            Icons.person_outline,
            color:
                _nameController.text.isNotEmpty
                    ? Colors.green
                    : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          suffixIcon:
              _nameController.text.isNotEmpty
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color:
                  _nameController.text.isNotEmpty
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
    );
  }

  Widget _buildAgeField() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow:
            _ageController.text.isNotEmpty
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
        enabled: !_isSaving,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Age',
          hintText: 'Enter your age (optional)',
          prefixIcon: Icon(
            Icons.cake_outlined,
            color:
                _ageController.text.isNotEmpty
                    ? Colors.green
                    : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          suffixIcon:
              _ageController.text.isNotEmpty
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color:
                  _ageController.text.isNotEmpty
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
    );
  }

  Widget _buildGenderField() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Gender',
          hintText: 'Select your gender (optional)',
          prefixIcon: Icon(
            Icons.person_pin_outlined,
            color:
                _selectedGender != null
                    ? Colors.green
                    : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          suffixIcon:
              _selectedGender != null
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
              child: Text('Non-binary', overflow: TextOverflow.ellipsis),
            ),
          ),
          DropdownMenuItem(
            value: 'prefer-not-to-say',
            child: SizedBox(
              width: double.infinity,
              child: Text('Prefer not to say', overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged:
            _isSaving
                ? null
                : (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
      ),
    );
  }

  Widget _buildAvatarSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Avatar',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: UserProfileService.getAvailableAvatars().length,
            itemBuilder: (context, index) {
              final avatar = UserProfileService.getAvailableAvatars()[index];
              final isSelected = avatar == _selectedAvatar;

              return GestureDetector(
                onTap: () => setState(() => _selectedAvatar = avatar),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: 12),
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                    border:
                        isSelected
                            ? Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 3,
                            )
                            : null,
                    boxShadow:
                        isSelected
                            ? [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ]
                            : null,
                  ),
                  child: Center(
                    child: Text(avatar, style: TextStyle(fontSize: 24)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildColorSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Color',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              UserProfileService.getAvailableColors().map((color) {
                final isSelected = color == _selectedColor;

                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _hexToColor(color),
                      shape: BoxShape.circle,
                      border:
                          isSelected
                              ? Border.all(
                                color: Theme.of(context).colorScheme.onSurface,
                                width: 3,
                              )
                              : Border.all(
                                color: Theme.of(context).colorScheme.outline,
                                width: 1,
                              ),
                      boxShadow:
                          isSelected
                              ? [
                                BoxShadow(
                                  color: _hexToColor(color).withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ]
                              : null,
                    ),
                    child:
                        isSelected
                            ? Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return AnimatedBuilder(
      animation: _saveAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_saveAnimationController.value * 0.05),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              child:
                  _isSaving
                      ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Saving...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Save Profile',
                            style: TextStyle(
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
    );
  }

  Widget _buildProfileInfoDisplay() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile Information',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            _buildInfoRow(
              'Name',
              _nameController.text.isNotEmpty
                  ? _nameController.text
                  : 'Not set',
              Icons.person_outline,
            ),
            if (_ageController.text.isNotEmpty)
              _buildInfoRow(
                'Age',
                '${_ageController.text} years old',
                Icons.cake_outlined,
              ),
            if (_selectedGender != null)
              _buildInfoRow(
                'Gender',
                _formatGenderText(_selectedGender!),
                Icons.person_pin_outlined,
              ),
            _buildInfoRow(
              'Member since',
              _formatMemberSince(),
              Icons.calendar_today_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: 12),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  String _formatGenderText(String gender) {
    switch (gender) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      case 'non-binary':
        return 'Non-binary';
      case 'prefer-not-to-say':
        return 'Prefer not to say';
      default:
        return gender;
    }
  }

  String _formatMemberSince() {
    final user = supabase.auth.currentUser;
    if (user?.createdAt != null) {
      final date = DateTime.parse(user!.createdAt);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[date.month - 1]} ${date.year}';
    }
    return 'Unknown';
  }

  Widget _buildThemeSettings() {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Theme Settings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  _buildThemeOption(
                    context,
                    themeService,
                    ThemeMode.system,
                    'System',
                    'Follow device settings',
                    Icons.settings_outlined,
                  ),
                  SizedBox(height: 12),
                  _buildThemeOption(
                    context,
                    themeService,
                    ThemeMode.light,
                    'Light',
                    'Always use light theme',
                    Icons.light_mode_outlined,
                  ),
                  SizedBox(height: 12),
                  _buildThemeOption(
                    context,
                    themeService,
                    ThemeMode.dark,
                    'Dark',
                    'Always use dark theme',
                    Icons.dark_mode_outlined,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeService themeService,
    ThemeMode themeMode,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = themeService.themeMode == themeMode;

    return GestureDetector(
      onTap: () => themeService.setThemeMode(themeMode),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color:
                  isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 24,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color:
                          isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
