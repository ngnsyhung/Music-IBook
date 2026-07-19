import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_ibook_flutter/models/lesson_note.dart';
import 'package:music_ibook_flutter/services/midi_service.dart';
import 'package:music_ibook_flutter/services/score_engraving_service.dart';

LessonNote _note(
  String pitch,
  double beat,
  double duration, {
  int staff = 0,
  int voice = 0,
}) {
  return LessonNote(
    second: beat - 1,
    startBeat: beat,
    durationBeat: duration,
    staff: staff,
    voice: voice,
    note: pitch,
    duration: 'quarter',
    lyric: '',
  );
}

void main() {
  test('packs several sparse measures into one justified system', () {
    final layout = ScoreEngravingService.layout(
      notes: [
        _note('C4', 1, 1),
        _note('D4', 5, 1),
        _note('E4', 9, 1),
        _note('F4', 13, 1),
      ],
      width: 1100,
      timeSignature: '4/4',
      timeSignatureMap: '1:4/4',
      keySignature: 'C Major',
    );

    expect(layout.measures, hasLength(4));
    expect(layout.systems, hasLength(1));
    expect(layout.systems.single.measures, hasLength(4));
  });

  test('splits a note at a barline and marks both sides of the tie', () {
    final layout = ScoreEngravingService.layout(
      notes: [_note('G4', 4.5, 1)],
      width: 700,
      timeSignature: '4/4',
      timeSignatureMap: '1:4/4',
      keySignature: 'C Major',
    );

    final fragments = layout.measures
        .expand((measure) => measure.notes)
        .toList();
    expect(fragments, hasLength(2));
    expect(fragments.first.tieToNext, isTrue);
    expect(fragments.first.tieFromPrevious, isFalse);
    expect(fragments.last.tieFromPrevious, isTrue);
    expect(fragments.last.tieToNext, isFalse);
  });

  test('tracks accidentals inside a measure against the key signature', () {
    final layout = ScoreEngravingService.layout(
      notes: [
        _note('F#4', 1, 0.5),
        _note('F4', 2, 0.5),
        _note('F4', 3, 0.5),
        _note('F#4', 4, 0.5),
      ],
      width: 700,
      timeSignature: '4/4',
      timeSignatureMap: '1:4/4',
      keySignature: 'D Major',
    );

    final notes = layout.measures.first.notes;
    expect(notes[0].accidental, isNull);
    expect(notes[1].accidental, '♮');
    expect(notes[2].accidental, isNull);
    expect(notes[3].accidental, '♯');
  });

  test('groups consecutive short notes into a meter-aware beam', () {
    final layout = ScoreEngravingService.layout(
      notes: [
        _note('C5', 1, 0.5),
        _note('D5', 1.5, 0.5),
        _note('E5', 2, 0.5),
        _note('F5', 2.5, 0.5),
      ],
      width: 700,
      timeSignature: '4/4',
      timeSignatureMap: '1:4/4',
      keySignature: 'C Major',
    );

    final notes = layout.measures.first.notes;
    expect(notes[0].beamGroup, isNotNull);
    expect(notes[0].beamGroup, notes[1].beamGroup);
    expect(notes[2].beamGroup, isNotNull);
    expect(notes[2].beamGroup, notes[3].beamGroup);
    expect(notes[0].beamGroup, isNot(notes[2].beamGroup));
  });

  test('River uses multiple measures per system when density allows', () {
    final file = File('../River Flows In You.mid');
    if (!file.existsSync()) return;
    final midi = MidiService.parseMidiBytes(file.readAsBytesSync());
    final layout = ScoreEngravingService.layout(
      notes: midi.notes,
      width: 1000,
      timeSignature: midi.timeSignature,
      timeSignatureMap: midi.timeSignatureMap,
      keySignature: midi.keySignature,
    );

    expect(layout.systems.length, greaterThan(1));
    expect(layout.systems.length, lessThan(layout.measures.length));
    expect(layout.systems.any((system) => system.measures.length > 1), isTrue);
  });
}
