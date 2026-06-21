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
    Future.microtask(() => context.read<LessonProvider>().loadLesson(widget.lessonId));
  }

  @override
  Widget build(BuildContext context) {
    final lesson = context.watch<LessonProvider>().current;

    return Scaffold(
      appBar: AppBar(title: Text(lesson?.title ?? 'Bài học')),
      floatingActionButton: lesson == null ? null : Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'practice_btn',
            onPressed: () => context.go('/student/practice/${lesson.id}'),
            icon: const Icon(Icons.piano),
            label: const Text('Luyện tập'),
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
          ),
          const SizedBox(width: 16),
          FloatingActionButton.extended(
            heroTag: 'exam_btn',
            onPressed: () => context.go('/student/exam/${lesson.id}'),
            icon: const Icon(Icons.quiz),
            label: const Text('Kiểm tra'),
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
          ),
        ],
      ),
      body: lesson == null ? const Center(child: CircularProgressIndicator()) : DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(tabs: [
              Tab(icon: Icon(Icons.menu_book), text: 'Lý thuyết'),
              Tab(icon: Icon(Icons.music_note), text: 'Bản nhạc'),
            ]),
            Expanded(
              child: TabBarView(
                children: [
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(lesson.theoryTitle, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(lesson.theoryContent, style: const TextStyle(fontSize: 16, height: 1.5)),
                      const SizedBox(height: 20),
                      const Text('Hướng dẫn luyện tập', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(lesson.practiceGuide, style: const TextStyle(fontSize: 16, height: 1.5)),
                    ],
                  ),
                  MusicStaff(lesson: lesson),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
