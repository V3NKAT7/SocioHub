import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/investments_screen.dart';
import 'screens/content_screen.dart';
import 'screens/rewards_screen.dart';
import 'screens/social_feed_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/streamline_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.backgroundDark,
    ),
  );
  runApp(const SocioHubApp());
}

class SocioHubApp extends StatefulWidget {
  const SocioHubApp({super.key});

  @override
  State<SocioHubApp> createState() => _SocioHubAppState();
}

class _SocioHubAppState extends State<SocioHubApp> {
  @override
  void initState() {
    super.initState();
    themeNotifier.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SocioHub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeNotifier.mode,
      home: const AuthGate(),
    );
  }
}

/// Controls the app flow: Splash → Login → Home
/// Logout sends the user back to Login.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => AuthGateState();
}

class AuthGateState extends State<AuthGate> {
  // 0 = splash, 1 = login, 2 = home
  int _authState = 0;

  static AuthGateState? of(BuildContext context) {
    return context.findAncestorStateOfType<AuthGateState>();
  }

  void logout() {
    setState(() => _authState = 1);
  }

  @override
  Widget build(BuildContext context) {
    switch (_authState) {
      case 0:
        return SplashScreen(
          onComplete: () => setState(() => _authState = 1),
        );
      case 1:
        return LoginScreen(
          onLoginSuccess: () => setState(() => _authState = 2),
        );
      default:
        return const HomeShell();
    }
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _swirlController;

  // 5 pages: Invest(0), Create(1), Rewards(2), Social(3), Profile(4)
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _swirlController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(); // aurora always animates
  }

  @override
  void dispose() {
    _pageController.dispose();
    _swirlController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (i) => setState(() => _currentIndex = i),
        children: const [
          InvestmentsScreen(),
          ContentScreen(),
          RewardsScreen(),
          SocialFeedScreen(),
          ProfileScreen(),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext ctx) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final navBg = (isDark ? AppTheme.backgroundDark : AppTheme.surfaceLight)
        .withValues(alpha: 0.92);
    final navH = 90 + MediaQuery.of(ctx).padding.bottom;

    return SizedBox(
      height: navH.toDouble(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Background bar + aurora clipped inside it ─────────────────────
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: navBg,
                    border: Border(top: BorderSide(color: AppTheme.border(ctx))),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Aurora INSIDE ClipRRect — strictly bounded to the bar
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedBuilder(
                            animation: _swirlController,
                            builder: (_, __) => CustomPaint(
                              painter: _AuroraPainter(_swirlController.value),
                            ),
                          ),
                        ),
                      ),
                      // Nav items on top
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _navItem(ctx, 0, StreamlineIcons.investments, 'Invest'),
                              _navItem(ctx, 1, StreamlineIcons.create, 'Create'),
                              const SizedBox(width: 64),
                              _navItem(ctx, 3, StreamlineIcons.social, 'Social'),
                              _navItem(ctx, 4, StreamlineIcons.profile, 'Profile'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Elevated crown button ─── slightly raised ──────────
          Positioned(
            top: -4, left: 0, right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => _onTabTapped(2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: _currentIndex == 2
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFBF8517), Color(0xFFE0A020)],
                          )
                        : const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF9C5F1A),
                              Color(0xFFCD7F32),
                              Color(0xFF7A4010),
                            ],
                          ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _currentIndex == 2
                            ? const Color(0xFFBF8517).withValues(alpha: 0.55)
                            : const Color(0xFFCD7F32).withValues(alpha: 0.40),
                        blurRadius: 14,
                        // no downward offset — bottom edge invisible
                        offset: Offset.zero,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.crown,
                        size: 20,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'REWARDS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(BuildContext ctx, int index, String svgData, String label) {
    final isActive = _currentIndex == index;
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    // Plain neutral colour for all icons — no active colour tinting
    const iconColor = Color(0xFFCBD5E1);  // soft white-grey
    final labelColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8);

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        width: 64,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreamlineIcons.icon(
              svgData,
              size: 22,
              color: iconColor,
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: labelColor,
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Royal Crown Painter (black body, 3 gem jewels) ─────────────────────────
class _NavCrownPainter extends CustomPainter {
  final bool isActive;
  const _NavCrownPainter({required this.isActive});

  void _drawJewel(Canvas c, Offset pos, Color color, double r) {
    // glow
    c.drawCircle(pos, r * 1.6,
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    // body
    c.drawCircle(pos, r, Paint()..color = color);
    // specular highlight
    c.drawCircle(
        pos + Offset(-r * 0.3, -r * 0.3), r * 0.38,
        Paint()..color = Colors.white.withValues(alpha: 0.75));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final body = Paint()..color = Colors.black..style = PaintingStyle.fill;

    // base strip
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0, h * 0.68, w, h * 0.32), const Radius.circular(2)),
      body);

    // left spike
    canvas.drawPath(
        Path()
          ..moveTo(0, h * 0.68)
          ..lineTo(0, h * 0.38)
          ..lineTo(w * 0.20, h * 0.14)
          ..lineTo(w * 0.28, h * 0.68)
          ..close(),
        body);

    // centre spike (tallest)
    canvas.drawPath(
        Path()
          ..moveTo(w * 0.26, h * 0.68)
          ..lineTo(w * 0.36, 0)
          ..lineTo(w * 0.64, 0)
          ..lineTo(w * 0.74, h * 0.68)
          ..close(),
        body);

    // right spike
    canvas.drawPath(
        Path()
          ..moveTo(w * 0.72, h * 0.68)
          ..lineTo(w * 0.80, h * 0.14)
          ..lineTo(w, h * 0.38)
          ..lineTo(w, h * 0.68)
          ..close(),
        body);

    final r = w * 0.068;
    // left jewel — ruby
    _drawJewel(canvas, Offset(w * 0.10, h * 0.30), const Color(0xFFE8201A), r);
    // centre jewel — diamond white
    _drawJewel(canvas, Offset(w * 0.50, h * 0.02), Colors.white, r);
    // right jewel — sapphire
    _drawJewel(canvas, Offset(w * 0.90, h * 0.30), const Color(0xFF1A6AE8), r);
  }

  @override
  bool shouldRepaint(_NavCrownPainter old) => old.isActive != isActive;
}

// ─── Aurora Background Painter (pink · purple · blue) ─────────────────────
class _AuroraPainter extends CustomPainter {
  final double t;
  const _AuroraPainter(this.t);

  void _wash(Canvas canvas, Size size, Color color, Alignment center,
      double radius, double alpha) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: center,
          radius: radius,
          colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final p = t * 2 * math.pi;

    // Pink wash — drifts left/right slowly
    _wash(canvas, size, const Color(0xFFFF2D78),
        Alignment(math.sin(p) * 0.7 - 0.15, -0.2), 1.3, 0.38);

    // Purple wash — slow circular drift at centre
    _wash(canvas, size, const Color(0xFF7C5CFC),
        Alignment(math.cos(p * 0.6) * 0.45, math.sin(p * 0.4) * 0.4), 1.1, 0.32);

    // Blue wash — drifts opposite to pink
    _wash(canvas, size, const Color(0xFF60A5FA),
        Alignment(math.cos(p * 0.8) * 0.55 + 0.2, 0.3), 1.2, 0.28);
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.t != t;
}
