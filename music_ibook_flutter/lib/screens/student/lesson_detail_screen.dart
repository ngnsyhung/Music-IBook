import 'dart:ui';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/lesson.dart';
import '../../models/lesson_authoring.dart';
import '../../providers/lesson_provider.dart';
import '../../providers/student_provider.dart';
import '../../utils/vietnam_time.dart';
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
    final lessonProvider = context.read<LessonProvider>();
    final studentProvider = context.read<StudentProvider>();
    Future.microtask(() {
      lessonProvider.loadLesson(widget.lessonId);
      studentProvider.loadAssignments(lessonId: widget.lessonId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lesson = context.watch<LessonProvider>().current;
    final colorScheme = Theme.of(context).colorScheme;
    final mediaSize = MediaQuery.sizeOf(context);
    final isSmallScreen = mediaSize.width < 600 || mediaSize.height < 500;

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
                              return _buildSplitView(
                                context,
                                lesson,
                                colorScheme,
                              );
                            } else {
                              return _buildTabView(
                                context,
                                lesson,
                                colorScheme,
                                isSmallScreen,
                              );
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

  Widget _buildTabView(
    BuildContext context,
    MusicLesson lesson,
    ColorScheme colorScheme,
    bool isSmallScreen,
  ) {
    return DefaultTabController(
      length: 2,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
                    padding: EdgeInsets.fromLTRB(
                      16,
                      4,
                      16,
                      isSmallScreen ? 70 : 120,
                    ),
                    children: [_buildPracticeContent(context, lesson)],
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      4,
                      16,
                      isSmallScreen ? 70 : 120,
                    ),
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

  Widget _buildPracticeContent(BuildContext context, MusicLesson lesson) {
    final student = context.watch<StudentProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        _AssignmentsCard(
          assignments: student.assignments,
          loading: student.assignmentsLoading,
          error: student.assignmentsError,
          onPractice: (assignment) => _openPractice(
            lesson,
            sectionId: assignment.lessonSectionId,
            exerciseId: assignment.lessonExerciseId,
            assignmentId: assignment.id,
          ),
        ),
        const SizedBox(height: 16),
        _PracticeSectionsCard(
          sections: lesson.sections,
          onPractice: (section) => _openPractice(lesson, sectionId: section.id),
        ),
        const SizedBox(height: 16),
        _ExercisesCard(
          exercises: lesson.exercises,
          onPractice: (exercise) => _openPractice(
            lesson,
            sectionId: exercise.lessonSectionId,
            exerciseId: exercise.id,
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Ghi chú của giáo viên',
          content: lesson.annotations.isEmpty
              ? 'Giáo viên chưa thêm ghi chú cho bài học.'
              : lesson.annotations
                    .map(
                      (annotation) =>
                          'Beat ${annotation.startBeat.toStringAsFixed(0)}: ${annotation.text}',
                    )
                    .join('\n'),
          icon: Icons.tips_and_updates_rounded,
          color: colorScheme.secondary,
        ),
      ],
    );
  }

  void _openPractice(
    MusicLesson lesson, {
    int? sectionId,
    int? exerciseId,
    int? assignmentId,
  }) {
    final query = <String, String>{
      if (sectionId != null) 'sectionId': '$sectionId',
      if (exerciseId != null) 'exerciseId': '$exerciseId',
      if (assignmentId != null) 'assignmentId': '$assignmentId',
    };
    context.push(
      Uri(
        path: '/student/practice/${lesson.id}',
        queryParameters: query.isEmpty ? null : query,
      ).toString(),
    );
  }

  Widget _buildSplitView(
    BuildContext context,
    MusicLesson lesson,
    ColorScheme colorScheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
              children: [_buildPracticeContent(context, lesson)],
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
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
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
  final MusicLesson lesson;
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
                      lesson.composer.isEmpty
                          ? '${lesson.notes.length} nốt nhạc · ${lesson.tempo} BPM'
                          : lesson.composer,
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

class _AssignmentsCard extends StatelessWidget {
  final List<StudentAssignmentItem> assignments;
  final bool loading;
  final String? error;
  final ValueChanged<StudentAssignmentItem> onPractice;

  const _AssignmentsCard({
    required this.assignments,
    required this.loading,
    required this.error,
    required this.onPractice,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.tertiary;
    return _SectionCard(
      title: 'Bài tập bổ sung (${assignments.length})',
      icon: Icons.assignment_rounded,
      color: color,
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Text('Không tải được bài tập bổ sung: $error')
          : assignments.isEmpty
          ? const Text('Giáo viên chưa giao bài tập bổ sung.')
          : Column(
              children: [
                for (final assignment in assignments)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      assignment.isCompleted
                          ? Icons.check_circle
                          : Icons.assignment_outlined,
                      color: assignment.isCompleted ? Colors.green : color,
                    ),
                    title: Text(
                      assignment.exerciseTitle ??
                          assignment.sectionTitle ??
                          'Luyện toàn bộ bài',
                    ),
                    subtitle: Text(
                      [
                        if (assignment.message.isNotEmpty) assignment.message,
                        if (assignment.dueAtUtc != null)
                          'Hạn: ${VietnamTime.format(assignment.dueAtUtc!)}',
                      ].join('\n'),
                    ),
                    trailing: IconButton.filledTonal(
                      tooltip: assignment.isCompleted ? 'Luyện lại' : 'Bắt đầu',
                      onPressed: () => onPractice(assignment),
                      icon: Icon(
                        assignment.isCompleted
                            ? Icons.replay
                            : Icons.play_arrow,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _PracticeSectionsCard extends StatelessWidget {
  final List<LessonSection> sections;
  final ValueChanged<LessonSection> onPractice;

  const _PracticeSectionsCard({
    required this.sections,
    required this.onPractice,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return _SectionCard(
      title: 'Đoạn luyện tập (${sections.length})',
      icon: Icons.menu_book_rounded,
      color: color,
      child: sections.isEmpty
          ? const Text('Giáo viên chưa chia bài thành đoạn luyện tập.')
          : Column(
              children: [
                for (final section in sections)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(section.title),
                    subtitle: Text(
                      'Beat ${section.startBeat.toStringAsFixed(0)}–${section.endBeat.toStringAsFixed(0)} · '
                      '${section.difficulty} · ${section.hand} · ${section.defaultTempo} BPM',
                    ),
                    trailing: IconButton.filled(
                      tooltip: 'Luyện đoạn này',
                      onPressed: () => onPractice(section),
                      icon: const Icon(Icons.play_arrow),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _ExercisesCard extends StatelessWidget {
  final List<LessonExercise> exercises;
  final ValueChanged<LessonExercise> onPractice;

  const _ExercisesCard({required this.exercises, required this.onPractice});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.secondary;
    return _SectionCard(
      title: 'Bài tập trong bài (${exercises.length})',
      icon: Icons.extension_rounded,
      color: color,
      child: exercises.isEmpty
          ? const Text('Giáo viên chưa thiết kế bài tập riêng.')
          : Column(
              children: [
                for (final exercise in exercises)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(exercise.title),
                    subtitle: Text(
                      '${_exerciseLabel(exercise.type)}'
                      '${exercise.instruction.isEmpty ? '' : '\n${exercise.instruction}'}',
                    ),
                    trailing: IconButton.filledTonal(
                      tooltip: 'Mở bài tập',
                      onPressed: () => onPractice(exercise),
                      icon: const Icon(Icons.play_arrow),
                    ),
                  ),
              ],
            ),
    );
  }

  static String _exerciseLabel(String type) => switch (type) {
    'NoteReading' => 'Luyện đọc nốt',
    'Rhythm' => 'Luyện tiết tấu',
    'MissingNote' => 'Điền nốt còn thiếu',
    'ChordRecognition' => 'Nhận diện hợp âm',
    'Dictation' => 'Nghe rồi chép nhạc',
    'Metronome' => 'Chơi với metronome',
    _ => type,
  };
}

/// Card used to display a titled block of content (theory / practice guide).
class _SectionCard extends StatelessWidget {
  final String title;
  final String? content;
  final Widget? child;
  final IconData icon;
  final Color color;

  const _SectionCard({
    required this.title,
    this.content,
    this.child,
    required this.icon,
    required this.color,
  }) : assert(content != null || child != null);

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
            if (child != null)
              child!
            else
              Text(
                content!,
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

  const _BottomDock({
    required this.onPractice,
    required this.onExam,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dockWidth = min(MediaQuery.sizeOf(context).width - 24, 520.0);

    return SizedBox(
      width: dockWidth,
      child: Container(
        margin: EdgeInsets.only(bottom: isSmallScreen ? 4 : 8),
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
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: isSmallScreen ? 14 : 15,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 24),
        ),
        elevation: 4,
        shadowColor: color.withValues(alpha: 0.5),
      ),
    );
  }
}
