import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/lesson_provider.dart';
import '../../widgets/lesson_card.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    Future.microtask(() => context.read<LessonProvider>().loadLessons());
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<LessonProvider>();
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;

    return Scaffold(
      extendBodyBehindAppBar: false,
      body: Stack(
        children: [
          // ===== Nền khuông nhạc =====
          Positioned.fill(
            child: CustomPaint(
              painter: _StaffLinesPainter(
                color: primary.withValues(alpha: 0.04),
              ),
            ),
          ),

          // ===== Watermark nốt nhạc =====
          Positioned(
            top: 90,
            right: -140,
            child: Transform.rotate(
              angle: -0.2,
              child: Icon(
                Icons.music_note_rounded,
                size: 380,
                color: primary.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -90,
            child: Icon(
              Icons.headphones_rounded,
              size: 280,
              color: secondary.withValues(alpha: 0.05),
            ),
          ),
          Positioned(
            top: 260,
            left: -40,
            child: Icon(
              Icons.piano_rounded,
              size: 160,
              color: primary.withValues(alpha: 0.04),
            ),
          ),

          // ===== Nội dung =====
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, primary, secondary),
              SliverToBoxAdapter(child: _buildStatsBar(context, p, primary)),
              if (p.loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (p.lessons.isEmpty)
                SliverFillRemaining(child: _buildEmptyState(context, primary))
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  sliver: SliverList.builder(
                    itemCount: p.lessons.length,
                    itemBuilder: (_, i) {
                      final l = p.lessons[i];
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(milliseconds: 350 + i * 60),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, (1 - value) * 20),
                              child: child,
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: LessonCard(
                            title: l.title,
                            subtitle: '${l.composer} • ${l.notes.length} nốt',
                            onTap: () =>
                                context.push('/student/lesson/${l.id}'),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(
    BuildContext context,
    Color primary,
    Color secondary,
  ) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      expandedHeight: 120,
      backgroundColor: primary,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: const Text(
          'Học sinh - Bài học',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primary, secondary],
            ),
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 12, top: 10),
              child: Icon(
                Icons.queue_music_rounded,
                size: 64,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Lịch sử',
          onPressed: () => context.push('/student/history'),
          icon: const Icon(Icons.history_rounded),
        ),
        IconButton(
          tooltip: 'Hồ sơ',
          onPressed: () => context.push('/profile'),
          icon: const Icon(Icons.account_circle_rounded),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildStatsBar(BuildContext context, LessonProvider p, Color primary) {
    if (p.loading || p.lessons.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Icon(Icons.library_music_rounded, size: 18, color: primary),
          const SizedBox(width: 6),
          Text(
            '${p.lessons.length} bài học',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, Color primary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.music_off_rounded,
              size: 72,
              color: primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có bài học nào',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy quay lại sau khi giáo viên thêm bài học mới.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vẽ các dòng kẻ khuông nhạc mờ làm nền, tạo cảm giác "âm nhạc" cho màn hình.
class _StaffLinesPainter extends CustomPainter {
  final Color color;
  const _StaffLinesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2;

    const groupSpacing = 180.0;
    const lineSpacing = 10.0;

    for (
      double groupTop = 40;
      groupTop < size.height;
      groupTop += groupSpacing
    ) {
      for (int line = 0; line < 5; line++) {
        final y = groupTop + line * lineSpacing;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StaffLinesPainter oldDelegate) =>
      oldDelegate.color != color;
}
