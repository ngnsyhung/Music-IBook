import 'dart:math';

import '../models/lesson_authoring.dart';
import '../models/lesson_note.dart';

/// Converts the editable lesson model to MusicXML before it is engraved by
/// OpenSheetMusicDisplay. Imported MIDI tracks remain separate MusicXML parts;
/// only notation that can be derived from timing/pitch metadata is generated.
class MusicXmlGenerator {
  static const _divisions = 192;
  static const _epsilon = 0.0001;

  static const _durationSpecs = <_DurationSpec>[
    _DurationSpec(4, 'whole'),
    _DurationSpec(3, 'half', dots: 1),
    _DurationSpec(2, 'half'),
    _DurationSpec(1.5, 'quarter', dots: 1),
    _DurationSpec(1, 'quarter'),
    _DurationSpec(2 / 3, 'quarter', triplet: true),
    _DurationSpec(0.75, 'eighth', dots: 1),
    _DurationSpec(0.5, 'eighth'),
    _DurationSpec(1 / 3, 'eighth', triplet: true),
    _DurationSpec(0.375, '16th', dots: 1),
    _DurationSpec(0.25, '16th'),
    _DurationSpec(1 / 6, '16th', triplet: true),
    _DurationSpec(0.125, '32nd'),
    _DurationSpec(0.0625, '64th'),
  ];

  static const _fifthsByKey = <String, int>{
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

  static String generate(
    List<LessonNote> notes, {
    String title = '',
    String composer = '',
    String timeSignature = '4/4',
    String timeSignatureMap = '',
    String keySignature = '',
    int tempo = 80,
    String tempoMap = '',
    List<LessonAnnotation> annotations = const [],
  }) {
    final safeTitle = title.trim();
    final notationNotes = _prepareNotationNotes(notes);
    final measures = _buildMeasures(
      notes: notationNotes,
      annotations: annotations,
      initialTimeSignature: timeSignature,
      timeSignatureMap: timeSignatureMap,
    );
    final fragmentsByMeasure = <int, List<_XmlNoteFragment>>{
      for (final measure in measures) measure.index: [],
    };

    for (final note in notationNotes) {
      final noteStart = max(1.0, note.startBeat);
      final noteEnd =
          noteStart + max(_durationSpecs.last.beats, note.durationBeat);
      for (final measure in measures) {
        final start = max(noteStart, measure.startBeat);
        final end = min(noteEnd, measure.endBeat);
        if (end - start <= _epsilon) continue;

        var cursor = start;
        for (final spec in _splitDuration(end - start)) {
          final fragmentEnd = cursor + spec.beats;
          fragmentsByMeasure[measure.index]!.add(
            _XmlNoteFragment(
              note: note,
              startBeat: cursor,
              spec: spec,
              tieStop: cursor > noteStart + _epsilon,
              tieStart: fragmentEnd < noteEnd - _epsilon,
              includeText: (cursor - noteStart).abs() <= _epsilon,
            ),
          );
          cursor = fragmentEnd;
        }
      }
    }

    final parts = _buildParts(notationNotes);
    final tempoChanges = _parseTempoChanges(tempoMap, tempo);
    final output = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8" standalone="no"?>')
      ..writeln('<score-partwise version="3.1">');
    if (safeTitle.isNotEmpty) {
      output.writeln(
        '  <work><work-title>${_escape(safeTitle)}</work-title></work>',
      );
    }
    if (composer.trim().isNotEmpty) {
      output
        ..writeln('  <identification>')
        ..writeln(
          '    <creator type="composer">${_escape(composer.trim())}</creator>',
        )
        ..writeln('  </identification>');
    }
    output.writeln('  <part-list>');
    for (var partIndex = 0; partIndex < parts.length; partIndex++) {
      output.writeln(
        '    <score-part id="P${partIndex + 1}"><part-name>${_escape(parts[partIndex].name)}</part-name></score-part>',
      );
    }
    output.writeln('  </part-list>');

    for (var partIndex = 0; partIndex < parts.length; partIndex++) {
      final part = parts[partIndex];
      output.writeln('  <part id="P${partIndex + 1}">');
      String? previousSignature;
      for (final measure in measures) {
        output.writeln('    <measure number="${measure.index + 1}">');
        final isFirstMeasure = measure.index == 0;
        final fragments = fragmentsByMeasure[measure.index]!
            .where((fragment) => fragment.note.track == part.track)
            .toList();
        if (isFirstMeasure || previousSignature != measure.timeSignature) {
          _writeAttributes(
            output,
            timeSignature: measure.timeSignature,
            keySignature: keySignature,
            firstMeasure: isFirstMeasure,
            staffCount: part.staffCount,
            clefs: part.clefs,
          );
        }
        if (partIndex == 0) {
          for (final change in tempoChanges.entries.where(
            (entry) =>
                entry.key >= measure.startBeat - _epsilon &&
                entry.key < measure.endBeat - _epsilon,
          )) {
            _writeTempoDirection(
              output,
              change.value,
              offset: change.key - measure.startBeat,
            );
          }
          for (final annotation in annotations.where(
            (annotation) =>
                annotation.startBeat >= measure.startBeat - _epsilon &&
                annotation.startBeat < measure.endBeat - _epsilon,
          )) {
            _writeAnnotation(
              output,
              annotation,
              offset: annotation.startBeat - measure.startBeat,
            );
          }
        }

        final voiceKeys = <_VoiceKey>{
          ...fragments.map(
            (fragment) => _VoiceKey(fragment.note.staff, fragment.note.voice),
          ),
        }.toList()..sort();
        if (voiceKeys.isEmpty) voiceKeys.add(const _VoiceKey(0, 0));

        for (var voiceIndex = 0; voiceIndex < voiceKeys.length; voiceIndex++) {
          if (voiceIndex > 0) {
            output.writeln(
              '      <backup><duration>${_duration(measure.length)}</duration></backup>',
            );
          }
          final key = voiceKeys[voiceIndex];
          final voiceFragments =
              fragments
                  .where(
                    (fragment) =>
                        fragment.note.staff == key.staff &&
                        fragment.note.voice == key.voice,
                  )
                  .toList()
                ..sort(_compareFragments);
          _writeVoice(
            output,
            measure: measure,
            fragments: voiceFragments,
            staff: key.staff,
            voice: key.voice,
          );
        }
        output.writeln('    </measure>');
        previousSignature = measure.timeSignature;
      }
      output.writeln('  </part>');
    }
    output.writeln('</score-partwise>');
    return output.toString();
  }

  /// MIDI recorders often release the keys of one chord a few milliseconds
  /// apart. If those tiny differences are preserved in MusicXML, engravers
  /// render several overlapping notes/stems instead of one chord. Snap notes
  /// sharing an onset/staff/voice to one notated duration and remove exact
  /// duplicates without changing the editable lesson data.
  static List<LessonNote> _prepareNotationNotes(List<LessonNote> notes) {
    final unique = <String, LessonNote>{};
    for (final source in notes.where((note) => note.note.trim().isNotEmpty)) {
      final onsetTick = (max(1.0, source.startBeat) * _divisions).round();
      final key =
          '${source.track}|${source.staff}|${source.voice}|$onsetTick|${source.note.trim()}';
      final prepared = source.copyWith(
        note: source.note.trim(),
        startBeat: onsetTick / _divisions,
        durationBeat: max(_durationSpecs.last.beats, source.durationBeat),
      );
      final existing = unique[key];
      if (existing == null || prepared.velocity > existing.velocity) {
        unique[key] = prepared;
      }
    }

    final result = unique.values.toList();
    final chordGroups = <String, List<LessonNote>>{};
    for (final note in result) {
      final onsetTick = (note.startBeat * _divisions).round();
      final key = '${note.track}|${note.staff}|${note.voice}|$onsetTick';
      chordGroups.putIfAbsent(key, () => []).add(note);
    }

    for (final chord in chordGroups.values.where((group) => group.length > 1)) {
      final durationTicks =
          chord.map((note) => (note.durationBeat * _divisions).round()).toList()
            ..sort();
      final frequencies = <int, int>{};
      for (final ticks in durationTicks) {
        frequencies[ticks] = (frequencies[ticks] ?? 0) + 1;
      }
      final highestFrequency = frequencies.values.reduce(max);
      final modalDurations =
          frequencies.entries
              .where((entry) => entry.value == highestFrequency)
              .map((entry) => entry.key)
              .toList()
            ..sort();
      final chosenTicks = highestFrequency > 1
          ? modalDurations.first
          : durationTicks[durationTicks.length ~/ 2];
      final chosenDuration = max(
        _durationSpecs.last.beats,
        chosenTicks / _divisions,
      );
      for (final note in chord) {
        note.durationBeat = chosenDuration;
      }
    }

    result.sort((left, right) {
      final track = left.track.compareTo(right.track);
      if (track != 0) return track;
      final beat = left.startBeat.compareTo(right.startBeat);
      if (beat != 0) return beat;
      final staff = left.staff.compareTo(right.staff);
      if (staff != 0) return staff;
      final voice = left.voice.compareTo(right.voice);
      if (voice != 0) return voice;
      return _pitchSortValue(left.note).compareTo(_pitchSortValue(right.note));
    });
    return result;
  }

  static List<_Measure> _buildMeasures({
    required List<LessonNote> notes,
    required List<LessonAnnotation> annotations,
    required String initialTimeSignature,
    required String timeSignatureMap,
  }) {
    final changes = <double, String>{1: _safeSignature(initialTimeSignature)};
    for (final raw in timeSignatureMap.split(';')) {
      final parts = raw.trim().split(':');
      if (parts.length != 2) continue;
      final beat = double.tryParse(parts.first.trim());
      if (beat != null && beat >= 1) {
        changes[beat] = _safeSignature(parts.last.trim());
      }
    }
    final changeBeats = changes.keys.toList()..sort();
    final scoreEnd = max(
      notes.isEmpty
          ? 1.0
          : notes
                .map((note) => note.startBeat + max(0.0625, note.durationBeat))
                .reduce(max),
      annotations.isEmpty
          ? 1.0
          : annotations
                .map((annotation) => annotation.endBeat ?? annotation.startBeat)
                .reduce(max),
    );

    final measures = <_Measure>[];
    var start = 1.0;
    var signature = changes[1] ?? _safeSignature(initialTimeSignature);
    while (start < scoreEnd + _epsilon || measures.isEmpty) {
      signature = changes[start] ?? signature;
      var end = start + _beatsPerMeasure(signature);
      for (final changedAt in changeBeats) {
        if (changedAt > start + _epsilon && changedAt < end - _epsilon) {
          end = changedAt;
          break;
        }
      }
      measures.add(
        _Measure(
          index: measures.length,
          startBeat: start,
          endBeat: end,
          timeSignature: signature,
        ),
      );
      start = end;
    }
    return measures;
  }

  static List<_TrackPart> _buildParts(List<LessonNote> notes) {
    final trackIds = notes.map((note) => note.track).toSet().toList()..sort();
    if (trackIds.isEmpty) trackIds.add(0);
    return trackIds.map((track) {
      final trackNotes = notes.where((note) => note.track == track).toList();
      String? sourceName;
      for (final note in trackNotes) {
        if (note.trackName.trim().isNotEmpty) {
          sourceName = note.trackName.trim();
          break;
        }
      }
      final staffCount = trackNotes.isEmpty
          ? 1
          : trackNotes.map((note) => max(0, note.staff)).reduce(max) + 1;
      final clefs = <String>[];
      for (var staff = 0; staff < staffCount; staff++) {
        final pitches =
            trackNotes
                .where((note) => max(0, note.staff) == staff)
                .map((note) => _pitchSortValue(note.note))
                .toList()
              ..sort();
        final medianPitch = pitches.isEmpty ? 60 : pitches[pitches.length ~/ 2];
        clefs.add(staffCount > 1 && staff > 0 || medianPitch < 60 ? 'F' : 'G');
      }
      return _TrackPart(
        track: track,
        name: sourceName ?? 'MIDI Track ${track + 1}',
        staffCount: staffCount,
        clefs: clefs,
      );
    }).toList();
  }

  static void _writeAttributes(
    StringBuffer output, {
    required String timeSignature,
    required String keySignature,
    required bool firstMeasure,
    required int staffCount,
    required List<String> clefs,
  }) {
    final parts = timeSignature.split('/');
    final beats = int.tryParse(parts.first) ?? 4;
    final beatType = parts.length == 2 ? int.tryParse(parts.last) ?? 4 : 4;
    output.writeln('      <attributes>');
    if (firstMeasure) {
      output.writeln('        <divisions>$_divisions</divisions>');
      if (_fifthsByKey.containsKey(keySignature)) {
        output.writeln(
          '        <key><fifths>${_fifthsByKey[keySignature]}</fifths><mode>${keySignature.endsWith('Minor') ? 'minor' : 'major'}</mode></key>',
        );
      }
    }
    output.writeln(
      '        <time><beats>$beats</beats><beat-type>$beatType</beat-type></time>',
    );
    if (firstMeasure) {
      if (staffCount > 1) {
        output.writeln('        <staves>$staffCount</staves>');
      }
      for (var staff = 0; staff < staffCount; staff++) {
        final sign = clefs[staff];
        final number = staffCount > 1 ? ' number="${staff + 1}"' : '';
        output.writeln(
          '        <clef$number><sign>$sign</sign><line>${sign == 'F' ? 4 : 2}</line></clef>',
        );
      }
    }
    output.writeln('      </attributes>');
  }

  static void _writeVoice(
    StringBuffer output, {
    required _Measure measure,
    required List<_XmlNoteFragment> fragments,
    required int staff,
    required int voice,
  }) {
    final beamMarks = _buildBeamMarks(fragments, measure);
    var cursor = measure.startBeat;
    for (var index = 0; index < fragments.length;) {
      final start = fragments[index].startBeat;
      if (start > cursor + _epsilon) {
        _writeRest(output, start - cursor, staff: staff, voice: voice);
        cursor = start;
      }
      final chord = <_XmlNoteFragment>[];
      while (index < fragments.length &&
          (fragments[index].startBeat - start).abs() <= _epsilon) {
        chord.add(fragments[index]);
        index++;
      }
      chord.sort(
        (a, b) => _pitchSortValue(
          a.note.note,
        ).compareTo(_pitchSortValue(b.note.note)),
      );
      for (var chordIndex = 0; chordIndex < chord.length; chordIndex++) {
        _writeNote(
          output,
          chord[chordIndex],
          staff: staff,
          voice: voice,
          chordMember: chordIndex > 0,
          beamMarks: beamMarks[start] ?? const [],
        );
      }
      cursor = max(
        cursor,
        chord
            .map((fragment) => fragment.startBeat + fragment.spec.beats)
            .reduce(max),
      );
    }
    if (cursor < measure.endBeat - _epsilon) {
      _writeRest(output, measure.endBeat - cursor, staff: staff, voice: voice);
    }
  }

  static void _writeRest(
    StringBuffer output,
    double beats, {
    required int staff,
    required int voice,
  }) {
    for (final spec in _splitDuration(beats)) {
      output.writeln('      <note>');
      output.writeln('        <rest/>');
      output.writeln('        <duration>${_duration(spec.beats)}</duration>');
      output.writeln('        <voice>${_musicXmlVoice(staff, voice)}</voice>');
      _writeType(output, spec, indent: '        ');
      output.writeln('        <staff>${staff + 1}</staff>');
      output.writeln('      </note>');
    }
  }

  static void _writeNote(
    StringBuffer output,
    _XmlNoteFragment fragment, {
    required int staff,
    required int voice,
    required bool chordMember,
    required List<_BeamMark> beamMarks,
  }) {
    final match = RegExp(
      r'^([A-G])([#b]?)(-?\d+)$',
    ).firstMatch(fragment.note.note);
    final step = match?.group(1) ?? 'C';
    final accidental = match?.group(2) ?? '';
    final octave = match?.group(3) ?? '4';
    if (fragment.includeText &&
        fragment.note.chord.trim().isNotEmpty &&
        !chordMember) {
      _writeHarmony(output, fragment.note.chord.trim());
    }
    output.writeln('      <note>');
    if (chordMember) output.writeln('        <chord/>');
    output.writeln('        <pitch>');
    output.writeln('          <step>$step</step>');
    if (accidental == '#') output.writeln('          <alter>1</alter>');
    if (accidental == 'b') output.writeln('          <alter>-1</alter>');
    output.writeln('          <octave>$octave</octave>');
    output.writeln('        </pitch>');
    output.writeln(
      '        <duration>${_duration(fragment.spec.beats)}</duration>',
    );
    output.writeln('        <voice>${_musicXmlVoice(staff, voice)}</voice>');
    _writeType(output, fragment.spec, indent: '        ');
    if (fragment.spec.type != 'whole') {
      output.writeln('        <stem>${voice.isEven ? 'up' : 'down'}</stem>');
    }
    for (final beam in beamMarks) {
      output.writeln(
        '        <beam number="${beam.number}">${beam.value}</beam>',
      );
    }
    output.writeln('        <staff>${staff + 1}</staff>');
    if (fragment.tieStop) output.writeln('        <tie type="stop"/>');
    if (fragment.tieStart) output.writeln('        <tie type="start"/>');
    if (fragment.includeText &&
        fragment.note.lyric.trim().isNotEmpty &&
        !chordMember) {
      output.writeln(
        '        <lyric><text>${_escape(fragment.note.lyric.trim())}</text></lyric>',
      );
    }
    if (fragment.tieStop ||
        fragment.tieStart ||
        (fragment.includeText &&
            fragment.note.fingering.trim().isNotEmpty &&
            !chordMember)) {
      output.writeln('        <notations>');
      if (fragment.tieStop) output.writeln('          <tied type="stop"/>');
      if (fragment.tieStart) output.writeln('          <tied type="start"/>');
      if (fragment.includeText &&
          fragment.note.fingering.trim().isNotEmpty &&
          !chordMember) {
        output.writeln(
          '          <technical><fingering>${_escape(fragment.note.fingering.trim())}</fingering></technical>',
        );
      }
      output.writeln('        </notations>');
    }
    output.writeln('      </note>');
  }

  static Map<double, List<_BeamMark>> _buildBeamMarks(
    List<_XmlNoteFragment> fragments,
    _Measure measure,
  ) {
    final slicesByStart = <double, _BeamSlice>{};
    for (final fragment in fragments) {
      final level = _beamLevel(fragment.spec.type);
      if (level == 0) continue;
      final current = slicesByStart[fragment.startBeat];
      if (current == null || level > current.level) {
        slicesByStart[fragment.startBeat] = _BeamSlice(
          startBeat: fragment.startBeat,
          durationBeat: fragment.spec.beats,
          level: level,
        );
      }
    }
    final slices = slicesByStart.values.toList()
      ..sort((left, right) => left.startBeat.compareTo(right.startBeat));
    if (slices.length < 2) return const {};

    final signature = measure.timeSignature.split('/');
    final numerator = int.tryParse(signature.first) ?? 4;
    final denominator = signature.length == 2
        ? int.tryParse(signature.last) ?? 4
        : 4;
    final unit = 4 / denominator;
    final groupLength = denominator == 8 && numerator >= 6 && numerator % 3 == 0
        ? unit * 3
        : unit;
    final runs = <List<_BeamSlice>>[];
    var run = <_BeamSlice>[];
    int? group;
    for (final slice in slices) {
      final sliceGroup =
          ((slice.startBeat - measure.startBeat + _epsilon) / groupLength)
              .floor();
      final contiguous =
          run.isEmpty ||
          slice.startBeat <=
              run.last.startBeat + run.last.durationBeat + _epsilon;
      if (run.isNotEmpty && (sliceGroup != group || !contiguous)) {
        if (run.length > 1) runs.add(run);
        run = <_BeamSlice>[];
      }
      run.add(slice);
      group = sliceGroup;
    }
    if (run.length > 1) runs.add(run);

    final result = <double, List<_BeamMark>>{};
    for (final beamRun in runs) {
      for (var level = 1; level <= 4; level++) {
        var index = 0;
        while (index < beamRun.length) {
          if (beamRun[index].level < level) {
            index++;
            continue;
          }
          final segmentStart = index;
          while (index + 1 < beamRun.length &&
              beamRun[index + 1].level >= level) {
            index++;
          }
          final segmentEnd = index;
          if (segmentStart == segmentEnd) {
            if (level > 1) {
              result
                  .putIfAbsent(beamRun[index].startBeat, () => [])
                  .add(
                    _BeamMark(
                      level,
                      index == 0 ? 'forward hook' : 'backward hook',
                    ),
                  );
            }
          } else {
            for (
              var beamIndex = segmentStart;
              beamIndex <= segmentEnd;
              beamIndex++
            ) {
              result
                  .putIfAbsent(beamRun[beamIndex].startBeat, () => [])
                  .add(
                    _BeamMark(
                      level,
                      beamIndex == segmentStart
                          ? 'begin'
                          : beamIndex == segmentEnd
                          ? 'end'
                          : 'continue',
                    ),
                  );
            }
          }
          index++;
        }
      }
    }
    return result;
  }

  static int _beamLevel(String type) => switch (type) {
    'eighth' => 1,
    '16th' => 2,
    '32nd' => 3,
    '64th' => 4,
    _ => 0,
  };

  static void _writeType(
    StringBuffer output,
    _DurationSpec spec, {
    required String indent,
  }) {
    output.writeln('$indent<type>${spec.type}</type>');
    for (var dot = 0; dot < spec.dots; dot++) {
      output.writeln('$indent<dot/>');
    }
    if (spec.triplet) {
      output.writeln(
        '$indent<time-modification><actual-notes>3</actual-notes><normal-notes>2</normal-notes><normal-type>${spec.type}</normal-type></time-modification>',
      );
    }
  }

  static void _writeHarmony(StringBuffer output, String symbol) {
    final match = RegExp(r'^([A-Ga-g])([#b]?)(.*)$').firstMatch(symbol);
    if (match == null) {
      output.writeln(
        '      <direction placement="above"><direction-type><words>${_escape(symbol)}</words></direction-type></direction>',
      );
      return;
    }
    final step = match.group(1)!.toUpperCase();
    final accidental = match.group(2)!;
    final suffix = match.group(3)!.trim();
    final kind = switch (suffix.toLowerCase()) {
      '' || 'maj' || 'major' => 'major',
      'm' || 'min' || 'minor' => 'minor',
      '7' => 'dominant',
      'maj7' || 'ma7' => 'major-seventh',
      'm7' || 'min7' => 'minor-seventh',
      _ => 'other',
    };
    output.writeln('      <harmony>');
    output.writeln(
      '        <root><root-step>$step</root-step>${accidental == '#'
          ? '<root-alter>1</root-alter>'
          : accidental == 'b'
          ? '<root-alter>-1</root-alter>'
          : ''}</root>',
    );
    output.writeln(
      '        <kind${suffix.isEmpty ? '' : ' text="${_escape(suffix)}"'}>$kind</kind>',
    );
    output.writeln('      </harmony>');
  }

  static void _writeAnnotation(
    StringBuffer output,
    LessonAnnotation annotation, {
    required double offset,
  }) {
    final normalizedKind = annotation.kind.toLowerCase();
    final text = annotation.text.trim();
    output.writeln(
      '      <direction placement="${normalizedKind.contains('pedal') ? 'below' : 'above'}">',
    );
    if (normalizedKind.contains('dynamic') && _isDynamic(text)) {
      output.writeln(
        '        <direction-type><dynamics><$text/></dynamics></direction-type>',
      );
    } else if (normalizedKind.contains('pedal')) {
      final stop = RegExp(
        r'(nhả|release|stop|off)',
        caseSensitive: false,
      ).hasMatch(text);
      output.writeln(
        '        <direction-type><pedal type="${stop ? 'stop' : 'start'}"/></direction-type>',
      );
      if (text.isNotEmpty) {
        output.writeln(
          '        <direction-type><words>${_escape(text)}</words></direction-type>',
        );
      }
    } else if (normalizedKind.contains('tempo')) {
      final bpm = int.tryParse(RegExp(r'\d+').firstMatch(text)?.group(0) ?? '');
      if (bpm != null) {
        output.writeln(
          '        <direction-type><metronome><beat-unit>quarter</beat-unit><per-minute>$bpm</per-minute></metronome></direction-type>',
        );
        output.writeln('        <sound tempo="$bpm"/>');
      } else {
        output.writeln(
          '        <direction-type><words>${_escape(text)}</words></direction-type>',
        );
      }
    } else {
      output.writeln(
        '        <direction-type><words>${_escape(text)}</words></direction-type>',
      );
    }
    if (offset > _epsilon) {
      output.writeln('        <offset>${_duration(offset)}</offset>');
    }
    output.writeln('      </direction>');
  }

  static Map<double, int> _parseTempoChanges(String value, int initialTempo) {
    final changes = <double, int>{1: max(1, initialTempo)};
    for (final raw in value.split(';')) {
      final parts = raw.trim().split(':');
      if (parts.length != 2) continue;
      final beat = double.tryParse(parts.first.trim());
      final bpm = int.tryParse(parts.last.trim());
      if (beat != null && beat >= 1 && bpm != null && bpm > 0) {
        changes[beat] = bpm;
      }
    }
    return Map.fromEntries(
      (changes.entries.toList()..sort((a, b) => a.key.compareTo(b.key))),
    );
  }

  static void _writeTempoDirection(
    StringBuffer output,
    int bpm, {
    required double offset,
  }) {
    output.writeln('      <direction placement="above">');
    output.writeln(
      '        <direction-type><metronome><beat-unit>quarter</beat-unit><per-minute>$bpm</per-minute></metronome></direction-type>',
    );
    if (offset > _epsilon) {
      output.writeln('        <offset>${_duration(offset)}</offset>');
    }
    output.writeln('        <sound tempo="$bpm"/>');
    output.writeln('      </direction>');
  }

  static List<_DurationSpec> _splitDuration(double beats) {
    var remaining = beats;
    final parts = <_DurationSpec>[];
    while (remaining > _epsilon) {
      final spec = _durationSpecs.firstWhere(
        (candidate) => candidate.beats <= remaining + _epsilon,
        orElse: () => _durationSpecs.last,
      );
      parts.add(spec);
      remaining -= spec.beats;
      if (parts.length > 64) break;
    }
    return parts;
  }

  static int _compareFragments(_XmlNoteFragment left, _XmlNoteFragment right) {
    final beatComparison = left.startBeat.compareTo(right.startBeat);
    if (beatComparison != 0) return beatComparison;
    return _pitchSortValue(
      left.note.note,
    ).compareTo(_pitchSortValue(right.note.note));
  }

  static int _pitchSortValue(String note) {
    final match = RegExp(r'^([A-G])([#b]?)(-?\d+)$').firstMatch(note);
    if (match == null) return 60;
    const base = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11};
    var value = (int.parse(match.group(3)!) + 1) * 12 + base[match.group(1)]!;
    if (match.group(2) == '#') value++;
    if (match.group(2) == 'b') value--;
    return value;
  }

  static int _musicXmlVoice(int staff, int voice) =>
      1 + staff * 4 + max(0, voice);
  static int _duration(double beats) => (beats * _divisions).round();
  static bool _isDynamic(String value) => const {
    'p',
    'pp',
    'ppp',
    'mp',
    'mf',
    'f',
    'ff',
    'fff',
    'fp',
    'sfz',
  }.contains(value);

  static String _safeSignature(String value) {
    final match = RegExp(r'^(\d+)\/(\d+)$').firstMatch(value.trim());
    if (match == null ||
        int.tryParse(match.group(1)!) == 0 ||
        int.tryParse(match.group(2)!) == 0) {
      return '4/4';
    }
    return value.trim();
  }

  static double _beatsPerMeasure(String signature) {
    final parts = signature.split('/');
    final numerator = double.tryParse(parts.first) ?? 4;
    final denominator = parts.length == 2
        ? double.tryParse(parts.last) ?? 4
        : 4;
    return numerator * 4 / denominator;
  }

  static String _escape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}

class _Measure {
  final int index;
  final double startBeat;
  final double endBeat;
  final String timeSignature;

  const _Measure({
    required this.index,
    required this.startBeat,
    required this.endBeat,
    required this.timeSignature,
  });
  double get length => endBeat - startBeat;
}

class _TrackPart {
  final int track;
  final String name;
  final int staffCount;
  final List<String> clefs;

  const _TrackPart({
    required this.track,
    required this.name,
    required this.staffCount,
    required this.clefs,
  });
}

class _BeamSlice {
  final double startBeat;
  final double durationBeat;
  final int level;

  const _BeamSlice({
    required this.startBeat,
    required this.durationBeat,
    required this.level,
  });
}

class _BeamMark {
  final int number;
  final String value;

  const _BeamMark(this.number, this.value);
}

class _DurationSpec {
  final double beats;
  final String type;
  final int dots;
  final bool triplet;

  const _DurationSpec(
    this.beats,
    this.type, {
    this.dots = 0,
    this.triplet = false,
  });
}

class _XmlNoteFragment {
  final LessonNote note;
  final double startBeat;
  final _DurationSpec spec;
  final bool tieStop;
  final bool tieStart;
  final bool includeText;

  const _XmlNoteFragment({
    required this.note,
    required this.startBeat,
    required this.spec,
    required this.tieStop,
    required this.tieStart,
    required this.includeText,
  });
}

class _VoiceKey implements Comparable<_VoiceKey> {
  final int staff;
  final int voice;

  const _VoiceKey(this.staff, this.voice);

  @override
  int compareTo(_VoiceKey other) {
    final staffComparison = staff.compareTo(other.staff);
    return staffComparison != 0
        ? staffComparison
        : voice.compareTo(other.voice);
  }

  @override
  bool operator ==(Object other) =>
      other is _VoiceKey && other.staff == staff && other.voice == voice;

  @override
  int get hashCode => Object.hash(staff, voice);
}
