import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/lesson_provider.dart';

import 'dashboard/dashboard_screen.dart';
import 'progress/progress_screen.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<LessonProvider>().loadLessons());
  }

  Widget _buildLessonList() {
    final provider = context.watch<LessonProvider>();
    if (provider.loading) return const Center(child: CircularProgressIndicator());
    
    return ListView.builder(
      itemCount: provider.lessons.length,
      itemBuilder: (_, i) {
        final l = provider.lessons[i];
        return Card(
          child: ListTile(
            title: Text(l.title),
            subtitle: Text('${l.keySignature} - ${l.timeSignature} - ${l.notes.length} nốt'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit), onPressed: () => context.go('/teacher/lesson/${l.id}')),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Xóa bài học'),
                        content: Text('Bạn có chắc muốn xóa "${l.title}"?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
                          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
                        ],
                      ),
                    );
                    if (confirm != true) return;
                    final ok = await context.read<LessonProvider>().deleteLesson(l.id!);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Đã xóa bài học' : 'Xóa thất bại')));
                    if (ok) context.read<LessonProvider>().loadLessons();
                  },
                ),
              ],
            ),
            onTap: () => context.go('/teacher/lesson/${l.id}'),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const DashboardScreen(),
      _buildLessonList(),
      const ProgressScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'Bảng điều khiển' : _currentIndex == 1 ? 'Bài học' : 'Tiến độ học sinh'),
        actions: [
          IconButton(onPressed: () => context.read<AuthProvider>().logout(), icon: const Icon(Icons.logout)),
        ],
      ),
      body: tabs[_currentIndex],
      floatingActionButton: _currentIndex == 1 ? FloatingActionButton.extended(
        onPressed: () => context.go('/teacher/lesson/new'),
        icon: const Icon(Icons.add),
        label: const Text('Tạo bài'),
      ) : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Tổng quan'),
          BottomNavigationBarItem(icon: Icon(Icons.library_music), label: 'Bài học'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Học sinh'),
        ],
      ),
    );
  }
}
