import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_ibook_flutter/models/lesson.dart';
import 'package:music_ibook_flutter/services/midi_service.dart';
import 'package:music_ibook_flutter/widgets/music_staff.dart';

void main() {
  test('parses timing, running status, tempo map and flat key spelling', () {
    final result = MidiService.parseMidiBytes(_buildRegressionMidi());

    expect(result.tempo, 120);
    expect(result.timeSignature, '3/4');
    expect(result.keySignature, 'F Major');
    expect(result.notes, hasLength(3));

    expect(result.notes[0].note, 'Db4');
    expect(result.notes[0].startBeat, 1);
    expect(result.notes[0].durationBeat, 0.5);

    expect(result.notes[1].note, 'D4');
    expect(result.notes[1].startBeat, 1.5);
    expect(result.notes[1].durationBeat, closeTo(1 / 3, 0.000001));
    expect(result.notes[1].duration, 'eighth_triplet');

    expect(result.notes[2].note, 'E4');
    expect(result.notes[2].startBeat, 2);
    expect(result.notes[2].durationBeat, 1);
    expect(result.notes[2].second, 0.5);
  });

  test('ignores General MIDI percussion channel', () {
    final result = MidiService.parseMidiBytes(_buildRegressionMidi());
    expect(result.notes.every((note) => note.note != 'C5'), isTrue);
  });

  test('parses the local jingle bells fixture when present', () {
    final file = File('../Music-IBook-API/jingle bel.mid');
    if (!file.existsSync()) return;

    final result = MidiService.parseMidiBytes(file.readAsBytesSync());
    expect(result.notes, hasLength(25));
    expect(result.tempo, 50);
    expect(result.timeSignature, '4/4');
    expect(result.notes.take(5).map((note) => note.note), [
      'E4',
      'E4',
      'E4',
      'E4',
      'E4',
    ]);
  });

  test('transcribes a polyphonic piano MIDI into two staves', () {
    final file = File('../River Flows In You.mid');
    if (!file.existsSync()) return;

    final result = MidiService.parseMidiBytes(file.readAsBytesSync());
    expect(result.notes, hasLength(837));
    expect(result.tempo, 65);
    expect(result.keySignature, 'A Major');
    expect(
      result.timeSignatureMap,
      '1.0:4/4;5.0:3/4;8.0:4/4;12.0:3/4;15.0:4/4;75.0:5/4;80.0:4/4',
    );
    expect(result.notes.any((note) => note.staff == 0), isTrue);
    expect(result.notes.any((note) => note.staff == 1), isTrue);
    expect(result.notes.where((note) => note.startBeat == 3.5), isNotEmpty);
  });

  testWidgets('renders an imported polyphonic score without layout errors', (
    tester,
  ) async {
    final file = File('../River Flows In You.mid');
    if (!file.existsSync()) return;

    final result = MidiService.parseMidiBytes(file.readAsBytesSync());
    final lesson = MusicLesson(
      title: 'River Flows In You',
      keySignature: result.keySignature,
      timeSignature: result.timeSignature,
      timeSignatureMap: result.timeSignatureMap,
      tempo: result.tempo,
      notes: result.notes,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 900,
          height: 600,
          child: MusicStaff(lesson: lesson),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

Uint8List _buildRegressionMidi() {
  const division = 384;
  final conductorTrack = <int>[
    ..._vlq(0),
    0xff,
    0x51,
    0x03,
    0x07,
    0xa1,
    0x20, // 120 BPM
    ..._vlq(0),
    0xff,
    0x58,
    0x04,
    0x03,
    0x02,
    0x18,
    0x08, // 3/4
    ..._vlq(0),
    0xff,
    0x59,
    0x02,
    0xff,
    0x00, // F Major, one flat
    ..._vlq(division),
    0xff,
    0x51,
    0x03,
    0x0f,
    0x42,
    0x40, // 60 BPM from beat 2
    ..._endOfTrack,
  ];

  final melodyTrack = <int>[
    ..._vlq(0),
    0x90,
    61,
    100, // Db4 on
    ..._vlq(192),
    61,
    0, // running-status Note On velocity 0 = off
    ..._vlq(0),
    0x90,
    62,
    90, // D4 on
    ..._vlq(128),
    62,
    0, // one-third beat duration, must not be quantized away
    ..._vlq(64),
    0x90,
    64,
    80, // E4 at tick 384
    ..._vlq(384),
    0x80,
    64,
    0,
    ..._endOfTrack,
  ];

  final percussionTrack = <int>[
    ..._vlq(0),
    0x99,
    72,
    100,
    ..._vlq(96),
    0x89,
    72,
    0,
    ..._endOfTrack,
  ];

  return Uint8List.fromList([
    ...'MThd'.codeUnits,
    ..._uint32(6),
    0,
    1, // format 1
    0,
    3, // three tracks
    ..._uint16(division),
    ..._chunk('MTrk', conductorTrack),
    ..._chunk('MTrk', melodyTrack),
    ..._chunk('MTrk', percussionTrack),
  ]);
}

const _endOfTrack = [0x00, 0xff, 0x2f, 0x00];

List<int> _chunk(String id, List<int> data) => [
  ...id.codeUnits,
  ..._uint32(data.length),
  ...data,
];

List<int> _uint16(int value) => [(value >> 8) & 0xff, value & 0xff];

List<int> _uint32(int value) => [
  (value >> 24) & 0xff,
  (value >> 16) & 0xff,
  (value >> 8) & 0xff,
  value & 0xff,
];

List<int> _vlq(int value) {
  final bytes = <int>[value & 0x7f];
  var remaining = value >> 7;
  while (remaining > 0) {
    bytes.insert(0, (remaining & 0x7f) | 0x80);
    remaining >>= 7;
  }
  return bytes;
}
