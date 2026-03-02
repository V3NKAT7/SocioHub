import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class InvestmentDonutChart extends StatefulWidget {
  const InvestmentDonutChart({super.key});

  @override
  State<InvestmentDonutChart> createState() => _InvestmentDonutChartState();
}

class _ChartItem {
  final String name;
  final double value;
  final String display;
  final Color color;

  const _ChartItem({
    required this.name,
    required this.value,
    required this.display,
    required this.color,
  });
}

class _InvestmentDonutChartState extends State<InvestmentDonutChart> {
  int? activeIndex;

  // 6 sectors totalling ₹8,90,000
  static const List<_ChartItem> data = [
    _ChartItem(name: 'IT',      value: 245000, display: '₹2,45,000', color: Color(0xFF3ECF8E)),
    _ChartItem(name: 'Auto',    value: 180000, display: '₹1,80,000', color: Color(0xFF7C6FF6)),
    _ChartItem(name: 'Finance', value: 150000, display: '₹1,50,000', color: Color(0xFFD6F36A)),
    _ChartItem(name: 'Bank',    value: 120000, display: '₹1,20,000', color: Color(0xFFF6C36B)),
    _ChartItem(name: 'Metal',   value: 85000,  display: '₹85,000',   color: Color(0xFF5B8DEF)),
    _ChartItem(name: 'Pharma',  value: 110000, display: '₹1,10,000', color: Color(0xFFE06B8D)),
  ];

  static const String _totalDisplay = '₹8,90,000';

  String get centerLabel =>
      activeIndex != null ? data[activeIndex!].name : 'Total Invested';

  String get centerValue =>
      activeIndex != null ? data[activeIndex!].display : _totalDisplay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            const Text(
              'Analytics',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            // Donut chart + Legend row
            Row(
              children: [
                // Donut chart with center text
                Expanded(
                  child: SizedBox(
                    height: 180,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    if (event is FlTapUpEvent || event is FlLongPressEnd) {
                                      // keep selection on tap
                                    } else {
                                      activeIndex = null;
                                    }
                                    return;
                                  }
                                  final idx = pieTouchResponse
                                      .touchedSection!.touchedSectionIndex;
                                  if (idx >= 0 && idx < data.length) {
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
                            sectionsSpace: 6,
                            centerSpaceRadius: 50,
                            startDegreeOffset: -90,
                            sections: _buildSections(),
                          ),
                        ),
                        // Center text
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
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Text(
                                  centerValue,
                                  key: ValueKey(centerValue),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // Legend section
                Expanded(
                  child: _buildLegend(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < data.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _legendItem(i),
        ],
      ],
    );
  }

  Widget _legendItem(int i) {
    final item = data[i];
    final isActive = activeIndex == null || activeIndex == i;

    return GestureDetector(
      onTap: () => setState(() => activeIndex = activeIndex == i ? null : i),
      child: MouseRegion(
        onEnter: (_) => setState(() => activeIndex = i),
        onExit: (_) => setState(() => activeIndex = null),
        cursor: SystemMouseCursors.click,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isActive ? 1.0 : 0.3,
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: item.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item.name,
                style: const TextStyle(color: Colors.white),
              ),
              const Spacer(),
              Text(
                item.display,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    return List.generate(data.length, (i) {
      final item = data[i];
      final isActive = activeIndex == i;
      final dimmed = activeIndex != null && !isActive;

      return PieChartSectionData(
        value: item.value,
        color: dimmed ? item.color.withOpacity(0.3) : item.color,
        radius: isActive ? 46 : 40,
        showTitle: false,
      );
    });
  }
}
