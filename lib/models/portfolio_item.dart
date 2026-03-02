import 'package:flutter/material.dart';

class PortfolioItem {
  final String name;
  final String svgIcon;
  final double value;
  final double changePercent;
  final Color color;
  final Color bgColor;

  const PortfolioItem({
    required this.name,
    required this.svgIcon,
    required this.value,
    required this.changePercent,
    required this.color,
    required this.bgColor,
  });
}

class TradeItem {
  final String title;
  final String subtitle;
  final double amount;
  final bool isBuy;

  const TradeItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isBuy,
  });
}

class ContentDraft {
  final String title;
  final String editedTime;
  final String type;
  final String? imageUrl;

  const ContentDraft({
    required this.title,
    required this.editedTime,
    required this.type,
    this.imageUrl,
  });
}
