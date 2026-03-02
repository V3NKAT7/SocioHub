import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum SocialPlatform { x, instagram, youtube, blog }

class SocialPost {
  final String authorName;
  final String authorHandle;
  final SocialPlatform platform;
  final String timeAgo;
  final String content;
  final String? imageUrl;
  final bool isVideo;
  final String? videoDuration;
  final String? videoTitle;
  final String? videoViews;
  final Map<String, String> stats; // likes, comments, shares
  final bool isLiked;

  const SocialPost({
    required this.authorName,
    required this.authorHandle,
    required this.platform,
    required this.timeAgo,
    required this.content,
    this.imageUrl,
    this.isVideo = false,
    this.videoDuration,
    this.videoTitle,
    this.videoViews,
    this.stats = const {},
    this.isLiked = false,
  });

  String get platformName {
    switch (platform) {
      case SocialPlatform.x:
        return 'X';
      case SocialPlatform.instagram:
        return 'Instagram';
      case SocialPlatform.youtube:
        return 'YouTube';
      case SocialPlatform.blog:
        return 'Blog';
    }
  }

  Color get platformColor {
    switch (platform) {
      case SocialPlatform.x:
        return Colors.white;
      case SocialPlatform.instagram:
        return const Color(0xFFE1306C);
      case SocialPlatform.youtube:
        return const Color(0xFFFF0000);
      case SocialPlatform.blog:
        return AppTheme.emerald;
    }
  }

  IconData get platformIcon {
    switch (platform) {
      case SocialPlatform.x:
        return Icons.tag;
      case SocialPlatform.instagram:
        return Icons.camera_alt;
      case SocialPlatform.youtube:
        return Icons.play_circle_fill;
      case SocialPlatform.blog:
        return Icons.rss_feed;
    }
  }
}

class MockSocialData {
  static const List<SocialPost> posts = [
    SocialPost(
      authorName: 'Alex Rivera',
      authorHandle: '@arivera',
      platform: SocialPlatform.x,
      timeAgo: '2h ago',
      content:
          'Exploring the intersection of SocioTech and decentralised identity today. The future is looking bright for privacy-first social layers. 🚀 #web3 #privacy',
      stats: {'likes': '1.2k', 'comments': '84', 'shares': '45'},
    ),
    SocialPost(
      authorName: 'DesignFlow',
      authorHandle: '@designflow',
      platform: SocialPlatform.instagram,
      timeAgo: '5h ago',
      content: 'New UI system preview! 🎨',
      imageUrl: 'instagram_post',
      stats: {'likes': '2.5k', 'comments': '112', 'shares': '94'},
      isLiked: true,
    ),
    SocialPost(
      authorName: 'TechInsider',
      authorHandle: '@techinsider',
      platform: SocialPlatform.youtube,
      timeAgo: '1 day ago',
      content: '',
      isVideo: true,
      videoDuration: '12:45',
      videoTitle: 'Mastering SocioTech Architecture: A 2026 Deep Dive',
      videoViews: '1.2M views',
      stats: {'likes': '45k', 'comments': '3.2k'},
    ),
    SocialPost(
      authorName: 'Alex Rivera',
      authorHandle: '@arivera',
      platform: SocialPlatform.blog,
      timeAgo: '2 days ago',
      content:
          'The complete guide to building modular investment platforms with real-time portfolio tracking and social integration layers...',
      stats: {'likes': '892', 'comments': '56', 'shares': '128'},
    ),
    SocialPost(
      authorName: 'MarketPulse',
      authorHandle: '@marketpulse',
      platform: SocialPlatform.x,
      timeAgo: '4h ago',
      content:
          'IT sector up 4.8% this week 📈 Banking stocks showing strong momentum. Pharma steady with +1.2% gains. What\'s your top pick? #investing #markets',
      stats: {'likes': '3.4k', 'comments': '267', 'shares': '189'},
    ),
    SocialPost(
      authorName: 'CreativeStudio',
      authorHandle: '@creativestudio',
      platform: SocialPlatform.instagram,
      timeAgo: '8h ago',
      content: 'Behind the scenes of our latest reel shoot 🎬✨',
      imageUrl: 'bts_reel',
      stats: {'likes': '5.1k', 'comments': '324', 'shares': '201'},
    ),
    SocialPost(
      authorName: 'FinanceGuru',
      authorHandle: '@financeguru',
      platform: SocialPlatform.youtube,
      timeAgo: '3 days ago',
      content: '',
      isVideo: true,
      videoDuration: '8:32',
      videoTitle: 'Portfolio Diversification: IT vs Pharma vs Banking — Which Wins?',
      videoViews: '892K views',
      stats: {'likes': '28k', 'comments': '1.8k'},
    ),
  ];
}
