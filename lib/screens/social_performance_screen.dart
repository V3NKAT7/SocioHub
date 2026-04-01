import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

// ─── Data models ─────────────────────────────────────────────────────────────

enum _MetricType { views, followers, shares, comments }

class _Milestone {
  final String label;
  final String emoji;
  final _MetricType type;
  final int threshold;
  final bool achieved;

  const _Milestone({
    required this.label,
    required this.emoji,
    required this.type,
    required this.threshold,
    required this.achieved,
  });
}

// ─── Mock social performance data ────────────────────────────────────────────

class _MockPerformance {
  // Cumulative totals (simulated)
  static const int totalViews     = 124800;
  static const int totalFollowers = 32100;
  static const int totalShares    = 8400;
  static const int totalComments  = 5200;

  // Monthly data — 12 months (Jan–Dec), normalised 0–1 for chart
  static const List<double> viewsData     = [0.05, 0.08, 0.12, 0.17, 0.21, 0.29, 0.38, 0.45, 0.54, 0.67, 0.80, 1.00];
  static const List<double> followersData = [0.06, 0.09, 0.13, 0.18, 0.24, 0.30, 0.37, 0.46, 0.58, 0.71, 0.85, 1.00];
  static const List<double> sharesData    = [0.04, 0.06, 0.11, 0.15, 0.19, 0.26, 0.34, 0.43, 0.55, 0.68, 0.82, 1.00];
  static const List<double> commentsData  = [0.07, 0.10, 0.14, 0.19, 0.23, 0.31, 0.40, 0.47, 0.57, 0.70, 0.84, 1.00];

  static const List<String> months =
      ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  static List<_Milestone> get milestones => [
    // Views
    _Milestone(label: '100 Views',   emoji: '👁️',  type: _MetricType.views,     threshold: 100,    achieved: true),
    _Milestone(label: '500 Views',   emoji: '👁️',  type: _MetricType.views,     threshold: 500,    achieved: true),
    _Milestone(label: '1K Views',    emoji: '👁️',  type: _MetricType.views,     threshold: 1000,   achieved: true),
    _Milestone(label: '10K Views',   emoji: '🔥',  type: _MetricType.views,     threshold: 10000,  achieved: true),
    _Milestone(label: '50K Views',   emoji: '🚀',  type: _MetricType.views,     threshold: 50000,  achieved: true),
    _Milestone(label: '100K Views',  emoji: '💎',  type: _MetricType.views,     threshold: 100000, achieved: true),
    _Milestone(label: '500K Views',  emoji: '🏆',  type: _MetricType.views,     threshold: 500000, achieved: false),
    // Followers
    _Milestone(label: '100 Followers',  emoji: '👥',  type: _MetricType.followers, threshold: 100,   achieved: true),
    _Milestone(label: '500 Followers',  emoji: '👥',  type: _MetricType.followers, threshold: 500,   achieved: true),
    _Milestone(label: '1K Followers',   emoji: '⭐',  type: _MetricType.followers, threshold: 1000,  achieved: true),
    _Milestone(label: '10K Followers',  emoji: '🌟',  type: _MetricType.followers, threshold: 10000, achieved: true),
    _Milestone(label: '50K Followers',  emoji: '👑',  type: _MetricType.followers, threshold: 50000, achieved: false),
    // Shares
    _Milestone(label: '50 Shares',   emoji: '📣',  type: _MetricType.shares,    threshold: 50,    achieved: true),
    _Milestone(label: '100 Shares',  emoji: '📣',  type: _MetricType.shares,    threshold: 100,   achieved: true),
    _Milestone(label: '500 Shares',  emoji: '📢',  type: _MetricType.shares,    threshold: 500,   achieved: true),
    _Milestone(label: '1K Shares',   emoji: '🔊',  type: _MetricType.shares,    threshold: 1000,  achieved: true),
    _Milestone(label: '5K Shares',   emoji: '📡',  type: _MetricType.shares,    threshold: 5000,  achieved: false),
    // Comments
    _Milestone(label: '50 Comments',  emoji: '💬',  type: _MetricType.comments,  threshold: 50,   achieved: true),
    _Milestone(label: '100 Comments', emoji: '💬',  type: _MetricType.comments,  threshold: 100,  achieved: true),
    _Milestone(label: '500 Comments', emoji: '🗨️',  type: _MetricType.comments,  threshold: 500,  achieved: true),
    _Milestone(label: '1K Comments',  emoji: '💭',  type: _MetricType.comments,  threshold: 1000,  achieved: true),
    _Milestone(label: '5K Comments',  emoji: '🌊',  type: _MetricType.comments,  threshold: 5000,  achieved: false),
  ];
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class SocialPerformanceScreen extends StatefulWidget {
  const SocialPerformanceScreen({super.key});

  @override
  State<SocialPerformanceScreen> createState() => _SocialPerformanceScreenState();
}

class _SocialPerformanceScreenState extends State<SocialPerformanceScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  Set<_MetricType> _selectedMetrics = {
    _MetricType.views,
    _MetricType.followers,
    _MetricType.shares,
    _MetricType.comments,
  };

  static const _kBg     = Color(0xFF0A0A0F);
  static const _kCard   = Color(0xFF13131A);
  static const _kBorder = Color(0xFF1E1E2E);
  static const _kGreen  = Color(0xFFADD984);

  // Metric colours
  static const _kViews     = Color(0xFF7C5CFC);
  static const _kFollowers = Color(0xFFADD984);
  static const _kShares    = Color(0xFFE84393);
  static const _kComments  = Color(0xFFF5A623);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Performance Overview',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            _buildStatsBanner(),
            const SizedBox(height: 20),
            _buildMilestonesSection(),
            const SizedBox(height: 20),
            _buildTrendChart(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // ── Top stats banner ──────────────────────────────────────────────────────
  Widget _buildStatsBanner() {
    final stats = [
      ('Total Views',      '124.8K', _kViews,     Icons.visibility_rounded),
      ('Followers',        '32.1K',  _kFollowers, Icons.people_rounded),
      ('Shares',           '8.4K',   _kShares,    Icons.share_rounded),
      ('Comments',         '5.2K',   _kComments,  Icons.chat_bubble_rounded),
    ];

    return GridView.count(
      crossAxisCount:  2,
      shrinkWrap:      true,
      physics:         const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing:  12,
      childAspectRatio: 2.5,
      children: stats.map((s) => Container(
        decoration: BoxDecoration(
          color:        _kCard,
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(color: _kBorder),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color:        s.$3.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(s.$4, color: s.$3, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(s.$2,
                    style: TextStyle(
                        color: s.$3, fontSize: 16,
                        fontWeight: FontWeight.w800)),
                Text(s.$1,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 10)),
              ],
            ),
          ],
        ),
      )).toList(),
    );
  }

  // ── Milestone groups (compact) ─────────────────────────────────────────────
  Widget _buildMilestonesSection() {
    final all = _MockPerformance.milestones;
    final achieved = all.where((m) => m.achieved).length;

    final groups = [
      (_MetricType.views,     'Views',     _kViews,     Icons.visibility_rounded),
      (_MetricType.followers, 'Followers', _kFollowers, Icons.people_rounded),
      (_MetricType.shares,    'Shares',    _kShares,    Icons.share_rounded),
      (_MetricType.comments,  'Comments',  _kComments,  Icons.chat_bubble_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        _kCard,
        borderRadius: BorderRadius.circular(24),
        border:       Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('Milestones',
                style: TextStyle(
                    color: Colors.white, fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color:        _kGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$achieved / ${all.length}',
                  style: const TextStyle(
                      color: _kGreen, fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 4),
          const Text('Latest achievement + next target per category',
              style: TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 14),
          ...groups.map((g) => _milestoneGroup(g.$1, g.$2, g.$3, g.$4)),
        ],
      ),
    );
  }

  Widget _milestoneGroup(
    _MetricType type, String label, Color color, IconData icon) {
    final group    = _MockPerformance.milestones
        .where((m) => m.type == type).toList();
    final achList  = group.where((m) => m.achieved).toList();
    final lockList = group.where((m) => !m.achieved).toList();
    final last     = achList.isNotEmpty ? achList.last : null;
    final next     = lockList.isNotEmpty ? lockList.first : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color:        color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          // Category icon + count
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(height: 3),
              Text(label,
                  style: TextStyle(
                      color: color, fontSize: 9,
                      fontWeight: FontWeight.w700)),
              Text('${achList.length}/${group.length}',
                  style: TextStyle(
                      color: color.withValues(alpha: 0.6), fontSize: 8)),
            ],
          ),
          const SizedBox(width: 14),
          // Last achieved badge
          if (last != null) _compactBadge(last, color, true),
          // Arrow
          if (last != null && next != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.arrow_forward_rounded,
                  color: Colors.white.withValues(alpha: 0.2), size: 14),
            ),
          // Next locked badge
          if (next != null) _compactBadge(next, color, false),
          const Spacer(),
        ]),
      ),
    );
  }

  Widget _compactBadge(_Milestone m, Color color, bool achieved) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: achieved
            ? color.withValues(alpha: 0.14)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: achieved
              ? color.withValues(alpha: 0.38)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(m.emoji,
            style: TextStyle(
                fontSize: 14,
                color: achieved ? null : Colors.grey)),
        const SizedBox(width: 5),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(m.label,
              style: TextStyle(
                  color: achieved ? color : Colors.white30,
                  fontSize: 9,
                  fontWeight: achieved
                      ? FontWeight.w700
                      : FontWeight.w500)),
          if (!achieved)
            Row(mainAxisSize: MainAxisSize.min, children: const [
              Icon(Icons.lock_rounded, color: Colors.white30, size: 9),
              SizedBox(width: 2),
              Text('Next',
                  style: TextStyle(
                      color: Colors.white24, fontSize: 8)),
            ]),
        ]),
      ]),
    );
  }


  // ── Trend line chart ──────────────────────────────────────────────────────
  Widget _buildTrendChart() {
    // Scale the 0–1 normalised values to actual numbers
    double scale(double norm, int total) => norm * total;

    final allLines = [
      (_MockPerformance.viewsData,     _MockPerformance.totalViews,     _kViews,     'Views',     _MetricType.views),
      (_MockPerformance.followersData, _MockPerformance.totalFollowers, _kFollowers, 'Followers', _MetricType.followers),
      (_MockPerformance.sharesData,    _MockPerformance.totalShares,    _kShares,    'Shares',    _MetricType.shares),
      (_MockPerformance.commentsData,  _MockPerformance.totalComments,  _kComments,  'Comments',  _MetricType.comments),
    ];
    final visibleLines = allLines.where((l) => _selectedMetrics.contains(l.$5)).toList();

    final maxY = visibleLines.isNotEmpty
        ? visibleLines
            .expand((l) => [l.$1.last * l.$2])
            .reduce((a, b) => a > b ? a : b) * 1.15
        : 1.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        _kCard,
        borderRadius: BorderRadius.circular(24),
        border:       Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Growth Trends',
              style: TextStyle(
                  color: Colors.white, fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          const Text('Account metrics — Jan to Dec',
              style: TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 12),
          // ── Metric chips ──
          Wrap(
            spacing: 6, runSpacing: 6,
            children: allLines.map((l) {
              final active = _selectedMetrics.contains(l.$5);
              return GestureDetector(
                onTap: () => setState(() {
                  if (active) {
                    if (_selectedMetrics.length > 1) {
                      _selectedMetrics.remove(l.$5);
                    }
                  } else {
                    _selectedMetrics.add(l.$5);
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: active
                        ? l.$3.withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active
                          ? l.$3.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 8, height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active ? l.$3 : Colors.white24)),
                    const SizedBox(width: 5),
                    Text(l.$4,
                        style: TextStyle(
                            color: active ? l.$3 : Colors.white30,
                            fontSize: 11,
                            fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
                  ]),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minX: 0, maxX: 11, minY: 0, maxY: maxY,
                gridData: FlGridData(
                  show:             true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Color(0xFF1E1E2E), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 46,
                      getTitlesWidget: (v, _) {
                        if (v >= 1000) return Text('${(v / 1000).toStringAsFixed(0)}K',
                            style: const TextStyle(color: Colors.white30, fontSize: 9));
                        return Text(v.toStringAsFixed(0),
                            style: const TextStyle(color: Colors.white30, fontSize: 9));
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= 12 || i % 3 != 0) {
                          return const SizedBox();
                        }
                        return Text(_MockPerformance.months[i],
                            style: const TextStyle(color: Colors.white30, fontSize: 9));
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF1E1E2E),
                    getTooltipItems: (spots) => spots.map((s) {
                      if (s.barIndex >= visibleLines.length) {
                        return const LineTooltipItem('', TextStyle());
                      }
                      final (_, _, color, label, __) = visibleLines[s.barIndex];
                      final v = s.y >= 1000
                          ? '${(s.y / 1000).toStringAsFixed(1)}K'
                          : s.y.toStringAsFixed(0);
                      return LineTooltipItem(
                        '$label\n$v',
                        TextStyle(color: color, fontSize: 10,
                            fontWeight: FontWeight.w600),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: visibleLines.map((l) {
                  final (data, total, color, _, __) = l;
                  return LineChartBarData(
                    spots: List.generate(
                        data.length,
                        (i) => FlSpot(i.toDouble(), scale(data[i], total))),
                    isCurved:        true,
                    curveSmoothness: 0.3,
                    color:     color,
                    barWidth:  2,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, pct, data, idx) =>
                          FlDotCirclePainter(
                            radius:      idx == 11 ? 4 : 2,
                            color:       color,
                            strokeColor: Colors.transparent,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withValues(alpha: 0.05),
                    ),
                  );
                }).toList(),
              ),
              duration: const Duration(milliseconds: 500),
            ),
          ),
          const SizedBox(height: 14),
          // Legend
          Wrap(
            spacing:    16,
            runSpacing: 8,
            children: visibleLines.map((l) {
              final (_, _, color, label, __) = l;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 20, height: 3,
                    decoration: BoxDecoration(
                      color:        color,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4)],
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(label,
                      style: TextStyle(
                          color:      color.withValues(alpha: 0.9),
                          fontSize:   10,
                          fontWeight: FontWeight.w500)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
