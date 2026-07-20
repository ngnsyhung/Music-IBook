import 'package:flutter_test/flutter_test.dart';
import 'package:music_ibook_flutter/models/lesson_authoring.dart';
import 'package:music_ibook_flutter/models/lesson_note.dart';
import 'package:music_ibook_flutter/utils/music_xml_generator.dart';

LessonNote _note(
  String note,
  double startBeat,
  double durationBeat, {
  int staff = 0,
  String lyric = '',
  String chord = '',
  String fingering = '',
  int track = 0,
  String trackName = '',
}) => LessonNote(
  second: startBeat - 1,
  startBeat: startBeat,
  durationBeat: durationBeat,
  staff: staff,
  track: track,
  trackName: trackName,
  note: note,
  duration: 'quarter',
  lyric: lyric,
  chord: chord,
  fingering: fingering,
);

void main() {
  test('creates a piano MusicXML score with editable notation metadata', () {
    final xml = MusicXmlGenerator.generate(
      [
        _note('C4', 1, 1, lyric: 'Em', chord: 'Am7', fingering: '3'),
        _note('A2', 1, 1, staff: 1),
      ],
      title: 'Em gì ơi',
      composer: 'Test composer',
      keySignature: 'A Minor',
      timeSignature: '3/4',
      tempo: 96,
      annotations: [LessonAnnotation(startBeat: 2, kind: 'Dynamic', text: 'f')],
    );

    expect(xml, contains('<staves>2</staves>'));
    expect(xml, contains('<clef number="2"><sign>F</sign>'));
    expect(xml, contains('<beats>3</beats><beat-type>4</beat-type>'));
    expect(xml, contains('<fifths>0</fifths><mode>minor</mode>'));
    expect(xml, contains('<harmony>'));
    expect(xml, contains('<fingering>3</fingering>'));
    expect(xml, contains('<dynamics><f/></dynamics>'));
    expect(xml, contains('<backup>'));
  });

  test('splits notes at barlines and writes ties', () {
    final xml = MusicXmlGenerator.generate([
      _note('G4', 4.5, 2),
    ], timeSignature: '4/4');

    expect(xml, contains('<measure number="2">'));
    expect(RegExp(r'<tie type="start"/>').allMatches(xml).length, 1);
    expect(RegExp(r'<tie type="stop"/>').allMatches(xml).length, 1);
  });

  test('groups simultaneous notes into a chord with one rhythmic duration', () {
    final xml = MusicXmlGenerator.generate([
      _note('C4', 1, 0.49),
      _note('E4', 1.001, 0.51),
      _note('G4', 1, 0.5),
    ]);

    expect(RegExp(r'<chord/>').allMatches(xml).length, 2);
    expect(
      RegExp(
        r'<note>\s*(?:<chord/>\s*)?<pitch>[\s\S]*?</pitch>\s*<duration>96</duration>',
      ).allMatches(xml).length,
      3,
    );
    expect(RegExp(r'<stem>up</stem>').allMatches(xml).length, 3);
  });

  test('adds beams to consecutive short notes', () {
    final xml = MusicXmlGenerator.generate([
      _note('C4', 1, 0.5),
      _note('D4', 1.5, 0.5),
      _note('E4', 2, 0.25),
      _note('F4', 2.25, 0.25),
    ]);

    expect(xml, contains('<beam number="1">begin</beam>'));
    expect(xml, contains('<beam number="1">end</beam>'));
    expect(xml, contains('<beam number="2">begin</beam>'));
    expect(xml, contains('<beam number="2">end</beam>'));
  });
}
