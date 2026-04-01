import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Drop-in replacement for [MaterialPageRoute] that plays a cinematic
/// diagonal-light-sweep + glow-edge-slide transition.
///
/// Usage:
///   Navigator.push(context, AppRoute(builder: (_) => MyScreen()));
class AppRoute<T> extends PageRouteBuilder<T> {
  AppRoute({required WidgetBuilder builder})
      : super(
          pageBuilder: (ctx, _, __) => builder(ctx),
          transitionDuration: const Duration(milliseconds: 550),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: _buildTransition,
        );

  static Widget _buildTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // ── 1. Incoming page: slide + fade ──────────────────────────────────────
    final slideIn = Tween<Offset>(begin: const Offset(0.10, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

    final fadeIn = CurvedAnimation(
        parent: animation, curve: const Interval(0.0, 0.65, curve: Curves.easeOut));

    // ── 2. Outgoing page: slight scale-down + fade ─────────────────────────
    final fadeOut = Tween<double>(begin: 1.0, end: 0.88).animate(
        CurvedAnimation(parent: secondaryAnimation,
            curve: const Interval(0.0, 0.6, curve: Curves.easeIn)));

    // ── 3. Light-sweep progress: travels from -0.3 → 1.3 ──────────────────
    final sweepProgress = Tween<double>(begin: -0.3, end: 1.3).animate(
        CurvedAnimation(parent: animation,
            curve: const Interval(0.0, 0.75, curve: Curves.easeOut)));

    return Stack(
      fit: StackFit.expand,
      children: [
        // Outgoing page dimming
        FadeTransition(
          opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
              CurvedAnimation(parent: animation,
                  curve: const Interval(0.0, 0.4, curve: Curves.easeIn))),
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.0),
              BlendMode.darken,
            ),
            child: const SizedBox.expand(),
          ),
        ),

        // Incoming page
        SlideTransition(
          position: slideIn,
          child: FadeTransition(opacity: fadeIn, child: child),
        ),

        // ── Glow edge: bright vertical sliver on the leading edge ───────────
        AnimatedBuilder(
          animation: animation,
          builder: (_, __) {
            if (animation.value <= 0.01 || animation.value >= 0.97) {
              return const SizedBox.shrink();
            }
            // Position matches the incoming page's current left edge
            final pageLeft = slideIn.value.dx * MediaQuery.of(context).size.width;

            return Positioned(
              left: pageLeft,
              top: 0,
              width: 28,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFFFFFF).withOpacity(0.0),
                        const Color(0xFFB8AAFF).withOpacity(0.22 * _glowCurve(animation.value)),
                        const Color(0xFF7B2FBE).withOpacity(0.38 * _glowCurve(animation.value)),
                        const Color(0xFFB8AAFF).withOpacity(0.16 * _glowCurve(animation.value)),
                        const Color(0xFFFFFFFF).withOpacity(0.0),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // ── Light sweep: diagonal luminous streak ───────────────────────────
        AnimatedBuilder(
          animation: sweepProgress,
          builder: (_, __) {
            final p = sweepProgress.value;
            if (p < -0.25 || p > 1.25) return const SizedBox.shrink();
            return Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _LightSweepPainter(progress: p),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Bell-curve opacity that peaks mid-animation.
  static double _glowCurve(double t) {
    // 0 at t=0, 1 at t=0.3, 0 at t=1
    return math.max(0.0, 1.0 - ((t - 0.35) / 0.45).abs() * 2.2).clamp(0.0, 1.0);
  }
}

// ─── Light sweep painter ──────────────────────────────────────────────────────

class _LightSweepPainter extends CustomPainter {
  final double progress; // -0.3 to 1.3

  const _LightSweepPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Opacity: max at centre (progress≈0.5), 0 at edges
    final opacity = (1.0 - ((progress - 0.5) * 2.4).abs()).clamp(0.0, 0.9);
    if (opacity < 0.01) return;

    // The sweep travels diagonally: tilt ≈ 15°
    const tiltAngle = math.pi / 12; // 15 degrees
    final beamW  = size.width * 0.18;
    final cx     = progress * (size.width + beamW * 3) - beamW;

    // Four-stop gradient for the streak
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          const Color(0xFFE0D4FF).withOpacity(0.08 * opacity),
          const Color(0xFFFFFFFF).withOpacity(0.20 * opacity),
          const Color(0xFFE0D4FF).withOpacity(0.08 * opacity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        begin: const Alignment(-1, 0),
        end: const Alignment(1, 0),
      ).createShader(Rect.fromLTWH(cx - beamW * 2, 0, beamW * 4, size.height));

    // Draw the tilted rectangle
    canvas.save();
    canvas.translate(cx, size.height / 2);
    canvas.rotate(tiltAngle);
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: beamW * 4, height: size.height * 1.5),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LightSweepPainter old) => old.progress != progress;
}
