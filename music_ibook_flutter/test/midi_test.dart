import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_ibook_flutter/services/midi_service.dart';
import 'package:music_ibook_flutter/utils/music_xml_generator.dart';

void main() {
  test('Test MIDI parsing and MusicXML generation performance', () {
    print('Reading file...');
    final bytes = File(
      r'C:\Users\NgnHung\Downloads\youre only lonely L.mid',
    ).readAsBytesSync();

    print('Parsing MIDI...');
    final stopwatch = Stopwatch()..start();
    final result = MidiService.parseMidiBytes(bytes);
    print(
      'Parsed ${result.notes.length} notes in ${stopwatch.elapsedMilliseconds}ms.',
    );

    print('Generating MusicXML...');
    stopwatch.reset();
    final xml = MusicXmlGenerator.generate(result.notes);
    print(
      'Generated MusicXML of length ${xml.length} in ${stopwatch.elapsedMilliseconds}ms.',
    );
  });
}
