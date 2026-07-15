import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/lesson_provider.dart';
import '../../widgets/music_staff.dart';

class LessonDetailScreen extends StatefulWidget {
  final int lessonId;
  const LessonDetailScreen({super.key, required this.lessonId});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
          () => context.read<LessonProvider>().loadLesson(widget.lessonId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lesson = context
        .watch<LessonProvider>()
        .current;
    final colorScheme = Theme
        .of(context)
        .colorScheme;
    final isSmallScreen = MediaQuery
        .of(context)
        .size
        .height < 500;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          lesson?.title ?? 'Bài học',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: lesson == null
          ? null
          : _BottomDock(
        onPractice: () => context.push('/student/practice/${lesson.id}'),
        onExam: () => context.push('/student/exam/${lesson.id}'),
        isSmallScreen: isSmallScreen,
      ),
      body: lesson == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          // Gradient background behind everything
          Container(
            height: isSmallScreen ? 170 : 280,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.85),
                  colorScheme.secondary.withValues(alpha: 0.8),
                ],
              ),
            ),
          ),

          // Watermark pattern
          Positioned(
            top: -20,
            right: -40,
            child: Transform.rotate(
              angle: 0.2,
              child: Icon(
                Icons.music_note_rounded,
                size: 260,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            top: 140,
            left: -50,
            child: Transform.rotate(
              angle: -0.15,
              child: Icon(
                Icons.music_note_rounded,
                size: 160,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                SizedBox(height: isSmallScreen ? 16 : kToolbarHeight - 8),

                // Lesson info card
                if (!isSmallScreen)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _LessonInfoCard(lesson: lesson),
                  ),

                if (!isSmallScreen) const SizedBox(height: 12),

                // Content area with pill TabBar or Split View
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth >= 900) {
                        return _buildSplitView(context, lesson, colorScheme);
                      } else {
                        return _buildTabView(context, lesson, colorScheme, isSmallScreen);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabView(BuildContext context, dynamic lesson,
      ColorScheme colorScheme, bool isSmallScreen) {
    return DefaultTabController(
      length: 2,
      child: Container(
        decoration: BoxDecoration(
          color: Theme
              .of(context)
              .colorScheme
              .surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _PillTabBar(colorScheme: colorScheme),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  ListView(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, isSmallScreen ? 70 : 120),
                    children: [
                      _SectionCard(
                        title: lesson.theoryTitle,
                        content: lesson.theoryContent,
                        icon: Icons.menu_book_rounded,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Hướng dẫn luyện tập',
                        content: lesson.practiceGuide,
                        icon: Icons.tips_and_updates_rounded,
                        color: colorScheme.secondary,
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, isSmallScreen ? 70 : 120),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: MusicStaff(lesson: lesson),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitView(BuildContext context, dynamic lesson,
      ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: Theme
            .of(context)
            .colorScheme
            .surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Theory Side
          Expanded(
            flex: 4,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 12, 120),
              children: [
                _SectionCard(
                  title: lesson.theoryTitle,
                  content: lesson.theoryContent,
                  icon: Icons.menu_book_rounded,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Hướng dẫn luyện tập',
                  content: lesson.practiceGuide,
                  icon: Icons.tips_and_updates_rounded,
                  color: colorScheme.secondary,
                ),
              ],
            ),
          ),
          // Divider
          Container(
            width: 1,
            margin: const EdgeInsets.symmetric(vertical: 24),
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          // Music Staff Side
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 24, 24, 120),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                            alpha: 0.5)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: MusicStaff(lesson: lesson),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lesson summary card shown at the top of the screen, over the gradient header.
class _LessonInfoCard extends StatelessWidget {
  final dynamic lesson;
  const _LessonInfoCard({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(Icons.piano, color: colorScheme.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lesson.theoryTitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Material 3 style pill-shaped TabBar.
class _PillTabBar extends StatelessWidget {
  final ColorScheme colorScheme;
  const _PillTabBar({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TabBar(
        indicator: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: colorScheme.onPrimary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14.5,
        ),
        splashBorderRadius: BorderRadius.circular(26),
        tabs: const [
          Tab(
            height: 48,
            icon: Icon(Icons.menu_book_rounded, size: 20),
            text: 'Lý thuyết',
          ),
          Tab(
            height: 48,
            icon: Icon(Icons.music_note_rounded, size: 20),
            text: 'Bản nhạc',
          ),
        ],
      ),
    );
  }
}

/// Card used to display a titled block of content (theory / practice guide).
class _SectionCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color color;

  const _SectionCard({
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 600;
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(isNarrow ? 16 : 24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.12), width: 1.5),
      ),
      child: Padding(
        padding: EdgeInsets.all(isNarrow ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isNarrow ? 8 : 10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(isNarrow ? 10 : 14),
                  ),
                  child: Icon(icon, color: color, size: isNarrow ? 18 : 22),
                ),
                SizedBox(width: isNarrow ? 10 : 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: isNarrow ? 17 : 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isNarrow ? 12 : 16),
            Text(
              content,
              style: TextStyle(
                fontSize: isNarrow ? 14 : 16,
                height: isNarrow ? 1.4 : 1.6,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating pill-shaped dock holding the two primary action buttons.
class _BottomDock extends StatelessWidget {
  final VoidCallback onPractice;
  final VoidCallback onExam;
  final bool isSmallScreen;

  const _BottomDock({required this.onPractice, required this.onExam, this.isSmallScreen = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.only(left: 16, right: 16, bottom: isSmallScreen ? 4 : 8),
      padding: EdgeInsets.all(isSmallScreen ? 6 : 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: _DockButton(
              label: 'Luyện tập',
              icon: Icons.piano,
              color: colorScheme.primary,
              onPressed: onPractice,
              isSmallScreen: isSmallScreen,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _DockButton(
              label: 'Kiểm tra',
              icon: Icons.quiz,
              color: colorScheme.secondary,
              onPressed: onExam,
              isSmallScreen: isSmallScreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool isSmallScreen;

  const _DockButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: isSmallScreen ? 20 : 22),
      label: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmallScreen ? 14 : 15),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 24)),
        elevation: 4,
        shadowColor: color.withValues(alpha: 0.5),
      ),
    );
  }
}
