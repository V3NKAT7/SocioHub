import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Streamline-style SVG icons for the app.
/// Each icon is a 24x24 viewbox SVG outline icon inspired by Streamline HQ.
class StreamlineIcons {
  StreamlineIcons._();

  // ─── TAB BAR ICONS ──────────────────────────────────────
  static const String investments = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M3 17L9 11L13 15L21 7" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M17 7H21V11" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
</svg>''';

  static const String create = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="1.8"/>
  <path d="M12 8V16M8 12H16" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
</svg>''';

  static const String social = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="3" y="3" width="7" height="7" rx="1.5" stroke="currentColor" stroke-width="1.8"/>
  <rect x="14" y="3" width="7" height="7" rx="1.5" stroke="currentColor" stroke-width="1.8"/>
  <rect x="3" y="14" width="7" height="7" rx="1.5" stroke="currentColor" stroke-width="1.8"/>
  <rect x="14" y="14" width="7" height="7" rx="1.5" stroke="currentColor" stroke-width="1.8"/>
</svg>''';

  static const String profile = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="8" r="4" stroke="currentColor" stroke-width="1.8"/>
  <path d="M5 20C5 16.6863 8.13401 14 12 14C15.866 14 19 16.6863 19 20" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
</svg>''';

  // ─── SECTOR / PORTFOLIO ICONS ────────────────────────────
  static const String computer = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="2" y="3" width="20" height="14" rx="2" stroke="currentColor" stroke-width="1.8"/>
  <path d="M8 21H16" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M12 17V21" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
</svg>''';

  static const String pill = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="8" y="2" width="8" height="20" rx="4" stroke="currentColor" stroke-width="1.8"/>
  <path d="M8 12H16" stroke="currentColor" stroke-width="1.8"/>
</svg>''';

  static const String car = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M5 17H3V13L5 8H19L21 13V17H19" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
  <circle cx="7" cy="17" r="2" stroke="currentColor" stroke-width="1.8"/>
  <circle cx="17" cy="17" r="2" stroke="currentColor" stroke-width="1.8"/>
  <path d="M9 17H15" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M3 13H21" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
</svg>''';

  static const String bank = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M3 21H21" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M5 21V11" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M9 21V11" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M15 21V11" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M19 21V11" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M12 3L3 9H21L12 3Z" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
</svg>''';

  static const String chartLine = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M3 3V21H21" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M7 15L11 9L15 13L21 5" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
</svg>''';

  static const String goldBars = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M4 20H20L22 14H2L4 20Z" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M6 14H18L20 8H4L6 14Z" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M9 8H15L16 4H8L9 8Z" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
</svg>''';

  /// Helper to build an SvgPicture from inline SVG string
  static Widget icon(
    String svgData, {
    double size = 24,
    Color color = Colors.white,
  }) {
    // Replace currentColor with the actual color hex
    final colorHex = '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
    final processedSvg = svgData.replaceAll('currentColor', colorHex);
    return SvgPicture.string(
      processedSvg,
      width: size,
      height: size,
    );
  }
}
