import 'package:flutter/material.dart';
import '../models/portfolio_item.dart';
import '../widgets/streamline_icons.dart';

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
      color: Color(0xFF3BAF8E),  // hsl(162, 48%, 45%)
      bgColor: Color(0x1A3BAF8E),
    ),
    PortfolioItem(
      name: 'Spent',
      svgIcon: StreamlineIcons.pill,
      value: 12273,
      changePercent: -2.3,
      color: Color(0xFF7B6CD1),  // hsl(252, 40%, 55%)
      bgColor: Color(0x1A7B6CD1),
    ),
    PortfolioItem(
      name: 'Available',
      svgIcon: StreamlineIcons.car,
      value: 8182,
      changePercent: 1.2,
      color: Color(0xFFA8CC42),  // hsl(68, 60%, 55%)
      bgColor: Color(0x1AA8CC42),
    ),
    PortfolioItem(
      name: 'Savings',
      svgIcon: StreamlineIcons.bank,
      value: 4091,
      changePercent: 3.1,
      color: Color(0xFFE8B84D),  // hsl(36, 70%, 65%)
      bgColor: Color(0x1AE8B84D),
    ),
  ];

  static const List<TradeItem> recentTrades = [
    TradeItem(
      title: 'Buy INFY',
      subtitle: 'Feb 24, 2026 • 10:45 AM',
      amount: -2450.00,
      isBuy: true,
    ),
    TradeItem(
      title: 'Sell HDFC',
      subtitle: 'Feb 23, 2026 • 3:20 PM',
      amount: 5120.00,
      isBuy: false,
    ),
    TradeItem(
      title: 'Buy TCS',
      subtitle: 'Feb 22, 2026 • 11:10 AM',
      amount: -3800.00,
      isBuy: true,
    ),
    TradeItem(
      title: 'Buy MARUTI',
      subtitle: 'Feb 21, 2026 • 2:05 PM',
      amount: -1920.00,
      isBuy: true,
    ),
  ];

  static const List<ContentDraft> drafts = [
    ContentDraft(
      title: 'My New Tech Setup 2026',
      editedTime: 'Edited 2 hours ago',
      type: 'Reel',
    ),
    ContentDraft(
      title: 'The Future of AI in Design',
      editedTime: 'Edited yesterday',
      type: 'Blog',
    ),
    ContentDraft(
      title: 'Market Analysis Q1 2026',
      editedTime: 'Edited 3 days ago',
      type: 'Short',
    ),
  ];

  // Chart data points for 7 days (normalized 0-1)
  static const List<double> chartData = [0.42, 0.86, 0.73, 0.38, 0.67, 0.59, 0.78];
  // Realised P&L chart data (different curve)
  static const List<double> realisedPnlData = [0.25, 0.40, 0.55, 0.48, 0.72, 0.65, 0.88];
  static const List<String> chartLabels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  // Insights data
  static const Map<String, dynamic> insightsData = {
    'totalViews': '124.8K',
    'viewsChange': 12.0,
    'engagement': '8.4K',
    'engagementChange': 5.0,
    'followers': '32.1K',
    'followersChange': 3.2,
    'shares': '2.1K',
    'sharesChange': 8.7,
  };
}
