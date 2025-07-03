import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import 'color_theme_picker.dart';

class ColorThemeButton extends StatefulWidget {
  final bool isFloating;
  final String? tooltipMessage;

  const ColorThemeButton({
    Key? key,
    this.isFloating = false,
    this.tooltipMessage,
  }) : super(key: key);

  @override
  State<ColorThemeButton> createState() => _ColorThemeButtonState();
}

class _ColorThemeButtonState extends State<ColorThemeButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Add a subtle pulse animation that repeats
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _showColorThemeModal() {
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => createColorThemeModal(
            onThemeChanged: () {
              // Add a subtle vibration when theme changes
              HapticFeedback.mediumImpact();
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        if (widget.isFloating) {
          return AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: FloatingActionButton(
                  heroTag: "color_theme",
                  onPressed: _showColorThemeModal,
                  tooltip: widget.tooltipMessage ?? 'Change color theme',
                  backgroundColor: themeService.seedColor,
                  foregroundColor: Colors.white,
                  elevation: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Icon(Icons.palette_rounded, size: 28),
                  ),
                ),
              );
            },
          );
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _showColorThemeModal,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: themeService.seedColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: themeService.seedColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.palette_rounded,
                color: themeService.seedColor,
                size: 20,
              ),
            ),
          ),
        );
      },
    );
  }
}
