import 'package:flutter/material.dart';
import 'dart:math' as math;

class InteractiveLogo extends StatefulWidget {
  final double size;
  final bool isAnimating;
  final VoidCallback? onTap;

  const InteractiveLogo({
    super.key,
    this.size = 120.0,
    this.isAnimating = true,
    this.onTap,
  });

  @override
  State<InteractiveLogo> createState() => _InteractiveLogoState();
}

class _InteractiveLogoState extends State<InteractiveLogo>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _bounceController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    // Rotation animation for the outer ring
    _rotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    // Pulse animation for the center circle
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Bounce animation for interactions
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    if (widget.isAnimating) {
      _rotationController.repeat();
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(InteractiveLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating && !oldWidget.isAnimating) {
      _rotationController.repeat();
      _pulseController.repeat(reverse: true);
    } else if (!widget.isAnimating && oldWidget.isAnimating) {
      _rotationController.stop();
      _pulseController.stop();
    }
  }

  void _handleTap() {
    _bounceController.forward().then((_) {
      _bounceController.reverse();
    });
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _rotationAnimation,
          _pulseAnimation,
          _bounceAnimation,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: _bounceAnimation.value,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer rotating ring with mood dots
                  Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: CustomPaint(
                      size: Size(widget.size, widget.size),
                      painter: MoodRingPainter(
                        primaryColor: colorScheme.primary,
                        secondaryColor: colorScheme.secondary,
                        tertiaryColor: colorScheme.tertiary,
                      ),
                    ),
                  ),

                  // Center pulsing circle with logo
                  Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: widget.size * 0.6,
                      height: widget.size * 0.6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            colorScheme.primaryContainer,
                            colorScheme.primary.withValues(alpha: 0.8),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.sentiment_satisfied_alt,
                              size: widget.size * 0.25,
                              color: colorScheme.onPrimaryContainer,
                            ),
                            Text(
                              'MF',
                              style: TextStyle(
                                fontSize: widget.size * 0.08,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimaryContainer,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Glowing effect when tapped
                  if (_bounceController.isAnimating)
                    Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class MoodRingPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;

  MoodRingPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Draw mood dots around the circle
    const moodEmojis = [
      {'emoji': '😊', 'color': Color(0xFF4CAF50)}, // Happy - Green
      {'emoji': '😐', 'color': Color(0xFFFF9800)}, // Neutral - Orange
      {'emoji': '😢', 'color': Color(0xFF2196F3)}, // Sad - Blue
      {'emoji': '😴', 'color': Color(0xFF9C27B0)}, // Tired - Purple
      {'emoji': '😤', 'color': Color(0xFFF44336)}, // Angry - Red
      {'emoji': '😍', 'color': Color(0xFFE91E63)}, // Love - Pink
    ];

    for (int i = 0; i < moodEmojis.length; i++) {
      final angle = (i * 2 * math.pi) / moodEmojis.length;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      // Draw mood dot
      final paint =
          Paint()
            ..color = moodEmojis[i]['color'] as Color
            ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), 8, paint);

      // Add small glow effect
      final glowPaint =
          Paint()
            ..color = (moodEmojis[i]['color'] as Color).withValues(alpha: 0.3)
            ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), 12, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Static version for app icon generation
class StaticLogo extends StatelessWidget {
  final double size;
  final Color? primaryColor;
  final Color? backgroundColor;

  const StaticLogo({
    super.key,
    this.size = 120.0,
    this.primaryColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = primaryColor ?? colorScheme.primary;
    final background = backgroundColor ?? colorScheme.primaryContainer;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [background, primary.withValues(alpha: 0.8)],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Mood dots around the edge
          CustomPaint(
            size: Size(size, size),
            painter: MoodRingPainter(
              primaryColor: primary,
              secondaryColor: colorScheme.secondary,
              tertiaryColor: colorScheme.tertiary,
            ),
          ),

          // Center content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sentiment_satisfied_alt,
                size: size * 0.3,
                color: colorScheme.onPrimaryContainer,
              ),
              Text(
                'MF',
                style: TextStyle(
                  fontSize: size * 0.1,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
