import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../transitions/app_transitions.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/sector_card.dart';
import '../widgets/investment_donut_chart.dart';
import 'analytics_dashboard_screen.dart';

class InvestmentsScreen extends StatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  State<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  int _periodIndex = 0;
  int _chartToggle = 0;
  final List<String> _periods = ['Last 7 Days', 'Last Month', 'Custom'];
  DateTimeRange? _customRange;
  late RandomPortfolio _portfolio;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _portfolio = RandomPortfolio.forSeed(1001); // seed for 'Last 7 Days'
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // Seed selection based on active period
  int get _seed {
    if (_periodIndex == 2 && _customRange != null) {
      return _customRange!.start.millisecondsSinceEpoch ~/ 86400000;
    }
    return [1001, 2001, 3001][_periodIndex];
  }

  void _refreshPortfolio() {
    setState(() => _portfolio = RandomPortfolio.forSeed(_seed));
  }

  String _fmtInr(double v) {
    if (v >= 1e7) return '₹${(v / 1e7).toStringAsFixed(2)}Cr';
    if (v >= 1e5) return '₹${(v / 1e5).toStringAsFixed(2)}L';
    if (v >= 1e3) return '₹${(v / 1e3).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  List<double> get _activeChartData =>
      _chartToggle == 0 ? _portfolio.roiLine : _portfolio.pnlLine;

  String get _activeChangeAmount {
    final v = _chartToggle == 0 ? _portfolio.earnings : _portfolio.earnings * 0.72;
    return '+${_fmtInr(v)}';
  }

  String get _activeChangePercent {
    final pct = _chartToggle == 0
        ? _portfolio.roiPercent
        : _portfolio.roiPercent * 0.72;
    return '+${pct.toStringAsFixed(1)}%';
  }

  // Neon purple for ROI, emerald for Realised P&L
  Color get _activeChartColor =>
      _chartToggle == 0 ? const Color(0xFFB026FF) : const Color(0xFF10B981);

  void _navigateToProfile() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _EditProfileSheet(),
    ));
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _NotificationsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverToBoxAdapter(child: _buildNetWorthCard(context)),
          SliverToBoxAdapter(child: _buildChartSection(context)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: InvestmentDonutChart(
                sectors:      _portfolio.sectors,
                totalInvested: _portfolio.invested,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }



  Widget _buildHeader(BuildContext ctx) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: _navigateToProfile,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.border(ctx)),
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withOpacity(0.7),
                    AppTheme.purple.withOpacity(0.7),
                  ],
                ),
              ),
              child: const Center(
                child: Text('A',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 18)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Good morning',
                    style: TextStyle(
                        color: AppTheme.textSecondary(ctx), fontSize: 12)),
                Text(
                  'Welcome back, Alex!',
                  style: TextStyle(
                    color: AppTheme.textPrimary(ctx),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _showNotifications,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.surface(ctx),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(Icons.notifications_outlined,
                        color: AppTheme.textSecondary(ctx), size: 22),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.rose,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildNetWorthCard(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFADD984), // sage green
              Color(0xFF7BC85A), // mid green
              Color(0xFF4DA832), // forest green
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFADD984).withValues(alpha: 0.35),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Net Worth',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w400)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5A0D3F).withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.trending_up,
                          color: Color(0xFFE879F9), size: 14),
                      const SizedBox(width: 4),
                      Text('+${_portfolio.roiPercent.toStringAsFixed(1)}%',
                          style: const TextStyle(
                              color: Color(0xFFE879F9),
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(_fmtInr(_portfolio.totalValue),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5)),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time,
                    color: Colors.white.withOpacity(0.6), size: 14),
                const SizedBox(width: 6),
                Text('Updated 2 minutes ago',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6), fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Title + Analytics arrow
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Portfolio Performance',
                  style: TextStyle(
                      color: AppTheme.textPrimary(ctx),
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  AppRoute(
                    builder: (_) => AnalyticsDashboardScreen(portfolio: _portfolio),
                  ),
                ),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.surface(ctx),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border(ctx)),
                  ),
                  child: const Icon(Icons.arrow_forward_ios_rounded,
                      color: AppTheme.primary, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Period chips
          Row(
            children: List.generate(_periods.length, (i) {
              final isActive = _periodIndex == i;
              // Build label — show range if Custom is selected
              String chipLabel = _periods[i];
              if (i == 2 && _customRange != null && isActive) {
                final s = '${_customRange!.start.day}/${_customRange!.start.month}';
                final e = '${_customRange!.end.day}/${_customRange!.end.month}';
                chipLabel = '$s – $e';
              }
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () async {
                    if (i == 2) {
                      // Custom → open date range picker
                      final now = DateTime.now();
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2024),
                        lastDate: now,
                        initialDateRange: _customRange ??
                            DateTimeRange(
                              start: now.subtract(const Duration(days: 30)),
                              end: now,
                            ),
                        builder: (ctx2, child) {
                          return Theme(
                            data: Theme.of(ctx2).copyWith(
                              colorScheme: Theme.of(ctx2).colorScheme.copyWith(
                                primary: AppTheme.primary,
                                onPrimary: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() {
                          _customRange = picked;
                          _periodIndex = 2;
                        });
                        _refreshPortfolio();
                      }
                    } else {
                      setState(() => _periodIndex = i);
                      _refreshPortfolio();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.primary.withOpacity(0.15)
                          : AppTheme.surface(ctx),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isActive
                              ? AppTheme.primary.withOpacity(0.4)
                              : AppTheme.border(ctx)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (i == 2) ...[
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: isActive
                                ? AppTheme.primary
                                : AppTheme.textSecondary(ctx),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          chipLabel,
                          style: TextStyle(
                            color: isActive
                                ? AppTheme.primary
                                : AppTheme.textSecondary(ctx),
                            fontSize: 12,
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          // ROI / Realised P&L toggle
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppTheme.surface(ctx),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _toggleButton(ctx, 'ROI', 0),
                _toggleButton(ctx, 'Realised P&L', 1),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Change amount
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(_activeChangeAmount,
                    key: ValueKey('amt_$_chartToggle'),
                    style: TextStyle(
                        color: AppTheme.textPrimary(ctx),
                        fontSize: 24,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(_activeChangePercent,
                    key: ValueKey('pct_$_chartToggle'),
                    style: TextStyle(
                        color: _activeChartColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Chart
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < MockData.chartLabels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(MockData.chartLabels[index],
                                style: TextStyle(
                                    color: AppTheme.textSecondary(ctx),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600)),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      interval: 1,
                      reservedSize: 28,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 1,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(_activeChartData.length,
                        (i) => FlSpot(i.toDouble(), _activeChartData[i])),
                    isCurved: true,
                    color: _activeChartColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius:
                              index == _activeChartData.length - 1 ? 5 : 0,
                          color: _activeChartColor,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _activeChartColor.withOpacity(0.3),
                          _activeChartColor.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.surface(ctx),
                  ),
                ),
              ),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleButton(BuildContext ctx, String label, int index) {
    final isActive = _chartToggle == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _chartToggle = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color: isActive
                        ? Colors.white
                        : AppTheme.textSecondary(ctx),
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400)),
          ),
        ),
      ),
    );
  }
}

// ─── Edit Profile Page ───────────────────────────────────
class _EditProfileSheet extends StatefulWidget {
  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  int _avatarColorIndex = 0;
  String _avatarLetter = 'A';

  static const _avatarGradients = [
    [AppTheme.primary, AppTheme.purple],
    [Color(0xFFF59E0B), Color(0xFFEF4444)],
    [Color(0xFF10B981), Color(0xFF06B6D4)],
    [Color(0xFFEC4899), Color(0xFF8B5CF6)],
  ];

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surface(ctx),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border(ctx),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text('Change Profile Photo',
                  style: TextStyle(
                      color: AppTheme.textPrimary(ctx),
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              // Color options
              Text('Choose avatar color',
                  style: TextStyle(
                      color: AppTheme.textSecondary(ctx), fontSize: 13)),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_avatarGradients.length, (i) {
                  final selected = _avatarColorIndex == i;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _avatarColorIndex = i);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                            colors: _avatarGradients[i]),
                        border: selected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: _avatarGradients[i][0]
                                      .withOpacity(0.4),
                                  blurRadius: 10,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(_avatarLetter,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              // Change initial
              ListTile(
                leading: Icon(Icons.edit,
                    color: AppTheme.textSecondary(ctx), size: 20),
                title: Text('Change Initial',
                    style: TextStyle(
                        color: AppTheme.textPrimary(ctx), fontSize: 15)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showInitialDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showInitialDialog() {
    final controller = TextEditingController(text: _avatarLetter);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surface(ctx),
          title: Text('Change Initial',
              style: TextStyle(color: AppTheme.textPrimary(ctx))),
          content: TextField(
            controller: controller,
            maxLength: 2,
            textCapitalization: TextCapitalization.characters,
            style: TextStyle(color: AppTheme.textPrimary(ctx), fontSize: 24),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'A',
              hintStyle: TextStyle(color: AppTheme.textSecondary(ctx)),
              counterStyle: TextStyle(color: AppTheme.textSecondary(ctx)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: TextStyle(color: AppTheme.textSecondary(ctx))),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() => _avatarLetter = controller.text.toUpperCase());
                }
                Navigator.pop(ctx);
              },
              child: const Text('Save',
                  style: TextStyle(color: AppTheme.primary)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surface(context),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Profile',
            style: TextStyle(
                color: AppTheme.textPrimary(context),
                fontWeight: FontWeight.w600)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: _showPhotoOptions,
              child: Stack(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                          colors: _avatarGradients[_avatarColorIndex]),
                    ),
                    child: Center(
                      child: Text(_avatarLetter,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.bg(context),
                          width: 2,
                        ),
                      ),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _showPhotoOptions,
              child: const Text('Change Photo',
                  style: TextStyle(color: AppTheme.primary)),
            ),
            const SizedBox(height: 20),
            _field(context, 'Full Name', 'Alex Mitchell'),
            const SizedBox(height: 14),
            _field(context, 'Username', '@alexmitchell'),
            const SizedBox(height: 14),
            _field(context, 'Bio', 'Creator & Investor'),
          ],
        ),
      ),
    );
  }

  Widget _field(BuildContext ctx, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: AppTheme.textSecondary(ctx),
                fontSize: 12,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.surface(ctx),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border(ctx)),
          ),
          child: Text(value,
              style: TextStyle(
                  color: AppTheme.textPrimary(ctx),
                  fontSize: 15,
                  fontWeight: FontWeight.w400)),
        ),
      ],
    );
  }
}

// ─── Notifications Bottom Sheet ──────────────────────────
class _NotificationsSheet extends StatelessWidget {
  final List<Map<String, String>> _notifications = const [
    {
      'title': 'INFY up 3.2%',
      'body': 'Your IT sector holding is performing well today.',
      'time': '5m ago',
    },
    {
      'title': 'New follower',
      'body': 'Ritu Sharma started following you.',
      'time': '12m ago',
    },
    {
      'title': 'Market alert',
      'body': 'Nifty50 crossed 25,000 for the first time.',
      'time': '1h ago',
    },
    {
      'title': 'Reel trending',
      'body': 'Your reel "Tech Setup 2026" got 12K views.',
      'time': '3h ago',
    },
    {
      'title': 'Dividend received',
      'body': '₹1,250 dividend from HDFC credited to your account.',
      'time': '1d ago',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: BoxDecoration(
        color: AppTheme.bg(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.textSecondary(context).withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text('Notifications',
                    style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('Mark all read',
                    style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _notifications.length,
              itemBuilder: (ctx, i) {
                final n = _notifications[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surface(ctx),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border(ctx)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_outlined,
                              color: AppTheme.primary, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n['title']!,
                                  style: TextStyle(
                                      color: AppTheme.textPrimary(ctx),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 2),
                              Text(n['body']!,
                                  style: TextStyle(
                                      color: AppTheme.textSecondary(ctx),
                                      fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        Text(n['time']!,
                            style: TextStyle(
                                color: AppTheme.textSecondary(ctx),
                                fontSize: 11)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

