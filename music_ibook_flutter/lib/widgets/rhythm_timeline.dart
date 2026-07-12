import 'package:flutter/material.dart';
import '../core/game_judge.dart';
import '../models/lesson_note.dart';

/// Widget hiển thị timeline nhịp điệu dạng scrolling piano roll.
/// Dùng [repaint] Listenable (ValueNotifier<double>) để chỉ repaint canvas
/// mà KHÔNG rebuild widget tree → đạt 60fps mượt mà.
class RhythmTimeline extends StatelessWidget {
  final List<LessonNote> notes;
  final ValueNotifier<double> elapsedNotifier;
  final int currentNoteIndex;
  final Map<int, String> judgeHistory; // noteIndex → JudgeResult label

  const RhythmTimeline({
    super.key,
    required this.notes,
    required this.elapsedNotifier,
    required this.currentNoteIndex,
    this.judgeHistory = const {},
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hitLineX = constraints.maxWidth * _RhythmPainter.kHitLineRatio;
        final isActive = currentNoteIndex < notes.length;
        
        return Stack(
          children: [
            RepaintBoundary(
              child: CustomPaint(
                painter: _RhythmPainter(
                  notes: notes,
                  elapsedNotifier: elapsedNotifier,
                  currentNoteIndex: currentNoteIndex,
                  judgeHistory: judgeHistory,
                  canvasWidth: constraints.maxWidth,
                  canvasHeight: constraints.maxHeight,
                ),
                size: Size(constraints.maxWidth, constraints.maxHeight),
              ),
            ),
            Positioned(
              left: hitLineX - 16, // center the line
              top: 0,
              bottom: 0,
              width: 32, // enough space for blur
              child: RepaintBoundary(
                child: _HitLineWidget(isActive: isActive),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RhythmPainter extends CustomPainter {
  final List<LessonNote> notes;
  final ValueNotifier<double> elapsedNotifier;
  final int currentNoteIndex;
  final Map<int, String> judgeHistory;
  final double canvasWidth;
  final double canvasHeight;

  // ─── Layout constants ──────────────────────────────────────────────
  static const double kHitLineRatio = 0.28;
  static const double kVisibleSeconds = 6.0;
  static const double kTopPad = 12.0;
  
  late final List<String> _pitches;
  late final double _rowHeight;
  late final double _noteBlockHeight;

  _RhythmPainter({
    required this.notes,
    required this.elapsedNotifier,
    required this.currentNoteIndex,
    required this.judgeHistory,
    required this.canvasWidth,
    required this.canvasHeight,
  }) : super(repaint: elapsedNotifier) {
    _pitches = _getUniquePitches();
    final pCount = _pitches.isEmpty ? 1 : _pitches.length;
    final maxAvailableRowHeight = (canvasHeight - kTopPad * 2) / pCount;
    _rowHeight = maxAvailableRowHeight.clamp(20.0, 60.0);
    _noteBlockHeight = (_rowHeight * 0.7).clamp(14.0, 42.0);
  }

  double get _elapsed => elapsedNotifier.value;

  double _secondToX(double second) {
    final hitLineX = canvasWidth * kHitLineRatio;
    final pps = canvasWidth / kVisibleSeconds;
    return hitLineX + (second - _elapsed) * pps;
  }

  double _durationToWidth(String duration) {
    final pps = canvasWidth / kVisibleSeconds;
    switch (duration) {
      case 'whole':   return pps * 2.0;
      case 'half':    return pps * 1.0;
      case 'quarter': return pps * 0.65;
      case 'eighth':  return pps * 0.4;
      default:        return pps * 0.5;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final hitLineX = canvasWidth * kHitLineRatio;
    final pps = canvasWidth / kVisibleSeconds;
    final timingWindowPx = (kPracticeTimingWindowMs / 1000.0) * pps;

    _drawBackground(canvas);
    _drawTimeRuler(canvas, hitLineX, pps);
    _drawHitZone(canvas, hitLineX, timingWindowPx);
    _drawNotes(canvas, hitLineX, pps);
    _drawTimeDisplay(canvas, hitLineX);
  }

  void _drawBackground(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, canvasWidth, canvasHeight),
      Paint()..color = const Color(0xFF0D1117),
    );
  }

  void _drawTimeRuler(Canvas canvas, double hitLineX, double pps) {
    final gridPaint = Paint()
      ..color = const Color(0xFF1E2A3A)
      ..strokeWidth = 1.0;
    final tp = TextPainter(textDirection: TextDirection.ltr);

    final startSec = (_elapsed - 1).floor();
    final endSec = (_elapsed + kVisibleSeconds + 1).ceil();

    for (int s = startSec; s <= endSec; s++) {
      final x = hitLineX + (s - _elapsed) * pps;
      if (x < -4 || x > canvasWidth + 4) continue;
      canvas.drawLine(Offset(x, 0), Offset(x, canvasHeight), gridPaint);

      tp.text = TextSpan(
        text: '${s}s',
        style: const TextStyle(color: Color(0xFF2D4A5E), fontSize: 10),
      );
      tp.layout();
      tp.paint(canvas, Offset(x + 3, 2));
    }

    // Lane dividers
    final lanePaint = Paint()
      ..color = const Color(0xFF1A2535)
      ..strokeWidth = 1.0;
    for (int i = 0; i <= _pitches.length; i++) {
      final y = kTopPad + i * _rowHeight;
      canvas.drawLine(Offset(0, y), Offset(canvasWidth, y), lanePaint);
    }
  }

  void _drawHitZone(Canvas canvas, double hitLineX, double windowPx) {
    final isActive = currentNoteIndex < notes.length;
    canvas.drawRect(
      Rect.fromLTWH(hitLineX - windowPx, 0, windowPx * 2, canvasHeight),
      Paint()
        ..color = (isActive
                ? const Color(0xFF00BCD4)
                : const Color(0xFF455A64))
            .withValues(alpha: isActive ? 0.07 : 0.03),
    );
  }

  void _drawNotes(Canvas canvas, double hitLineX, double pps) {
    final tp = TextPainter(textDirection: TextDirection.ltr);

    // Draw lane labels
    for (int i = 0; i < _pitches.length; i++) {
      final y = kTopPad + i * _rowHeight;
      tp.text = TextSpan(
        text: _pitches[i],
        style: const TextStyle(
            color: Color(0xFF4A6278), fontSize: 11, fontWeight: FontWeight.bold),
      );
      tp.layout();
      tp.paint(canvas, Offset(6, y + (_rowHeight - tp.height) / 2));
    }

    // Draw note blocks
    // Culling bounds
    final visibleStart = _elapsed - (canvasWidth * kHitLineRatio / pps) - 2.0;
    final visibleEnd = _elapsed + kVisibleSeconds + 2.0;

    for (int i = 0; i < notes.length; i++) {
      final note = notes[i];
      if (note.second < visibleStart || note.second > visibleEnd) continue;

      final x = _secondToX(note.second);
      final w = _durationToWidth(note.duration);

      if (x + w < 0 || x > canvasWidth) continue;

      final pitchIdx = _pitches.indexOf(note.note);
      if (pitchIdx < 0) continue;

      final y = kTopPad + pitchIdx * _rowHeight + (_rowHeight - _noteBlockHeight) / 2;
      final isCurrent = i == currentNoteIndex;
      final isInWindow = isCurrent &&
          (_elapsed - note.second).abs() < kPracticeTimingWindowMs / 1000.0;

      // Determine colors
      Color fill;
      Color border;
      if (judgeHistory.containsKey(i)) {
        fill = _judgeColor(judgeHistory[i]!);
        border = fill.withValues(alpha: 1.0);
      } else if (isCurrent) {
        fill = isInWindow
            ? const Color(0xFFE65100)
            : const Color(0xFF263238);
        border = isInWindow
            ? const Color(0xFFFF6D00)
            : const Color(0xFF37474F);
      } else if (i < currentNoteIndex) {
        fill = const Color(0xFF1A1F26);
        border = const Color(0xFF2D3A47);
      } else {
        fill = const Color(0xFF0D2137);
        border = const Color(0xFF1565C0);
      }

      final rRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
            x, y, w.clamp(14.0, canvasWidth.toDouble()), _noteBlockHeight),
        const Radius.circular(6),
      );

      canvas.drawRRect(rRect, Paint()..color = fill);
      canvas.drawRRect(
        rRect,
        Paint()
          ..color = border
          ..style = PaintingStyle.stroke
          ..strokeWidth = isCurrent ? 2.5 : 1.5,
      );

      // Note label
      if (w > 22) {
        String labelText = '${note.note}\n${note.lyric}';
        if (_noteBlockHeight < 30) {
          labelText = '${note.note} - ${note.lyric}';
        }

        tp.text = TextSpan(
          text: labelText,
          style: TextStyle(
            color: isCurrent ? Colors.white : const Color(0xFF78909C),
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            height: 1.25,
          ),
        );
        tp.layout(maxWidth: w - 4);
        tp.paint(canvas, Offset(x + 4, y + (_noteBlockHeight - tp.height) / 2));
      }
    }
  }

  void _drawTimeDisplay(Canvas canvas, double hitLineX) {
    final mm = (_elapsed ~/ 60).toString().padLeft(2, '0');
    final ss = (_elapsed % 60).toStringAsFixed(1).padLeft(4, '0');

    final tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = TextSpan(
      text: '$mm:$ss',
      style: const TextStyle(
          color: Color(0xFF80DEEA),
          fontSize: 12,
          fontWeight: FontWeight.bold),
    );
    tp.layout();

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(hitLineX - tp.width / 2 - 8, canvasHeight - 26,
          tp.width + 16, 20),
      const Radius.circular(10),
    );
    canvas.drawRRect(
        bgRect, Paint()..color = const Color(0xFF0D2137));
    canvas.drawRRect(
        bgRect,
        Paint()
          ..color = const Color(0xFF00BCD4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);
    tp.paint(canvas, Offset(hitLineX - tp.width / 2, canvasHeight - 23));
  }

  List<String> _getUniquePitches() {
    const order = [
      'E5','D#5','D5','C#5','C5','B4','A#4','A4','G#4','G4','F#4','F4',
      'E4','D#4','D4','C#4','C4','B3','A3','G3'
    ];
    final inLesson = notes.map((n) => n.note).toSet();
    final result = <String>[];
    final seen = <String>{};
    for (final p in order) {
      if (inLesson.contains(p)) { result.add(p); seen.add(p); }
    }
    for (final n in notes) {
      if (!seen.contains(n.note)) { result.add(n.note); seen.add(n.note); }
    }
    return result;
  }

  Color _judgeColor(String judge) {
    switch (judge) {
      case 'PERFECT': return const Color(0xFF00BCD4).withValues(alpha: 0.65);
      case 'GOOD':    return const Color(0xFF4CAF50).withValues(alpha: 0.65);
      case 'LATE':    return const Color(0xFFFFEB3B).withValues(alpha: 0.65);
      case 'WRONG':   return const Color(0xFFF44336).withValues(alpha: 0.65);
      case 'MISS':    return const Color(0xFF37474F).withValues(alpha: 0.65);
      default:        return const Color(0xFF263238);
    }
  }

  @override
  bool shouldRepaint(covariant _RhythmPainter old) =>
      old.currentNoteIndex != currentNoteIndex ||
      old.judgeHistory.length != judgeHistory.length ||
      old.notes.length != notes.length;
}

class _HitLineWidget extends StatelessWidget {
  final bool isActive;
  const _HitLineWidget({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _HitLinePainter(isActive: isActive),
    );
  }
}

class _HitLinePainter extends CustomPainter {
  final bool isActive;
  _HitLinePainter({required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final color = isActive ? const Color(0xFF00E5FF) : const Color(0xFF546E7A);
    final centerX = size.width / 2;
    final canvasHeight = size.height;

    // Glow layers
    for (final d in [16.0, 8.0, 3.0]) {
      canvas.drawLine(
        Offset(centerX, 0),
        Offset(centerX, canvasHeight),
        Paint()
          ..color = color.withValues(alpha: 0.15 / (d / 3))
          ..strokeWidth = d
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, d / 2),
      );
    }

    // Solid line
    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, canvasHeight),
      Paint()
        ..color = color
        ..strokeWidth = 2.0,
    );

    // Arrow indicator
    final ay = canvasHeight / 2;
    final path = Path()
      ..moveTo(centerX + 9, ay - 8)
      ..lineTo(centerX - 1, ay)
      ..lineTo(centerX + 9, ay + 8);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _HitLinePainter old) => old.isActive != isActive;
}
