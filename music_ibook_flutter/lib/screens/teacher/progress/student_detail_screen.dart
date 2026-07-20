import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../providers/progress_provider.dart';
import '../../../../utils/vietnam_time.dart';

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
    final provider = context.read<ProgressProvider>();
    Future.microtask(() => provider.loadStudentDetail(widget.studentId));
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
      appBar: AppBar(
        title: Text(detail.studentName),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          // Background Watermark
          Positioned(
            bottom: -50,
            right: -100,
            child: Icon(
              Icons.school,
              size: 300,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.05),
            ),
          ),
          Column(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.8),
                      Theme.of(
                        context,
                      ).colorScheme.secondary.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                ),
                padding: const EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 16,
                  bottom: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.studentName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tiến độ các bài học',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
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

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).shadowColor.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: ExpansionTile(
                          shape: const Border(),
                          collapsedShape: const Border(),
                          leading: Icon(
                            status == 'Hoàn thành'
                                ? Icons.check_circle
                                : (status == 'Đang học'
                                      ? Icons.play_circle
                                      : Icons.radio_button_unchecked),
                            color: status == 'Hoàn thành'
                                ? Colors.green
                                : (status == 'Đang học'
                                      ? Colors.orange
                                      : Colors.grey),
                            size: 32,
                          ),
                          title: Text(
                            l.lessonName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text('Trạng thái: $status'),
                          children: [
                            const Divider(),
                            ListTile(
                              title: Text(
                                'Điểm cao nhất: ${l.highestScore}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Điểm trung bình: ${l.averageScore.toStringAsFixed(1)}\nĐộ chính xác: ${l.accuracy.toStringAsFixed(1)}%',
                              ),
                            ),
                            if (l.lastPracticeAt != null)
                              ListTile(
                                leading: const Icon(Icons.piano, size: 20),
                                title: const Text('Luyện tập gần nhất'),
                                subtitle: Text(
                                  VietnamTime.format(l.lastPracticeAt!),
                                ),
                              ),
                            if (l.lastExamAt != null)
                              ListTile(
                                leading: const Icon(Icons.quiz, size: 20),
                                title: const Text('Kiểm tra gần nhất'),
                                subtitle: Text(
                                  VietnamTime.format(l.lastExamAt!),
                                ),
                              ),
                            ListTile(
                              leading: const Icon(Icons.insights_outlined),
                              title: const Text('Xem lỗi nốt & tiến bộ'),
                              subtitle: const Text(
                                'So sánh các lần luyện và giao bài bổ sung',
                              ),
                              onTap: () => context.push(
                                '/teacher/student/${widget.studentId}/lesson/${l.lessonId}/analytics',
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ), // closes Expanded
            ], // closes Column children
          ), // closes Column
        ], // closes Stack children
      ), // closes Stack
    ); // closes Scaffold
  }
}
