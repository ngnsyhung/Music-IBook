import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../models/lesson.dart';
import '../../../models/practice.dart';
import '../../../providers/lesson_provider.dart';
import '../../../providers/student_provider.dart';
import '../../../widgets/music_staff.dart';
import '../../../widgets/piano_keyboard.dart';

class PracticeScreen extends StatefulWidget {
  final int lessonId;
  const PracticeScreen({super.key, required this.lessonId});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
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

  void startPractice() {
    setState(() {
      isPlaying = true;
      elapsedSeconds = 0;
      currentIndex = 0;
      correct = 0;
      wrong = 0;
      attempts.clear();
      durationSeconds = 0;
    });

    timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted) return;
      setState(() {
        elapsedSeconds += 0.1;
        durationSeconds = elapsedSeconds.floor();
      });

      if (lesson != null && currentIndex >= lesson!.notes.length) {
        _endPractice();
      }
    });
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

    final isCorrect = expected.note == note;

    setState(() {
      if (isCorrect) {
        correct++;
        currentIndex++;
      } else {
        wrong++;
      }
    });
  }

  void _endPractice() {
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
      isExam: false,
      durationSeconds: durationSeconds,
    );
    
    if (!mounted || result == null) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Kết quả luyện tập', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Đúng: ${result.correctCount}', style: const TextStyle(fontSize: 18, color: Colors.green)),
            Text('Sai: ${result.wrongCount}', style: const TextStyle(fontSize: 18, color: Colors.red)),
            const SizedBox(height: 10),
            Text('Tỷ lệ chính xác: ${result.accuracy}%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('Hoàn thành'),
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
    final current = l == null || currentIndex >= l.notes.length ? null : l.notes[currentIndex];

    double? countdown;
    if (isPlaying && current != null) {
      countdown = current.second - elapsedSeconds;
      if (countdown < 0) countdown = 0; 
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Luyện tập'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: l == null ? const Center(child: CircularProgressIndicator()) : Column(
        children: [
          const SizedBox(height: 12),
          
          if (!isPlaying && attempts.isEmpty)
            ElevatedButton.icon(
              onPressed: startPractice,
              icon: const Icon(Icons.play_arrow),
              label: const Text('START'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
              ),
            ),
            
          if (isPlaying) ...[
            Text('Đúng: $correct | Sai: $wrong', style: const TextStyle(fontSize: 20)),
            if (current != null)
              Text('Bấm nốt: ${current.note}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
          ],

          Expanded(
            child: MusicStaff(
              lesson: l,
              highlightIndex: isPlaying && currentIndex < l.notes.length ? currentIndex : null,
              countdownSeconds: countdown,
            )
          ),
          PianoKeyboard(onPressed: press, targetNote: isPlaying ? current?.note : null),
        ],
      ),
    );
  }
}
