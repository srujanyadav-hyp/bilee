import 'package:flutter/material.dart';
import 'dart:math' as math;

/// BILEE Splash Animation
/// Smooth, fluid animation with overlapping transitions
class SplashAnimation extends StatefulWidget {
  const SplashAnimation({super.key});

  @override
  State<SplashAnimation> createState() => _SplashAnimationState();
}

class _SplashAnimationState extends State<SplashAnimation>
    with TickerProviderStateMixin {
  // Master animation controller for synchronized timing
  late AnimationController _masterController;

  // Individual animation curves
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoSlideAnimation;
  late Animation<double> _logoRotateAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<double> _textScaleAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _layoutTransitionAnimation;
  late Animation<double> _logoVerticalMoveAnimation;
  late Animation<double> _textVerticalMoveAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _fadeOutAnimation;

  // State tracking
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _checkReducedMotion();
    _initializeAnimations();
    _startAnimationSequence();
  }

  void _checkReducedMotion() {
    _reducedMotion = false;
  }

  void _initializeAnimations() {
    // Master controller - 10 seconds total
    _masterController = AnimationController(
      duration: const Duration(milliseconds: 10000),
      vsync: this,
    );

    // Timeline breakdown (in percentages of 10s):
    // 0.0 - 0.05 (0-500ms): Initial pause
    // 0.05 - 0.25 (500-2500ms): Logo entrance with scale & rotation
    // 0.15 - 0.40 (1500-4000ms): Text slides in with fade (overlaps with logo)
    // 0.25 - 0.55 (2500-5500ms): Background gradient fades in
    // 0.50 - 0.75 (5000-7500ms): Layout transition to vertical
    // 0.70 - 0.92 (7000-9200ms): Glow/pulse effect
    // 0.92 - 1.0 (9200-10000ms): Fade out

    // Logo animations - smooth entrance
    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.05, 0.25, curve: Curves.elasticOut),
      ),
    );

    _logoRotateAnimation = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.05, 0.25, curve: Curves.easeOutCubic),
      ),
    );

    _logoSlideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.20, 0.40, curve: Curves.easeInOutCubic),
      ),
    );

    // Text animations - slide from right with fade
    _textSlideAnimation =
        Tween<Offset>(begin: const Offset(2.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _masterController,
            curve: const Interval(0.15, 0.40, curve: Curves.easeOutCubic),
          ),
        );

    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.15, 0.35, curve: Curves.easeIn),
      ),
    );

    _textScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.15, 0.40, curve: Curves.easeOutBack),
      ),
    );

    // Background gradient fade - smooth transition
    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.25, 0.55, curve: Curves.easeInOutSine),
      ),
    );

    // Layout transition - vertical arrangement
    _layoutTransitionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.50, 0.75, curve: Curves.easeInOutCubic),
      ),
    );

    _logoVerticalMoveAnimation = Tween<double>(begin: 0.0, end: -40.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.50, 0.75, curve: Curves.easeInOutCubic),
      ),
    );

    _textVerticalMoveAnimation = Tween<double>(begin: 0.0, end: 40.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.50, 0.75, curve: Curves.easeInOutCubic),
      ),
    );

    // Glow/pulse effect
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.70, 0.92, curve: Curves.easeInOut),
      ),
    );

    // Final fade out
    _fadeOutAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.92, 1.0, curve: Curves.easeInCubic),
      ),
    );
  }

  Future<void> _startAnimationSequence() async {
    if (_reducedMotion) {
      await Future.delayed(const Duration(milliseconds: 600));
      _navigateToOnboarding();
      return;
    }

    // Start master animation
    await _masterController.forward();
    _navigateToOnboarding();
  }

  void _navigateToOnboarding() {
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/role_selection');
    }
  }

  @override
  void dispose() {
    _masterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _masterController,
        builder: (context, child) {
          final layoutProgress = _layoutTransitionAnimation.value;
          final isVertical = layoutProgress > 0.3;

          // Background gradient interpolation
          final bgProgress = _backgroundAnimation.value;
          final startColor = Color.lerp(
            Colors.black,
            const Color(0xFF00D4AA),
            bgProgress,
          )!;
          final endColor = Color.lerp(
            Colors.black,
            const Color(0xFF1E5BFF),
            bgProgress,
          )!;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [startColor, endColor],
              ),
            ),
            child: Opacity(
              opacity: _fadeOutAnimation.value,
              child: Center(
                child: isVertical
                    ? _buildVerticalLayout(layoutProgress)
                    : _buildHorizontalLayout(),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Horizontal layout - initial state with smooth animations
  Widget _buildHorizontalLayout() {
    final logoScale = _logoScaleAnimation.value;
    final logoRotate = _logoRotateAnimation.value;
    final logoSlide = _logoSlideAnimation.value;
    final textOpacity = _textOpacityAnimation.value;
    final textScale = _textScaleAnimation.value;

    // Glow pulse effect
    final glowIntensity =
        math.sin(_glowAnimation.value * math.pi * 2) * 0.5 + 0.5;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo with scale, rotation, and glow
        Transform.translate(
          offset: Offset(-15 * logoSlide, 0),
          child: Transform.scale(
            scale: logoScale,
            child: Transform.rotate(
              angle: logoRotate,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFF00D4AA,
                      ).withOpacity(0.6 * glowIntensity),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/logos/logo_symbol_glow-removebg-preview.png',
                  width: 150,
                  height: 150,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 16 + (8 * logoSlide)),
        // Text with slide, opacity, and scale
        SlideTransition(
          position: _textSlideAnimation,
          child: Opacity(
            opacity: textOpacity,
            child: Transform.scale(
              scale: textScale,
              child: _buildBileeText(glowIntensity),
            ),
          ),
        ),
      ],
    );
  }

  /// Vertical layout - fluid transition
  Widget _buildVerticalLayout(double progress) {
    final logoVertical = _logoVerticalMoveAnimation.value;
    final textVertical = _textVerticalMoveAnimation.value;

    // Glow pulse effect
    final glowIntensity =
        math.sin(_glowAnimation.value * math.pi * 2) * 0.5 + 0.5;

    // Smooth rotation during transition
    final logoRotate = progress * 0.1;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo moves up with rotation and circular loading indicator
        Transform.translate(
          offset: Offset(0, logoVertical),
          child: Transform.rotate(
            angle: logoRotate,
            child: Transform.scale(
              scale: 1.0 + (progress * 0.1),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Circular loading indicator
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: CircularProgressIndicator(
                      value: null, // Indeterminate animation
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color.lerp(
                          const Color(0xFF00D4AA),
                          const Color(0xFF1E5BFF),
                          glowIntensity,
                        )!,
                      ),
                    ),
                  ),
                  // Logo with glow
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF00D4AA,
                          ).withOpacity(0.6 * glowIntensity),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/logos/logo_symbol_glow-removebg-preview.png',
                      width: 150,
                      height: 150,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 20 + (8 * progress)),
        // Text moves down
        Transform.translate(
          offset: Offset(0, textVertical),
          child: Transform.scale(
            scale: 1.0 - (progress * 0.05),
            child: _buildBileeText(glowIntensity),
          ),
        ),
      ],
    );
  }

  /// BILEE text with subtle glow
  Widget _buildBileeText(double glowIntensity) {
    return Stack(
      children: [
        // Glow layer
        Text(
          'BILEE',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 52,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = Colors.white.withOpacity(0.3 * glowIntensity)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
            letterSpacing: 2,
          ),
        ),
        // Main text
        const Text(
          'BILEE',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 52,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}
