import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/lesson.dart';
import '../../../models/practice.dart';
import '../../../providers/lesson_provider.dart';
import '../../../providers/student_provider.dart';
import '../../../widgets/music_staff.dart';
import '../../../widgets/piano_keyboard.dart';
import 'package:go_router/go_router.dart';

class ExamScreen extends StatefulWidget {
  final int lessonId;
  const ExamScreen({super.key, required this.lessonId});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  MusicLesson? lesson;
  int currentIndex = 0;
  int correct = 0;
  int wrong = 0;
  final attempts = <NoteAttemptRequest>[];
  bool isPlaying = false;
  double elapsedSeconds = 0;
  Timer? timer;
  int durationSeconds = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      lesson = await context.read<LessonProvider>().loadLesson(widget.lessonId);
      setState(() {});
    });
  }

  void startExam() {
    setState(() {
      isPlaying = true;
      elapsedSeconds = 0;
      currentIndex = 0;
      correct = 0;
      wrong = 0;
      attempts.clear();
      durationSeconds = 0;
    });

    // Start timer logic
    timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted) return;
      setState(() {
        elapsedSeconds += 0.1;
        durationSeconds = elapsedSeconds.floor();
      });

      _checkMissedNotes();

      if (lesson != null && currentIndex >= lesson!.notes.length) {
        _endExam();
      }
    });
  }

  void _checkMissedNotes() {
    if (lesson == null) return;
    
    // Auto mark as wrong if elapsed > expected + 0.3s
    if (currentIndex < lesson!.notes.length) {
      final expected = lesson!.notes[currentIndex];
      if (elapsedSeconds > expected.second + 0.3) {
        wrong++;
        attempts.add(NoteAttemptRequest(
          lessonNoteId: expected.id ?? 0,
          playedNote: '', // Missed
          playedSecond: elapsedSeconds,
        ));
        currentIndex++;
      }
    }
  }

  void press(String note) {
    if (!isPlaying) return;
    final l = lesson;
    if (l == null || currentIndex >= l.notes.length) return;

    final expected = l.notes[currentIndex];
    
    attempts.add(NoteAttemptRequest(
      lessonNoteId: expected.id ?? 0,
      playedNote: note,
      playedSecond: elapsedSeconds,
    ));

    final timeDiff = (elapsedSeconds - expected.second).abs();
    final correctPitch = expected.note == note;
    final correctTiming = timeDiff <= 0.3;

    setState(() {
      if (correctPitch && correctTiming) {
        correct++;
      } else {
        wrong++;
      }
      currentIndex++;
    });
  }

  void _endExam() {
    timer?.cancel();
    setState(() {
      isPlaying = false;
    });
    submit();
  }

  Future<void> submit() async {
    final result = await context.read<StudentProvider>().submitPractice(
      widget.lessonId, 
      attempts,
      isExam: true,
      durationSeconds: durationSeconds,
    );
    if (!mounted || result == null) return;
    
    String getGrade(double score) {
      if (score >= 90) return 'Xuất sắc';
      if (score >= 80) return 'Tốt';
      if (score >= 65) return 'Khá';
      if (score >= 50) return 'Trung bình';
      return 'Cần luyện thêm';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Kết quả kiểm tra', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Điểm: ${result.score}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Đúng: ${result.correctCount}'),
            Text('Sai: ${result.wrongCount}'),
            Text('Xếp loại: ${getGrade(result.score.toDouble())}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              context.pop(); // return to previous screen
            },
            child: const Text('Đóng'),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = lesson;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiểm tra'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: l == null ? const Center(child: CircularProgressIndicator()) : Column(
        children: [
          const SizedBox(height: 12),
          if (!isPlaying && attempts.isEmpty)
            ElevatedButton.icon(
              onPressed: startExam,
              icon: const Icon(Icons.play_arrow),
              label: const Text('START'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
              ),
            ),
          if (isPlaying)
            Text('Thời gian: ${elapsedSeconds.toStringAsFixed(1)}s', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),
          
          Expanded(child: MusicStaff(lesson: l)),
          PianoKeyboard(onPressed: press), // No targetNote to hide hints
        ],
      ),
    );
  }
}
