import 'package:flutter/material.dart';

class ResultDialog extends StatelessWidget {
  final String title;
  final int correctCount;
  final int wrongCount;
  final num accuracy;
  final bool isPractice;
  final VoidCallback onClose;

  const ResultDialog({
    super.key,
    required this.title,
    required this.correctCount,
    required this.wrongCount,
    required this.accuracy,
    required this.isPractice,
    required this.onClose,
  });

  String _grade(num acc) {
    if (acc >= 90) return '⭐⭐⭐ Xuất sắc';
    if (acc >= 80) return '⭐⭐ Tốt';
    if (acc >= 65) return '⭐ Khá';
    if (acc >= 50) return '📘 Trung bình';
    return '💪 Cần luyện thêm';
  }

  Color _gradeColor(num acc) {
    if (acc >= 90) return Colors.amber;
    if (acc >= 80) return Colors.green;
    if (acc >= 65) return Colors.blue;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final isCompact = screenH < 500;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(isCompact ? 18 : 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1a1a3e), Color(0xFF0d1b2a)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withAlpha(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(120),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isCompact ? 17 : 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isCompact ? 14 : 20),

              // Accuracy ring
              if (!isCompact) ...[
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _gradeColor(accuracy).withAlpha(60),
                        Colors.transparent,
                      ],
                    ),
                    border: Border.all(color: _gradeColor(accuracy), width: 3),
                  ),
                  child: Center(
                    child: Text(
                      '$accuracy%',
                      style: TextStyle(
                        color: _gradeColor(accuracy),
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ] else ...[
                // Compact: inline accuracy
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: _gradeColor(accuracy), width: 2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '$accuracy%',
                    style: TextStyle(
                      color: _gradeColor(accuracy),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Grade label
              Text(
                _grade(accuracy),
                style: TextStyle(
                  color: _gradeColor(accuracy),
                  fontSize: isCompact ? 15 : 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: isCompact ? 12 : 18),

              // Correct / Wrong stats
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _statBox('✅ Đúng', '$correctCount', Colors.green, isCompact),
                  const SizedBox(width: 12),
                  _statBox('❌ Sai', '$wrongCount', Colors.red, isCompact),
                ],
              ),
              SizedBox(height: isCompact ? 16 : 24),

              // Done button
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: isCompact ? 11 : 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPractice
                          ? [Colors.blue.shade400, Colors.blue.shade700]
                          : [Colors.red.shade400, Colors.red.shade700],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Hoàn thành',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statBox(String label, String value, Color color, bool compact) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 20,
        vertical: compact ? 6 : 10,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(color: color.withAlpha(200), fontSize: 12)),
          Text(
            value,
            style: TextStyle(
                color: color,
                fontSize: compact ? 20 : 24,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
