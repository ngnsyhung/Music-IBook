import 'dart:math';

import 'package:flutter/material.dart';

import '../models/lesson_note.dart';
import '../services/score_engraving_service.dart';

class EngravedScoreGeometry {
  static double staffTop(
    EngravedScoreLayout layout,
    int systemIndex,
    int staff,
  ) {
    final top = layout.systems[systemIndex].top;
    return top + (staff == 1 ? layout.style.grandStaffDistance : 0);
  }

  static double noteY(
    EngravedScoreLayout layout,
    int systemIndex,
    int staff,
    String note,
  ) {
    final parsed = RegExp(r'^([A-G])([#b]?)(-?\d+)$').firstMatch(note);
    final top = staffTop(layout, systemIndex, staff);
    if (parsed == null) return top + layout.style.staffSpace * 2;
    const steps = {'C': 0, 'D': 1, 'E': 2, 'F': 3, 'G': 4, 'A': 5, 'B': 6};
    final octave = int.parse(parsed.group(3)!);
    final fromC4 = (octave - 4) * 7 + steps[parsed.group(1)]!;
    if (staff == 1) {
      return top - (fromC4 + 2) * layout.style.staffSpace / 2;
    }
    return top +
        layout.style.staffSpace * 5 -
        fromC4 * layout.style.staffSpace / 2;
  }

  static int staffAt(EngravedScoreLayout layout, Offset point) {
    final system = _systemAt(layout, point.dy);
    final top = layout.systems[system].top;
    final trebleCenter = top + layout.style.staffSpace * 2;
    final bassCenter =
        top + layout.style.grandStaffDistance + layout.style.staffSpace * 2;
    return (point.dy - bassCenter).abs() < (point.dy - trebleCenter).abs()
        ? 1
        : 0;
  }

  static String noteAt(EngravedScoreLayout layout, Offset point, int staff) {
    final system = _systemAt(layout, point.dy);
    var best = staff == 1 ? 'C3' : 'C4';
    var distance = double.infinity;
    const names = [
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#',
      'A',
      'A#',
      'B',
    ];
    for (var midi = 24; midi <= 108; midi++) {
      final note = '${names[midi % 12]}${midi ~/ 12 - 1}';
      final y = noteY(layout, system, staff, note);
      if ((y - point.dy).abs() < distance) {
        distance = (y - point.dy).abs();
        best = note;
      }
    }
    return best;
  }

  static int? hitTest(EngravedScoreLayout layout, Offset point) {
    for (final system in layout.systems.reversed) {
      for (final measureLayout in system.measures.reversed) {
        for (final note in measureLayout.measure.notes.reversed) {
          final x = measureLayout.xForBeat(note.startBeat);
          final y = noteY(layout, system.index, note.staff, note.source.note);
          if (Rect.fromCenter(
            center: Offset(x, y),
            width: 28,
            height: 24,
          ).contains(point)) {
            return note.sourceIndex;
          }
        }
      }
    }
    return null;
  }

  static int _systemAt(EngravedScoreLayout layout, double y) {
    final raw =
        ((y - layout.style.pageTop + layout.style.systemHeight * 0.18) /
                layout.style.systemHeight)
            .floor();
    return raw.clamp(0, layout.systems.length - 1).toInt();
  }
}

class EngravedScorePainter extends CustomPainter {
  final EngravedScoreLayout layout;
  final int tempo;
  final int? selectedSourceIndex;
  final int? highlightedSourceIndex;
  final double? playheadBeat;
  final Color backgroundColor;
  final String title;
  final String composer;

  EngravedScorePainter({
    required this.layout,
    required this.tempo,
    this.selectedSourceIndex,
    this.highlightedSourceIndex,
    this.playheadBeat,
    this.backgroundColor = const Color(0xFFFFFAF0),
    this.title = '',
    this.composer = '',
    super.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = backgroundColor);
    final staffPaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.15;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    if (title.isNotEmpty) {
      _text(
        canvas,
        textPainter,
        title,
        layout.width / 2,
        12,
        28,
        weight: FontWeight.bold,
        centered: true,
      );
    }
    if (composer.isNotEmpty) {
      _text(
        canvas,
        textPainter,
        composer,
        layout.width - layout.style.pageRight,
        48,
        14,
        color: Colors.black87,
        alignedRight: true,
      );
    }

    for (final system in layout.systems) {
      _drawSystem(canvas, system, staffPaint, textPainter);
    }
    _drawNotesAndRests(canvas, staffPaint, textPainter);
    _drawBeams(canvas);
    _drawPlayhead(canvas);
  }

  void _drawSystem(
    Canvas canvas,
    EngravedSystem system,
    Paint staffPaint,
    TextPainter textPainter,
  ) {
    final style = layout.style;
    final top = system.top;
    final left = style.pageLeft;
    final right = system.measures.last.x + system.measures.last.width;
    final bassTop = top + style.grandStaffDistance;

    for (final staffTop in [top, bassTop]) {
      for (var line = 0; line < 5; line++) {
        final y = staffTop + line * style.staffSpace;
        canvas.drawLine(Offset(left, y), Offset(right, y), staffPaint);
      }
    }
    canvas.drawLine(
      Offset(left, top),
      Offset(left, bassTop + style.staffSpace * 4),
      Paint()
        ..color = Colors.black87
        ..strokeWidth = 1.8,
    );
    _drawBrace(canvas, left - 5, top, bassTop + style.staffSpace * 4);

    _text(canvas, textPainter, '\u{1D11E}', left + 5, top - 35, 48);
    _text(canvas, textPainter, '\u{1D122}', left + 8, bassTop - 23, 40);
    _drawKeySignature(canvas, textPainter, system);

    if (system.index == 0) {
      _text(
        canvas,
        textPainter,
        '♩ = $tempo',
        left,
        top - 62,
        13,
        weight: FontWeight.w600,
      );
    } else {
      _text(
        canvas,
        textPainter,
        '${system.measures.first.measure.index + 1}',
        system.measures.first.x + 3,
        top - 25,
        10,
        color: Colors.black54,
        weight: FontWeight.w600,
      );
    }

    for (final measureLayout in system.measures) {
      final measure = measureLayout.measure;
      if (measure.showTimeSignature) {
        _drawTimeSignature(
          canvas,
          textPainter,
          measure.timeSignature,
          measureLayout.x + 4,
          top,
        );
      }
      canvas.drawLine(
        Offset(measureLayout.x, top),
        Offset(measureLayout.x, bassTop + style.staffSpace * 4),
        staffPaint,
      );
    }
    canvas.drawLine(
      Offset(right, top),
      Offset(right, bassTop + style.staffSpace * 4),
      Paint()
        ..color = Colors.black87
        ..strokeWidth = system == layout.systems.last ? 2.2 : 1.15,
    );
  }

  void _drawNotesAndRests(
    Canvas canvas,
    Paint staffPaint,
    TextPainter textPainter,
  ) {
    for (final system in layout.systems) {
      for (final measureLayout in system.measures) {
        final measure = measureLayout.measure;
        final noteheadShifts = _noteheadShifts(measure.notes);
        final accidentalShifts = _accidentalShifts(measure.notes);
        for (final rest in measure.rests) {
          _drawRest(canvas, measureLayout, system, rest, textPainter);
        }
        for (final note in measure.notes) {
          _drawNote(
            canvas,
            measureLayout,
            system,
            note,
            noteheadShifts[note] ?? 0,
            accidentalShifts[note] ?? 0,
            staffPaint,
            textPainter,
          );
        }
      }
    }
  }

  Map<EngravedNoteFragment, double> _noteheadShifts(
    List<EngravedNoteFragment> notes,
  ) {
    final result = <EngravedNoteFragment, double>{};
    final groups = <String, List<EngravedNoteFragment>>{};
    for (final note in notes) {
      final key = '${note.startBeat}:${note.staff}:${note.voice}';
      groups.putIfAbsent(key, () => []).add(note);
    }
    for (final group in groups.values) {
      group.sort(
        (a, b) => _diatonicStep(
          a.source.note,
        ).compareTo(_diatonicStep(b.source.note)),
      );
      var shifted = false;
      for (var i = 0; i < group.length; i++) {
        if (i > 0 &&
            (_diatonicStep(group[i].source.note) -
                        _diatonicStep(group[i - 1].source.note))
                    .abs() ==
                1) {
          shifted = !shifted;
        } else {
          shifted = false;
        }
        result[group[i]] = shifted ? 7.0 : 0.0;
      }
    }
    return result;
  }

  Map<EngravedNoteFragment, double> _accidentalShifts(
    List<EngravedNoteFragment> notes,
  ) {
    final result = <EngravedNoteFragment, double>{};
    final groups = <String, List<EngravedNoteFragment>>{};
    for (final note in notes.where((note) => note.accidental != null)) {
      groups.putIfAbsent('${note.startBeat}:${note.staff}', () => []).add(note);
    }
    for (final group in groups.values) {
      group.sort(
        (a, b) => _diatonicStep(
          b.source.note,
        ).compareTo(_diatonicStep(a.source.note)),
      );
      final lastStepByColumn = <int>[];
      for (final note in group) {
        final step = _diatonicStep(note.source.note);
        var column = lastStepByColumn.indexWhere(
          (lastStep) => (lastStep - step).abs() >= 7,
        );
        if (column < 0) {
          column = lastStepByColumn.length;
          lastStepByColumn.add(step);
        } else {
          lastStepByColumn[column] = step;
        }
        result[note] = column * 8.0;
      }
    }
    return result;
  }

  void _drawNote(
    Canvas canvas,
    EngravedMeasureLayout measureLayout,
    EngravedSystem system,
    EngravedNoteFragment note,
    double headShift,
    double accidentalShift,
    Paint staffPaint,
    TextPainter textPainter,
  ) {
    final selected = note.sourceIndex == selectedSourceIndex;
    final highlighted = note.sourceIndex == highlightedSourceIndex;
    final color = selected
        ? Colors.deepOrange
        : highlighted
        ? Colors.orange
        : Colors.black;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final outline = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 2 : 1.35;
    final x = measureLayout.xForBeat(note.startBeat) + headShift;
    final y = EngravedScoreGeometry.noteY(
      layout,
      system.index,
      note.staff,
      note.source.note,
    );
    final staffTop = EngravedScoreGeometry.staffTop(
      layout,
      system.index,
      note.staff,
    );
    _drawLedgerLines(canvas, x, y, staffTop, staffPaint);
    if (note.accidental != null) {
      _text(
        canvas,
        textPainter,
        note.accidental!,
        x - 22 - accidentalShift,
        y - 12,
        19,
        color: color,
      );
    }

    final whole = note.duration == 'whole' || note.durationBeat >= 3.75;
    final half =
        !whole &&
        (note.duration == 'half' ||
            note.duration == 'dotted_half' ||
            note.durationBeat >= 1.75);
    final head = Rect.fromCenter(
      center: Offset(x, y),
      width: 15.5,
      height: 10.5,
    );
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(-0.22);
    canvas.translate(-x, -y);
    canvas.drawOval(head, whole || half ? outline : fill);
    canvas.restore();
    if (whole) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 8, height: 4.5),
        Paint()..color = backgroundColor,
      );
    }

    if (note.duration.startsWith('dotted_')) {
      canvas.drawCircle(Offset(x + 12, y - 1), 1.8, fill);
    }
    if (!whole && note.beamGroup == null) {
      final stemUp = _stemUp(note, measureLayout.measure);
      _drawStemAndFlags(canvas, x, y, stemUp, note.duration, outline, color);
    }
    if (note.duration.contains('triplet')) {
      _text(
        canvas,
        textPainter,
        '3',
        x - 3,
        y - 48,
        10,
        color: color,
        weight: FontWeight.bold,
      );
    }
    if (note.tieToNext) {
      _drawTie(
        canvas,
        Offset(x + 5, y + 5),
        Offset(measureLayout.x + measureLayout.width - 4, y + 5),
        color,
      );
    }
    if (note.tieFromPrevious) {
      _drawTie(
        canvas,
        Offset(measureLayout.x + 4, y + 5),
        Offset(x - 5, y + 5),
        color,
      );
    }
    if (note.source.chord.isNotEmpty) {
      _text(
        canvas,
        textPainter,
        note.source.chord,
        x - 8,
        system.top - 45,
        12,
        color: Colors.indigo,
        weight: FontWeight.w600,
      );
    }
    if (note.source.lyric.isNotEmpty) {
      _text(
        canvas,
        textPainter,
        note.source.lyric,
        x - 10,
        staffTop + layout.style.staffSpace * 5 + 10,
        11,
        color: color,
      );
    }
  }

  void _drawBeams(Canvas canvas) {
    final groups =
        <
          int,
          List<
            ({
              EngravedNoteFragment note,
              EngravedMeasureLayout measure,
              EngravedSystem system,
            })
          >
        >{};
    for (final system in layout.systems) {
      for (final measure in system.measures) {
        for (final note in measure.measure.notes) {
          if (note.beamGroup != null) {
            groups.putIfAbsent(note.beamGroup!, () => []).add((
              note: note,
              measure: measure,
              system: system,
            ));
          }
        }
      }
    }

    for (final group in groups.values) {
      final byOnset = <double, List<BeamEntry>>{};
      for (final entry in group) {
        byOnset.putIfAbsent(entry.note.startBeat, () => []).add(entry);
      }
      final onsets = byOnset.keys.toList()..sort();
      if (onsets.length < 2) continue;
      final firstEntry = byOnset[onsets.first]!.first;
      final system = firstEntry.system;
      final staff = firstEntry.note.staff;
      final voice = firstEntry.note.voice;
      final measure = firstEntry.measure.measure;
      final voices = measure.notes
          .where((note) => note.staff == staff)
          .map((note) => note.voice)
          .toSet();
      final averageY =
          group
              .map(
                (entry) => EngravedScoreGeometry.noteY(
                  layout,
                  system.index,
                  staff,
                  entry.note.source.note,
                ),
              )
              .reduce((a, b) => a + b) /
          group.length;
      final middleY =
          EngravedScoreGeometry.staffTop(layout, system.index, staff) +
          layout.style.staffSpace * 2;
      final stemUp = voices.length > 1 ? voice.isEven : averageY >= middleY;
      final points = <Offset>[];
      for (final onset in onsets) {
        final entries = byOnset[onset]!;
        final x = entries.first.measure.xForBeat(onset) + (stemUp ? 7 : -7);
        final ys = entries.map(
          (entry) => EngravedScoreGeometry.noteY(
            layout,
            system.index,
            staff,
            entry.note.source.note,
          ),
        );
        final y = stemUp ? ys.reduce(min) - 36 : ys.reduce(max) + 36;
        points.add(Offset(x, y));
      }
      final start = points.first;
      final end = points.last;
      final beamPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.butt;
      canvas.drawLine(start, end, beamPaint);

      for (var i = 0; i < onsets.length; i++) {
        final entries = byOnset[onsets[i]]!;
        final beamY =
            start.dy +
            (end.dy - start.dy) *
                (end.dx == start.dx
                    ? 0
                    : (points[i].dx - start.dx) / (end.dx - start.dx));
        final headYs = entries.map(
          (entry) => EngravedScoreGeometry.noteY(
            layout,
            system.index,
            staff,
            entry.note.source.note,
          ),
        );
        final stemStartY = stemUp ? headYs.reduce(max) : headYs.reduce(min);
        canvas.drawLine(
          Offset(points[i].dx, stemStartY),
          Offset(points[i].dx, beamY),
          Paint()
            ..color = Colors.black
            ..strokeWidth = 1.25,
        );
      }

      final maxFlags = group
          .map((entry) => _flagCount(entry.note.duration))
          .reduce(max);
      for (var level = 2; level <= maxFlags; level++) {
        final offset = (stemUp ? 1 : -1) * 5.5 * (level - 1);
        for (var i = 0; i < onsets.length - 1; i++) {
          final leftFlags = byOnset[onsets[i]]!
              .map((entry) => _flagCount(entry.note.duration))
              .reduce(max);
          final rightFlags = byOnset[onsets[i + 1]]!
              .map((entry) => _flagCount(entry.note.duration))
              .reduce(max);
          if (leftFlags >= level && rightFlags >= level) {
            final leftRatio = end.dx == start.dx
                ? 0.0
                : (points[i].dx - start.dx) / (end.dx - start.dx);
            final rightRatio = end.dx == start.dx
                ? 1.0
                : (points[i + 1].dx - start.dx) / (end.dx - start.dx);
            canvas.drawLine(
              Offset(
                points[i].dx,
                start.dy + (end.dy - start.dy) * leftRatio + offset,
              ),
              Offset(
                points[i + 1].dx,
                start.dy + (end.dy - start.dy) * rightRatio + offset,
              ),
              beamPaint,
            );
          }
        }
      }
      // Keep analyzer aware that the beam belongs to this measure; this also
      // documents that beams never cross a barline in the generated model.
      assert(group.every((entry) => entry.measure.measure == measure));
    }
  }

  void _drawRest(
    Canvas canvas,
    EngravedMeasureLayout measureLayout,
    EngravedSystem system,
    EngravedRest rest,
    TextPainter textPainter,
  ) {
    final x = rest.isMeasureRest
        ? measureLayout.x + measureLayout.width / 2
        : measureLayout.xForBeat(rest.startBeat + rest.durationBeat / 2);
    final top = EngravedScoreGeometry.staffTop(
      layout,
      system.index,
      rest.staff,
    );
    final voiceOffset = rest.voice == 0 ? 0.0 : (rest.voice.isOdd ? 9.0 : -9.0);
    final y = top + layout.style.staffSpace * 2 + voiceOffset;
    final fill = Paint()..color = Colors.black87;
    final stroke = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (rest.isMeasureRest || rest.duration == 'whole') {
      canvas.drawRect(Rect.fromLTWH(x - 6, y - 5, 12, 4.5), fill);
    } else if (rest.duration == 'half' || rest.duration == 'dotted_half') {
      canvas.drawRect(Rect.fromLTWH(x - 6, y, 12, 4.5), fill);
    } else if (rest.duration.contains('quarter')) {
      final path = Path()
        ..moveTo(x + 2, y - 12)
        ..lineTo(x - 3, y - 3)
        ..lineTo(x + 3, y + 5)
        ..lineTo(x - 2, y + 14)
        ..quadraticBezierTo(x + 6, y + 11, x + 2, y + 18);
      canvas.drawPath(path, stroke);
    } else {
      final flags = _flagCount(rest.duration).clamp(1, 4);
      canvas.drawLine(Offset(x + 2, y - 11), Offset(x - 2, y + 14), stroke);
      for (var flag = 0; flag < flags; flag++) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x + 3, y - 9 + flag * 5.5),
            width: 7,
            height: 5,
          ),
          fill,
        );
      }
    }
    if (rest.duration.startsWith('dotted_')) {
      canvas.drawCircle(Offset(x + 10, y), 1.6, fill);
    }
    if (rest.duration.contains('triplet')) {
      _text(
        canvas,
        textPainter,
        '3',
        x - 3,
        y - 28,
        9,
        weight: FontWeight.bold,
      );
    }
  }

  void _drawPlayhead(Canvas canvas) {
    if (playheadBeat == null) return;
    final measure = layout.measureForBeat(playheadBeat!);
    final system = layout.systems[measure.systemIndex];
    final x = measure.xForBeat(playheadBeat!);
    canvas.drawLine(
      Offset(x, system.top - 42),
      Offset(
        x,
        system.top +
            layout.style.grandStaffDistance +
            layout.style.staffSpace * 5,
      ),
      Paint()
        ..color = Colors.redAccent
        ..strokeWidth = 2,
    );
  }

  void _drawLedgerLines(
    Canvas canvas,
    double x,
    double y,
    double staffTop,
    Paint paint,
  ) {
    final bottom = staffTop + layout.style.staffSpace * 4;
    if (y < staffTop - 1) {
      for (
        var ledger = staffTop - layout.style.staffSpace;
        ledger >= y - 1;
        ledger -= layout.style.staffSpace
      ) {
        canvas.drawLine(Offset(x - 10, ledger), Offset(x + 10, ledger), paint);
      }
    } else if (y > bottom + 1) {
      for (
        var ledger = bottom + layout.style.staffSpace;
        ledger <= y + 1;
        ledger += layout.style.staffSpace
      ) {
        canvas.drawLine(Offset(x - 10, ledger), Offset(x + 10, ledger), paint);
      }
    }
  }

  bool _stemUp(EngravedNoteFragment note, EngravedMeasure measure) {
    final voices = measure.notes
        .where((item) => item.staff == note.staff)
        .map((item) => item.voice)
        .toSet();
    if (voices.length > 1) return note.voice.isEven;
    final system = layout.measureForBeat(note.startBeat).systemIndex;
    final y = EngravedScoreGeometry.noteY(
      layout,
      system,
      note.staff,
      note.source.note,
    );
    final middle =
        EngravedScoreGeometry.staffTop(layout, system, note.staff) +
        layout.style.staffSpace * 2;
    return y >= middle;
  }

  void _drawStemAndFlags(
    Canvas canvas,
    double x,
    double y,
    bool stemUp,
    String duration,
    Paint outline,
    Color color,
  ) {
    final stemX = x + (stemUp ? 7 : -7);
    final stemEnd = y + (stemUp ? -36 : 36);
    canvas.drawLine(Offset(stemX, y), Offset(stemX, stemEnd), outline);
    final flags = _flagCount(duration);
    final direction = stemUp ? 1.0 : -1.0;
    for (var flag = 0; flag < flags; flag++) {
      final anchor = stemEnd + (stemUp ? flag * 5.5 : -flag * 5.5);
      final path = Path()
        ..moveTo(stemX, anchor)
        ..cubicTo(
          stemX + direction * 11,
          anchor + (stemUp ? 7 : -7),
          stemX + direction * 10,
          anchor + (stemUp ? 15 : -15),
          stemX + direction * 2,
          anchor + (stemUp ? 19 : -19),
        );
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
  }

  void _drawTie(Canvas canvas, Offset start, Offset end, Color color) {
    if (end.dx <= start.dx + 2) return;
    final height = min(10.0, max(5.0, (end.dx - start.dx) * 0.08));
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(
        (start.dx + end.dx) / 2,
        start.dy + height,
        end.dx,
        end.dy,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _drawBrace(Canvas canvas, double x, double top, double bottom) {
    final middle = (top + bottom) / 2;
    final path = Path()
      ..moveTo(x + 4, top)
      ..cubicTo(x - 4, top + 18, x - 4, middle - 15, x + 1, middle)
      ..cubicTo(x - 4, middle + 15, x - 4, bottom - 18, x + 4, bottom);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawTimeSignature(
    Canvas canvas,
    TextPainter painter,
    String signature,
    double x,
    double top,
  ) {
    final parts = signature.split('/');
    if (parts.length != 2) return;
    for (final staffTop in [top, top + layout.style.grandStaffDistance]) {
      _text(
        canvas,
        painter,
        parts[0],
        x,
        staffTop - 11,
        17,
        weight: FontWeight.bold,
      );
      _text(
        canvas,
        painter,
        parts[1],
        x,
        staffTop + 8,
        17,
        weight: FontWeight.bold,
      );
    }
  }

  void _drawKeySignature(
    Canvas canvas,
    TextPainter painter,
    EngravedSystem system,
  ) {
    final count = _keySignatureAccidentalCount(layout.keySignature);
    final symbol = count >= 0 ? '♯' : '♭';
    final treble = count >= 0
        ? const ['F5', 'C5', 'G5', 'D5', 'A4', 'E5', 'B4']
        : const ['B4', 'E5', 'A4', 'D5', 'G4', 'C5', 'F4'];
    final bass = count >= 0
        ? const ['F3', 'C3', 'G3', 'D3', 'A2', 'E3', 'B2']
        : const ['B2', 'E3', 'A2', 'D3', 'G2', 'C3', 'F2'];
    final startX = layout.style.pageLeft + 49;
    for (var i = 0; i < count.abs(); i++) {
      _text(
        canvas,
        painter,
        symbol,
        startX + i * 8.5,
        EngravedScoreGeometry.noteY(layout, system.index, 0, treble[i]) - 12,
        17,
      );
      _text(
        canvas,
        painter,
        symbol,
        startX + i * 8.5,
        EngravedScoreGeometry.noteY(layout, system.index, 1, bass[i]) - 12,
        17,
      );
    }
  }

  int _keySignatureAccidentalCount(String key) {
    const counts = {
      'Cb Major': -7,
      'Gb Major': -6,
      'Db Major': -5,
      'Ab Major': -4,
      'Eb Major': -3,
      'Bb Major': -2,
      'F Major': -1,
      'C Major': 0,
      'G Major': 1,
      'D Major': 2,
      'A Major': 3,
      'E Major': 4,
      'B Major': 5,
      'F# Major': 6,
      'C# Major': 7,
      'Ab Minor': -7,
      'Eb Minor': -6,
      'Bb Minor': -5,
      'F Minor': -4,
      'C Minor': -3,
      'G Minor': -2,
      'D Minor': -1,
      'A Minor': 0,
      'E Minor': 1,
      'B Minor': 2,
      'F# Minor': 3,
      'C# Minor': 4,
      'G# Minor': 5,
      'D# Minor': 6,
      'A# Minor': 7,
    };
    return counts[key] ?? 0;
  }

  int _flagCount(String duration) {
    if (duration.contains('sixty_fourth')) return 4;
    if (duration.contains('thirty_second')) return 3;
    if (duration.contains('sixteenth')) return 2;
    if (duration.contains('eighth')) return 1;
    return 0;
  }

  int _diatonicStep(String note) {
    final match = RegExp(r'^([A-G])([#b]?)(-?\d+)$').firstMatch(note);
    if (match == null) return 28;
    const steps = {'C': 0, 'D': 1, 'E': 2, 'F': 3, 'G': 4, 'A': 5, 'B': 6};
    return int.parse(match.group(3)!) * 7 + steps[match.group(1)]!;
  }

  void _text(
    Canvas canvas,
    TextPainter painter,
    String text,
    double x,
    double y,
    double fontSize, {
    Color color = Colors.black,
    FontWeight weight = FontWeight.normal,
    bool centered = false,
    bool alignedRight = false,
  }) {
    painter.text = TextSpan(
      text: text,
      style: TextStyle(color: color, fontSize: fontSize, fontWeight: weight),
    );
    painter.layout();
    final paintX = centered
        ? x - painter.width / 2
        : alignedRight
        ? x - painter.width
        : x;
    painter.paint(canvas, Offset(paintX, y));
  }

  @override
  bool shouldRepaint(covariant EngravedScorePainter oldDelegate) {
    return oldDelegate.layout != layout ||
        oldDelegate.selectedSourceIndex != selectedSourceIndex ||
        oldDelegate.highlightedSourceIndex != highlightedSourceIndex ||
        oldDelegate.playheadBeat != playheadBeat ||
        oldDelegate.tempo != tempo ||
        oldDelegate.title != title ||
        oldDelegate.composer != composer;
  }
}

class EngravedScoreOverlayPainter extends CustomPainter {
  final EngravedScoreLayout layout;
  final List<LessonNote> notes;
  final int? highlightIndex;
  final double? countdownSeconds;
  final double glowProgress;
  final ValueNotifier<double>? elapsedNotifier;
  final bool showTimeline;

  EngravedScoreOverlayPainter({
    required this.layout,
    required this.notes,
    required this.highlightIndex,
    required this.countdownSeconds,
    required this.glowProgress,
    required this.elapsedNotifier,
    required this.showTimeline,
  }) : super(repaint: elapsedNotifier);

  @override
  void paint(Canvas canvas, Size size) {
    if (highlightIndex != null && highlightIndex! < notes.length) {
      final source = notes[highlightIndex!];
      final fragment = layout.measures
          .expand((measure) => measure.notes)
          .where((note) => note.sourceIndex == highlightIndex)
          .firstOrNull;
      if (fragment != null) {
        final measure = layout.measureForBeat(fragment.startBeat);
        final x = measure.xForBeat(fragment.startBeat);
        final y = EngravedScoreGeometry.noteY(
          layout,
          measure.systemIndex,
          fragment.staff,
          source.note,
        );
        final radius = 15 + glowProgress * 8;
        canvas.drawCircle(
          Offset(x, y),
          radius,
          Paint()
            ..color = Colors.orange.withAlpha(
              (55 + glowProgress * 70).round().clamp(0, 255),
            )
            ..maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              6 + glowProgress * 4,
            ),
        );
        if (countdownSeconds != null) {
          final painter = TextPainter(
            textDirection: TextDirection.ltr,
            text: TextSpan(
              text: countdownSeconds!.toStringAsFixed(1),
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          )..layout();
          painter.paint(canvas, Offset(x - painter.width / 2, y - 55));
        }
      }
    }

    if (showTimeline && elapsedNotifier != null && notes.isNotEmpty) {
      final beat = _beatAtElapsed(elapsedNotifier!.value);
      final measure = layout.measureForBeat(beat);
      final system = layout.systems[measure.systemIndex];
      final x = measure.xForBeat(beat);
      final top = system.top - layout.style.staffSpace;
      final bottom =
          system.top +
          layout.style.grandStaffDistance +
          layout.style.staffSpace * 5;
      canvas.drawLine(
        Offset(x, top),
        Offset(x, bottom),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.18)
          ..strokeWidth = 6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawLine(
        Offset(x, top),
        Offset(x, bottom),
        Paint()
          ..color = Colors.black87
          ..strokeWidth = 2,
      );
    }
  }

  double _beatAtElapsed(double elapsed) {
    final ordered = [...notes]..sort((a, b) => a.second.compareTo(b.second));
    if (elapsed <= ordered.first.second) return ordered.first.startBeat;
    if (elapsed >= ordered.last.second) {
      final last = ordered.last;
      return last.startBeat + max(0, elapsed - last.second);
    }
    for (var i = 0; i < ordered.length - 1; i++) {
      final left = ordered[i];
      final right = ordered[i + 1];
      if (elapsed <= right.second) {
        if ((right.second - left.second).abs() < 0.0001) {
          return left.startBeat;
        }
        final ratio = (elapsed - left.second) / (right.second - left.second);
        return left.startBeat + (right.startBeat - left.startBeat) * ratio;
      }
    }
    return ordered.last.startBeat;
  }

  @override
  bool shouldRepaint(covariant EngravedScoreOverlayPainter oldDelegate) {
    return oldDelegate.layout != layout ||
        oldDelegate.highlightIndex != highlightIndex ||
        oldDelegate.countdownSeconds != countdownSeconds ||
        oldDelegate.glowProgress != glowProgress ||
        oldDelegate.showTimeline != showTimeline;
  }
}

typedef BeamEntry = ({
  EngravedNoteFragment note,
  EngravedMeasureLayout measure,
  EngravedSystem system,
});
