import 'package:flutter/material.dart';
import 'dart:math' as math;

// ─── Royal gold accent used throughout ──────────────────────────────────────
const _kGold = Color(0xFFBF8517);
const _kGoldLight = Color(0xFFE0A020);
const _kGoldDim = Color(0xFF7A5510);
const _kNearBlack = Color(0xFF0A0A0F);
const _kSurface = Color(0xFF13131A);
const _kBorder = Color(0xFF2A2010);

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        color: _kNearBlack,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildPointsCard()),
            SliverToBoxAdapter(child: _buildStreakSection()),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: Text(
                  'Available Rewards',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _rewardTile('🎟️', 'Free Premium (1 Week)', '2,500 pts',
                      const Color(0xFF6366F1)),
                  const SizedBox(height: 10),
                  _rewardTile('📊', 'Advanced Analytics Unlock', '5,000 pts',
                      _kGold),
                  const SizedBox(height: 10),
                  _rewardTile('🎨', 'Custom Profile Theme', '1,200 pts',
                      const Color(0xFFEC4899)),
                  const SizedBox(height: 10),
                  _rewardTile('⚡', 'Priority Content Boost', '3,000 pts',
                      _kGold),
                  const SizedBox(height: 10),
                  _rewardTile('💎', 'Exclusive Creator Badge', '10,000 pts',
                      _kGold),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(
          children: [
            // Royal minimal crown icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _kGold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kGold.withValues(alpha: 0.25)),
              ),
              child: const Center(
                child: _CrownIcon(size: 24, color: _kGold),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Rewards',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            // Level badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_kGold, _kGoldLight]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _kGold.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CrownIcon(size: 13, color: Colors.white),
                  SizedBox(width: 5),
                  Text(
                    'Level 4',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kBorder),
          boxShadow: [
            BoxShadow(
              color: _kGold.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Points',
                  style: TextStyle(
                    color: Color(0xFFBBAA88),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: _kGold.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    '🔥 12-day streak',
                    style: TextStyle(
                      color: _kGoldLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '8,450',
              style: TextStyle(
                color: _kGold,
                fontSize: 44,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Earn 1,550 more to reach Level 5',
              style: TextStyle(
                color: Color(0xFF8A7A55),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 16),
            // Gold progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: _kGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: 0.845,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_kGold, _kGoldLight],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: _kGold.withValues(alpha: 0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakSection() {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final completed = [true, true, true, true, true, false, false];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Streak',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: completed[i]
                      ? _kGold
                      : _kSurface,
                  border: Border.all(
                    color: completed[i]
                        ? _kGold
                        : _kBorder,
                  ),
                  boxShadow: completed[i]
                      ? [
                          BoxShadow(
                            color: _kGold.withValues(alpha: 0.4),
                            blurRadius: 8,
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: completed[i]
                      ? const Icon(Icons.check,
                          color: Colors.white, size: 18)
                      : Text(
                          days[i],
                          style: const TextStyle(
                            color: Color(0xFF55503A),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _rewardTile(
      String emoji, String title, String cost, Color accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withValues(alpha: 0.2)),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cost,
                  style: TextStyle(
                    color: accent.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withValues(alpha: 0.3)),
            ),
            child: Text(
              'Redeem',
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Royal Minimal Crown ────────────────────────────────────────────────────
class _CrownIcon extends StatelessWidget {
  final double size;
  final Color color;
  const _CrownIcon({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.78),
      painter: _CrownPainter(color: color),
    );
  }
}

class _CrownPainter extends CustomPainter {
  final Color color;
  const _CrownPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Crown silhouette path:
    // base bar + three upward points (left, center-tall, right)
    final path = Path();

    // Base bar (bottom strip)
    final baseH = h * 0.28;
    final baseTop = h * 0.72;
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, baseTop, w, baseH),
      const Radius.circular(2),
    ));

    // Left point
    path.moveTo(0, baseTop);
    path.lineTo(0, h * 0.42);
    path.lineTo(w * 0.22, h * 0.18);
    path.lineTo(w * 0.30, baseTop);
    path.close();

    // Center point (tallest)
    path.moveTo(w * 0.28, baseTop);
    path.lineTo(w * 0.36, h * 0.04); // tip
    path.lineTo(w * 0.64, h * 0.04);
    path.lineTo(w * 0.72, baseTop);
    path.close();

    // Right point
    path.moveTo(w * 0.70, baseTop);
    path.lineTo(w * 0.78, h * 0.18);
    path.lineTo(w, h * 0.42);
    path.lineTo(w, baseTop);
    path.close();

    canvas.drawPath(path, fillPaint);

    // Three jewel dots on the tips
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    final dotR = w * 0.065;
    // Left jewel
    canvas.drawCircle(Offset(w * 0.13, h * 0.38), dotR, dotPaint);
    // Center jewel (top)
    canvas.drawCircle(Offset(w * 0.5, h * 0.06), dotR, dotPaint);
    // Right jewel
    canvas.drawCircle(Offset(w * 0.87, h * 0.38), dotR, dotPaint);
  }

  @override
  bool shouldRepaint(_CrownPainter old) => old.color != color;
}
