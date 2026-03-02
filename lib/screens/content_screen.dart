import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/creator_tool_card.dart';

class ContentScreen extends StatefulWidget {
  const ContentScreen({super.key});

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Content Ideas (was Drafts)
  final List<Map<String, String>> _ideas = [
    {'title': '5 underrated stocks for 2026', 'source': 'AI Generated', 'time': '2h ago'},
    {'title': 'My morning routine as a creator', 'source': 'Your idea', 'time': 'Yesterday'},
    {'title': 'Portfolio rebalancing tutorial', 'source': 'AI Generated', 'time': '3d ago'},
  ];

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

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverToBoxAdapter(child: _buildHero(context)),
          SliverToBoxAdapter(child: _buildToolsGrid(context)),
          SliverToBoxAdapter(child: _buildPerformance(context)),
          SliverToBoxAdapter(child: _buildContentIdeas(context)),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.surface(ctx),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.arrow_back,
                color: AppTheme.textSecondary(ctx), size: 20),
          ),
          Expanded(
            child: Text(
              'Create New Content',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textPrimary(ctx),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.surface(ctx),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.settings_outlined,
                color: AppTheme.textSecondary(ctx), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppTheme.primary, AppTheme.purple],
            ).createShader(bounds),
            child: const Text(
              'Ready to inspire?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a format and start creating today.',
            style: TextStyle(
              color: AppTheme.textSecondary(ctx),
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsGrid(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          CreatorToolCard(
            title: 'Record\nReel',
            icon: Icons.camera_alt_rounded, // Instagram camera
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE1306C), Color(0xFFFCAF45)],
            ),
            onTap: () => _openUrl('https://www.instagram.com/create/story/'),
          ),
          CreatorToolCard(
            title: 'Upload\nShort',
            icon: Icons.play_circle_fill_rounded, // YouTube
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF0000), Color(0xFFCC0000)],
            ),
            onTap: () => _openUrl('https://www.youtube.com/upload'),
          ),
          CreatorToolCard(
            title: 'Tweet\non X',
            icon: Icons.tag_rounded, // X
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blueGrey.shade800, Colors.black87],
            ),
            onTap: () => _openUrl('https://x.com/compose/post'),
          ),
          CreatorToolCard(
            title: 'Write\nBlog',
            icon: Icons.edit_note_rounded,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.purple, AppTheme.pink],
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildPerformance(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Performance',
                  style: TextStyle(
                      color: AppTheme.textPrimary(ctx),
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              Text('View All',
                  style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 14),
          // Total Views with sparkline
          _perfCard(
            ctx,
            icon: Icons.trending_up,
            iconColor: AppTheme.primary,
            label: 'Total Views',
            value: '124.8K',
            change: 12,
            sparkData: const [0.3, 0.5, 0.45, 0.7, 0.65, 0.8, 0.9],
            sparkColor: AppTheme.primary,
          ),
          const SizedBox(height: 10),
          // Engagement with sparkline
          _perfCard(
            ctx,
            icon: Icons.favorite,
            iconColor: AppTheme.purple,
            label: 'Engagement',
            value: '8.4K',
            change: 5,
            sparkData: const [0.2, 0.35, 0.5, 0.4, 0.6, 0.55, 0.75],
            sparkColor: AppTheme.purple,
          ),
        ],
      ),
    );
  }

  Widget _perfCard(
    BuildContext ctx, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required double change,
    required List<double> sparkData,
    required Color sparkColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface(ctx),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(ctx)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: AppTheme.textSecondary(ctx), fontSize: 12)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        color: AppTheme.textPrimary(ctx),
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          // Sparkline chart
          SizedBox(
            width: 60,
            height: 30,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (sparkData.length - 1).toDouble(),
                minY: 0,
                maxY: 1,
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(sparkData.length,
                        (i) => FlSpot(i.toDouble(), sparkData[i])),
                    isCurved: true,
                    color: sparkColor,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          sparkColor.withOpacity(0.2),
                          sparkColor.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              duration: Duration.zero,
            ),
          ),
          const SizedBox(width: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_upward, color: Color(0xFF10B981), size: 14),
              Text('${change.toInt()}%',
                  style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContentIdeas(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Content Ideas',
                  style: TextStyle(
                      color: AppTheme.textPrimary(ctx),
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              GestureDetector(
                onTap: () => _showAddIdea(ctx),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, color: AppTheme.primary, size: 16),
                      const SizedBox(width: 4),
                      Text('New Idea',
                          style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._ideas.map((idea) => Padding(
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
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: idea['source'] == 'AI Generated'
                              ? AppTheme.purple.withOpacity(0.1)
                              : AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          idea['source'] == 'AI Generated'
                              ? Icons.auto_awesome
                              : Icons.lightbulb_outline,
                          color: idea['source'] == 'AI Generated'
                              ? AppTheme.purple
                              : AppTheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(idea['title']!,
                                style: TextStyle(
                                    color: AppTheme.textPrimary(ctx),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 3),
                            Text('${idea['source']} • ${idea['time']}',
                                style: TextStyle(
                                    color: AppTheme.textSecondary(ctx),
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          color: AppTheme.textSecondary(ctx), size: 20),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  void _showAddIdea(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.bg(context),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary(context).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('New Content Idea',
                  style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surface(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border(context)),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Write your idea...',
                    hintStyle:
                        TextStyle(color: AppTheme.textSecondary(context)),
                    border: InputBorder.none,
                  ),
                  style: TextStyle(color: AppTheme.textPrimary(context)),
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: const Text('AI Suggest'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Save Idea'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
