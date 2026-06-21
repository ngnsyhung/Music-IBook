import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../providers/progress_provider.dart';

class StudentDetailScreen extends StatefulWidget {
  final int studentId;
  const StudentDetailScreen({super.key, required this.studentId});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ProgressProvider>().loadStudentDetail(widget.studentId));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProgressProvider>();

    if (p.loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết học sinh')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (p.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết học sinh')),
        body: Center(child: Text('Lỗi: ${p.error}')),
      );
    }

    final detail = p.currentStudentDetail;
    if (detail == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết học sinh')),
        body: const Center(child: Text('Không tìm thấy dữ liệu')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(detail.studentName)),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.blueAccent.withOpacity(0.1),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(detail.studentName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Tiến độ các bài học', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: detail.lessons.length,
              itemBuilder: (_, i) {
                final l = detail.lessons[i];
                String status = 'Chưa học';
                if (l.lastPracticeAt != null || l.lastExamAt != null) {
                  status = 'Đang học';
                }
                if (l.highestScore >= 80) {
                  status = 'Hoàn thành';
                }

                return Card(
                  child: ExpansionTile(
                    title: Text(l.lessonName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Trạng thái: $status'),
                    children: [
                      ListTile(
                        title: Text('Điểm cao nhất: ${l.highestScore}'),
                        subtitle: Text('Điểm trung bình: ${l.averageScore.toStringAsFixed(1)}\nĐộ chính xác: ${l.accuracy.toStringAsFixed(1)}%'),
                      ),
                      if (l.lastPracticeAt != null)
                        ListTile(
                          title: const Text('Luyện tập gần nhất'),
                          subtitle: Text(l.lastPracticeAt!),
                        ),
                      if (l.lastExamAt != null)
                        ListTile(
                          title: const Text('Kiểm tra gần nhất'),
                          subtitle: Text(l.lastExamAt!),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
