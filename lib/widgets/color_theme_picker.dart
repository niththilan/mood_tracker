import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

class ColorThemePicker extends StatefulWidget {
  final VoidCallback? onThemeChanged;

  const ColorThemePicker({Key? key, this.onThemeChanged}) : super(key: key);

  @override
  State<ColorThemePicker> createState() => _ColorThemePickerState();
}

class _ColorThemePickerState extends State<ColorThemePicker>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showColorThemeModal(BuildContext context) {
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _ColorThemeModal(onThemeChanged: widget.onThemeChanged),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showColorThemeModal(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.shadow.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: themeService.seedColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: themeService.seedColor.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            themeService.colorThemeName,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ColorThemeModal extends StatefulWidget {
  final VoidCallback? onThemeChanged;

  const _ColorThemeModal({Key? key, this.onThemeChanged}) : super(key: key);

  @override
  State<_ColorThemeModal> createState() => _ColorThemeModalState();
}

class _ColorThemeModalState extends State<_ColorThemeModal>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late List<AnimationController> _itemControllers;
  late List<Animation<double>> _itemAnimations;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutQuart),
    );

    // Create controllers for each theme item
    _itemControllers = List.generate(
      ThemeService.availableColorThemes.length,
      (index) => AnimationController(
        duration: Duration(milliseconds: 200 + (index * 50)),
        vsync: this,
      ),
    );

    _itemAnimations =
        _itemControllers
            .map(
              (controller) => Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
              ),
            )
            .toList();

    _slideController.forward();

    // Animate items with staggered effect
    for (int i = 0; i < _itemControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 100 + (i * 80)), () {
        if (mounted) {
          _itemControllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    for (final controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _selectTheme(ColorTheme theme) async {
    HapticFeedback.selectionClick();

    final themeService = Provider.of<ThemeService>(context, listen: false);
    await themeService.setColorTheme(theme);

    widget.onThemeChanged?.call();

    // Close modal with animation
    await _slideController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding =
        mediaQuery.viewInsets.bottom + mediaQuery.padding.bottom;
    final screenHeight = mediaQuery.size.height;
    final availableHeight =
        screenHeight - 120; // Leave space for top margin and safe area

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: availableHeight,
        margin: const EdgeInsets.only(top: 80),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Theme.of(
                context,
              ).colorScheme.shadow.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose Your Color Theme',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pick a color that reflects your mood and personality',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),

            // Color theme grid with proper scrolling
            Expanded(
              child: Consumer<ThemeService>(
                builder: (context, themeService, child) {
                  // Make grid responsive based on screen size
                  final screenWidth = MediaQuery.of(context).size.width;
                  final crossAxisCount =
                      screenWidth > 600
                          ? 4
                          : 3; // Use 3 columns on smaller screens
                  final childAspectRatio = screenWidth > 600 ? 0.85 : 0.9;

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPadding + 24),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: childAspectRatio,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: ThemeService.availableColorThemes.length,
                      itemBuilder: (context, index) {
                        final themeData =
                            ThemeService.availableColorThemes[index];
                        final isSelected =
                            themeService.colorTheme == themeData['theme'];

                        return AnimatedBuilder(
                          animation: _itemAnimations[index],
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _itemAnimations[index].value,
                              child: _ColorThemeItem(
                                name: themeData['name'],
                                color: themeData['color'],
                                icon: themeData['icon'],
                                isSelected: isSelected,
                                onTap: () => _selectTheme(themeData['theme']),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorThemeItem extends StatefulWidget {
  final String name;
  final Color color;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorThemeItem({
    Key? key,
    required this.name,
    required this.color,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_ColorThemeItem> createState() => _ColorThemeItemState();
}

class _ColorThemeItemState extends State<_ColorThemeItem>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      widget.isSelected
                          ? widget.color
                          : widget.color.withValues(alpha: 0.3),
                  width: widget.isSelected ? 3 : 1,
                ),
                boxShadow:
                    widget.isSelected
                        ? [
                          BoxShadow(
                            color: widget.color.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                        : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: Text(
                      widget.name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight:
                            widget.isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                        color:
                            widget.isSelected
                                ? widget.color
                                : Theme.of(context).colorScheme.onSurface,
                        fontSize:
                            MediaQuery.of(context).size.width > 600 ? 12 : 10,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.isSelected) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: widget.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Creates a color theme modal widget that can be used directly in showModalBottomSheet
Widget createColorThemeModal({VoidCallback? onThemeChanged}) {
  return _ColorThemeModal(onThemeChanged: onThemeChanged);
}
