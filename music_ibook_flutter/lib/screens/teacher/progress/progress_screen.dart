import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../providers/progress_provider.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ProgressProvider>().loadStudentsProgress());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProgressProvider>();

    if (p.loading) return const Center(child: CircularProgressIndicator());
    if (p.error != null) return Center(child: Text('Lỗi: ${p.error}'));

    return ListView.builder(
      itemCount: p.studentsProgress.length,
      itemBuilder: (_, i) {
        final s = p.studentsProgress[i];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green,
              child: Text(s.studentName.isNotEmpty ? s.studentName[0].toUpperCase() : 'S', style: const TextStyle(color: Colors.white)),
            ),
            title: Text(s.studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${s.email}\nBài học: ${s.lessonCount} | Kiểm tra: ${s.examCount} | Điểm TB: ${s.averageScore.toStringAsFixed(1)}'),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.go('/teacher/student/${s.studentId}');
            },
          ),
        );
      },
    );
  }
}
