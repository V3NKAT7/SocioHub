import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/mock_data.dart';

class InvestmentDonutChart extends StatefulWidget {
  final List<SectorData> sectors;
  final double totalInvested;

  const InvestmentDonutChart({
    super.key,
    required this.sectors,
    required this.totalInvested,
  });

  @override
  State<InvestmentDonutChart> createState() => _InvestmentDonutChartState();
}

class _InvestmentDonutChartState extends State<InvestmentDonutChart> {
  int? activeIndex; // index into _visible sectors
  int _filterIndex = 0; // 0=All, 1=Low-risk, 2=Med-risk

  // Filtered + renormalised sector list
  List<SectorData> get _visible {
    List<SectorData> raw;
    if (_filterIndex == 1) {
      raw = widget.sectors.where((s) => s.risk == 'low').toList();
    } else if (_filterIndex == 2) {
      raw = widget.sectors.where((s) => s.risk == 'medium').toList();
    } else {
      return widget.sectors;
    }
    final sum = raw.fold(0.0, (a, s) => a + s.percent);
    if (sum == 0) return [];
    return raw
        .map((s) => SectorData(
              name:    s.name,
              percent: s.percent / sum * 100,
              color:   s.color,
              risk:    s.risk,
            ))
        .toList();
  }

  // The fraction of totalInvested that the visible sectors represent
  double get _visibleFraction {
    if (_filterIndex == 0) return 1.0;
    final risk = _filterIndex == 1 ? 'low' : 'medium';
    return widget.sectors
        .where((s) => s.risk == risk)
        .fold(0.0, (a, s) => a + s.percent) /
        100;
  }

  String get centerLabel =>
      activeIndex != null && activeIndex! < _visible.length
          ? _visible[activeIndex!].name
          : 'Total Invested';

  String get centerValue {
    if (activeIndex != null && activeIndex! < _visible.length) {
      final amt = widget.totalInvested *
          _visible[activeIndex!].percent /
          100 *
          _visibleFraction;
      return formatInr(amt);
    }
    return formatInr(widget.totalInvested * _visibleFraction);
  }

  @override
  void didUpdateWidget(InvestmentDonutChart old) {
    super.didUpdateWidget(old);
    // Reset active index when data changes
    if (old.sectors != widget.sectors) {
      activeIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        decoration: BoxDecoration(
          color: const Color(0xFF111118),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 4),
            _buildFilterChips(),
            const SizedBox(height: 24),
            _buildDonut(),
            const SizedBox(height: 28),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Row(
      children: [
        Text(
          'Asset Allocation',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    final labels = ['All', 'Low-risk', 'Med-risk'];
    return Row(
      children: List.generate(labels.length, (i) {
        final isActive = _filterIndex == i;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() {
              _filterIndex = i;
              activeIndex  = null;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF7C5CFC)
                    : Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white54,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDonut() {
    const double chartSize    = 280.0;
    const double centerRadius = 72.0;
    const double sectionRadius = 36.0;
    final vis = _visible;

    if (vis.isEmpty) {
      return const SizedBox(
        height: chartSize,
        child: Center(
          child: Text('No sectors for this filter',
              style: TextStyle(color: Colors.white38)),
        ),
      );
    }

    return SizedBox(
      height: chartSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer percent labels
          CustomPaint(
            size: const Size(chartSize, chartSize),
            painter: _PercentLabelPainter(
              sectors:       vis,
              activeIndex:   activeIndex,
              centerRadius:  centerRadius,
              sectionRadius: sectionRadius,
            ),
          ),
          // Pie chart
          PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      if (event is FlTapUpEvent || event is FlLongPressEnd) {
                        // keep selection
                      } else {
                        activeIndex = null;
                      }
                      return;
                    }
                    final idx =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                    if (idx >= 0 && idx < vis.length) {
                      if (event is FlTapUpEvent) {
                        activeIndex = activeIndex == idx ? null : idx;
                      } else {
                        activeIndex = idx;
                      }
                    }
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 4,
              centerSpaceRadius: centerRadius,
              startDegreeOffset: -90,
              sections: _buildSections(sectionRadius, vis),
            ),
          ),
          // Center content
          IgnorePointer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    centerLabel,
                    key: ValueKey(centerLabel),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    centerValue,
                    key: ValueKey(centerValue),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections(
      double baseRadius, List<SectorData> vis) {
    return List.generate(vis.length, (i) {
      final sector   = vis[i];
      final isActive = activeIndex == i;
      final dimmed   = activeIndex != null && !isActive;

      return PieChartSectionData(
        value:      sector.percent,
        color:      dimmed
            ? sector.color.withValues(alpha: 0.25)
            : sector.color.withValues(alpha: isActive ? 1.0 : 0.88),
        radius:     isActive ? baseRadius + 8 : baseRadius,
        showTitle:  false,
      );
    });
  }

  Widget _buildLegend() {
    final vis = _visible;
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: List.generate(vis.length, (i) {
        final s        = vis[i];
        final isActive = activeIndex == null || activeIndex == i;
        return GestureDetector(
          onTap: () =>
              setState(() => activeIndex = activeIndex == i ? null : i),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isActive ? 1.0 : 0.35,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color:  s.color,
                    shape:  BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: s.color.withValues(alpha: 0.5), blurRadius: 4),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${s.name}  ${s.percent.toInt()}%',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ─── Outer % label painter ───────────────────────────────────────────────────
class _PercentLabelPainter extends CustomPainter {
  final List<SectorData> sectors;
  final int? activeIndex;
  final double centerRadius;
  final double sectionRadius;

  _PercentLabelPainter({
    required this.sectors,
    required this.activeIndex,
    required this.centerRadius,
    required this.sectionRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx          = size.width / 2;
    final cy          = size.height / 2;
    final labelRadius = centerRadius + sectionRadius + 18;
    double startAngle = -math.pi / 2;

    for (int i = 0; i < sectors.length; i++) {
      final sweep    = (sectors[i].percent / 100) * 2 * math.pi;
      final midAngle = startAngle + sweep / 2;

      if (sweep < 0.15) {
        startAngle += sweep;
        continue;
      }

      final x        = cx + labelRadius * math.cos(midAngle);
      final y        = cy + labelRadius * math.sin(midAngle);
      final isDimmed = activeIndex != null && activeIndex != i;

      final tp = TextPainter(
        text: TextSpan(
          text: '${sectors[i].percent.toInt()}%',
          style: TextStyle(
            color: isDimmed
                ? sectors[i].color.withValues(alpha: 0.25)
                : sectors[i].color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(_PercentLabelPainter old) =>
      old.activeIndex != activeIndex || old.sectors != sectors;
}
