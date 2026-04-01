import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _pulseController;
  late AnimationController _fadeOutController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _textOpacity;
  late Animation<double> _pulseAnim;
  late Animation<double> _fadeOut;

  @override
  void initState() {
    super.initState();

    // Logo entrance
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0, 0.4)),
    );

    // Tagline entrance
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    // Pulse glow
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Fade out
    _fadeOutController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeOutController, curve: Curves.easeIn),
    );

    _runAnimation();
  }

  Future<void> _runAnimation() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    _textController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _pulseController.forward();
    await Future.delayed(const Duration(milliseconds: 1400));
    _fadeOutController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) widget.onComplete();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    _fadeOutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeOut,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated logo with pulse glow
              _MergedAnimBuilder(
                listenables: [_logoController, _pulseController],
                builder: (context) {
                  return Transform.scale(
                    scale: _logoScale.value,
                    child: Opacity(
                      opacity: _logoOpacity.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF1A0533), // deep dark purple
                              Color(0xFF7B2FBE), // neon purple
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF7B2FBE)
                                  .withOpacity(0.55 * _pulseAnim.value + 0.15),
                              blurRadius: 40 + 20 * _pulseAnim.value,
                              spreadRadius: 5 * _pulseAnim.value,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'T',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 52,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              // App name
              FadeTransition(
                opacity: _logoOpacity,
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFFD946EF), // fuchsia
                      Color(0xFF7B2FBE), // neon purple
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    'Trade99',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              // Powered-by tagline
              FadeTransition(
                opacity: _textOpacity,
                child: const Text(
                  'powered by GenAIlakes',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Tagline
              SlideTransition(
                position: _textSlide,
                child: FadeTransition(
                  opacity: _textOpacity,
                  child: Text(
                    'Invest • Create • Connect',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 60),
              // Loading dots
              SlideTransition(
                position: _textSlide,
                child: FadeTransition(
                  opacity: _textOpacity,
                  child: const _LoadingDots(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rebuilds when any of the given listenables change.
class _MergedAnimBuilder extends StatefulWidget {
  final List<Listenable> listenables;
  final Widget Function(BuildContext) builder;

  const _MergedAnimBuilder({
    required this.listenables,
    required this.builder,
  });

  @override
  State<_MergedAnimBuilder> createState() => _MergedAnimBuilderState();
}

class _MergedAnimBuilderState extends State<_MergedAnimBuilder> {
  late Listenable _merged;

  @override
  void initState() {
    super.initState();
    _merged = Listenable.merge(widget.listenables);
    _merged.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _merged.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

// Pulsing dot loader
class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final progress = (_controller.value * 3 - i).clamp(0.0, 1.0);
            final scale = 0.5 + 0.5 * (progress < 0.5
                ? progress * 2
                : (1 - progress) * 2);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7B2FBE).withOpacity(scale),
              ),
            );
          },
        );
      }),
    );
  }
}
