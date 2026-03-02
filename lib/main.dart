import 'dart:ui';
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

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;
  late PageController _pageController;

  // 5 pages: Invest(0), Create(1), Rewards(2), Social(3), Profile(4)
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
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
    return SizedBox(
      height: 90 + MediaQuery.of(ctx).padding.bottom,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: (isDark
                            ? AppTheme.backgroundDark
                            : AppTheme.surfaceLight)
                        .withOpacity(0.92),
                    border: Border(
                      top: BorderSide(color: AppTheme.border(ctx)),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _navItem(
                              ctx, 0, StreamlineIcons.investments, 'Invest'),
                          _navItem(ctx, 1, StreamlineIcons.create, 'Create'),
                          // Spacer for the elevated center button
                          const SizedBox(width: 64),
                          _navItem(ctx, 3, StreamlineIcons.social, 'Social'),
                          _navItem(ctx, 4, StreamlineIcons.profile, 'Profile'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Elevated Rewards button — bleeds out above the navbar
          Positioned(
            top: -10,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => _onTabTapped(2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    gradient: _currentIndex == 2
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
                          )
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.surface(ctx),
                              AppTheme.surface(ctx),
                            ],
                          ),
                    shape: BoxShape.circle,
                    border: _currentIndex == 2
                        ? null
                        : Border.all(color: AppTheme.border(ctx), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: _currentIndex == 2
                            ? const Color(0xFFF59E0B).withOpacity(0.4)
                            : Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emoji_events_rounded,
                        size: 24,
                        color: _currentIndex == 2
                            ? Colors.white
                            : AppTheme.textSecondary(ctx),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'REWARDS',
                        style: TextStyle(
                          color: _currentIndex == 2
                              ? Colors.white
                              : AppTheme.textSecondary(ctx),
                          fontSize: 7,
                          fontWeight: FontWeight.w600,
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
    final inactive = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        width: 64,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color:
              isActive ? AppTheme.primary.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreamlineIcons.icon(
              svgData,
              size: 22,
              color: isActive ? AppTheme.primary : inactive,
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: isActive ? AppTheme.primary : inactive,
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
