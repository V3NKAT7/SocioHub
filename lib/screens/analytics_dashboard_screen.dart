import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../data/mock_data.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  final RandomPortfolio portfolio;

  const AnalyticsDashboardScreen({super.key, required this.portfolio});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  int?          _goalTapIndex;
  List<LifeGoal> _extraGoals      = [];
  Set<int>       _selectedSectors  = {};
  bool           _showGrowth      = false;
  bool           _showSectors     = false;

  static const _kBg      = Color(0xFF0A0A0F);
  static const _kCard    = Color(0xFF13131A);
  static const _kBorder  = Color(0xFF1E1E2E);
  static const _kPurple  = Color(0xFF7C5CFC);
  static const _kBlue    = Color(0xFF3D8BFF);
  static const _kGold    = Color(0xFFBF8517);
  static const _kEmerald = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    // Default: top 3 sectors by absolute return
    final sorted = widget.portfolio.sectorReturns.asMap().entries.toList()
      ..sort((a, b) => b.value.returnPercent.abs()
          .compareTo(a.value.returnPercent.abs()));
    _selectedSectors = {sorted[0].key, sorted[1].key, sorted[2].key};
  }

  RandomPortfolio get p => widget.portfolio;

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
          'Analytics Dashboard',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          _chartCard(
            title:    'Asset Allocation',
            subtitle: 'How your returns fund essential life goals',
            child:    Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildChartB(),
                const SizedBox(height: 12),
                // ── Expand toggles ──
                Row(children: [
                  _expandToggle(
                    'Investment Growth',
                    Icons.trending_up_rounded,
                    _showGrowth, _kBlue,
                    () => setState(() => _showGrowth = !_showGrowth),
                  ),
                  const SizedBox(width: 8),
                  _expandToggle(
                    'Sector Performance',
                    Icons.bar_chart_rounded,
                    _showSectors, _kPurple,
                    () => setState(() => _showSectors = !_showSectors),
                  ),
                ]),
                // ── Expandable: Investment Growth ──
                AnimatedSize(
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeInOut,
                  child: _showGrowth
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            Container(height: 1, color: _kBorder),
                            const SizedBox(height: 16),
                            const Text('Investment Growth',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 3),
                            const Text('Invested vs Portfolio Value — 12 months',
                                style: TextStyle(
                                    color: Colors.white38, fontSize: 10)),
                            const SizedBox(height: 12),
                            _buildChartA(),
                          ])
                      : const SizedBox.shrink(),
                ),
                // ── Expandable: Sector Performance ──
                AnimatedSize(
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeInOut,
                  child: _showSectors
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            Container(height: 1, color: _kBorder),
                            const SizedBox(height: 16),
                            const Text('Sector Performance',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 3),
                            const Text('Return % by sector · select up to 3',
                                style: TextStyle(
                                    color: Colors.white38, fontSize: 10)),
                            const SizedBox(height: 12),
                            _buildChartE(),
                          ])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _chartCard(
            title:    'Life Goals Progress',
            subtitle: 'Tap a goal to see details',
            action:   IconButton(
              onPressed: _showAddGoalDialog,
              icon: const Icon(Icons.add_circle_outline_rounded,
                  color: _kPurple, size: 22),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            child:    _buildChartC(),
          ),
          const SizedBox(height: 16),
          _chartCard(
            title:    'Monthly Financial Footprint',
            subtitle: 'Expenses vs passive income · gold = financially free',
            child:    _buildChartD(),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ── Expand toggle button ──────────────────────────────────────────────────
  Widget _expandToggle(
    String label,
    IconData icon,
    bool active,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? color.withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active
                  ? color.withValues(alpha: 0.4)
                  : _kBorder,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13,
                  color: active ? color : Colors.white38),
              const SizedBox(width: 5),
              Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: active ? color : Colors.white38,
                        fontSize: 11,
                        fontWeight: active
                            ? FontWeight.w600
                            : FontWeight.w400)),
              ),
              const SizedBox(width: 4),
              Icon(
                active
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 13,
                color: active ? color : Colors.white30,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Shared card wrapper ────────────────────────────────────────────────────
  Widget _chartCard({
    required String title,
    required String subtitle,
    required Widget child,
    Widget?        action,
  }) {
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  // ── Chart A: Dual-area line — Invested vs Portfolio Value ─────────────────
  Widget _buildChartA() {
    final mg  = p.monthlyGrowth;
    final maxY = mg.map((e) => e.value).reduce(math.max) * 1.1;

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 11,
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show:              true,
            drawVerticalLine:  false,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: Color(0xFF1E1E2E), strokeWidth: 1),
          ),
          borderData:  FlBorderData(show: false),
          titlesData:  FlTitlesData(
            leftTitles:   AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                getTitlesWidget: (v, _) => Text(
                  formatInr(v),
                  style: const TextStyle(color: Colors.white30, fontSize: 9),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= mg.length) return const SizedBox();
                  if (idx % 3 != 0) return const SizedBox();
                  return Text(mg[idx].month,
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
                final color = s.barIndex == 0 ? _kBlue : _kPurple;
                final label = s.barIndex == 0 ? 'Invested' : 'Value';
                return LineTooltipItem(
                  '$label\n${formatInr(s.y)}',
                  TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            // Invested (blue)
            LineChartBarData(
              spots: List.generate(
                  mg.length, (i) => FlSpot(i.toDouble(), mg[i].invested)),
              isCurved: true,
              color: _kBlue,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    _kBlue.withValues(alpha: 0.3),
                    _kBlue.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Portfolio value (purple)
            LineChartBarData(
              spots: List.generate(
                  mg.length, (i) => FlSpot(i.toDouble(), mg[i].value)),
              isCurved: true,
              color: _kPurple,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    _kPurple.withValues(alpha: 0.22),
                    _kPurple.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 400),
      ),
    );
  }

  // ── Chart B: Sausage-link donut — Earnings allocations ────────────────────
  Widget _buildChartB() {
    final goals = p.lifeGoals;
    final totalAlloc = goals.fold(0.0, (a, g) => a + g.monthlyAlloc);

    return Column(
      children: [
        // ── Donut chart ──
        SizedBox(
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // CustomPaint sausage-link donut
              CustomPaint(
                size: const Size(220, 220),
                painter: _SausagePainter(
                  goals:      goals,
                  totalAlloc: totalAlloc,
                ),
              ),
              // Centre label
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Monthly',
                      style: TextStyle(color: Colors.white38, fontSize: 10)),
                  const SizedBox(height: 2),
                  Text(
                    formatInr(totalAlloc),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 17,
                        fontWeight: FontWeight.w800, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 2),
                  const Text('allocated',
                      style: TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // ── Legend ──
        Wrap(
          spacing:    10,
          runSpacing: 8,
          children: goals.map((g) => SizedBox(
            width: (MediaQuery.of(context).size.width - 72) / 2,
            child: Row(
              children: [
                Container(
                  width: 9, height: 9,
                  decoration: BoxDecoration(
                    color:  g.color, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: g.color.withValues(alpha: 0.5), blurRadius: 4)],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${g.emoji} ${g.name}',
                          style: const TextStyle(color: Colors.white60, fontSize: 10),
                          overflow: TextOverflow.ellipsis),
                      Text(formatInr(g.monthlyAlloc) + '/mo',
                          style: TextStyle(
                              color: g.color, fontSize: 9,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
      ],
    );
  }

  // ── Chart C: 3×3 radial arc grid ──────────────────────────────────────────
  Widget _buildChartC() {
    final goals = [...p.lifeGoals, ..._extraGoals];
    return GridView.builder(
      shrinkWrap:  true,
      physics:     const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:   3,
        mainAxisSpacing:  12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount:   goals.length,
      itemBuilder: (ctx, i) => GestureDetector(
        onTap: () {
          setState(() => _goalTapIndex = _goalTapIndex == i ? null : i);
          _showGoalDetail(ctx, goals[i]);
        },
        child: _goalArc(goals[i]),
      ),
    );
  }

  Widget _goalArc(LifeGoal goal) {
    return Container(
      decoration: BoxDecoration(
        color:        const Color(0xFF0F0F18),
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: _kBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width:  64,
            height: 64,
            child:  CustomPaint(
              painter: _ArcPainter(progress: goal.progress, color: goal.color),
              child: Center(
                child: Text(goal.emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(goal.progress * 100).toInt()}%',
            style: TextStyle(
                color:       goal.color,
                fontSize:    12,
                fontWeight:  FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              goal.name,
              textAlign: TextAlign.center,
              style:     const TextStyle(color: Colors.white54, fontSize: 9),
              maxLines:  2,
              overflow:  TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showGoalDetail(BuildContext ctx, LifeGoal goal) {
    final remaining = goal.targetAmount - goal.fundedAmount;
    final monthsLeft = goal.monthlyAlloc > 0
        ? (remaining / goal.monthlyAlloc).ceil()
        : 999;
    final completionYear =
        DateTime.now().year + (monthsLeft / 12).ceil();

    showModalBottomSheet(
      context:             ctx,
      backgroundColor:     Colors.transparent,
      isScrollControlled:  true,
      builder: (_) => Container(
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
          color:        Color(0xFF13131A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize:      MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color:        Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(children: [
              Text(goal.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(goal.name,
                    style: const TextStyle(
                        color:       Colors.white,
                        fontSize:    18,
                        fontWeight:  FontWeight.w700)),
                Text('${(goal.progress * 100).toInt()}% funded',
                    style: TextStyle(color: goal.color, fontSize: 13)),
              ]),
            ]),
            const SizedBox(height: 20),
            _goalRow('Funded so far',  formatInr(goal.fundedAmount), goal.color),
            _goalRow('Target amount',  formatInr(goal.targetAmount), Colors.white70),
            _goalRow('Monthly contribution', formatInr(goal.monthlyAlloc) + '/mo', _kEmerald),
            _goalRow('Est. completion', completionYear.toString(), _kGold),
            const SizedBox(height: 20),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value:           goal.progress,
                backgroundColor: Colors.white10,
                valueColor:      AlwaysStoppedAnimation(goal.color),
                minHeight:       8,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _goalRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value,
              style: TextStyle(
                  color:      valueColor,
                  fontSize:   13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Add custom goal dialog ───────────────────────────────────────────
  void _showAddGoalDialog() {
    final nameCtrl   = TextEditingController();
    final amountCtrl = TextEditingController();
    final monthsCtrl = TextEditingController();
    final palette    = [
      const Color(0xFF00D4AA), const Color(0xFF3D8BFF), _kPurple,
      const Color(0xFFF5A623), const Color(0xFFE84393), const Color(0xFFFF5B3B),
    ];

    showModalBottomSheet(
      context:            context,
      backgroundColor:    Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(builder: (ctx, ss) {
        final months  = int.tryParse(monthsCtrl.text)    ?? 0;
        final amount  = double.tryParse(amountCtrl.text) ?? 0;
        final monthly = months > 0 ? (amount / months)   : 0.0;
        final yr      = months > 0
            ? DateTime.now().year + (months / 12).ceil()
            : DateTime.now().year;

        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
            decoration: const BoxDecoration(
              color:        Color(0xFF13131A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Add Life Goal',
                    style: TextStyle(
                        color: Colors.white, fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                const Text('We’ll calculate your monthly contribution',
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
                const SizedBox(height: 20),
                _addGoalField('Goal Name', nameCtrl, 'e.g. World Tour', false, ss),
                const SizedBox(height: 12),
                _addGoalField('Target Amount (₹)', amountCtrl, 'e.g. 1500000', true, ss),
                const SizedBox(height: 12),
                _addGoalField('Months to completion', monthsCtrl, 'e.g. 36', true, ss),
                if (monthly > 0) ...[  
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color:  _kPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kPurple.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.calculate_rounded, color: _kPurple, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${formatInr(monthly)}/month · Est. done: $yr',
                          style: const TextStyle(
                              color: _kPurple, fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ]),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: nameCtrl.text.trim().isEmpty || monthly <= 0
                        ? null
                        : () {
                            final color = palette[_extraGoals.length % palette.length];
                            setState(() {
                              _extraGoals.add(LifeGoal(
                                name:         nameCtrl.text.trim(),
                                emoji:        '🎯',
                                color:        color,
                                progress:     0.0,
                                fundedAmount: 0.0,
                                targetAmount: amount,
                                monthlyAlloc: monthly,
                              ));
                            });
                            Navigator.pop(ctx);
                          },
                    child: const Text('Add Goal',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _addGoalField(
    String label,
    TextEditingController ctrl,
    String hint,
    bool numeric,
    void Function(void Function()) ss,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
          controller:  ctrl,
          keyboardType: numeric ? TextInputType.number : TextInputType.text,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          onChanged: (_) => ss(() {}),
          decoration: InputDecoration(
            hintText:  hint,
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
            filled:    true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1E1E2E))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1E1E2E))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: Color(0xFF7C5CFC), width: 1.5)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  // ── Chart D: Monthly financial footprint ──────────────────────────────────
  Widget _buildChartD() {
    final fp   = p.footprint;
    final maxY = fp.map((e) => math.max(e.expenses, e.passiveIncome)).reduce(math.max) * 1.15;

    return SizedBox(
      height: 200,
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
                reservedSize: 52,
                getTitlesWidget: (v, _) => Text(
                  formatInr(v),
                  style: const TextStyle(color: Colors.white30, fontSize: 9),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= fp.length || idx % 3 != 0) {
                    return const SizedBox();
                  }
                  return Text(fp[idx].month,
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
                final color = s.barIndex == 0 ? Colors.white38 : _kGold;
                final label = s.barIndex == 0 ? 'Expenses' : 'Income';
                return LineTooltipItem(
                  '$label\n${formatInr(s.y)}',
                  TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            // Expenses (white-grey dashed area)
            LineChartBarData(
              spots: List.generate(
                  fp.length, (i) => FlSpot(i.toDouble(), fp[i].expenses)),
              isCurved: true,
              color: Colors.white24,
              barWidth: 1.5,
              dashArray: [6, 4],
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            // Passive income (gold line)
            LineChartBarData(
              spots: List.generate(
                  fp.length, (i) => FlSpot(i.toDouble(), fp[i].passiveIncome)),
              isCurved: true,
              color: _kGold,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, pct, data, idx) {
                  final isFree =
                      fp[idx].passiveIncome >= fp[idx].expenses;
                  return FlDotCirclePainter(
                    radius:     isFree ? 4 : 2,
                    color:      isFree ? _kGold : _kGold.withValues(alpha: 0.5),
                    strokeColor: Colors.transparent,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    _kGold.withValues(alpha: 0.25),
                    _kGold.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end:   Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 400),
      ),
    );
  }

  // ── Trend data helper (deterministic from sector index + portfolio seed) ───
  List<FlSpot> _sectorTrend(SectorReturn sr, int idx) {
    final rng      = math.Random(idx * 137 + (p.seed % 1000));
    final endpoint = sr.returnPercent;
    double val     = 0;
    return List.generate(7, (i) {
      if (i == 6) return FlSpot(6, endpoint);
      val = endpoint * (i / 6) + (rng.nextDouble() - 0.5) * 3;
      return FlSpot(i.toDouble(), val);
    });
  }

  // ── Chart E: Sector return trend lines ────────────────────────────────────
  Widget _buildChartE() {
    final returns = p.sectorReturns;
    final sel     = _selectedSectors.where((i) => i < returns.length).toList()..sort();
    final selReturns = sel.map((i) => (i, returns[i])).toList();

    // Compute axis bounds from selected sectors only (or full range if none selected)
    final allY = sel.isNotEmpty
        ? selReturns.expand((e) => _sectorTrend(e.$2, e.$1).map((s) => s.y))
        : returns.expand((r) => _sectorTrend(r, returns.indexOf(r)).map((s) => s.y));
    final minY = (allY.reduce(math.min) - 1).floorToDouble();
    final maxY = (allY.reduce(math.max) + 1).ceilToDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Sector selector chips ──
        const Text('Select sectors (up to 3)',
            style: TextStyle(color: Colors.white38, fontSize: 10)),
        const SizedBox(height: 8),
        Wrap(
          spacing:    6,
          runSpacing: 6,
          children: returns.asMap().entries.map((e) {
            final i  = e.key;
            final sr = e.value;
            final isSelected = _selectedSectors.contains(i);
            final isPos      = sr.returnPercent >= 0;
            final chipColor  = isPos ? sr.color : const Color(0xFFEF4444);
            return GestureDetector(
              onTap: () => setState(() {
                if (isSelected) {
                  if (_selectedSectors.length > 1) _selectedSectors.remove(i);
                } else if (_selectedSectors.length < 3) {
                  _selectedSectors.add(i);
                }
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? chipColor.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? chipColor.withValues(alpha: 0.55)
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Text(
                  '${sr.name}  ${isPos ? '+' : ''}${sr.returnPercent.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: isSelected ? chipColor : Colors.white30,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        // ── Trend Chart ──
        if (selReturns.isNotEmpty) SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minX: 0, maxX: 6,
              minY: minY, maxY: maxY,
              gridData: FlGridData(
                show: true, drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: Color(0xFF1E1E2E), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 40,
                  getTitlesWidget: (v, _) => Text('${v.toStringAsFixed(0)}%',
                      style: const TextStyle(color: Colors.white30, fontSize: 9)),
                )),
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    const labels = ['W1', 'W2', 'W3', 'W4', 'W5', 'W6', 'Now'];
                    final i = v.toInt();
                    if (i < 0 || i >= labels.length) return const SizedBox();
                    return Text(labels[i],
                        style: const TextStyle(color: Colors.white30, fontSize: 9));
                  },
                )),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              extraLinesData: ExtraLinesData(horizontalLines: [
                HorizontalLine(y: 0, color: Colors.white24,
                    strokeWidth: 1, dashArray: [4, 4]),
              ]),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => const Color(0xFF1E1E2E),
                  getTooltipItems: (spots) => spots.map((s) {
                    if (s.barIndex >= selReturns.length) {
                      return const LineTooltipItem('', TextStyle());
                    }
                    final (_, sr) = selReturns[s.barIndex];
                    final color   = sr.returnPercent >= 0 ? sr.color : const Color(0xFFEF4444);
                    return LineTooltipItem(
                      '${sr.name}\n${s.y >= 0 ? '+' : ''}${s.y.toStringAsFixed(1)}%',
                      TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
                    );
                  }).toList(),
                ),
              ),
              lineBarsData: selReturns.map((entry) {
                final (idx, sr) = entry;
                final isPos     = sr.returnPercent >= 0;
                final color     = isPos ? sr.color : const Color(0xFFEF4444);
                return LineChartBarData(
                  spots:     _sectorTrend(sr, idx),
                  isCurved:  true,
                  curveSmoothness: 0.35,
                  color:     color,
                  barWidth:  2.2,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, pct, data, i) => FlDotCirclePainter(
                      radius:      i == 6 ? 5 : 2.5,
                      color:       color,
                      strokeColor: Colors.transparent,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: isPos,
                    color: color.withValues(alpha: 0.06),
                  ),
                );
              }).toList(),
            ),
            duration: const Duration(milliseconds: 300),
          ),
        ),
      ],
    );
  }
}

// ─── Sausage-link donut painter ─────────────────────────────────────────────
class _SausagePainter extends CustomPainter {
  final List<LifeGoal> goals;
  final double totalAlloc;

  const _SausagePainter({required this.goals, required this.totalAlloc});

  @override
  void paint(Canvas canvas, Size size) {
    final cx     = size.width / 2;
    final cy     = size.height / 2;
    final r      = math.min(cx, cy) - 18;
    final rect   = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    const sw     = 20.0;   // stroke width — thinner ring
    const gapRad = 0.09;   // larger gap for clear separation

    // Background track
    canvas.drawCircle(
      Offset(cx, cy), r,
      Paint()
        ..color       = Colors.white.withValues(alpha: 0.06)
        ..style       = PaintingStyle.stroke
        ..strokeWidth = sw,
    );

    double startAngle = -math.pi / 2;

    for (final goal in goals) {
      final frac  = goal.monthlyAlloc / totalAlloc;
      final sweep = frac * 2 * math.pi - gapRad;
      if (sweep <= 0) {
        startAngle += frac * 2 * math.pi;
        continue;
      }

      // Glow layer
      canvas.drawArc(
        rect,
        startAngle + gapRad / 2,
        sweep,
        false,
        Paint()
          ..color       = goal.color.withValues(alpha: 0.20)
          ..style       = PaintingStyle.stroke
          ..strokeWidth = sw + 4
          ..strokeCap   = StrokeCap.butt
          ..maskFilter  = const MaskFilter.blur(BlurStyle.normal, 5),
      );

      // Solid segment
      canvas.drawArc(
        rect,
        startAngle + gapRad / 2,
        sweep,
        false,
        Paint()
          ..color       = goal.color
          ..style       = PaintingStyle.stroke
          ..strokeWidth = sw
          ..strokeCap   = StrokeCap.butt,
      );

      startAngle += frac * 2 * math.pi;
    }
  }

  @override
  bool shouldRepaint(_SausagePainter old) =>
      old.goals != goals || old.totalAlloc != totalAlloc;
}

class _ArcPainter extends CustomPainter {
  final double progress; // 0–1
  final Color  color;

  const _ArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx   = size.width / 2;
    final cy   = size.height / 2;
    final r    = math.min(cx, cy) - 4;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    // Background track
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi,
      false,
      Paint()
        ..color       = Colors.white.withValues(alpha: 0.08)
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap   = StrokeCap.round,
    );

    // Progress arc
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color       = color
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap   = StrokeCap.round
        ..maskFilter  = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Bright tip
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color       = color
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap   = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress || old.color != color;
}
