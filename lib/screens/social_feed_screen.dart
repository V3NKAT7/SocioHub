import 'package:flutter/material.dart';
import '../models/social_post.dart';
import '../theme/app_theme.dart';

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  SocialPlatform? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  List<SocialPost> get _filteredPosts {
    if (_selectedFilter == null) return MockSocialData.posts;
    return MockSocialData.posts
        .where((p) => p.platform == _selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        children: [
          _buildHeader(context),
          _buildFilterChips(context),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              itemCount: _filteredPosts.length,
              itemBuilder: (context, index) {
                final post = _filteredPosts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildPostCard(context, post),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.grid_view_rounded,
                color: AppTheme.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Unified Feed',
              style: TextStyle(
                color: AppTheme.textPrimary(ctx),
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ),
          _headerButton(ctx, Icons.notifications_outlined, badge: true),
          const SizedBox(width: 8),
          _headerButton(ctx, Icons.settings_outlined),
        ],
      ),
    );
  }

  Widget _headerButton(BuildContext ctx, IconData icon, {bool badge = false}) {
    return Stack(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.surface(ctx),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.textSecondary(ctx), size: 20),
        ),
        if (badge)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChips(BuildContext ctx) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          _filterChip(ctx, null, 'All', Icons.dashboard_rounded),
          const SizedBox(width: 8),
          _filterChip(
              ctx, SocialPlatform.youtube, 'YouTube', Icons.play_circle_fill),
          const SizedBox(width: 8),
          _filterChip(
              ctx, SocialPlatform.instagram, 'Instagram', Icons.camera_alt),
          const SizedBox(width: 8),
          _filterChip(ctx, SocialPlatform.x, 'X', Icons.tag),
          const SizedBox(width: 8),
          _filterChip(ctx, SocialPlatform.blog, 'Blogs', Icons.rss_feed),
        ],
      ),
    );
  }

  Widget _filterChip(
      BuildContext ctx, SocialPlatform? platform, String label, IconData icon) {
    final isSelected = _selectedFilter == platform;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = platform),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surface(ctx),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border(ctx),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : AppTheme.textSecondary(ctx)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : AppTheme.textSecondary(ctx),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(BuildContext ctx, SocialPost post) {
    if (post.isVideo) return _buildVideoPost(ctx, post);
    if (post.imageUrl != null) return _buildImagePost(ctx, post);
    return _buildTextPost(ctx, post);
  }

  Widget _buildTextPost(BuildContext ctx, SocialPost post) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface(ctx),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(ctx)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _postHeader(ctx, post),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text(
              post.content,
              style: TextStyle(
                color: AppTheme.textPrimary(ctx).withOpacity(0.85),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          _postActions(ctx, post),
        ],
      ),
    );
  }

  Widget _buildImagePost(BuildContext ctx, SocialPost post) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface(ctx),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(ctx)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _postHeader(ctx, post),
          Container(
            height: 280,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  post.platformColor.withOpacity(0.3),
                  AppTheme.primary.withOpacity(0.2),
                  AppTheme.surface(ctx),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 40,
                  left: 40,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.textPrimary(ctx).withOpacity(0.05),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 30,
                  right: 30,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: AppTheme.textPrimary(ctx).withOpacity(0.05),
                    ),
                  ),
                ),
                Center(
                  child: Icon(Icons.image_rounded,
                      size: 48,
                      color: AppTheme.textSecondary(ctx).withOpacity(0.3)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Text(
              post.content,
              style: TextStyle(
                color: AppTheme.textPrimary(ctx),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          _postActions(ctx, post),
        ],
      ),
    );
  }

  Widget _buildVideoPost(BuildContext ctx, SocialPost post) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface(ctx),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(ctx)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.surface(ctx),
                  AppTheme.primary.withOpacity(0.15),
                  AppTheme.surface(ctx),
                ],
              ),
            ),
            child: Stack(
              children: [
                ...List.generate(5, (i) {
                  return Positioned(
                    left: 0,
                    right: 0,
                    top: 30.0 + i * 35,
                    child: Container(
                        height: 1,
                        color:
                            AppTheme.textPrimary(ctx).withOpacity(0.03)),
                  );
                }),
                Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF0000),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF0000).withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.play_arrow,
                        color: Colors.white, size: 32),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(post.videoDuration ?? '',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.surface(ctx),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.border(ctx)),
                  ),
                  child: Center(
                    child: Text(post.authorName[0],
                        style: TextStyle(
                            color: AppTheme.textPrimary(ctx),
                            fontWeight: FontWeight.w600,
                            fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.videoTitle ?? '',
                          style: TextStyle(
                              color: AppTheme.textPrimary(ctx),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 1.3),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _platformBadge(ctx, post),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '${post.authorName} • ${post.videoViews} • ${post.timeAgo}',
                              style: TextStyle(
                                  color: AppTheme.textSecondary(ctx),
                                  fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _postActions(ctx, post),
        ],
      ),
    );
  }

  Widget _postHeader(BuildContext ctx, SocialPost post) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: post.platform == SocialPlatform.instagram
                  ? const LinearGradient(colors: [
                      Color(0xFFFCAF45),
                      Color(0xFFE1306C),
                      Color(0xFF833AB4)
                    ])
                  : null,
              color: post.platform != SocialPlatform.instagram
                  ? AppTheme.surface(ctx)
                  : null,
            ),
            padding: EdgeInsets.all(
                post.platform == SocialPlatform.instagram ? 2 : 0),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.3),
                border: post.platform == SocialPlatform.instagram
                    ? Border.all(color: AppTheme.bg(ctx), width: 2)
                    : null,
              ),
              child: Center(
                child: Text(post.authorName[0],
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(post.authorName,
                        style: TextStyle(
                            color: AppTheme.textPrimary(ctx),
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    Text(post.authorHandle,
                        style: TextStyle(
                            color: AppTheme.textSecondary(ctx),
                            fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _platformBadge(ctx, post),
                    const SizedBox(width: 6),
                    Text(post.timeAgo,
                        style: TextStyle(
                            color: AppTheme.textSecondary(ctx),
                            fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.more_horiz,
              color: AppTheme.textSecondary(ctx), size: 20),
        ],
      ),
    );
  }

  Widget _platformBadge(BuildContext ctx, SocialPost post) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: post.platformColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(post.platformIcon, size: 12, color: post.platformColor),
          const SizedBox(width: 4),
          Text(post.platformName,
              style: TextStyle(
                  color: post.platformColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _postActions(BuildContext ctx, SocialPost post) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.textPrimary(ctx).withOpacity(0.02),
        border: Border(
          top: BorderSide(color: AppTheme.border(ctx)),
        ),
      ),
      child: Row(
        children: [
          _actionButton(
            ctx,
            post.isLiked ? Icons.favorite : Icons.favorite_outline,
            post.stats['likes'] ?? '0',
            color: post.isLiked ? const Color(0xFFF43F5E) : null,
          ),
          const SizedBox(width: 20),
          _actionButton(
              ctx, Icons.chat_bubble_outline, post.stats['comments'] ?? '0'),
          const SizedBox(width: 20),
          if (post.stats.containsKey('shares'))
            _actionButton(
                ctx, Icons.share_outlined, post.stats['shares']!),
          const Spacer(),
          Icon(Icons.bookmark_outline,
              color: AppTheme.textSecondary(ctx), size: 20),
        ],
      ),
    );
  }

  Widget _actionButton(BuildContext ctx, IconData icon, String count,
      {Color? color}) {
    return Row(
      children: [
        Icon(icon,
            size: 18, color: color ?? AppTheme.textSecondary(ctx)),
        const SizedBox(width: 6),
        Text(count,
            style: TextStyle(
                color: color ?? AppTheme.textSecondary(ctx),
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
