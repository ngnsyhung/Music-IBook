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
        backgroundColor: Colors.transparent,
      ),
      body: p.loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Background Watermark
                Positioned(
                  top: 50,
                  left: -80,
                  child: Icon(
                    Icons.history,
                    size: 300,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.05),
                  ),
                ),
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: p.history.length,
                  itemBuilder: (_, i) {
                    final h = p.history[i];
                    final title = h.lessonTitle ?? 'Bài ${h.lessonId}';
                    final type = h.isExam ? 'Kiểm tra' : 'Luyện tập';
                    final color = h.isExam
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.primary;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(24),
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
                        borderRadius: BorderRadius.circular(24),
                        child: ExpansionTile(
                          shape: const Border(), // Remove default borders
                          collapsedShape: const Border(),
                          leading: CircleAvatar(
                            backgroundColor: color,
                            radius: 24,
                            child: Text(
                              h.score.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            '$title ($type)',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          subtitle: Text(
                            'Đúng: ${h.correctCount} | Sai: ${h.wrongCount} | Chính xác: ${h.accuracy}%',
                          ),
                          children: [
                            const Divider(),
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Nốt yêu cầu',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'Nốt bạn đánh',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'Lệch (ms)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'Kết quả',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...h.noteAttempts.map((attempt) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 4.0,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(child: Text(attempt.expectedNote)),
                                    Expanded(
                                      child: Text(
                                        attempt.playedNote.isEmpty
                                            ? '(Bỏ qua)'
                                            : attempt.playedNote,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        attempt.timingErrorMs.toStringAsFixed(
                                          0,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(
                                            attempt.isCorrect
                                                ? Icons.check_circle
                                                : Icons.cancel,
                                            color: attempt.isCorrect
                                                ? Colors.green
                                                : Colors.red,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            attempt.isCorrect ? 'Đúng' : 'Sai',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
