import 'dart:math';

import '../models/lesson_note.dart';

/// Style values are expressed in logical pixels.  The layout algorithm follows
/// the same high-level model used by desktop engraving programs: calculate a
/// minimum width for every measure, pack measures into systems, then justify
/// the rhythmic slices inside each system.
class EngravingStyle {
  final double pageTop;
  final double pageBottom;
  final double pageLeft;
  final double pageRight;
  final double systemHeaderWidth;
  final double systemHeight;
  final double staffSpace;
  final double grandStaffDistance;
  final double minimumMeasureWidth;
  final double minimumSliceWidth;
  final double spacingRatio;
  final double lastSystemFillThreshold;

  const EngravingStyle({
    this.pageTop = 76,
    this.pageBottom = 28,
    this.pageLeft = 28,
    this.pageRight = 24,
    this.systemHeaderWidth = 132,
    this.systemHeight = 270,
    this.staffSpace = 10,
    this.grandStaffDistance = 100,
    this.minimumMeasureWidth = 104,
    this.minimumSliceWidth = 20,
    this.spacingRatio = 1.5,
    this.lastSystemFillThreshold = 0.65,
  });
}

class EngravedNoteFragment {
  final int sourceIndex;
  final LessonNote source;
  final int measureIndex;
  final double startBeat;
  final double durationBeat;
  final String duration;
  final bool tieFromPrevious;
  final bool tieToNext;
  String? accidental;
  int? beamGroup;

  EngravedNoteFragment({
    required this.sourceIndex,
    required this.source,
    required this.measureIndex,
    required this.startBeat,
    required this.durationBeat,
    required this.duration,
    required this.tieFromPrevious,
    required this.tieToNext,
  });

  int get staff => source.staff == 1 ? 1 : 0;
  int get voice => source.voice.clamp(0, 3);
}

class EngravedRest {
  final int measureIndex;
  final int staff;
  final int voice;
  final double startBeat;
  final double durationBeat;
  final String duration;
  final bool isMeasureRest;

  const EngravedRest({
    required this.measureIndex,
    required this.staff,
    required this.voice,
    required this.startBeat,
    required this.durationBeat,
    required this.duration,
    required this.isMeasureRest,
  });
}

class EngravedMeasure {
  final int index;
  final double startBeat;
  final double endBeat;
  final String timeSignature;
  final List<EngravedNoteFragment> notes = [];
  final List<EngravedRest> rests = [];
  final Map<double, double> sliceWeights = {};
  bool showTimeSignature = false;
  double minimumWidth = 0;

  EngravedMeasure({
    required this.index,
    required this.startBeat,
    required this.endBeat,
    required this.timeSignature,
  });

  double get length => endBeat - startBeat;
}

class EngravedMeasureLayout {
  final EngravedMeasure measure;
  final int systemIndex;
  final double x;
  final double width;
  final Map<double, double> beatX;

  const EngravedMeasureLayout({
    required this.measure,
    required this.systemIndex,
    required this.x,
    required this.width,
    required this.beatX,
  });

  double xForBeat(double beat) {
    final entries = beatX.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    if (entries.isEmpty || beat <= entries.first.key) return x;
    if (beat >= entries.last.key) return x + width;
    for (var i = 0; i < entries.length - 1; i++) {
      final left = entries[i];
      final right = entries[i + 1];
      if (beat < right.key + 0.000001) {
        final span = right.key - left.key;
        final ratio = span <= 0 ? 0.0 : (beat - left.key) / span;
        return left.value + (right.value - left.value) * ratio;
      }
    }
    return x + width;
  }
}

class EngravedSystem {
  final int index;
  final double top;
  final List<EngravedMeasureLayout> measures;

  const EngravedSystem({
    required this.index,
    required this.top,
    required this.measures,
  });

  double get startBeat => measures.first.measure.startBeat;
  double get endBeat => measures.last.measure.endBeat;
}

class EngravedScoreLayout {
  final double width;
  final double height;
  final String keySignature;
  final EngravingStyle style;
  final List<EngravedMeasure> measures;
  final List<EngravedSystem> systems;

  const EngravedScoreLayout({
    required this.width,
    required this.height,
    required this.keySignature,
    required this.style,
    required this.measures,
    required this.systems,
  });

  EngravedMeasureLayout measureForBeat(double beat) {
    for (final system in systems) {
      for (final measure in system.measures) {
        final isLast = identical(measure, systems.last.measures.last);
        if (beat < measure.measure.endBeat - 0.0001 || isLast) return measure;
      }
    }
    return systems.last.measures.last;
  }

  int systemForBeat(double beat) => measureForBeat(beat).systemIndex;

  double xForBeat(double beat) {
    final measure = measureForBeat(beat);
    return measure.xForBeat(beat);
  }

  double beatAt(double x, double y) {
    final rawSystem =
        ((y - style.pageTop + style.systemHeight * 0.18) / style.systemHeight)
            .floor();
    final systemIndex = rawSystem.clamp(0, systems.length - 1);
    final system = systems[systemIndex];
    var measure = system.measures.first;
    for (final candidate in system.measures) {
      if (x >= candidate.x) measure = candidate;
      if (x <= candidate.x + candidate.width) {
        measure = candidate;
        break;
      }
    }

    final entries = measure.beatX.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    if (x <= entries.first.value) return measure.measure.startBeat;
    if (x >= entries.last.value) {
      return max(measure.measure.startBeat, measure.measure.endBeat - 0.0001);
    }
    for (var i = 0; i < entries.length - 1; i++) {
      final left = entries[i];
      final right = entries[i + 1];
      if (x <= right.value) {
        final span = right.value - left.value;
        final ratio = span <= 0 ? 0.0 : (x - left.value) / span;
        return left.key + (right.key - left.key) * ratio;
      }
    }
    return measure.measure.endBeat - 0.0001;
  }
}

class ScoreEngravingService {
  static const _epsilon = 0.0001;
  static const _durationOptions = <({String name, double beats})>[
    (name: 'whole', beats: 4),
    (name: 'dotted_half', beats: 3),
    (name: 'half', beats: 2),
    (name: 'dotted_quarter', beats: 1.5),
    (name: 'quarter', beats: 1),
    (name: 'dotted_eighth', beats: 0.75),
    (name: 'quarter_triplet', beats: 2 / 3),
    (name: 'eighth', beats: 0.5),
    (name: 'dotted_sixteenth', beats: 0.375),
    (name: 'eighth_triplet', beats: 1 / 3),
    (name: 'sixteenth', beats: 0.25),
    (name: 'sixteenth_triplet', beats: 1 / 6),
    (name: 'thirty_second', beats: 0.125),
    (name: 'sixty_fourth', beats: 0.0625),
  ];

  static EngravedScoreLayout layout({
    required List<LessonNote> notes,
    required double width,
    required String timeSignature,
    required String timeSignatureMap,
    required String keySignature,
    double minimumEndBeat = 1,
    EngravingStyle style = const EngravingStyle(),
  }) {
    final scoreWidth = max(320.0, width);
    final lastNoteBeat = notes.isEmpty
        ? 1.0
        : notes.map((note) => note.startBeat + note.durationBeat).reduce(max);
    final measures = _buildMeasures(
      timeSignature: timeSignature,
      timeSignatureMap: timeSignatureMap,
      targetBeat: max(minimumEndBeat, lastNoteBeat),
      minimumMeasures: notes.isEmpty ? 4 : 1,
    );
    for (var i = 0; i < measures.length; i++) {
      measures[i].showTimeSignature =
          i == 0 || measures[i - 1].timeSignature != measures[i].timeSignature;
    }
    _splitNotesAcrossMeasures(notes, measures);
    _buildRests(measures);
    _assignAccidentals(measures, keySignature);
    _assignBeams(measures);
    for (final measure in measures) {
      _calculateMeasureSpacing(measure, style);
    }
    final systems = _packSystems(measures, scoreWidth, style);
    final height =
        style.pageTop + systems.length * style.systemHeight + style.pageBottom;
    return EngravedScoreLayout(
      width: scoreWidth,
      height: height,
      keySignature: keySignature,
      style: style,
      measures: measures,
      systems: systems,
    );
  }

  static List<EngravedMeasure> _buildMeasures({
    required String timeSignature,
    required String timeSignatureMap,
    required double targetBeat,
    required int minimumMeasures,
  }) {
    final fallback = _validSignature(timeSignature) ? timeSignature : '4/4';
    final events = <({double beat, String signature})>[];
    for (final raw in timeSignatureMap.split(';')) {
      final entry = raw.trim();
      final separator = entry.indexOf(':');
      if (separator <= 0) continue;
      final beat = double.tryParse(entry.substring(0, separator));
      final signature = entry.substring(separator + 1).trim();
      if (beat != null && _validSignature(signature)) {
        events.add((beat: max(1.0, beat), signature: signature));
      }
    }
    events.sort((a, b) => a.beat.compareTo(b.beat));
    if (events.isEmpty || events.first.beat > 1 + _epsilon) {
      events.insert(0, (beat: 1, signature: fallback));
    }

    final measures = <EngravedMeasure>[];
    var cursor = 1.0;
    while ((cursor < targetBeat - _epsilon ||
            measures.length < minimumMeasures) &&
        measures.length < 4096) {
      var signature = events.first.signature;
      for (final event in events) {
        if (event.beat <= cursor + _epsilon) {
          signature = event.signature;
        } else {
          break;
        }
      }
      var end = cursor + _signatureBeats(signature);
      for (final event in events) {
        if (event.beat > cursor + _epsilon && event.beat < end - _epsilon) {
          end = event.beat;
          break;
        }
      }
      measures.add(
        EngravedMeasure(
          index: measures.length,
          startBeat: cursor,
          endBeat: end,
          timeSignature: signature,
        ),
      );
      cursor = end;
    }
    return measures;
  }

  static void _splitNotesAcrossMeasures(
    List<LessonNote> notes,
    List<EngravedMeasure> measures,
  ) {
    int measureIndexAt(double beat) {
      for (var i = 0; i < measures.length; i++) {
        if (beat < measures[i].endBeat - _epsilon || i == measures.length - 1) {
          return i;
        }
      }
      return measures.length - 1;
    }

    for (var sourceIndex = 0; sourceIndex < notes.length; sourceIndex++) {
      final source = notes[sourceIndex];
      var cursor = max(1.0, source.startBeat);
      final noteEnd = max(cursor + 0.0625, cursor + source.durationBeat);
      var hasPrevious = false;
      while (cursor < noteEnd - _epsilon) {
        final measureIndex = measureIndexAt(cursor);
        final measure = measures[measureIndex];
        final fragmentEnd = min(noteEnd, measure.endBeat);
        final duration = max(0.0625, fragmentEnd - cursor);
        final hasNext = fragmentEnd < noteEnd - _epsilon;
        measure.notes.add(
          EngravedNoteFragment(
            sourceIndex: sourceIndex,
            source: source,
            measureIndex: measureIndex,
            startBeat: cursor,
            durationBeat: duration,
            duration: _durationName(duration),
            tieFromPrevious: hasPrevious,
            tieToNext: hasNext,
          ),
        );
        cursor = fragmentEnd;
        hasPrevious = true;
      }
    }
    for (final measure in measures) {
      measure.notes.sort((a, b) {
        var order = a.startBeat.compareTo(b.startBeat);
        if (order != 0) return order;
        order = a.staff.compareTo(b.staff);
        if (order != 0) return order;
        order = a.voice.compareTo(b.voice);
        if (order != 0) return order;
        return _midiNumber(a.source.note).compareTo(_midiNumber(b.source.note));
      });
    }
  }

  static void _buildRests(List<EngravedMeasure> measures) {
    for (final measure in measures) {
      for (final staff in [0, 1]) {
        final staffNotes = measure.notes.where((note) => note.staff == staff);
        final voices = staffNotes.map((note) => note.voice).toSet();
        if (voices.isEmpty) {
          measure.rests.add(
            EngravedRest(
              measureIndex: measure.index,
              staff: staff,
              voice: 0,
              startBeat: measure.startBeat,
              durationBeat: measure.length,
              duration: 'measure',
              isMeasureRest: true,
            ),
          );
          continue;
        }

        for (final voice in voices) {
          final spans =
              measure.notes
                  .where((note) => note.staff == staff && note.voice == voice)
                  .map(
                    (note) => (
                      start: max(measure.startBeat, note.startBeat),
                      end: min(
                        measure.endBeat,
                        note.startBeat + note.durationBeat,
                      ),
                    ),
                  )
                  .toList()
                ..sort((a, b) => a.start.compareTo(b.start));
          var cursor = measure.startBeat;
          for (final span in spans) {
            if (span.start > cursor + _epsilon) {
              _appendRestDurations(
                measure,
                staff,
                voice,
                cursor,
                span.start - cursor,
              );
            }
            cursor = max(cursor, span.end);
          }
          if (cursor < measure.endBeat - _epsilon) {
            _appendRestDurations(
              measure,
              staff,
              voice,
              cursor,
              measure.endBeat - cursor,
            );
          }
        }
      }
    }
  }

  static void _appendRestDurations(
    EngravedMeasure measure,
    int staff,
    int voice,
    double start,
    double duration,
  ) {
    var cursor = start;
    var remaining = duration;
    while (remaining > _epsilon) {
      final beatUnit = _beamUnit(measure.timeSignature);
      final nextBoundary =
          measure.startBeat +
          (((cursor - measure.startBeat) / beatUnit).floor() + 1) * beatUnit;
      final rhythmicChunk = min(remaining, max(0.0625, nextBoundary - cursor));
      var option = _durationOptions.last;
      for (final candidate in _durationOptions) {
        if (candidate.beats <= rhythmicChunk + _epsilon) {
          option = candidate;
          break;
        }
      }
      final used = min(rhythmicChunk, option.beats);
      measure.rests.add(
        EngravedRest(
          measureIndex: measure.index,
          staff: staff,
          voice: voice,
          startBeat: cursor,
          durationBeat: used,
          duration: option.name,
          isMeasureRest: false,
        ),
      );
      cursor += used;
      remaining -= used;
    }
  }

  static void _assignAccidentals(
    List<EngravedMeasure> measures,
    String keySignature,
  ) {
    final keyAccidentals = _keyAccidentals(keySignature);
    for (final measure in measures) {
      for (final staff in [0, 1]) {
        final state = <String, String>{};
        final staffNotes = measure.notes.where((note) => note.staff == staff);
        for (final note in staffNotes) {
          if (note.tieFromPrevious) continue;
          final parsed = _parsePitch(note.source.note);
          if (parsed == null) continue;
          final stateKey = '${parsed.letter}${parsed.octave}';
          final expected =
              state[stateKey] ?? keyAccidentals[parsed.letter] ?? '';
          if (parsed.accidental != expected) {
            note.accidental = switch (parsed.accidental) {
              '#' => '♯',
              'b' => '♭',
              _ => '♮',
            };
          }
          state[stateKey] = parsed.accidental;
        }
      }
    }
  }

  static void _assignBeams(List<EngravedMeasure> measures) {
    var nextBeam = 0;
    for (final measure in measures) {
      final beamUnit = _beamUnit(measure.timeSignature);
      for (final staff in [0, 1]) {
        final voices = measure.notes
            .where((note) => note.staff == staff)
            .map((note) => note.voice)
            .toSet();
        for (final voice in voices) {
          final onsetGroups = <double, List<EngravedNoteFragment>>{};
          for (final note in measure.notes.where(
            (note) => note.staff == staff && note.voice == voice,
          )) {
            onsetGroups.putIfAbsent(note.startBeat, () => []).add(note);
          }
          final onsets = onsetGroups.keys.toList()..sort();
          var current = <double>[];

          void flush() {
            if (current.length >= 2) {
              final id = nextBeam++;
              for (final onset in current) {
                for (final note in onsetGroups[onset]!) {
                  if (_flagCount(note.duration) > 0) note.beamGroup = id;
                }
              }
            }
            current = [];
          }

          for (final onset in onsets) {
            final group = onsetGroups[onset]!;
            final shortest = group.map((note) => note.durationBeat).reduce(min);
            if (shortest > 0.5 + _epsilon) {
              flush();
              continue;
            }
            if (current.isEmpty) {
              current.add(onset);
              continue;
            }
            final previousOnset = current.last;
            final previousDuration = onsetGroups[previousOnset]!
                .map((note) => note.durationBeat)
                .reduce(min);
            final contiguous =
                (previousOnset + previousDuration - onset).abs() < 0.001;
            final groupStart =
                measure.startBeat +
                ((onset - measure.startBeat) / beamUnit).floor() * beamUnit;
            final previousGroupStart =
                measure.startBeat +
                ((previousOnset - measure.startBeat) / beamUnit).floor() *
                    beamUnit;
            if (contiguous &&
                (groupStart - previousGroupStart).abs() < _epsilon) {
              current.add(onset);
            } else {
              flush();
              current.add(onset);
            }
          }
          flush();
        }
      }
    }
  }

  static void _calculateMeasureSpacing(
    EngravedMeasure measure,
    EngravingStyle style,
  ) {
    final onsets = <double>{measure.startBeat, measure.endBeat};
    onsets.addAll(measure.notes.map((note) => note.startBeat));
    onsets.addAll(measure.rests.map((rest) => rest.startBeat));
    final sorted = onsets.toList()..sort();
    final exponent = log(style.spacingRatio) / log(2);
    var minimumWidth = 18.0;
    for (var i = 0; i < sorted.length - 1; i++) {
      final onset = sorted[i];
      final delta = max(0.0625, sorted[i + 1] - onset);
      final notesAtOnset = measure.notes.where(
        (note) => (note.startBeat - onset).abs() < _epsilon,
      );
      final accidentalColumns = notesAtOnset
          .where((note) => note.accidental != null)
          .length;
      final hasSecondCollision = _hasSecondCollision(notesAtOnset);
      final lyricLength = notesAtOnset.fold<int>(
        0,
        (value, note) => max(value, note.source.lyric.length),
      );
      final chordLength = notesAtOnset.fold<int>(
        0,
        (value, note) => max(value, note.source.chord.length),
      );
      final rhythmic = style.minimumSliceWidth * pow(delta, exponent);
      final collision =
          accidentalColumns * 5.5 +
          (hasSecondCollision ? 7 : 0) +
          max(lyricLength * 2.2, chordLength * 2.5);
      final weight = max(style.minimumSliceWidth, rhythmic + collision);
      measure.sliceWeights[onset] = weight;
      minimumWidth += weight;
    }
    final signatureWidth = measure.showTimeSignature ? 28.0 : 0.0;
    measure.minimumWidth = max(
      style.minimumMeasureWidth,
      minimumWidth + 14 + signatureWidth,
    );
  }

  static List<EngravedSystem> _packSystems(
    List<EngravedMeasure> measures,
    double width,
    EngravingStyle style,
  ) {
    final notationWidth = max(
      style.minimumMeasureWidth,
      width - style.pageLeft - style.pageRight - style.systemHeaderWidth,
    );
    final packed = <List<EngravedMeasure>>[];
    var current = <EngravedMeasure>[];
    var currentWidth = 0.0;
    for (final measure in measures) {
      final wouldOverflow =
          current.isNotEmpty &&
          currentWidth + measure.minimumWidth > notationWidth + _epsilon;
      if (wouldOverflow) {
        packed.add(current);
        current = [];
        currentWidth = 0;
      }
      current.add(measure);
      currentWidth += measure.minimumWidth;
    }
    if (current.isNotEmpty) packed.add(current);

    final systems = <EngravedSystem>[];
    for (var systemIndex = 0; systemIndex < packed.length; systemIndex++) {
      final systemMeasures = packed[systemIndex];
      final rawWidth = systemMeasures
          .map((measure) => measure.minimumWidth)
          .reduce((a, b) => a + b);
      final isLast = systemIndex == packed.length - 1;
      final shouldFill =
          !isLast || rawWidth / notationWidth >= style.lastSystemFillThreshold;
      final targetWidth = shouldFill
          ? notationWidth
          : min(notationWidth, rawWidth * 1.12);
      final widthScale = targetWidth / rawWidth;
      var x = style.pageLeft + style.systemHeaderWidth;
      final layouts = <EngravedMeasureLayout>[];
      for (final measure in systemMeasures) {
        final measureWidth = measure.minimumWidth * widthScale;
        final beatX = _justifySlices(measure, x, measureWidth);
        layouts.add(
          EngravedMeasureLayout(
            measure: measure,
            systemIndex: systemIndex,
            x: x,
            width: measureWidth,
            beatX: beatX,
          ),
        );
        x += measureWidth;
      }
      systems.add(
        EngravedSystem(
          index: systemIndex,
          top: style.pageTop + systemIndex * style.systemHeight,
          measures: layouts,
        ),
      );
    }
    return systems;
  }

  static Map<double, double> _justifySlices(
    EngravedMeasure measure,
    double x,
    double width,
  ) {
    final onsets = <double>{
      measure.startBeat,
      measure.endBeat,
      ...measure.notes.map((note) => note.startBeat),
      ...measure.rests.map((rest) => rest.startBeat),
    }.toList()..sort();
    final rawTotal = onsets
        .take(onsets.length - 1)
        .map((beat) => measure.sliceWeights[beat] ?? 20)
        .fold<double>(0, (sum, value) => sum + value);
    final leadingPadding = measure.showTimeSignature ? 32.0 : 9.0;
    final available = max(1.0, width - leadingPadding - 9);
    final scale = rawTotal <= 0 ? 1.0 : available / rawTotal;
    final result = <double, double>{onsets.first: x + leadingPadding};
    var cursor = x + leadingPadding;
    for (var i = 0; i < onsets.length - 1; i++) {
      cursor += (measure.sliceWeights[onsets[i]] ?? 20) * scale;
      result[onsets[i + 1]] = cursor;
    }
    result[measure.endBeat] = x + width - 9;
    return result;
  }

  static bool _hasSecondCollision(Iterable<EngravedNoteFragment> notes) {
    final byStaffVoice = <String, List<int>>{};
    for (final note in notes) {
      byStaffVoice
          .putIfAbsent('${note.staff}:${note.voice}', () => [])
          .add(_diatonicStep(note.source.note));
    }
    for (final steps in byStaffVoice.values) {
      steps.sort();
      for (var i = 0; i < steps.length - 1; i++) {
        if ((steps[i + 1] - steps[i]).abs() == 1) return true;
      }
    }
    return false;
  }

  static bool _validSignature(String value) {
    final parts = value.split('/');
    if (parts.length != 2) return false;
    final numerator = int.tryParse(parts[0]);
    final denominator = int.tryParse(parts[1]);
    return numerator != null &&
        numerator > 0 &&
        denominator != null &&
        denominator > 0;
  }

  static double _signatureBeats(String signature) {
    final parts = signature.split('/');
    final numerator = double.tryParse(parts[0]) ?? 4;
    final denominator = double.tryParse(parts[1]) ?? 4;
    return numerator * 4 / denominator;
  }

  static double _beamUnit(String signature) {
    final parts = signature.split('/');
    final numerator = int.tryParse(parts[0]) ?? 4;
    final denominator = int.tryParse(parts[1]) ?? 4;
    if (denominator == 8 && numerator >= 6 && numerator % 3 == 0) return 1.5;
    return 1;
  }

  static String _durationName(double duration) {
    var best = _durationOptions.first;
    var error = double.infinity;
    for (final option in _durationOptions) {
      final current = (duration - option.beats).abs();
      if (current < error) {
        error = current;
        best = option;
      }
    }
    return best.name;
  }

  static int _flagCount(String duration) {
    if (duration.contains('sixty_fourth')) return 4;
    if (duration.contains('thirty_second')) return 3;
    if (duration.contains('sixteenth')) return 2;
    if (duration.contains('eighth')) return 1;
    return 0;
  }

  static Map<String, String> _keyAccidentals(String key) {
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
    final count = counts[key] ?? 0;
    const sharps = ['F', 'C', 'G', 'D', 'A', 'E', 'B'];
    const flats = ['B', 'E', 'A', 'D', 'G', 'C', 'F'];
    final result = <String, String>{};
    if (count > 0) {
      for (final letter in sharps.take(count)) {
        result[letter] = '#';
      }
    } else if (count < 0) {
      for (final letter in flats.take(-count)) {
        result[letter] = 'b';
      }
    }
    return result;
  }

  static ({String letter, String accidental, int octave})? _parsePitch(
    String note,
  ) {
    final match = RegExp(r'^([A-G])([#b]?)(-?\d+)$').firstMatch(note);
    if (match == null) return null;
    return (
      letter: match.group(1)!,
      accidental: match.group(2)!,
      octave: int.parse(match.group(3)!),
    );
  }

  static int _midiNumber(String note) {
    final parsed = _parsePitch(note);
    if (parsed == null) return 60;
    const pitchClass = {
      'C': 0,
      'D': 2,
      'E': 4,
      'F': 5,
      'G': 7,
      'A': 9,
      'B': 11,
    };
    final alteration = parsed.accidental == '#'
        ? 1
        : parsed.accidental == 'b'
        ? -1
        : 0;
    return (parsed.octave + 1) * 12 + pitchClass[parsed.letter]! + alteration;
  }

  static int _diatonicStep(String note) {
    final parsed = _parsePitch(note);
    if (parsed == null) return 28;
    const steps = {'C': 0, 'D': 1, 'E': 2, 'F': 3, 'G': 4, 'A': 5, 'B': 6};
    return parsed.octave * 7 + steps[parsed.letter]!;
  }
}
