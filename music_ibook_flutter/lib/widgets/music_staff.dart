import 'package:flutter/material.dart';

import 'dart:math';

import '../models/lesson.dart';

class MusicStaff extends StatefulWidget {
  final MusicLesson lesson;
  final int? highlightIndex;
  final double? countdownSeconds;
  final bool wasCorrect;
  final ValueNotifier<double>? elapsedNotifier;
  final bool showTimeline;

  const MusicStaff({
    super.key,
    required this.lesson,
    this.highlightIndex,
    this.countdownSeconds,
    this.wasCorrect = false,
    this.elapsedNotifier,
    this.showTimeline = false,
  });

  @override
  State<MusicStaff> createState() => _MusicStaffState();
}

class _MusicStaffState extends State<MusicStaff> with TickerProviderStateMixin {
  final ScrollController _verticalController = ScrollController();
  late final AnimationController _glowController;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glowController, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(covariant MusicStaff oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlightIndex != oldWidget.highlightIndex &&
        widget.highlightIndex != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToHighlight();
      });
    }
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _scrollToHighlight() {
    if (widget.highlightIndex == null) return;
    
    final i = widget.highlightIndex!;
    const perLine = 12;
    final line = i ~/ perLine;
    
    const top0 = 150.0;
    const systemGap = 110.0;
    
    final top = top0 + line * systemGap;
    
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Vertical scroll only, since horizontal is scaled to fit
    double targetY = top - (screenHeight / 3);
    if (targetY < 0) targetY = 0;
    if (_verticalController.hasClients) {
      final maxScrollY = _verticalController.position.maxScrollExtent;
      if (targetY > maxScrollY) targetY = maxScrollY;
      _verticalController.animateTo(targetY, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalLines = widget.lesson.notes.isEmpty
        ? 1
        : (widget.lesson.notes.length / 12).ceil();
    final contentHeight = max(360.0, 150.0 + totalLines * 110.0 + 100.0);

    return Container(
      color: const Color(0xFFFFF6E6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            controller: _verticalController,
            scrollDirection: Axis.vertical,
            child: SizedBox(
              width: constraints.maxWidth,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 1250,
                  height: max(constraints.maxHeight, contentHeight),
                  child: AnimatedBuilder(
                    animation: _glowAnim,
                    builder: (context, _) => CustomPaint(
                      painter: MusicSheetPainter(
                        widget.lesson,
                        widget.highlightIndex,
                        widget.countdownSeconds,
                        _glowAnim.value,
                        widget.elapsedNotifier,
                        widget.showTimeline,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class MusicSheetPainter extends CustomPainter {
  final MusicLesson lesson;
  final int? highlightIndex;
  final double? countdownSeconds;
  final double glowProgress;
  final ValueNotifier<double>? elapsedNotifier;
  final bool showTimeline;

  MusicSheetPainter(
    this.lesson, 
    this.highlightIndex, 
    this.countdownSeconds, 
    [this.glowProgress = 0.5, 
     this.elapsedNotifier, 
     this.showTimeline = false]
  ) : super(repaint: elapsedNotifier);

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.4;
    final tp = TextPainter(textDirection: TextDirection.ltr);

    void text(
      String s,
      double x,
      double y, {
      double size = 16,
      FontWeight weight = FontWeight.normal,
      Color color = Colors.black,
    }) {
      tp.text = TextSpan(
        text: s,
        style: TextStyle(color: color, fontSize: size, fontWeight: weight),
      );
      tp.layout();
      tp.paint(canvas, Offset(x, y));
    }

    text(lesson.title, 450, 10, size: 32, weight: FontWeight.bold);
    text(lesson.composer.isEmpty ? 'Tác giả' : lesson.composer, 1040, 55);

    const top0 = 150.0,
        gap = 12.0,
        left = 70.0,
        right = 1180.0,
        systemGap = 110.0;
    const perLine = 12;
    final totalLines = lesson.notes.isEmpty
        ? 1
        : (lesson.notes.length / perLine).ceil();

    for (var line = 0; line < totalLines; line++) {
      final top = top0 + line * systemGap;

      for (var i = 0; i < 5; i++) {
        canvas.drawLine(
          Offset(left, top + i * gap),
          Offset(right, top + i * gap),
          linePaint,
        );
      }

      text('𝄞', left + 5, top - 22, size: 52);
      _keySignature(lesson.keySignature, left + 55, top, text);

      final t = lesson.timeSignature.split('/');
      if (t.length == 2) {
        text(t[0], left + 105, top - 8, size: 20);
        text(t[1], left + 105, top + 18, size: 20);
      }

      canvas.drawLine(
        Offset(left, top),
        Offset(left, top + gap * 4),
        linePaint,
      );
      final start = line * perLine;
      final end = (start + perLine > lesson.notes.length)
          ? lesson.notes.length
          : start + perLine;

      for (var i = start; i < end; i++) {
        final n = lesson.notes[i];
        final local = i - start;
        final x = left + 155 + local * 78;
        final y = _noteY(n.note, top, gap);

        final isHighlight = highlightIndex == i;
        final noteColor = isHighlight ? Colors.orange : Colors.black;
        final paint = Paint()
          ..color = noteColor
          ..strokeWidth = 1.4;

        if (n.chord.isNotEmpty) text(n.chord, x - 8, top - 55, size: 14);

        if (isHighlight && countdownSeconds != null) {
          text(
            countdownSeconds!.toStringAsFixed(1),
            x - 10,
            top - 95,
            size: 14,
            color: Colors.orange,
            weight: FontWeight.bold,
          );
          text(
            '↓',
            x - 2,
            top - 75,
            size: 18,
            color: Colors.orange,
            weight: FontWeight.bold,
          );
        }

        _note(canvas, x, y, n.duration, paint, isHighlight);
        text(n.lyric, x - 14, top + 75, size: 14, color: noteColor);

        if ((local + 1) % 4 == 0) {
          canvas.drawLine(
            Offset(x + 35, top),
            Offset(x + 35, top + gap * 4),
            linePaint,
          );
        }
      }
      canvas.drawLine(
        Offset(right, top),
        Offset(right, top + gap * 4),
        linePaint,
      );
    }

    if (showTimeline && elapsedNotifier != null) {
      _drawTimeline(canvas, elapsedNotifier!.value, gap, left, perLine);
    }
  }

  void _drawTimeline(Canvas canvas, double elapsed, double gap, double left, int perLine) {
    if (lesson.notes.isEmpty) return;

    int idx = 0;
    while (idx < lesson.notes.length && lesson.notes[idx].second <= elapsed) {
      idx++;
    }
    
    double x = left + 155; 
    int line = 0;

    if (idx == 0) {
      double t1 = lesson.notes[0].second;
      double p = t1 > 0 ? (elapsed / t1).clamp(0.0, 1.0) : 1.0;
      x = left + 80 + p * 75; 
      line = 0;
    } else if (idx == lesson.notes.length) {
      int lastIdx = lesson.notes.length - 1;
      int local = lastIdx % perLine;
      line = lastIdx ~/ perLine;
      double t0 = lesson.notes[lastIdx].second;
      double diff = elapsed - t0;
      x = left + 155 + local * 78 + diff * 78;
    } else {
      double t0 = lesson.notes[idx-1].second;
      double t1 = lesson.notes[idx].second;
      double p = (elapsed - t0) / (t1 - t0);
      
      int local0 = (idx - 1) % perLine;
      int local1 = idx % perLine;
      line = (idx - 1) ~/ perLine;
      
      if (line == idx ~/ perLine) {
        double x0 = left + 155 + local0 * 78;
        double x1 = left + 155 + local1 * 78;
        x = x0 + (x1 - x0) * p;
      } else {
        if (p < 0.5) {
          double x0 = left + 155 + local0 * 78;
          double x1 = left + 155 + perLine * 78;
          x = x0 + (x1 - x0) * (p * 2);
        } else {
          line = idx ~/ perLine;
          double x0 = left + 80;
          double x1 = left + 155 + local1 * 78;
          x = x0 + (x1 - x0) * ((p - 0.5) * 2);
        }
      }
    }
    
    final top = 150.0 + line * 110.0;
    
    final glowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x, top - gap), Offset(x, top + gap * 5), glowPaint);

    final linePaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x, top - gap), Offset(x, top + gap * 5), linePaint);
  }

  void _keySignature(
    String key,
    double x,
    double top,
    void Function(
      String,
      double,
      double, {
      double size,
      FontWeight weight,
      Color color,
    })
    text,
  ) {
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

  void _note(
    Canvas canvas,
    double x,
    double y,
    String duration,
    Paint paint,
    bool isHighlight,
  ) {
    // Draw halo glow for highlighted note
    if (isHighlight) {
      final haloRadius = 16.0 + glowProgress * 10.0;
      final haloAlpha = (80 + glowProgress * 100).toInt().clamp(0, 255);
      final haloPaint = Paint()
        ..color = Colors.orange.withAlpha(haloAlpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 + glowProgress * 6);
      canvas.drawCircle(Offset(x, y), haloRadius, haloPaint);

      // Outer ring
      final ringPaint = Paint()
        ..color = Colors.orange.withAlpha((40 + glowProgress * 60).toInt())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(x, y), haloRadius + 8, ringPaint);
    }

    final fill = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;
    final outline = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y), width: 16, height: 11),
      duration == 'half' ? outline : fill,
    );
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
