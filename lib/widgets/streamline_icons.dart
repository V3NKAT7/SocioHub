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

// ─── Brand / Platform SVG Icons ────────────────────────────────────────────
class BrandIcons {
  BrandIcons._();

  /// Instagram logo (rounded-square camera)
  static const String instagram = '''
<svg viewBox="0 0 24 24" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
  <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z"/>
</svg>''';

  /// YouTube play-button logo
  static const String youtube = '''
<svg viewBox="0 0 24 24" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
  <path d="M23.495 6.205a3.007 3.007 0 0 0-2.088-2.088c-1.87-.501-9.396-.501-9.396-.501s-7.507-.01-9.396.501A3.007 3.007 0 0 0 .527 6.205a31.247 31.247 0 0 0-.522 5.805 31.247 31.247 0 0 0 .522 5.783 3.007 3.007 0 0 0 2.088 2.088c1.868.502 9.396.502 9.396.502s7.506 0 9.396-.502a3.007 3.007 0 0 0 2.088-2.088 31.247 31.247 0 0 0 .5-5.783 31.247 31.247 0 0 0-.5-5.805zM9.609 15.601V8.408l6.264 3.602z"/>
</svg>''';

  /// X (Twitter) logo
  static const String xTwitter = '''
<svg viewBox="0 0 24 24" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
  <path d="M18.901 1.153h3.68l-8.04 9.19L24 22.846h-7.406l-5.8-7.584-6.638 7.584H.474l8.6-9.83L0 1.154h7.594l5.243 6.932ZM17.61 20.644h2.039L6.486 3.24H4.298Z"/>
</svg>''';

  /// Pen-nib icon for blog writing
  static const String penNib = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M14.5 2.5L20 8l-10 10H4v-6L14.5 2.5z" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M14.5 2.5L17.5 5.5" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M4 18l2-2" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M2 22h6" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
</svg>''';

  /// Helper — same interface as StreamlineIcons.icon()
  static Widget icon(String svgData, {double size = 24, Color color = Colors.white}) {
    final hex = '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
    final svg = svgData.replaceAll('currentColor', hex);
    return SvgPicture.string(svg, width: size, height: size);
  }
}
