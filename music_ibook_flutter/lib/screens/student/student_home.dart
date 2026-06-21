import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/lesson_provider.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<LessonProvider>().loadLessons());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<LessonProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Học sinh - Bài học'),
        actions: [
          IconButton(onPressed: () => context.go('/student/history'), icon: const Icon(Icons.history)),
          IconButton(onPressed: () => context.read<AuthProvider>().logout(), icon: const Icon(Icons.logout)),
        ],
      ),
      body: p.loading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
        itemCount: p.lessons.length,
        itemBuilder: (_, i) {
          final l = p.lessons[i];
          return Card(
            child: ListTile(
              title: Text(l.title),
              subtitle: Text('${l.composer} - ${l.notes.length} nốt'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/student/lesson/${l.id}'),
            ),
          );
        },
      ),
    );
  }
}
