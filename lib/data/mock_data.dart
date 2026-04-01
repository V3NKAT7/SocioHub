import 'dart:math';
import 'package:flutter/material.dart';
import '../models/portfolio_item.dart';
import '../widgets/streamline_icons.dart';

// ─── Formatting helper ────────────────────────────────────────────────────────
String formatInr(double v) {
  if (v >= 1e7) return '₹${(v / 1e7).toStringAsFixed(1)}Cr';
  if (v >= 1e5) return '₹${(v / 1e5).toStringAsFixed(1)}L';
  if (v >= 1e3) return '₹${(v / 1e3).toStringAsFixed(1)}K';
  return '₹${v.toStringAsFixed(0)}';
}

// ─── New domain models ────────────────────────────────────────────────────────

class SectorData {
  final String name;
  final double percent; // 0–100, normalised to sum to 100
  final Color color;
  final String risk; // 'low' | 'medium'

  const SectorData({
    required this.name,
    required this.percent,
    required this.color,
    required this.risk,
  });
}

class MonthlyPoint {
  final String month;
  final double invested; // cumulative ₹ invested
  final double value;    // portfolio market value ₹

  const MonthlyPoint(this.month, this.invested, this.value);
}

class LifeGoal {
  final String name;
  final String emoji;
  final Color color;
  final double progress;      // 0–1 cumulative funded fraction
  final double fundedAmount;  // ₹ funded so far
  final double targetAmount;  // ₹ total goal cost
  final double monthlyAlloc;  // ₹/month allocated from earnings

  const LifeGoal({
    required this.name,
    required this.emoji,
    required this.color,
    required this.progress,
    required this.fundedAmount,
    required this.targetAmount,
    required this.monthlyAlloc,
  });
}

class MonthlyFootprintPoint {
  final String month;
  final double expenses;      // monthly living expenses ₹
  final double passiveIncome; // passive income from portfolio ₹

  const MonthlyFootprintPoint(this.month, this.expenses, this.passiveIncome);
}

class SectorReturn {
  final String name;
  final Color color;
  final String risk;
  final double returnPercent;
  final double gainAmount; // ₹

  const SectorReturn({
    required this.name,
    required this.color,
    required this.risk,
    required this.returnPercent,
    required this.gainAmount,
  });
}

// ─── Seeded random-data factory ───────────────────────────────────────────────

class RandomPortfolio {
  final int seed;

  // Investments screen
  final double totalValue;
  final double invested;
  final double earnings;
  final double roiPercent;
  final List<double> roiLine;   // 7 normalised chart points
  final List<double> pnlLine;   // 7 normalised chart points
  final List<SectorData> sectors;

  // Analytics screen
  final List<MonthlyPoint> monthlyGrowth; // 12 months
  final List<LifeGoal> lifeGoals;         // 9 life goals
  final List<MonthlyFootprintPoint> footprint; // 12 months
  final List<SectorReturn> sectorReturns;      // 8 sectors, sorted desc

  RandomPortfolio._({
    required this.seed,
    required this.totalValue,
    required this.invested,
    required this.earnings,
    required this.roiPercent,
    required this.roiLine,
    required this.pnlLine,
    required this.sectors,
    required this.monthlyGrowth,
    required this.lifeGoals,
    required this.footprint,
    required this.sectorReturns,
  });

  factory RandomPortfolio.forSeed(int seed) {
    final rng = Random(seed);
    double rd(double lo, double hi) => lo + rng.nextDouble() * (hi - lo);

    // ── Core metrics ────────────────────────────────────────────────────────
    final totalValue = rd(500000, 1800000);
    final roiPct     = rd(3, 14);
    final invested   = totalValue / (1 + roiPct / 100);
    final earnings   = totalValue - invested;

    // ── Line charts (7 points) ──────────────────────────────────────────────
    final roiLine = List<double>.generate(7, (_) => rd(0.18, 0.95));
    final pnlLine = List<double>.generate(7, (_) => rd(0.12, 0.90));

    // ── Sectors ─────────────────────────────────────────────────────────────
    const sNames  = ['IT', 'Pharma', 'Bank', 'Finance', 'Metals', 'Auto', 'Forex', 'Crypto'];
    const sColors = [
      Color(0xFF7C5CFC), Color(0xFF00D4AA), Color(0xFF3D8BFF), Color(0xFFF5A623),
      Color(0xFFFF5B3B), Color(0xFF10B981), Color(0xFFE84393), Color(0xFFD4F53C),
    ];
    const sRisks  = ['medium', 'low', 'medium', 'medium', 'medium', 'low', 'low', 'medium'];

    final rawW = List<double>.generate(8, (_) => rd(4, 25));
    final sumW = rawW.fold(0.0, (a, b) => a + b);
    final sectors = List<SectorData>.generate(8, (i) => SectorData(
      name:    sNames[i],
      percent: rawW[i] / sumW * 100,
      color:   sColors[i],
      risk:    sRisks[i],
    ));

    // ── Monthly growth (12 months) ───────────────────────────────────────────
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    var cumInv = invested * 0.35;
    var cumVal = cumInv * rd(0.9, 1.05);
    final monthlyGrowth = List<MonthlyPoint>.generate(12, (i) {
      cumInv = (cumInv + invested * 0.055 * rd(0.8, 1.2)).clamp(0, invested);
      cumVal = (cumVal * rd(1.01, 1.045) + invested * 0.055 * rd(0.8, 1.1))
          .clamp(0, totalValue * 1.15);
      return MonthlyPoint(months[i], cumInv, cumVal);
    });

    // ── Life goals ───────────────────────────────────────────────────────────
    final goalDefs = [
      ('Health Insurance',    '🏥', const Color(0xFF00D4AA)),
      ('Retirement Savings',  '🏦', const Color(0xFF3D8BFF)),
      ('Future Wealth Fund',  '💰', const Color(0xFF7C5CFC)),
      ('New House',           '🏠', const Color(0xFFF5A623)),
      ('Dream Car',           '🚗', const Color(0xFFE84393)),
      ('Yearly Maintenance',  '🔧', const Color(0xFFFF5B3B)),
      ('School / Tuition',    '🎓', const Color(0xFF10B981)),
      ('Destination Wedding', '💒', const Color(0xFFEC4899)),
      ('Higher Education',    '📚', const Color(0xFF60A5FA)),
      ('Vacation',            '✈️', const Color(0xFFFF8C42)),
    ];
    final rawGoal = List<double>.generate(10, (_) => rd(3, 18));
    final sumGoal = rawGoal.fold(0.0, (a, b) => a + b);
    // Lifestyle multiplier: 0 = base lifestyle, 1 = premium lifestyle
    // Scales with invested amount: ₹4.5L → 0.0, ₹16L → 1.0
    final lm = ((invested - 450000) / 1200000).clamp(0.0, 1.0);

    // Realistic INR target ranges (min, max) per goal
    // More invested → higher lifestyle → target closer to max
    final goalTargetRanges = [
      (2500000.0,  10000000.0),  // Health Insurance:    25L – 1Cr
      (8000000.0,  20000000.0),  // Retirement Savings:  80L – 2Cr
      (10000000.0, 50000000.0),  // Future Wealth Fund:  1Cr – 5Cr
      (10000000.0, 40000000.0),  // New House:           1Cr – 4Cr
      (5000000.0,  10000000.0),  // Dream Car:           50L – 1Cr
      (1000000.0,  2000000.0),   // Yearly Maintenance:  10L – 20L
      (300000.0,   600000.0),    // School / Tuition:    3L – 6L
      (7000000.0,  20000000.0),  // Destination Wedding: 70L – 2Cr
      (7000000.0,  15000000.0),  // Higher Education:    70L – 1.5Cr
      (400000.0,   1000000.0),   // Yearly Vacation:     4L – 10L
    ];

    final lifeGoals = List<LifeGoal>.generate(10, (i) {
      final frac      = rawGoal[i] / sumGoal;
      final monthly   = earnings / 12 * frac;
      final range     = goalTargetRanges[i];
      // Scale target: 70% by lifestyle multiplier, 30% random
      final target    = range.$1 + (range.$2 - range.$1) * (lm * 0.7 + rd(0, 0.3));
      final prog      = rd(0.12, 0.88);
      return LifeGoal(
        name:         goalDefs[i].$1,
        emoji:        goalDefs[i].$2,
        color:        goalDefs[i].$3,
        progress:     prog,
        fundedAmount: target * prog,
        targetAmount: target,
        monthlyAlloc: monthly,
      );
    });

    // ── Monthly footprint (12 months) ────────────────────────────────────────
    final baseExp = invested * rd(0.003, 0.006);
    final footprint = List<MonthlyFootprintPoint>.generate(12, (i) =>
      MonthlyFootprintPoint(
        months[i],
        baseExp * rd(0.92, 1.10),
        earnings / 12 * ((i + 1) / 12) * rd(0.70, 1.30),
      ));

    // ── Sector returns (sorted descending) ───────────────────────────────────
    final sectorReturns = List<SectorReturn>.generate(8, (i) {
      final ret = rd(-3, 20);
      return SectorReturn(
        name:          sNames[i],
        color:         sColors[i],
        risk:          sRisks[i],
        returnPercent: ret,
        gainAmount:    invested * sectors[i].percent / 100 * ret / 100,
      );
    })..sort((a, b) => b.returnPercent.compareTo(a.returnPercent));

    return RandomPortfolio._(
      seed:          seed,
      totalValue:    totalValue,
      invested:      invested,
      earnings:      earnings,
      roiPercent:    roiPct,
      roiLine:       roiLine,
      pnlLine:       pnlLine,
      sectors:       sectors,
      monthlyGrowth: monthlyGrowth,
      lifeGoals:     lifeGoals,
      footprint:     footprint,
      sectorReturns: sectorReturns,
    );
  }
}

// ─── Legacy static data (unchanged) ──────────────────────────────────────────

class MockData {
  static const double totalNetWorth = 124850.00;
  static const double weeklyChange = 6492.12;
  static const double weeklyChangePercent = 5.2;
  static const double overallChangePercent = 2.4;

  static const List<PortfolioItem> portfolioItems = [
    PortfolioItem(
      name: 'Earned',
      svgIcon: StreamlineIcons.computer,
      value: 40911,
      changePercent: 4.8,
      color: Color(0xFF3BAF8E),
      bgColor: Color(0x1A3BAF8E),
    ),
    PortfolioItem(
      name: 'Spent',
      svgIcon: StreamlineIcons.pill,
      value: 12273,
      changePercent: -2.3,
      color: Color(0xFF7B6CD1),
      bgColor: Color(0x1A7B6CD1),
    ),
    PortfolioItem(
      name: 'Available',
      svgIcon: StreamlineIcons.car,
      value: 8182,
      changePercent: 1.2,
      color: Color(0xFFA8CC42),
      bgColor: Color(0x1AA8CC42),
    ),
    PortfolioItem(
      name: 'Savings',
      svgIcon: StreamlineIcons.bank,
      value: 4091,
      changePercent: 3.1,
      color: Color(0xFFE8B84D),
      bgColor: Color(0x1AE8B84D),
    ),
  ];

  static const List<TradeItem> recentTrades = [
    TradeItem(title: 'Buy INFY',   subtitle: 'Feb 24, 2026 • 10:45 AM', amount: -2450.00, isBuy: true),
    TradeItem(title: 'Sell HDFC',  subtitle: 'Feb 23, 2026 • 3:20 PM',  amount:  5120.00, isBuy: false),
    TradeItem(title: 'Buy TCS',    subtitle: 'Feb 22, 2026 • 11:10 AM', amount: -3800.00, isBuy: true),
    TradeItem(title: 'Buy MARUTI', subtitle: 'Feb 21, 2026 • 2:05 PM',  amount: -1920.00, isBuy: true),
  ];

  static const List<ContentDraft> drafts = [
    ContentDraft(title: 'My New Tech Setup 2026',      editedTime: 'Edited 2 hours ago', type: 'Reel'),
    ContentDraft(title: 'The Future of AI in Design',  editedTime: 'Edited yesterday',   type: 'Blog'),
    ContentDraft(title: 'Market Analysis Q1 2026',     editedTime: 'Edited 3 days ago',  type: 'Short'),
  ];

  static const List<double> chartData       = [0.42, 0.86, 0.73, 0.38, 0.67, 0.59, 0.78];
  static const List<double> realisedPnlData = [0.25, 0.40, 0.55, 0.48, 0.72, 0.65, 0.88];
  static const List<String> chartLabels     = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  static const Map<String, dynamic> insightsData = {
    'totalViews':       '124.8K', 'viewsChange':      12.0,
    'engagement':       '8.4K',   'engagementChange':  5.0,
    'followers':        '32.1K',  'followersChange':   3.2,
    'shares':           '2.1K',   'sharesChange':      8.7,
  };
}
