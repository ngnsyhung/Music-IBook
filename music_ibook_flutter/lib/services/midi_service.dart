import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../models/lesson_note.dart';
import '../utils/music_xml_generator.dart';

class MidiParserResult {
  final List<LessonNote> notes;
  final int tempo;
  final String tempoMap;
  final String timeSignature;
  final String timeSignatureMap;
  final String keySignature;

  const MidiParserResult({
    required this.notes,
    required this.tempo,
    required this.tempoMap,
    required this.timeSignature,
    required this.timeSignatureMap,
    required this.keySignature,
  });
}

class _PendingNote {
  final int noteNumber;
  final int velocity;
  final int startTick;

  const _PendingNote({
    required this.noteNumber,
    required this.velocity,
    required this.startTick,
  });
}

class _RawNote {
  final int noteNumber;
  final int velocity;
  final int startTick;
  final int endTick;
  final int track;
  final int channel;

  const _RawNote({
    required this.noteNumber,
    required this.velocity,
    required this.startTick,
    required this.endTick,
    required this.track,
    required this.channel,
  });
}

class _QuantizedNote {
  final _RawNote raw;
  double startBeat;
  double durationBeat;
  int staff = 0;
  int voice = 0;

  _QuantizedNote({
    required this.raw,
    required this.startBeat,
    required this.durationBeat,
  });
}

class _MidiMeasure {
  final int startTick;
  final int endTick;
  final String timeSignature;

  const _MidiMeasure({
    required this.startTick,
    required this.endTick,
    required this.timeSignature,
  });
}

class _TempoEvent {
  final int tick;
  final int microsecondsPerBeat;
  final int sequence;

  const _TempoEvent(this.tick, this.microsecondsPerBeat, this.sequence);
}

class _SignatureEvent<T> {
  final int tick;
  final T value;
  final int sequence;

  const _SignatureEvent(this.tick, this.value, this.sequence);
}

class _MidiTextEvent {
  final int tick;
  final int track;
  final String text;
  final int sequence;

  const _MidiTextEvent(this.tick, this.track, this.text, this.sequence);
}

class _KeySignature {
  final int sharpsOrFlats;
  final bool minor;

  const _KeySignature(this.sharpsOrFlats, this.minor);
}

class MidiService {
  static const _ticksPerNotationBeat = 192;
  static const _sharpNoteNames = [
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

  static const _flatNoteNames = [
    'C',
    'Db',
    'D',
    'Eb',
    'E',
    'F',
    'Gb',
    'G',
    'Ab',
    'A',
    'Bb',
    'B',
  ];

  static const _majorKeys = {
    -7: 'Cb Major',
    -6: 'Gb Major',
    -5: 'Db Major',
    -4: 'Ab Major',
    -3: 'Eb Major',
    -2: 'Bb Major',
    -1: 'F Major',
    0: 'C Major',
    1: 'G Major',
    2: 'D Major',
    3: 'A Major',
    4: 'E Major',
    5: 'B Major',
    6: 'F# Major',
    7: 'C# Major',
  };

  static const _minorKeys = {
    -7: 'Ab Minor',
    -6: 'Eb Minor',
    -5: 'Bb Minor',
    -4: 'F Minor',
    -3: 'C Minor',
    -2: 'G Minor',
    -1: 'D Minor',
    0: 'A Minor',
    1: 'E Minor',
    2: 'B Minor',
    3: 'F# Minor',
    4: 'C# Minor',
    5: 'G# Minor',
    6: 'D# Minor',
    7: 'A# Minor',
  };

  /// Chọn một Standard MIDI File và chuyển dữ liệu của nó thành các nốt nhạc.
  static Future<MidiParserResult?> importMidiFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mid', 'midi'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    Uint8List? bytes = file.bytes;
    if (bytes == null && file.path != null) {
      final selectedFile = File(file.path!);
      if (await selectedFile.exists()) {
        bytes = await selectedFile.readAsBytes();
      }
    }

    if (bytes == null) {
      throw const FormatException('Không thể đọc dữ liệu file MIDI.');
    }
    return compute(parseMidiBytes, bytes);
  }

  /// Parse Standard MIDI File format 0 và 1.
  ///
  /// Nhịp trong editor bắt đầu từ 1, vì vậy tick 0 của MIDI tương ứng beat 1.
  /// MIDI channel 10 (chỉ số 9) là percussion theo General MIDI và không được
  /// đưa lên khuông nhạc giai điệu.
  static MidiParserResult parseMidiBytes(Uint8List bytes) {
    var position = 0;

    void requireBytes(int count, [String context = 'dữ liệu MIDI']) {
      if (count < 0 || position + count > bytes.length) {
        throw FormatException('File MIDI bị thiếu hoặc hỏng tại $context.');
      }
    }

    int readUint16([String context = 'uint16']) {
      requireBytes(2, context);
      final value = (bytes[position] << 8) | bytes[position + 1];
      position += 2;
      return value;
    }

    int readUint32([String context = 'uint32']) {
      requireBytes(4, context);
      final value =
          (bytes[position] << 24) |
          (bytes[position + 1] << 16) |
          (bytes[position + 2] << 8) |
          bytes[position + 3];
      position += 4;
      return value;
    }

    String readChunkId() {
      requireBytes(4, 'chunk id');
      final value = String.fromCharCodes(bytes.sublist(position, position + 4));
      position += 4;
      return value;
    }

    if (readChunkId() != 'MThd') {
      throw const FormatException(
        'File không đúng định dạng Standard MIDI File (thiếu MThd).',
      );
    }

    final headerLength = readUint32('độ dài MThd');
    if (headerLength < 6) {
      throw const FormatException('MThd của file MIDI không hợp lệ.');
    }
    requireBytes(headerLength, 'MThd');

    final format = readUint16('MIDI format');
    final trackCount = readUint16('số track');
    final division = readUint16('time division');
    position += headerLength - 6;

    if (format < 0 || format > 1) {
      throw FormatException(
        'MIDI format $format chưa được hỗ trợ. Hãy dùng format 0 hoặc 1.',
      );
    }
    if (trackCount == 0) {
      throw const FormatException('File MIDI không có track nào.');
    }
    if ((division & 0x8000) != 0) {
      throw const FormatException(
        'MIDI dùng SMPTE time division chưa được hỗ trợ để dựng sheet music.',
      );
    }

    final ticksPerBeat = division & 0x7fff;
    if (ticksPerBeat == 0) {
      throw const FormatException('Ticks per beat của file MIDI bằng 0.');
    }

    final rawNotes = <_RawNote>[];
    final tempoEvents = <_TempoEvent>[];
    final timeSignatureEvents = <_SignatureEvent<String>>[];
    final keySignatureEvents = <_SignatureEvent<_KeySignature>>[];
    final lyricEvents = <_MidiTextEvent>[];
    final trackNames = <int, String>{};
    var eventSequence = 0;
    var parsedTrackCount = 0;

    while (parsedTrackCount < trackCount && position < bytes.length) {
      final chunkId = readChunkId();
      final chunkLength = readUint32('độ dài $chunkId');
      requireBytes(chunkLength, chunkId);
      final trackEnd = position + chunkLength;

      if (chunkId != 'MTrk') {
        position = trackEnd;
        continue;
      }

      final trackIndex = parsedTrackCount++;
      var currentTick = 0;
      int? runningStatus;
      final activeNotes = <int, List<_PendingNote>>{};

      int readVlq(String context) {
        var value = 0;
        var byteCount = 0;
        while (position < trackEnd) {
          final byte = bytes[position++];
          value = (value << 7) | (byte & 0x7f);
          byteCount++;
          if ((byte & 0x80) == 0) return value;
          if (byteCount == 4) {
            throw FormatException('VLQ quá dài tại $context.');
          }
        }
        throw FormatException('VLQ bị thiếu tại $context.');
      }

      void requireTrackBytes(int count, String context) {
        if (count < 0 || position + count > trackEnd) {
          throw FormatException(
            'Track $trackIndex bị thiếu dữ liệu tại $context.',
          );
        }
      }

      void closeNote(int channel, int noteNumber, int endTick) {
        final key = (channel << 8) | noteNumber;
        final pendingList = activeNotes[key];
        if (pendingList == null || pendingList.isEmpty) return;

        final pending = pendingList.removeAt(0);
        if (endTick <= pending.startTick || channel == 9) return;
        rawNotes.add(
          _RawNote(
            noteNumber: pending.noteNumber,
            velocity: pending.velocity,
            startTick: pending.startTick,
            endTick: endTick,
            track: trackIndex,
            channel: channel,
          ),
        );
      }

      while (position < trackEnd) {
        currentTick += readVlq('delta-time track $trackIndex');
        requireTrackBytes(1, 'status byte');

        var status = bytes[position];
        if ((status & 0x80) != 0) {
          position++;
        } else {
          if (runningStatus == null) {
            throw FormatException(
              'Running status không hợp lệ tại track $trackIndex, tick $currentTick.',
            );
          }
          status = runningStatus;
        }

        if (status == 0xff) {
          runningStatus = null;
          requireTrackBytes(1, 'meta event type');
          final metaType = bytes[position++];
          final length = readVlq('meta event length');
          requireTrackBytes(
            length,
            'meta event 0x${metaType.toRadixString(16)}',
          );
          final dataStart = position;
          position += length;

          String metaText() => utf8
              .decode(
                bytes.sublist(dataStart, dataStart + length),
                allowMalformed: true,
              )
              .trim();

          if (metaType == 0x51 && length == 3) {
            final microsecondsPerBeat =
                (bytes[dataStart] << 16) |
                (bytes[dataStart + 1] << 8) |
                bytes[dataStart + 2];
            if (microsecondsPerBeat > 0) {
              tempoEvents.add(
                _TempoEvent(currentTick, microsecondsPerBeat, eventSequence++),
              );
            }
          } else if (metaType == 0x58 && length >= 2) {
            final numerator = bytes[dataStart];
            final denominatorPower = bytes[dataStart + 1];
            if (numerator > 0 && denominatorPower <= 7) {
              timeSignatureEvents.add(
                _SignatureEvent(
                  currentTick,
                  '$numerator/${1 << denominatorPower}',
                  eventSequence++,
                ),
              );
            }
          } else if (metaType == 0x59 && length >= 2) {
            final sharpsOrFlats = bytes[dataStart].toSigned(8).clamp(-7, 7);
            keySignatureEvents.add(
              _SignatureEvent(
                currentTick,
                _KeySignature(sharpsOrFlats, bytes[dataStart + 1] == 1),
                eventSequence++,
              ),
            );
          } else if (metaType == 0x03 && length > 0) {
            final name = metaText();
            if (name.isNotEmpty) trackNames[trackIndex] = name;
          } else if (metaType == 0x05 && length > 0) {
            final lyric = metaText();
            if (lyric.isNotEmpty) {
              lyricEvents.add(
                _MidiTextEvent(currentTick, trackIndex, lyric, eventSequence++),
              );
            }
          }
          continue;
        }

        if (status == 0xf0 || status == 0xf7) {
          runningStatus = null;
          final length = readVlq('SysEx length');
          requireTrackBytes(length, 'SysEx');
          position += length;
          continue;
        }

        if (status < 0x80 || status > 0xef) {
          throw FormatException(
            'Status byte 0x${status.toRadixString(16)} không hợp lệ trong SMF.',
          );
        }

        runningStatus = status;
        final eventType = status & 0xf0;
        final channel = status & 0x0f;

        if (eventType == 0x80 || eventType == 0x90) {
          requireTrackBytes(2, 'note event');
          final noteNumber = bytes[position++];
          final velocity = bytes[position++];
          if (eventType == 0x90 && velocity > 0) {
            final key = (channel << 8) | noteNumber;
            activeNotes
                .putIfAbsent(key, () => [])
                .add(
                  _PendingNote(
                    noteNumber: noteNumber,
                    velocity: velocity,
                    startTick: currentTick,
                  ),
                );
          } else {
            closeNote(channel, noteNumber, currentTick);
          }
        } else if (eventType == 0xa0 ||
            eventType == 0xb0 ||
            eventType == 0xe0) {
          requireTrackBytes(2, 'channel event');
          position += 2;
        } else if (eventType == 0xc0 || eventType == 0xd0) {
          requireTrackBytes(1, 'channel event');
          position++;
        }
      }

      // Một vài MIDI recorder không phát Note Off cuối track. Đóng nốt ở tick
      // cuối chỉ khi nó có trường độ dương, không tự cộng thêm một beat giả.
      for (final entry in activeNotes.entries) {
        final channel = entry.key >> 8;
        for (final pending in entry.value) {
          if (channel != 9 && currentTick > pending.startTick) {
            rawNotes.add(
              _RawNote(
                noteNumber: pending.noteNumber,
                velocity: pending.velocity,
                startTick: pending.startTick,
                endTick: currentTick,
                track: trackIndex,
                channel: channel,
              ),
            );
          }
        }
      }
      position = trackEnd;
    }

    if (parsedTrackCount != trackCount) {
      throw FormatException(
        'File khai báo $trackCount track nhưng chỉ đọc được $parsedTrackCount track.',
      );
    }

    tempoEvents.sort((a, b) {
      final tickOrder = a.tick.compareTo(b.tick);
      return tickOrder != 0 ? tickOrder : a.sequence.compareTo(b.sequence);
    });
    timeSignatureEvents.sort((a, b) {
      final tickOrder = a.tick.compareTo(b.tick);
      return tickOrder != 0 ? tickOrder : a.sequence.compareTo(b.sequence);
    });
    keySignatureEvents.sort((a, b) {
      final tickOrder = a.tick.compareTo(b.tick);
      return tickOrder != 0 ? tickOrder : a.sequence.compareTo(b.sequence);
    });

    var initialTempoMicroseconds = 500000;
    for (final event in tempoEvents.where((event) => event.tick == 0)) {
      initialTempoMicroseconds = event.microsecondsPerBeat;
    }
    var initialTimeSignature = '4/4';
    for (final event in timeSignatureEvents.where((event) => event.tick == 0)) {
      initialTimeSignature = event.value;
    }
    var initialKey = const _KeySignature(0, false);
    for (final event in keySignatureEvents.where((event) => event.tick == 0)) {
      initialKey = event.value;
    }

    rawNotes.sort((a, b) {
      var comparison = a.startTick.compareTo(b.startTick);
      if (comparison != 0) return comparison;
      comparison = a.track.compareTo(b.track);
      if (comparison != 0) return comparison;
      comparison = a.channel.compareTo(b.channel);
      if (comparison != 0) return comparison;
      return a.noteNumber.compareTo(b.noteNumber);
    });

    final preferFlats = initialKey.sharpsOrFlats < 0;
    final quantizedNotes = _quantizeNotes(
      rawNotes,
      ticksPerBeat,
      timeSignatureEvents,
      initialTimeSignature,
    );
    _assignTrackVoices(quantizedNotes);

    lyricEvents.sort((left, right) {
      final tick = left.tick.compareTo(right.tick);
      return tick != 0 ? tick : left.sequence.compareTo(right.sequence);
    });
    final lyricsByTrackAndTick = <String, String>{};
    for (final event in lyricEvents) {
      lyricsByTrackAndTick.putIfAbsent(
        '${event.track}:${event.tick}',
        () => event.text,
      );
    }
    final consumedLyrics = <String>{};

    final notes = quantizedNotes
        .map((quantized) {
          final raw = quantized.raw;
          final lyricKey = '${raw.track}:${raw.startTick}';
          final lyric = consumedLyrics.add(lyricKey)
              ? lyricsByTrackAndTick[lyricKey] ?? ''
              : '';
          return LessonNote(
            second: _ticksToSeconds(raw.startTick, ticksPerBeat, tempoEvents),
            startBeat: _cleanNumber(quantized.startBeat),
            durationBeat: _cleanNumber(quantized.durationBeat),
            velocity: raw.velocity,
            track: raw.track,
            trackName: trackNames[raw.track] ?? '',
            staff: quantized.staff,
            voice: quantized.voice,
            note: _midiNoteToName(raw.noteNumber, preferFlats: preferFlats),
            duration: _beatToDurationName(quantized.durationBeat),
            lyric: lyric,
            chord: '',
          );
        })
        .toList(growable: false);

    final keyMap = initialKey.minor ? _minorKeys : _majorKeys;
    final timeSignatureMap = _buildTimeSignatureMap(
      timeSignatureEvents,
      ticksPerBeat,
      initialTimeSignature,
    );
    final tempoMap = _buildTempoMap(
      tempoEvents,
      ticksPerBeat,
      initialTempoMicroseconds,
    );
    return MidiParserResult(
      notes: notes,
      tempo: (60000000 / initialTempoMicroseconds).round(),
      tempoMap: tempoMap,
      timeSignature: initialTimeSignature,
      timeSignatureMap: timeSignatureMap,
      keySignature: keySignatureEvents.isEmpty
          ? ''
          : keyMap[initialKey.sharpsOrFlats] ?? '',
    );
  }

  /// Converts a Standard MIDI File directly to a MusicXML document.
  /// No title, composer, annotations, chord symbols or fingering are added.
  static String convertToMusicXml(Uint8List bytes) {
    final result = parseMidiBytes(bytes);
    return MusicXmlGenerator.generate(
      result.notes,
      title: '',
      composer: '',
      timeSignature: result.timeSignature,
      timeSignatureMap: result.timeSignatureMap,
      keySignature: result.keySignature,
      tempo: result.tempo,
      tempoMap: result.tempoMap,
    );
  }

  static List<_QuantizedNote> _quantizeNotes(
    List<_RawNote> rawNotes,
    int ticksPerBeat,
    List<_SignatureEvent<String>> timeSignatureEvents,
    String initialTimeSignature,
  ) {
    if (rawNotes.isEmpty) return const [];

    final maxTick = rawNotes.map((note) => note.endTick).reduce(max);
    final measures = _buildMidiMeasures(
      maxTick + ticksPerBeat,
      ticksPerBeat,
      timeSignatureEvents,
      initialTimeSignature,
    );
    final notesByMeasure = <_MidiMeasure, List<_RawNote>>{};

    _MidiMeasure measureForTick(int tick) {
      for (final measure in measures) {
        if (tick >= measure.startTick && tick < measure.endTick) {
          return measure;
        }
      }
      return measures.last;
    }

    for (final note in rawNotes) {
      notesByMeasure
          .putIfAbsent(measureForTick(note.startTick), () => [])
          .add(note);
    }

    final gridByMeasure = <_MidiMeasure, double>{};
    for (final entry in notesByMeasure.entries) {
      final localOnsets = entry.value
          .map((note) => (note.startTick - entry.key.startTick) / ticksPerBeat)
          .toSet()
          .toList();
      gridByMeasure[entry.key] = _selectNotationGrid(localOnsets);
    }

    final result = <_QuantizedNote>[];
    for (final raw in rawNotes) {
      final measure = measureForTick(raw.startTick);
      final rawLocalBeat = (raw.startTick - measure.startTick) / ticksPerBeat;
      final grid = gridByMeasure[measure] ?? 0.25;
      final snappedLocalBeat = (rawLocalBeat / grid).round() * grid;
      final normalizedError = (snappedLocalBeat - rawLocalBeat).abs() / grid;
      final localBeat = normalizedError <= 0.46
          ? snappedLocalBeat
          : rawLocalBeat;
      final measureStartBeat = 1 + measure.startTick / ticksPerBeat;
      final rawDuration = (raw.endTick - raw.startTick) / ticksPerBeat;

      result.add(
        _QuantizedNote(
          raw: raw,
          startBeat: _cleanNumber(measureStartBeat + localBeat),
          durationBeat: _cleanNumber(_quantizeDuration(rawDuration)),
        ),
      );
    }

    // Không để việc làm tròn trường độ tạo ra hai lần Note On chồng nhau cho
    // cùng một phím. Đây là trường hợp phổ biến ở MIDI thu trực tiếp.
    final byPitch = <int, List<_QuantizedNote>>{};
    for (final note in result) {
      final key =
          (note.raw.track << 16) |
          (note.raw.channel << 8) |
          note.raw.noteNumber;
      byPitch.putIfAbsent(key, () => []).add(note);
    }
    for (final pitchNotes in byPitch.values) {
      pitchNotes.sort((a, b) => a.startBeat.compareTo(b.startBeat));
      for (var i = 0; i < pitchNotes.length - 1; i++) {
        final current = pitchNotes[i];
        final next = pitchNotes[i + 1];
        if (current.startBeat + current.durationBeat > next.startBeat &&
            current.raw.endTick <= next.raw.startTick) {
          current.durationBeat = max(
            0.0625,
            next.startBeat - current.startBeat,
          );
        }
      }
    }

    result.sort((a, b) {
      final beatOrder = a.startBeat.compareTo(b.startBeat);
      if (beatOrder != 0) return beatOrder;
      return a.raw.noteNumber.compareTo(b.raw.noteNumber);
    });
    return result;
  }

  static List<_MidiMeasure> _buildMidiMeasures(
    int maxTick,
    int ticksPerBeat,
    List<_SignatureEvent<String>> events,
    String initialTimeSignature,
  ) {
    final signatureAtTick = <int, String>{0: initialTimeSignature};
    for (final event in events) {
      signatureAtTick[event.tick] = event.value;
    }
    final changeTicks = signatureAtTick.keys.toList()..sort();

    final measures = <_MidiMeasure>[];
    var startTick = 0;
    var signature = signatureAtTick[0] ?? '4/4';
    while (startTick <= maxTick) {
      if (signatureAtTick.containsKey(startTick)) {
        signature = signatureAtTick[startTick]!;
      }
      final parts = signature.split('/');
      final numerator = int.tryParse(parts.first) ?? 4;
      final denominator = parts.length > 1 ? int.tryParse(parts.last) ?? 4 : 4;
      final measureTicks = max(
        1,
        (numerator * 4 / denominator * ticksPerBeat).round(),
      );
      var endTick = startTick + measureTicks;
      for (final changeTick in changeTicks) {
        if (changeTick > startTick && changeTick < endTick) {
          endTick = changeTick;
          break;
        }
      }
      measures.add(
        _MidiMeasure(
          startTick: startTick,
          endTick: endTick,
          timeSignature: signature,
        ),
      );
      startTick = endTick;
    }
    return measures;
  }

  static double _selectNotationGrid(List<double> onsets) {
    if (onsets.length <= 1) return 0.25;
    const candidates = [1.0, 0.75, 0.5, 1 / 3, 0.25, 1 / 6, 0.125, 0.0625];
    var bestGrid = 0.25;
    var bestScore = double.infinity;

    for (final grid in candidates) {
      var squaredError = 0.0;
      for (final onset in onsets) {
        final snapped = (onset / grid).round() * grid;
        final normalizedError = (snapped - onset).abs() / grid;
        squaredError += normalizedError * normalizedError;
      }
      final fit = squaredError / onsets.length;
      final complexity = grid < 0.5 ? 0.012 * (0.5 / grid - 1) : 0.0;
      final score = fit + complexity;
      if (score < bestScore) {
        bestScore = score;
        bestGrid = grid;
      }
    }
    return bestGrid;
  }

  static double _quantizeDuration(double rawBeat) {
    if (rawBeat <= 0) return 0.0625;
    const candidates = [
      4.0,
      3.0,
      2.0,
      1.5,
      1.0,
      0.75,
      2 / 3,
      0.5,
      0.375,
      1 / 3,
      0.25,
      1 / 6,
      0.125,
      0.0625,
    ];
    var best = candidates.first;
    var bestError = double.infinity;
    for (final candidate in candidates) {
      final error = log(rawBeat / candidate).abs();
      if (error < bestError) {
        bestError = error;
        best = candidate;
      }
    }
    return bestError <= log(1.35) ? best : rawBeat;
  }

  static void _assignTrackVoices(List<_QuantizedNote> notes) {
    final tracks = notes.map((note) => note.raw.track).toSet().toList()..sort();
    for (final track in tracks) {
      final staffGroups = <double, List<_QuantizedNote>>{};
      for (final note in notes.where((note) => note.raw.track == track)) {
        note.staff = 0;
        staffGroups.putIfAbsent(note.startBeat, () => []).add(note);
      }
      final starts = staffGroups.keys.toList()..sort();
      final voiceEnds = <double>[];
      for (final start in starts) {
        final durationGroups = <int, List<_QuantizedNote>>{};
        for (final note in staffGroups[start]!) {
          final durationKey = (note.durationBeat * _ticksPerNotationBeat)
              .round();
          durationGroups.putIfAbsent(durationKey, () => []).add(note);
        }
        final groups = durationGroups.values.toList()
          ..sort(
            (left, right) =>
                right.first.durationBeat.compareTo(left.first.durationBeat),
          );
        for (final group in groups) {
          var voice = voiceEnds.indexWhere((end) => end <= start + 0.000001);
          if (voice < 0) {
            voice = voiceEnds.length;
            voiceEnds.add(start);
          }
          voice = min(voice, 3);
          final groupEnd = group
              .map((note) => note.startBeat + note.durationBeat)
              .reduce(max);
          voiceEnds[voice] = max(voiceEnds[voice], groupEnd);
          for (final note in group) {
            note.voice = voice;
          }
        }
      }
    }
  }

  static String _buildTimeSignatureMap(
    List<_SignatureEvent<String>> events,
    int ticksPerBeat,
    String initialTimeSignature,
  ) {
    final signatureAtTick = <int, String>{0: initialTimeSignature};
    for (final event in events) {
      signatureAtTick[event.tick] = event.value;
    }
    final ticks = signatureAtTick.keys.toList()..sort();
    return ticks
        .map(
          (tick) =>
              '${_cleanNumber(1 + tick / ticksPerBeat)}:${signatureAtTick[tick]}',
        )
        .join(';');
  }

  static String _buildTempoMap(
    List<_TempoEvent> events,
    int ticksPerBeat,
    int initialMicrosecondsPerBeat,
  ) {
    final tempoAtTick = <int, int>{
      0: (60000000 / initialMicrosecondsPerBeat).round(),
    };
    for (final event in events) {
      tempoAtTick[event.tick] = (60000000 / event.microsecondsPerBeat).round();
    }
    final ticks = tempoAtTick.keys.toList()..sort();
    return ticks
        .map(
          (tick) =>
              '${_cleanNumber(1 + tick / ticksPerBeat)}:${tempoAtTick[tick]}',
        )
        .join(';');
  }

  static double _ticksToSeconds(
    int targetTick,
    int ticksPerBeat,
    List<_TempoEvent> tempoEvents,
  ) {
    if (targetTick <= 0) return 0;

    var seconds = 0.0;
    var previousTick = 0;
    var microsecondsPerBeat = 500000;

    for (final event in tempoEvents) {
      if (event.tick > targetTick) break;
      if (event.tick > previousTick) {
        seconds +=
            (event.tick - previousTick) *
            microsecondsPerBeat /
            ticksPerBeat /
            1000000;
        previousTick = event.tick;
      }
      microsecondsPerBeat = event.microsecondsPerBeat;
    }

    seconds +=
        (targetTick - previousTick) *
        microsecondsPerBeat /
        ticksPerBeat /
        1000000;
    return _cleanNumber(seconds);
  }

  static double _cleanNumber(double value) {
    return double.parse(value.toStringAsFixed(6));
  }

  static String _midiNoteToName(int noteNumber, {required bool preferFlats}) {
    final octave = (noteNumber ~/ 12) - 1;
    final names = preferFlats ? _flatNoteNames : _sharpNoteNames;
    return '${names[noteNumber % 12]}$octave';
  }

  static String _beatToDurationName(double beat) {
    const options = [
      (name: 'whole', beats: 4.0),
      (name: 'dotted_half', beats: 3.0),
      (name: 'half', beats: 2.0),
      (name: 'dotted_quarter', beats: 1.5),
      (name: 'quarter', beats: 1.0),
      (name: 'quarter_triplet', beats: 2 / 3),
      (name: 'dotted_eighth', beats: 0.75),
      (name: 'eighth', beats: 0.5),
      (name: 'eighth_triplet', beats: 1 / 3),
      (name: 'dotted_sixteenth', beats: 0.375),
      (name: 'sixteenth', beats: 0.25),
      (name: 'sixteenth_triplet', beats: 1 / 6),
      (name: 'thirty_second', beats: 0.125),
      (name: 'sixty_fourth', beats: 0.0625),
    ];

    return options
        .reduce(
          (a, b) => (a.beats - beat).abs() <= (b.beats - beat).abs() ? a : b,
        )
        .name;
  }
}
