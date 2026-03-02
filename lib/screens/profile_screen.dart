import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  bool _notifications = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildProfileHeader(context)),
          SliverToBoxAdapter(child: _buildStatsRow(context)),
          SliverToBoxAdapter(child: _buildLinkedAccounts(context)),
          SliverToBoxAdapter(child: _buildSettings(context)),
          SliverToBoxAdapter(child: _buildLogout(context)),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.purple]),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Text('A',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Alex Mitchell',
              style: TextStyle(
                  color: AppTheme.textPrimary(ctx),
                  fontSize: 24,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('@alexmitchell • Creator & Investor',
              style: TextStyle(
                  color: AppTheme.textSecondary(ctx),
                  fontSize: 14,
                  fontWeight: FontWeight.w400)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.primary.withOpacity(0.5)),
              color: AppTheme.primary.withOpacity(0.08),
            ),
            child: const Text('Edit Profile',
                style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppTheme.surface(ctx),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border(ctx)),
        ),
        child: Row(
          children: [
            _statItem(ctx, '32.1K', 'Followers'),
            _divider(ctx),
            _statItem(ctx, '156', 'Posts'),
            _divider(ctx),
            _statItem(ctx, '₹1.2L', 'Portfolio'),
          ],
        ),
      ),
    );
  }

  Widget _statItem(BuildContext ctx, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: AppTheme.textPrimary(ctx),
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: AppTheme.textSecondary(ctx),
                  fontSize: 12,
                  fontWeight: FontWeight.w400)),
        ],
      ),
    );
  }

  Widget _divider(BuildContext ctx) {
    return Container(width: 1, height: 36, color: AppTheme.border(ctx));
  }

  Widget _buildLinkedAccounts(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Linked Accounts',
              style: TextStyle(
                  color: AppTheme.textPrimary(ctx),
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          _accountTile(ctx, 'YouTube', Icons.play_circle_fill_rounded,
              const Color(0xFFFF0000), true,
              url: 'https://studio.youtube.com'),
          _accountTile(ctx, 'Instagram', Icons.camera_alt_rounded,
              const Color(0xFFE1306C), false,
              url: 'https://www.instagram.com/accounts/login/'),
          _accountTile(
              ctx, 'X (Twitter)', Icons.tag_rounded, 
              Theme.of(ctx).brightness == Brightness.dark ? Colors.white : Colors.black, 
              true,
              url: 'https://x.com'),
          _accountTile(ctx, 'LinkedIn', Icons.work_rounded,
              const Color(0xFF0A66C2), false,
              url: 'https://www.linkedin.com/login'),
        ],
      ),
    );
  }

  Widget _accountTile(BuildContext ctx, String name, IconData icon, Color color,
      bool connected,
      {required String url}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _openUrl(url),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.surface(ctx),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border(ctx)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Text(name,
                    style: TextStyle(
                        color: AppTheme.textPrimary(ctx),
                        fontSize: 15,
                        fontWeight: FontWeight.w500)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: connected
                      ? AppTheme.emerald.withOpacity(0.12)
                      : AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  connected ? 'Connected' : 'Connect',
                  style: TextStyle(
                    color: connected ? AppTheme.emerald : AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettings(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings',
              style: TextStyle(
                  color: AppTheme.textPrimary(ctx),
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          // Dark Mode toggle — functional!
          _settingToggle(ctx, 'Dark Mode', Icons.dark_mode_outlined,
              themeNotifier.isDark, (v) {
            themeNotifier.toggle();
          }),
          _settingToggle(ctx, 'Push Notifications', Icons.notifications_outlined,
              _notifications, (v) {
            setState(() => _notifications = v);
          }),
          _settingTile(ctx, 'Privacy', Icons.lock_outline),
          _settingTile(ctx, 'Help & Support', Icons.help_outline),
          _settingTile(ctx, 'About', Icons.info_outline),
        ],
      ),
    );
  }

  Widget _settingToggle(BuildContext ctx, String title, IconData icon,
      bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface(ctx),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border(ctx)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textSecondary(ctx), size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      color: AppTheme.textPrimary(ctx),
                      fontSize: 15,
                      fontWeight: FontWeight.w400)),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppTheme.primary,
              inactiveTrackColor: AppTheme.surface(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingTile(BuildContext ctx, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface(ctx),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border(ctx)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textSecondary(ctx), size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      color: AppTheme.textPrimary(ctx),
                      fontSize: 15,
                      fontWeight: FontWeight.w400)),
            ),
            Icon(Icons.chevron_right,
                color: AppTheme.textSecondary(ctx), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLogout(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: GestureDetector(
        onTap: () {
          AuthGateState.of(ctx)?.logout();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.rose.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.rose.withOpacity(0.15)),
          ),
          child: const Center(
            child: Text('Log Out',
                style: TextStyle(
                    color: AppTheme.rose,
                    fontSize: 16,
                    fontWeight: FontWeight.w500)),
          ),
        ),
      ),
    );
  }
}
