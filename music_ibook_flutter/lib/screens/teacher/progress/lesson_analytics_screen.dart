import 'dart:math';

import 'package:flutter/material.dart';

import '../../../models/lesson.dart';
import '../../../services/lesson_service.dart';
import '../../../services/teacher_service.dart';
import '../../../utils/vietnam_time.dart';

class LessonAnalyticsScreen extends StatefulWidget {
  final int studentId;
  final int lessonId;

  const LessonAnalyticsScreen({
    super.key,
    required this.studentId,
    required this.lessonId,
  });

  @override
  State<LessonAnalyticsScreen> createState() => _LessonAnalyticsScreenState();
}

class _LessonAnalyticsScreenState extends State<LessonAnalyticsScreen> {
  final _teacherService = TeacherService();
  bool _loading = true;
  String? _error;
  LessonAnalytics? _analytics;
  MusicLesson? _lesson;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await Future.wait([
        _teacherService.getLessonAnalytics(widget.studentId, widget.lessonId),
        LessonService().getById(widget.lessonId),
      ]);
      if (!mounted) return;
      setState(() {
        _analytics = result[0] as LessonAnalytics;
        _lesson = result[1] as MusicLesson;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _assignExtraWork() async {
    final lesson = _lesson;
    if (lesson == null) return;
    final message = TextEditingController();
    int? sectionId;
    int? exerciseId;
    final assigned = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Giao bài tập bổ sung'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int?>(
                  initialValue: sectionId,
                  decoration: const InputDecoration(
                    labelText: 'Đoạn luyện tập',
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Toàn bộ bài học'),
                    ),
                    ...lesson.sections
                        .where((section) => section.id != null)
                        .map(
                          (section) => DropdownMenuItem<int?>(
                            value: section.id,
                            child: Text(section.title),
                          ),
                        ),
                  ],
                  onChanged: (value) => setDialogState(() => sectionId = value),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int?>(
                  initialValue: exerciseId,
                  decoration: const InputDecoration(labelText: 'Bài tập mẫu'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Chỉ giao đoạn luyện tập'),
                    ),
                    ...lesson.exercises
                        .where((exercise) => exercise.id != null)
                        .map(
                          (exercise) => DropdownMenuItem<int?>(
                            value: exercise.id,
                            child: Text(exercise.title),
                          ),
                        ),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => exerciseId = value),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: message,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Lời nhắn cho học sinh',
                    hintText: 'Ví dụ: Luyện chậm ở 80 BPM và chú ý ngón số 3.',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  await _teacherService.createAssignment(
                    studentId: widget.studentId,
                    lessonId: widget.lessonId,
                    lessonSectionId: sectionId,
                    lessonExerciseId: exerciseId,
                    message: message.text.trim(),
                  );
                  if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text('Không thể giao bài: $e')),
                    );
                  }
                }
              },
              child: const Text('Giao bài'),
            ),
          ],
        ),
      ),
    );
    message.dispose();
    if (assigned == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Phân tích luyện tập')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _analytics == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Phân tích luyện tập')),
        body: Center(child: Text('Không tải được dữ liệu: $_error')),
      );
    }

    final analytics = _analytics!;
    final sessions = analytics.sessions;
    final bestAccuracy = sessions.isEmpty
        ? 0.0
        : sessions.map((session) => session.accuracy).reduce(max);
    final latest = sessions.isEmpty ? null : sessions.last;

    return Scaffold(
      appBar: AppBar(
        title: Text(_lesson?.title ?? 'Phân tích luyện tập'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _assignExtraWork,
        icon: const Icon(Icons.assignment_add),
        label: const Text('Giao bổ sung'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 92),
        children: [
          _SummaryCard(
            sessionCount: sessions.length,
            bestAccuracy: bestAccuracy,
            latestAccuracy: latest?.accuracy ?? 0,
          ),
          const SizedBox(height: 16),
          Text(
            'So sánh các lần luyện tập',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: sessions.isEmpty
                  ? const _EmptyState(
                      'Học sinh chưa có lượt luyện nào cho bài này.',
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 160,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: _AccuracyChartPainter(sessions),
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final session in sessions.reversed.take(5))
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              session.isExam
                                  ? Icons.quiz_outlined
                                  : Icons.piano_outlined,
                            ),
                            title: Text(
                              '${session.accuracy.toStringAsFixed(1)}% chính xác · ${session.score} điểm',
                            ),
                            subtitle: Text(
                              '${session.correctCount} đúng · ${session.wrongCount} sai · ${_formatDate(session.startedAt)}',
                            ),
                          ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Nốt cần luyện thêm',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: analytics.errorNotes.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: _EmptyState('Chưa có nốt sai được ghi nhận.'),
                  )
                : Column(
                    children: [
                      for (final error in analytics.errorNotes)
                        ListTile(
                          leading: CircleAvatar(child: Text(error.note)),
                          title: Text(
                            '${error.errorCount} lỗi ở nốt ${error.note}',
                          ),
                          subtitle: Text(
                            '${error.wrongPitchCount} sai cao độ · ${error.timingErrorCount} lệch nhịp',
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          Text('Bài đã giao', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: analytics.assignments.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: _EmptyState('Chưa giao bài tập bổ sung.'),
                  )
                : Column(
                    children: [
                      for (final assignment in analytics.assignments)
                        ListTile(
                          leading: Icon(
                            assignment.isCompleted
                                ? Icons.check_circle
                                : Icons.assignment_outlined,
                          ),
                          title: Text(
                            assignment.exerciseTitle ??
                                assignment.sectionTitle ??
                                'Bài học bổ sung',
                          ),
                          subtitle: Text(
                            assignment.message.isEmpty
                                ? 'Không có lời nhắn'
                                : assignment.message,
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int sessionCount;
  final double bestAccuracy;
  final double latestAccuracy;
  const _SummaryCard({
    required this.sessionCount,
    required this.bestAccuracy,
    required this.latestAccuracy,
  });

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.primaryContainer,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Metric(value: '$sessionCount', label: 'lần luyện'),
          _Metric(
            value: '${bestAccuracy.toStringAsFixed(0)}%',
            label: 'tốt nhất',
          ),
          _Metric(
            value: '${latestAccuracy.toStringAsFixed(0)}%',
            label: 'gần nhất',
          ),
        ],
      ),
    ),
  );
}

class _Metric extends StatelessWidget {
  final String value;
  final String label;
  const _Metric({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
      Text(label),
    ],
  );
}

class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.bodyMedium);
}

class _AccuracyChartPainter extends CustomPainter {
  final List<PracticeSessionTrend> sessions;
  _AccuracyChartPainter(this.sessions);

  @override
  void paint(Canvas canvas, Size size) {
    const left = 30.0;
    const top = 12.0;
    const bottom = 26.0;
    final chart = Rect.fromLTWH(
      left,
      top,
      size.width - left - 8,
      size.height - top - bottom,
    );
    final gridPaint = Paint()
      ..color = const Color(0x334A5568)
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = const Color(0xFF1976D2)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final pointPaint = Paint()..color = const Color(0xFF1976D2);
    final text = TextPainter(textDirection: TextDirection.ltr);

    for (final percentage in [0, 50, 100]) {
      final y = chart.bottom - chart.height * percentage / 100;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
      text.text = TextSpan(
        text: '$percentage',
        style: const TextStyle(fontSize: 10, color: Color(0xFF607D8B)),
      );
      text.layout();
      text.paint(canvas, Offset(0, y - 6));
    }
    if (sessions.length == 1) {
      final y =
          chart.bottom -
          chart.height * sessions.first.accuracy.clamp(0, 100) / 100;
      canvas.drawCircle(Offset(chart.center.dx, y), 4, pointPaint);
      return;
    }
    final path = Path();
    for (var index = 0; index < sessions.length; index++) {
      final x = chart.left + chart.width * index / (sessions.length - 1);
      final y =
          chart.bottom -
          chart.height * sessions[index].accuracy.clamp(0, 100) / 100;
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 3.5, pointPaint);
    }
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _AccuracyChartPainter oldDelegate) =>
      oldDelegate.sessions != sessions;
}

String _formatDate(DateTime value) => VietnamTime.format(value);
