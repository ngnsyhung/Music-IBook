import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/history_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<HistoryProvider>().loadHistory());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<HistoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử học tập'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: p.loading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: p.history.length,
        itemBuilder: (_, i) {
          final h = p.history[i];
          final title = h.lessonTitle ?? 'Bài ${h.lessonId}';
          final type = h.isExam ? 'Kiểm tra' : 'Luyện tập';
          final color = h.isExam ? Colors.redAccent : Colors.blueAccent;

          return Card(
            elevation: 3,
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: color,
                child: Text(h.score.toString(), style: const TextStyle(color: Colors.white)),
              ),
              title: Text('$title ($type)', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Đúng: ${h.correctCount} | Sai: ${h.wrongCount} | Chính xác: ${h.accuracy}%'),
              children: [
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(child: Text('Nốt yêu cầu', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(child: Text('Nốt bạn đánh', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(child: Text('Lệch (ms)', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(child: Text('Kết quả', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                ...h.noteAttempts.map((attempt) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: Row(
                      children: [
                        Expanded(child: Text(attempt.expectedNote)),
                        Expanded(child: Text(attempt.playedNote.isEmpty ? '(Bỏ qua)' : attempt.playedNote)),
                        Expanded(child: Text(attempt.timingErrorMs.toStringAsFixed(0))),
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                attempt.isCorrect ? Icons.check_circle : Icons.cancel,
                                color: attempt.isCorrect ? Colors.green : Colors.red,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(attempt.isCorrect ? 'Đúng' : 'Sai'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }
}
