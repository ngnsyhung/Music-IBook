import 'package:flutter/material.dart';

import '../models/lesson.dart';

class MusicStaff extends StatelessWidget {
  final MusicLesson lesson;
  final int? highlightIndex;
  final double? countdownSeconds;

  const MusicStaff({
    super.key, 
    required this.lesson,
    this.highlightIndex,
    this.countdownSeconds,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF6E6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 1250,
          height: 360,
          child: CustomPaint(painter: MusicSheetPainter(lesson, highlightIndex, countdownSeconds)),
        ),
      ),
    );
  }
}

class MusicSheetPainter extends CustomPainter {
  final MusicLesson lesson;
  final int? highlightIndex;
  final double? countdownSeconds;

  MusicSheetPainter(this.lesson, this.highlightIndex, this.countdownSeconds);

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()..color = Colors.black..strokeWidth = 1.4;
    final tp = TextPainter(textDirection: TextDirection.ltr);

    void text(String s, double x, double y, {double size = 16, FontWeight weight = FontWeight.normal, Color color = Colors.black}) {
      tp.text = TextSpan(text: s, style: TextStyle(color: color, fontSize: size, fontWeight: weight));
      tp.layout();
      tp.paint(canvas, Offset(x, y));
    }

    text(lesson.title, 450, 10, size: 32, weight: FontWeight.bold);
    text(lesson.composer.isEmpty ? 'Tác giả' : lesson.composer, 1040, 55);

    const top0 = 110.0, gap = 12.0, left = 70.0, right = 1180.0, systemGap = 110.0;
    const perLine = 12;
    final totalLines = lesson.notes.isEmpty ? 1 : (lesson.notes.length / perLine).ceil();

    for (var line = 0; line < totalLines; line++) {
      final top = top0 + line * systemGap;

      for (var i = 0; i < 5; i++) {
        canvas.drawLine(Offset(left, top + i * gap), Offset(right, top + i * gap), linePaint);
      }

      text('𝄞', left + 5, top - 22, size: 52);
      _keySignature(lesson.keySignature, left + 55, top, text);

      final t = lesson.timeSignature.split('/');
      if (t.length == 2) {
        text(t[0], left + 105, top - 8, size: 20);
        text(t[1], left + 105, top + 18, size: 20);
      }

      canvas.drawLine(Offset(left, top), Offset(left, top + gap * 4), linePaint);
      final start = line * perLine;
      final end = (start + perLine > lesson.notes.length) ? lesson.notes.length : start + perLine;

      for (var i = start; i < end; i++) {
        final n = lesson.notes[i];
        final local = i - start;
        final x = left + 155 + local * 78;
        final y = _noteY(n.note, top, gap);

        final isHighlight = highlightIndex == i;
        final noteColor = isHighlight ? Colors.orange : Colors.black;
        final paint = Paint()..color = noteColor..strokeWidth = 1.4;

        if (n.chord.isNotEmpty) text(n.chord, x - 8, top - 35, size: 14);
        
        if (isHighlight && countdownSeconds != null) {
          text(countdownSeconds!.toStringAsFixed(1), x - 10, y - 65, size: 14, color: Colors.orange, weight: FontWeight.bold);
          text('↓', x - 2, y - 48, size: 18, color: Colors.orange, weight: FontWeight.bold);
        }

        _note(canvas, x, y, n.duration, paint, isHighlight);
        text(n.lyric, x - 14, top + 62, size: 14, color: noteColor);

        if ((local + 1) % 4 == 0) {
          canvas.drawLine(Offset(x + 35, top), Offset(x + 35, top + gap * 4), linePaint);
        }
      }
      canvas.drawLine(Offset(right, top), Offset(right, top + gap * 4), linePaint);
    }
  }

  void _keySignature(String key, double x, double top, void Function(String, double, double, {double size, FontWeight weight, Color color}) text) {
    if (key == 'G Major') {
      text('♯', x, top - 5, size: 22);
    } else if (key == 'D Major') {
      text('♯', x, top - 5, size: 22);
      text('♯', x + 14, top + 18, size: 22);
    } else if (key == 'A Major') {
      text('♯', x, top - 5, size: 22);
      text('♯', x + 14, top + 18, size: 22);
      text('♯', x + 28, top - 12, size: 22);
    } else if (key == 'F Major') {
      text('♭', x, top + 5, size: 22);
    }
  }

  double _noteY(String note, double top, double gap) {
    final map = {
      'C4': top + gap * 5.0,
      'D4': top + gap * 4.5,
      'E4': top + gap * 4.0,
      'F4': top + gap * 3.5,
      'F#4': top + gap * 3.5,
      'G4': top + gap * 3.0,
      'A4': top + gap * 2.5,
      'B4': top + gap * 2.0,
      'C5': top + gap * 1.5,
      'D5': top + gap * 1.0,
      'E5': top + gap * 0.5,
    };
    return map[note] ?? top + gap * 3;
  }

  void _note(Canvas canvas, double x, double y, String duration, Paint paint, bool isHighlight) {
    final fill = Paint()..color = paint.color..style = PaintingStyle.fill;
    final outline = Paint()..color = paint.color..style = PaintingStyle.stroke..strokeWidth = 1.4;

    canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 16, height: 11), duration == 'half' ? outline : fill);
    canvas.drawLine(Offset(x + 8, y), Offset(x + 8, y - 45), paint);

    if (duration == 'eighth') {
      final path = Path()
        ..moveTo(x + 8, y - 45)
        ..quadraticBezierTo(x + 30, y - 35, x + 15, y - 22);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant MusicSheetPainter oldDelegate) => true;
}
