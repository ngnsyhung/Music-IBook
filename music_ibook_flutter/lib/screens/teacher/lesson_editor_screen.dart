import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/lesson.dart';
import '../../models/lesson_note.dart';
import '../../providers/lesson_provider.dart';
import '../../services/midi_service.dart';
import '../../services/note_audio_service.dart';
import '../../services/score_engraving_service.dart';
import '../../widgets/engraved_score.dart';
import '../../widgets/piano_keyboard.dart';

class _DurationOption {
  final String name;
  final String symbol;
  final String label;
  final double beats;
  final LogicalKeyboardKey? shortcut;

  const _DurationOption({
    required this.name,
    required this.symbol,
    required this.label,
    required this.beats,
    this.shortcut,
  });
}

const _durationOptions = [
  _DurationOption(
    name: 'whole',
    symbol: '𝅝',
    label: 'Tròn',
    beats: 4,
    shortcut: LogicalKeyboardKey.digit1,
  ),
  _DurationOption(
    name: 'dotted_half',
    symbol: '𝅗𝅥.',
    label: 'Trắng chấm',
    beats: 3,
    shortcut: LogicalKeyboardKey.digit3,
  ),
  _DurationOption(
    name: 'half',
    symbol: '𝅗𝅥',
    label: 'Trắng',
    beats: 2,
    shortcut: LogicalKeyboardKey.digit2,
  ),
  _DurationOption(
    name: 'dotted_quarter',
    symbol: '𝅘𝅥.',
    label: 'Đen chấm',
    beats: 1.5,
    shortcut: LogicalKeyboardKey.digit5,
  ),
  _DurationOption(
    name: 'quarter',
    symbol: '𝅘𝅥',
    label: 'Đen',
    beats: 1,
    shortcut: LogicalKeyboardKey.digit4,
  ),
  _DurationOption(
    name: 'dotted_eighth',
    symbol: '𝅘𝅥𝅮.',
    label: 'Móc đơn chấm',
    beats: 0.75,
    shortcut: LogicalKeyboardKey.digit6,
  ),
  _DurationOption(
    name: 'eighth',
    symbol: '𝅘𝅥𝅮',
    label: 'Móc đơn',
    beats: 0.5,
    shortcut: LogicalKeyboardKey.digit8,
  ),
  _DurationOption(
    name: 'dotted_sixteenth',
    symbol: '𝅘𝅥𝅯.',
    label: 'Móc kép chấm',
    beats: 0.375,
    shortcut: LogicalKeyboardKey.digit7,
  ),
  _DurationOption(
    name: 'sixteenth',
    symbol: '𝅘𝅥𝅯',
    label: 'Móc kép',
    beats: 0.25,
    shortcut: LogicalKeyboardKey.digit9,
  ),
  _DurationOption(
    name: 'thirty_second',
    symbol: '𝅘𝅥𝅰',
    label: '1/32',
    beats: 0.125,
    shortcut: LogicalKeyboardKey.digit0,
  ),
  _DurationOption(
    name: 'sixty_fourth',
    symbol: '𝅘𝅥𝅱',
    label: '1/64',
    beats: 0.0625,
  ),
];

class LessonEditorScreen extends StatefulWidget {
  final int? lessonId;

  const LessonEditorScreen({super.key, this.lessonId});

  @override
  State<LessonEditorScreen> createState() => _LessonEditorScreenState();
}

class _LessonEditorScreenState extends State<LessonEditorScreen> {
  static final _keyboardNotes = {
    LogicalKeyboardKey.keyA: 'C4',
    LogicalKeyboardKey.keyS: 'D4',
    LogicalKeyboardKey.keyD: 'E4',
    LogicalKeyboardKey.keyF: 'F4',
    LogicalKeyboardKey.keyG: 'G4',
    LogicalKeyboardKey.keyH: 'A4',
    LogicalKeyboardKey.keyJ: 'B4',
  };
  static final _durationKeys = {
    for (final option in _durationOptions)
      if (option.shortcut != null) option.shortcut!: option.beats,
    LogicalKeyboardKey.numpad1: 4.0,
    LogicalKeyboardKey.numpad3: 3.0,
    LogicalKeyboardKey.numpad2: 2.0,
    LogicalKeyboardKey.numpad5: 1.5,
    LogicalKeyboardKey.numpad4: 1.0,
    LogicalKeyboardKey.numpad6: 0.75,
    LogicalKeyboardKey.numpad8: 0.5,
    LogicalKeyboardKey.numpad7: 0.375,
    LogicalKeyboardKey.numpad9: 0.25,
    LogicalKeyboardKey.numpad0: 0.125,
    LogicalKeyboardKey.minus: 0.0625,
    LogicalKeyboardKey.numpadSubtract: 0.0625,
  };

  final _focusNode = FocusNode();
  final _title = TextEditingController();
  final _composer = TextEditingController();
  final _description = TextEditingController();
  final _lyric = TextEditingController();
  final _chord = TextEditingController();
  final _recordClock = Stopwatch();
  final _playClock = Stopwatch();

  Timer? _ticker;
  Timer? _metronomeTimer;
  MusicLesson _lesson = MusicLesson.empty();
  List<List<LessonNote>> _undoStack = [];
  List<List<LessonNote>> _redoStack = [];

  int _tempo = 80;
  String _timeSignature = '4/4';
  String _keySignature = 'C Major';
  double _quantizeStep = 0.5;
  double _selectedDurationBeat = 1;
  double _playheadBeat = 1;
  double _playStartBeat = 1;
  double _lastPlayedBeat = 1;
  double _zoom = 1;
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _metronomeEnabled = true;
  int? _selectedIndex;
  int _octaveShift = 0;

  final List<String> _timeSignatures = [
    '2/2',
    '2/4',
    '3/4',
    '4/4',
    '5/4',
    '6/8',
    '7/8',
    '9/8',
    '12/8',
  ];
  final List<String> _keySignatures = [
    'Cb Major',
    'Gb Major',
    'Db Major',
    'Ab Major',
    'Eb Major',
    'Bb Major',
    'F Major',
    'C Major',
    'G Major',
    'D Major',
    'A Major',
    'E Major',
    'B Major',
    'F# Major',
    'C# Major',
    'Ab Minor',
    'Eb Minor',
    'Bb Minor',
    'F Minor',
    'C Minor',
    'G Minor',
    'D Minor',
    'A Minor',
    'E Minor',
    'B Minor',
    'F# Minor',
    'C# Minor',
    'G# Minor',
    'D# Minor',
    'A# Minor',
  ];

  @override
  void initState() {
    super.initState();
    NoteAudioService.init();
    if (widget.lessonId != null) {
      Future.microtask(_loadLesson);
    } else {
      _setLesson(
        MusicLesson.empty()
          ..timeSignature = _timeSignature
          ..keySignature = _keySignature,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  Future<void> _loadLesson() async {
    final loaded = await context.read<LessonProvider>().loadLesson(
      widget.lessonId!,
    );
    if (loaded != null) _setLesson(loaded);
  }

  void _setLesson(MusicLesson lesson) {
    final normalizedNotes =
        lesson.notes.map((note) => _syncNoteTiming(note)).toList()
          ..sort((a, b) => a.startBeat.compareTo(b.startBeat));

    setState(() {
      _lesson = lesson..notes = normalizedNotes;
      _title.text = lesson.title;
      _composer.text = lesson.composer;
      _description.text = lesson.practiceGuide;
      _timeSignature = lesson.timeSignature.isEmpty
          ? '4/4'
          : lesson.timeSignature;
      if (lesson.timeSignatureMap.isEmpty) {
        lesson.timeSignatureMap = '1:$_timeSignature';
      }
      _keySignature = lesson.keySignature.isEmpty
          ? 'C Major'
          : lesson.keySignature;
      _tempo = lesson.tempo.clamp(40, 220);
      _playheadBeat = 1;
    });
  }

  LessonNote _syncNoteTiming(LessonNote note) {
    final startBeat = note.startBeat <= 0
        ? _secondsToBeat(note.second)
        : note.startBeat;
    final durationBeat = note.durationBeat <= 0
        ? _durationNameToBeat(note.duration)
        : note.durationBeat;
    return note.copyWith(
      startBeat: startBeat,
      durationBeat: durationBeat,
      second: note.second >= 0 ? note.second : _beatToSeconds(startBeat),
      duration: _beatToDurationName(durationBeat),
    );
  }

  double get _msPerBeat => 60000 / _tempo;
  double get _beatsPerMeasure {
    final parts = _timeSignature.split('/');
    final numerator = double.tryParse(parts.first) ?? 4;
    final denominator = parts.length > 1 ? double.tryParse(parts.last) ?? 4 : 4;
    return numerator * (4 / denominator);
  }

  double _elapsedToBeat(Duration elapsed) =>
      1 + elapsed.inMilliseconds / _msPerBeat;
  double _beatToSeconds(double beat) => max(0, beat - 1) * _msPerBeat / 1000;
  double _secondsToBeat(double seconds) => 1 + seconds / (_msPerBeat / 1000);
  double _quantize(double beat) =>
      (beat / _quantizeStep).round() * _quantizeStep;

  double _quantizeForward(double beat) =>
      (beat / _quantizeStep).ceil() * _quantizeStep;

  double _nextFreeBeat(
    double requestedBeat,
    double durationBeat, {
    int? ignoreIndex,
  }) {
    var startBeat = max(1.0, requestedBeat);
    const epsilon = 0.0001;
    final occupied = <LessonNote>[
      for (var i = 0; i < _lesson.notes.length; i++)
        if (i != ignoreIndex) _lesson.notes[i],
    ]..sort((a, b) => a.startBeat.compareTo(b.startBeat));

    for (final note in occupied) {
      final endBeat = startBeat + durationBeat;
      final noteStart = note.startBeat;
      final noteEnd = note.startBeat + note.durationBeat;

      if (endBeat <= noteStart + epsilon) break;
      if (startBeat < noteEnd - epsilon && endBeat > noteStart + epsilon) {
        startBeat = _quantizeForward(noteEnd);
      }
    }

    return startBeat;
  }

  void _movePlayheadTo(double beat) {
    _playheadBeat = max(_playheadBeat, beat);
    if (_isPlaying) {
      _playStartBeat = _playheadBeat;
      _lastPlayedBeat = _playheadBeat - 0.001;
      _playClock
        ..reset()
        ..start();
    }
  }

  void _pushUndo() {
    _undoStack = [
      ..._undoStack,
      _lesson.notes.map((n) => n.copyWith()).toList(),
    ];
    _redoStack = [];
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    setState(() {
      _redoStack = [
        ..._redoStack,
        _lesson.notes.map((n) => n.copyWith()).toList(),
      ];
      _lesson.notes = _undoStack.removeLast();
      _selectedIndex = null;
    });
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    setState(() {
      _undoStack = [
        ..._undoStack,
        _lesson.notes.map((n) => n.copyWith()).toList(),
      ];
      _lesson.notes = _redoStack.removeLast();
      _selectedIndex = null;
    });
  }

  void _toggleRecord() {
    if (_isRecording) {
      _stopTransport();
      return;
    }
    _recordClock
      ..reset()
      ..start();
    _playClock.stop();
    setState(() {
      _isRecording = true;
      _isPlaying = false;
      _playheadBeat = 1;
    });
    _startTicker();
    _startMetronome();
  }

  void _togglePlay() {
    if (_isPlaying) {
      _playClock.stop();
      _metronomeTimer?.cancel();
      setState(() {
        _isPlaying = false;
        _playStartBeat = _playheadBeat;
        _lastPlayedBeat = _playheadBeat;
      });
      return;
    }
    _recordClock.stop();
    _playClock
      ..reset()
      ..start();
    setState(() {
      _isPlaying = true;
      _isRecording = false;
      _playStartBeat = _playheadBeat;
      _lastPlayedBeat = _playheadBeat - 0.001;
    });
    _startTicker();
    _startMetronome();
  }

  void _stopTransport() {
    _recordClock.stop();
    _playClock.stop();
    _metronomeTimer?.cancel();
    setState(() {
      _isRecording = false;
      _isPlaying = false;
      _playheadBeat = 1;
      _playStartBeat = 1;
      _lastPlayedBeat = 1;
    });
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (!_isRecording && !_isPlaying) return;
      final clock = _isRecording ? _recordClock : _playClock;
      final beat = _isRecording
          ? _elapsedToBeat(clock.elapsed)
          : _playStartBeat + clock.elapsed.inMilliseconds / _msPerBeat;

      if (!_isRecording && _isPlaying) {
        for (final note in _lesson.notes) {
          if (note.startBeat >= _lastPlayedBeat && note.startBeat < beat) {
            NoteAudioService.playNote(note.note);
          }
        }
        double maxEndBeat = 4.0;
        for (final n in _lesson.notes) {
          if (n.startBeat + n.durationBeat > maxEndBeat) {
            maxEndBeat = n.startBeat + n.durationBeat;
          }
        }
        if (beat > maxEndBeat + 1.5) {
          _stopTransport();
          return;
        }
      }
      _lastPlayedBeat = beat;

      if (mounted) setState(() => _playheadBeat = beat);
    });
  }

  void _startMetronome() {
    _metronomeTimer?.cancel();
    if (!_metronomeEnabled) return;
    SystemSound.play(SystemSoundType.click);
    _metronomeTimer = Timer.periodic(
      Duration(milliseconds: _msPerBeat.round()),
      (_) => SystemSound.play(SystemSoundType.click),
    );
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;

    final note = _keyboardNotes[event.logicalKey];
    if (note != null) {
      final shifted = _shiftOctave(note);
      NoteAudioService.playNote(shifted);
      _insertNote(shifted);
      return;
    }

    final duration = _durationKeys[event.logicalKey];
    if (duration != null) {
      _selectDuration(duration);
      return;
    }

    if (event.logicalKey == LogicalKeyboardKey.space) {
      _togglePlay();
    } else if (event.logicalKey == LogicalKeyboardKey.delete) {
      _deleteSelected();
    } else if (event.logicalKey == LogicalKeyboardKey.keyQ) {
      setState(() => _octaveShift = (_octaveShift - 1).clamp(-1, 1).toInt());
    } else if (event.logicalKey == LogicalKeyboardKey.keyW) {
      setState(() => _octaveShift = 0);
    } else if (event.logicalKey == LogicalKeyboardKey.keyE ||
        event.logicalKey == LogicalKeyboardKey.keyR) {
      setState(() => _octaveShift = (_octaveShift + 1).clamp(-1, 1).toInt());
    }
  }

  void _selectDuration(double duration) {
    setState(() => _selectedDurationBeat = duration);
    _focusNode.requestFocus();
  }

  String _shiftOctave(String note) {
    if (_octaveShift == 0) return note;
    final match = RegExp(r'^([A-G]#?)(\d)$').firstMatch(note);
    if (match == null) return note;
    final octave = int.parse(match.group(2)!) + _octaveShift;
    return '${match.group(1)}$octave';
  }

  void _insertNote(String note, {double? beat, int velocity = 90, int? staff}) {
    _focusNode.requestFocus();
    final rawBeat =
        beat ??
        (_isRecording ? _elapsedToBeat(_recordClock.elapsed) : _playheadBeat);
    final quantizedBeat = max(1.0, _quantize(rawBeat));
    final startBeat = _nextFreeBeat(quantizedBeat, _selectedDurationBeat);
    final endBeat = startBeat + _selectedDurationBeat;
    final newNote = LessonNote(
      second: _beatToSeconds(startBeat),
      startBeat: startBeat,
      durationBeat: _selectedDurationBeat,
      velocity: velocity,
      staff: staff ?? (_noteMidiNumber(note) < 60 ? 1 : 0),
      note: note,
      duration: _beatToDurationName(_selectedDurationBeat),
      lyric: _lyric.text.trim(),
      chord: _chord.text.trim(),
    );

    _pushUndo();
    setState(() {
      _lesson.notes = [..._lesson.notes, newNote]
        ..sort((a, b) => a.startBeat.compareTo(b.startBeat));
      _selectedIndex = _lesson.notes.indexOf(newNote);
      _movePlayheadTo(endBeat);
      _lyric.clear();
      _chord.clear();
    });
  }

  int _noteMidiNumber(String note) {
    final match = RegExp(r'^([A-G])([#b]?)(-?\d+)$').firstMatch(note);
    if (match == null) return 60;
    const pitchClasses = {
      'C': 0,
      'D': 2,
      'E': 4,
      'F': 5,
      'G': 7,
      'A': 9,
      'B': 11,
    };
    var pitchClass = pitchClasses[match.group(1)]!;
    if (match.group(2) == '#') pitchClass++;
    if (match.group(2) == 'b') pitchClass--;
    final octave = int.parse(match.group(3)!);
    return (octave + 1) * 12 + pitchClass;
  }

  void _updateNote(int index, LessonNote updated) {
    if (index < 0 || index >= _lesson.notes.length) return;
    _pushUndo();
    setState(() {
      final resolvedStart = _nextFreeBeat(
        _quantize(updated.startBeat),
        updated.durationBeat,
        ignoreIndex: index,
      );
      final notes = [..._lesson.notes];
      final changed = _syncNoteTiming(
        updated.copyWith(startBeat: resolvedStart),
      );
      notes[index] = changed;
      notes.sort((a, b) => a.startBeat.compareTo(b.startBeat));
      _lesson.notes = notes;
      _selectedIndex = notes.indexOf(changed);
      if (_selectedIndex == -1) _selectedIndex = null;
    });
  }

  void _deleteSelected() {
    if (_selectedIndex == null) return;
    _pushUndo();
    setState(() {
      _lesson.notes = [..._lesson.notes]..removeAt(_selectedIndex!);
      _selectedIndex = null;
    });
  }

  void _duplicateSelected() {
    if (_selectedIndex == null) return;
    final note = _lesson.notes[_selectedIndex!];
    _insertNote(note.note, beat: note.startBeat + note.durationBeat);
  }

  Future<void> _importMidi() async {
    try {
      final result = await MidiService.importMidiFile();
      if (result == null) return;

      _pushUndo();
      setState(() {
        if (result.notes.isNotEmpty) {
          _lesson.notes = result.notes;
        }
        _tempo = result.tempo.clamp(40, 220).toInt();
        if (!_timeSignatures.contains(result.timeSignature)) {
          _timeSignatures.add(result.timeSignature);
        }
        _timeSignature = result.timeSignature;
        _lesson.timeSignatureMap = result.timeSignatureMap;
        if (!_keySignatures.contains(result.keySignature)) {
          _keySignatures.add(result.keySignature);
        }
        _keySignature = result.keySignature;
        _selectedIndex = null;
        _playheadBeat = 1;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã nhập thành công ${result.notes.length} nốt từ file MIDI',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi nhập file MIDI: $e')));
    }
  }

  Future<void> _save({bool publish = false}) async {
    final syncedNotes = _lesson.notes.map(_syncNoteTiming).toList()
      ..sort((a, b) => a.startBeat.compareTo(b.startBeat));

    _lesson
      ..title = _title.text.trim().isEmpty ? 'Bài nhạc mới' : _title.text.trim()
      ..composer = _composer.text.trim()
      ..keySignature = _keySignature
      ..timeSignature = _timeSignature
      ..tempo = _tempo
      ..practiceGuide = _description.text.trim()
      ..notes = syncedNotes;

    final provider = context.read<LessonProvider>();
    final saved = await provider.saveLesson(_lesson);
    if (saved == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Không thể lưu bài học')),
      );
      return;
    }

    _lesson.id = saved.id;
    final deleted = await provider.deleteAllNotes(saved.id!);
    final inserted =
        deleted && await provider.addNotesOneByOne(saved.id!, _lesson.notes);
    if (publish && inserted) await provider.publish(saved.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          inserted
              ? (publish
                    ? 'Đã lưu và xuất bản bài học'
                    : 'Đã lưu bản nhạc theo beat')
              : provider.error ?? 'Không thể đồng bộ nốt nhạc',
        ),
      ),
    );
  }

  String _beatToDurationName(double beat) {
    const triplets = [
      (name: 'quarter_triplet', beats: 2 / 3),
      (name: 'eighth_triplet', beats: 1 / 3),
      (name: 'sixteenth_triplet', beats: 1 / 6),
    ];
    for (final triplet in triplets) {
      if ((beat - triplet.beats).abs() < 0.02) return triplet.name;
    }
    return _durationOptions
        .reduce(
          (a, b) => (a.beats - beat).abs() <= (b.beats - beat).abs() ? a : b,
        )
        .name;
  }

  double _durationNameToBeat(String duration) {
    switch (duration) {
      case 'quarter_triplet':
        return 2 / 3;
      case 'eighth_triplet':
        return 1 / 3;
      case 'sixteenth_triplet':
        return 1 / 6;
    }
    for (final option in _durationOptions) {
      if (option.name == duration) return option.beats;
    }
    return 1;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _metronomeTimer?.cancel();
    _playClock.stop();
    _recordClock.stop();
    _focusNode.dispose();
    _title.dispose();
    _composer.dispose();
    _description.dispose();
    _lyric.dispose();
    _chord.dispose();
    NoteAudioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LessonProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    final isPhone = size.shortestSide < 600;
    final staffHeight = isPhone ? 260.0 : 390.0;
    final timelineHeight = isPhone ? 72.0 : 92.0;

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Soạn nhạc cho giáo viên'),
          actions: [
            IconButton(
              tooltip: 'Nhập từ file MIDI',
              onPressed: _importMidi,
              icon: const Icon(Icons.file_open_outlined),
            ),
            IconButton(
              tooltip: 'Lưu',
              onPressed: provider.loading ? null : _save,
              icon: const Icon(Icons.save),
            ),
            IconButton(
              tooltip: 'Xuất bản',
              onPressed: provider.loading ? null : () => _save(publish: true),
              icon: const Icon(Icons.publish),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              _TransportBar(
                isPlaying: _isPlaying,
                isRecording: _isRecording,
                canUndo: _undoStack.isNotEmpty,
                canRedo: _redoStack.isNotEmpty,
                hasSelection: _selectedIndex != null,
                onPlay: _togglePlay,
                onStop: _stopTransport,
                onRecord: _toggleRecord,
                onUndo: _undo,
                onRedo: _redo,
                onDelete: _deleteSelected,
                onDuplicate: _duplicateSelected,
                onImportMidi: _importMidi,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                  children: [
                    _LessonSetupPanel(
                      title: _title,
                      composer: _composer,
                      description: _description,
                      tempo: _tempo,
                      timeSignature: _timeSignature,
                      keySignature: _keySignature,
                      metronomeEnabled: _metronomeEnabled,
                      timeSignatures: _timeSignatures,
                      keySignatures: _keySignatures,
                      onTempoChanged: (value) {
                        setState(() => _tempo = value.clamp(40, 220).toInt());
                        if (_isRecording || _isPlaying) _startMetronome();
                      },
                      onTimeSignatureChanged: (value) => setState(() {
                        _timeSignature = value;
                        _lesson.timeSignatureMap = '1:$value';
                      }),
                      onKeySignatureChanged: (value) =>
                          setState(() => _keySignature = value),
                      onMetronomeChanged: (value) {
                        setState(() => _metronomeEnabled = value);
                        if (_isRecording || _isPlaying) _startMetronome();
                      },
                    ),
                    const SizedBox(height: 12),
                    _EditorSettings(
                      selectedDurationBeat: _selectedDurationBeat,
                      quantizeStep: _quantizeStep,
                      zoom: _zoom,
                      octaveShift: _octaveShift,
                      onDurationChanged: _selectDuration,
                      onQuantizeChanged: (value) =>
                          setState(() => _quantizeStep = value),
                      onZoomChanged: (value) => setState(() => _zoom = value),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _lyric,
                      decoration: const InputDecoration(
                        labelText: 'Lời bài hát cho nốt tiếp theo',
                        prefixIcon: Icon(Icons.lyrics),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _chord,
                      decoration: const InputDecoration(
                        labelText: 'Hợp âm / ghi chú cho nốt tiếp theo',
                        prefixIcon: Icon(Icons.sticky_note_2_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: staffHeight,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFAF0),
                        border: Border.all(color: colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _CompositionStaff(
                        notes: _lesson.notes,
                        playheadBeat: _playheadBeat,
                        tempo: _tempo,
                        timeSignature: _timeSignature,
                        timeSignatureMap: _lesson.timeSignatureMap,
                        keySignature: _keySignature,
                        zoom: _zoom,
                        selectedIndex: _selectedIndex,
                        onSelect: (index) =>
                            setState(() => _selectedIndex = index),
                        onCreate: (note, beat, staff) =>
                            _insertNote(note, beat: beat, staff: staff),
                        onChange: _updateNote,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: timelineHeight,
                      child: _BeatTimeline(
                        notes: _lesson.notes,
                        playheadBeat: _playheadBeat,
                        beatsPerMeasure: _beatsPerMeasure,
                        zoom: _zoom,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _KeyboardStatusCard(
                      isRecording: _isRecording,
                      tempo: _tempo,
                      beat: _playheadBeat,
                    ),
                    const SizedBox(height: 12),
                    _NotesInspector(
                      notes: _lesson.notes,
                      selectedIndex: _selectedIndex,
                      onSelect: (index) =>
                          setState(() => _selectedIndex = index),
                      onDelete: (index) {
                        _pushUndo();
                        setState(() {
                          _lesson.notes = [..._lesson.notes]..removeAt(index);
                          _selectedIndex = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: PianoKeyboard(
                    compact: true,
                    onPressed: (note) => _insertNote(note),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransportBar extends StatelessWidget {
  final bool isPlaying;
  final bool isRecording;
  final bool canUndo;
  final bool canRedo;
  final bool hasSelection;
  final VoidCallback onPlay;
  final VoidCallback onStop;
  final VoidCallback onRecord;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onImportMidi;

  const _TransportBar({
    required this.isPlaying,
    required this.isRecording,
    required this.canUndo,
    required this.canRedo,
    required this.hasSelection,
    required this.onPlay,
    required this.onStop,
    required this.onRecord,
    required this.onUndo,
    required this.onRedo,
    required this.onDelete,
    required this.onDuplicate,
    required this.onImportMidi,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      color: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            IconButton.filledTonal(
              tooltip: isPlaying ? 'Pause' : 'Play',
              onPressed: onPlay,
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
            ),
            IconButton(
              tooltip: 'Stop',
              onPressed: onStop,
              icon: const Icon(Icons.stop),
            ),
            IconButton.filled(
              tooltip: 'Record',
              style: IconButton.styleFrom(
                backgroundColor: isRecording ? Colors.red : null,
              ),
              onPressed: onRecord,
              icon: const Icon(Icons.fiber_manual_record),
            ),
            const VerticalDivider(width: 18),
            IconButton(
              tooltip: 'Undo',
              onPressed: canUndo ? onUndo : null,
              icon: const Icon(Icons.undo),
            ),
            IconButton(
              tooltip: 'Redo',
              onPressed: canRedo ? onRedo : null,
              icon: const Icon(Icons.redo),
            ),
            IconButton(
              tooltip: 'Sao chép nốt',
              onPressed: hasSelection ? onDuplicate : null,
              icon: const Icon(Icons.copy),
            ),
            IconButton(
              tooltip: 'Xóa nốt',
              onPressed: hasSelection ? onDelete : null,
              icon: const Icon(Icons.delete_outline),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: onImportMidi,
              icon: const Icon(Icons.file_open_outlined, size: 18),
              label: const Text('Nhập MIDI'),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonSetupPanel extends StatelessWidget {
  final TextEditingController title;
  final TextEditingController composer;
  final TextEditingController description;
  final int tempo;
  final String timeSignature;
  final String keySignature;
  final bool metronomeEnabled;
  final List<String> timeSignatures;
  final List<String> keySignatures;
  final ValueChanged<int> onTempoChanged;
  final ValueChanged<String> onTimeSignatureChanged;
  final ValueChanged<String> onKeySignatureChanged;
  final ValueChanged<bool> onMetronomeChanged;

  const _LessonSetupPanel({
    required this.title,
    required this.composer,
    required this.description,
    required this.tempo,
    required this.timeSignature,
    required this.keySignature,
    required this.metronomeEnabled,
    required this.timeSignatures,
    required this.keySignatures,
    required this.onTempoChanged,
    required this.onTimeSignatureChanged,
    required this.onKeySignatureChanged,
    required this.onMetronomeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(
                labelText: 'Tên bài học',
                prefixIcon: Icon(Icons.library_music),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: composer,
              decoration: const InputDecoration(
                labelText: 'Tác giả',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: description,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Mô tả / hướng dẫn bài học',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: tempo.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'BPM',
                      prefixIcon: Icon(Icons.speed),
                    ),
                    onChanged: (value) =>
                        onTempoChanged(int.tryParse(value) ?? tempo),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: timeSignature,
                    decoration: const InputDecoration(labelText: 'Nhịp'),
                    items: timeSignatures
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) onTimeSignatureChanged(value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: keySignature,
                    decoration: const InputDecoration(labelText: 'Tông nhạc'),
                    items: keySignatures
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) onKeySignatureChanged(value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Metronome'),
                    value: metronomeEnabled,
                    onChanged: onMetronomeChanged,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorSettings extends StatelessWidget {
  final double selectedDurationBeat;
  final double quantizeStep;
  final double zoom;
  final int octaveShift;
  final ValueChanged<double> onDurationChanged;
  final ValueChanged<double> onQuantizeChanged;
  final ValueChanged<double> onZoomChanged;

  const _EditorSettings({
    required this.selectedDurationBeat,
    required this.quantizeStep,
    required this.zoom,
    required this.octaveShift,
    required this.onDurationChanged,
    required this.onQuantizeChanged,
    required this.onZoomChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 78,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _durationOptions.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final option = _durationOptions[index];
                  return _DurationButton(
                    option: option,
                    selected:
                        (option.beats - selectedDurationBeat).abs() < 0.0001,
                    onPressed: () => onDurationChanged(option.beats),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.grid_on, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<double>(
                    initialValue: quantizeStep,
                    decoration: const InputDecoration(labelText: 'Quantize'),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1 phách')),
                      DropdownMenuItem(value: 0.5, child: Text('1/2 phách')),
                      DropdownMenuItem(value: 0.25, child: Text('1/4 phách')),
                      DropdownMenuItem(value: 0.125, child: Text('1/8 phách')),
                      DropdownMenuItem(
                        value: 0.0625,
                        child: Text('1/16 phách'),
                      ),
                      DropdownMenuItem(
                        value: 0.03125,
                        child: Text('1/32 phách'),
                      ),
                      DropdownMenuItem(
                        value: 0.015625,
                        child: Text('1/64 phách'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) onQuantizeChanged(value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Text('Q/W/E/R: octave $octaveShift'),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.zoom_out, size: 18),
                Expanded(
                  child: Slider(
                    value: zoom.clamp(0.6, 3.6),
                    min: 0.6,
                    max: 3.6,
                    divisions: 30,
                    onChanged: onZoomChanged,
                  ),
                ),
                const Icon(Icons.zoom_in, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationButton extends StatelessWidget {
  final _DurationOption option;
  final bool selected;
  final VoidCallback onPressed;

  const _DurationButton({
    required this.option,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 98,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          backgroundColor: selected ? colorScheme.primaryContainer : null,
          foregroundColor: selected ? colorScheme.onPrimaryContainer : null,
          side: BorderSide(
            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(option.symbol, style: const TextStyle(fontSize: 23)),
            const SizedBox(height: 2),
            Text(
              option.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
            Text(
              '${option.beats} beat',
              maxLines: 1,
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompositionStaff extends StatelessWidget {
  final List<LessonNote> notes;
  final double playheadBeat;
  final int tempo;
  final String timeSignature;
  final String timeSignatureMap;
  final String keySignature;
  final double zoom;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;
  final void Function(String note, double beat, int staff) onCreate;
  final void Function(int index, LessonNote updated) onChange;

  const _CompositionStaff({
    required this.notes,
    required this.playheadBeat,
    required this.tempo,
    required this.timeSignature,
    required this.timeSignatureMap,
    required this.keySignature,
    required this.zoom,
    required this.selectedIndex,
    required this.onSelect,
    required this.onCreate,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth;
        final scoreLayout = ScoreEngravingService.layout(
          notes: notes,
          minimumEndBeat: playheadBeat,
          timeSignature: timeSignature,
          timeSignatureMap: timeSignatureMap,
          keySignature: keySignature,
          width: contentWidth,
          style: EngravingStyle(
            systemHeight: 270 * max(0.85, zoom),
            staffSpace: 10 * max(0.85, zoom),
            grandStaffDistance: 100 * max(0.85, zoom),
            minimumSliceWidth: 20 * max(0.75, zoom),
          ),
        );
        final contentHeight = scoreLayout.height;
        return SingleChildScrollView(
          child: SizedBox(
            width: contentWidth,
            height: contentHeight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                final hit = EngravedScoreGeometry.hitTest(
                  scoreLayout,
                  details.localPosition,
                );
                if (hit != null) {
                  onSelect(hit);
                  return;
                }
                final beat = scoreLayout.beatAt(
                  details.localPosition.dx,
                  details.localPosition.dy,
                );
                final staff = EngravedScoreGeometry.staffAt(
                  scoreLayout,
                  details.localPosition,
                );
                final note = EngravedScoreGeometry.noteAt(
                  scoreLayout,
                  details.localPosition,
                  staff,
                );
                onCreate(note, beat, staff);
              },
              onPanUpdate: (details) {
                if (selectedIndex == null) return;
                final selected = notes[selectedIndex!];
                final beat = scoreLayout.beatAt(
                  details.localPosition.dx,
                  details.localPosition.dy,
                );
                final staff = EngravedScoreGeometry.staffAt(
                  scoreLayout,
                  details.localPosition,
                );
                final note = EngravedScoreGeometry.noteAt(
                  scoreLayout,
                  details.localPosition,
                  staff,
                );
                onChange(
                  selectedIndex!,
                  selected.copyWith(
                    startBeat: beat.clamp(1, 256).toDouble(),
                    second: -1,
                    note: note,
                    staff: staff,
                  ),
                );
              },
              onLongPressMoveUpdate: (details) {
                if (selectedIndex == null) return;
                final selected = notes[selectedIndex!];
                final beat = scoreLayout.beatAt(
                  details.localPosition.dx,
                  details.localPosition.dy,
                );
                onChange(
                  selectedIndex!,
                  selected.copyWith(
                    durationBeat: max(0.125, beat - selected.startBeat),
                  ),
                );
              },
              child: CustomPaint(
                size: Size(contentWidth, contentHeight),
                painter: EngravedScorePainter(
                  layout: scoreLayout,
                  tempo: tempo,
                  playheadBeat: playheadBeat,
                  selectedSourceIndex: selectedIndex,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BeatTimeline extends StatelessWidget {
  final List<LessonNote> notes;
  final double playheadBeat;
  final double beatsPerMeasure;
  final double zoom;

  const _BeatTimeline({
    required this.notes,
    required this.playheadBeat,
    required this.beatsPerMeasure,
    required this.zoom,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _TimelinePainter(
          notes: notes,
          playheadBeat: playheadBeat,
          beatsPerMeasure: beatsPerMeasure,
          zoom: zoom,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  final List<LessonNote> notes;
  final double playheadBeat;
  final double beatsPerMeasure;
  final double zoom;

  _TimelinePainter({
    required this.notes,
    required this.playheadBeat,
    required this.beatsPerMeasure,
    required this.zoom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF101820),
    );
    final beatWidth = 72 * zoom;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var beat = 1.0; beat < size.width / beatWidth + 3; beat += 1) {
      final x = 18 + (beat - 1) * beatWidth;
      final isMeasure = ((beat - 1) % beatsPerMeasure).abs() < 0.01;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = isMeasure
              ? const Color(0xFF5DD8FF)
              : const Color(0xFF263341)
          ..strokeWidth = isMeasure ? 1.4 : 1,
      );
      if (isMeasure) {
        textPainter.text = TextSpan(
          text: '${((beat - 1) / beatsPerMeasure).floor() + 1}',
          style: const TextStyle(color: Color(0xFF8BC7D9), fontSize: 11),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x + 3, 6));
      }
    }

    final staggerMap = <int, int>{};
    final beatGroupCount = <double, int>{};
    for (var i = 0; i < notes.length; i++) {
      final b = (notes[i].startBeat * 16).round() / 16;
      final idx = beatGroupCount[b] ?? 0;
      staggerMap[i] = idx;
      beatGroupCount[b] = idx + 1;
    }

    for (var i = 0; i < notes.length; i++) {
      final note = notes[i];
      final x = 18 + (note.startBeat - 1) * beatWidth;
      final staggerIdx = staggerMap[i] ?? 0;
      final laneTop = staggerIdx == 0 ? 10.0 : (staggerIdx == 1 ? 34.0 : 58.0);

      double nextBeat = 999999.0;
      for (var j = i + 1; j < notes.length; j++) {
        if (notes[j].startBeat > note.startBeat + 0.01) {
          nextBeat = notes[j].startBeat;
          break;
        }
      }
      final rawW = note.durationBeat * beatWidth;
      final maxAllowedW = (nextBeat < 999999.0)
          ? (nextBeat - note.startBeat) * beatWidth - 3.0
          : rawW;
      final w = max(16.0, min(rawW, maxAllowedW));

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, laneTop, w, 20),
        const Radius.circular(5),
      );
      canvas.drawRRect(rect, Paint()..color = const Color(0xFF39A0ED));
      textPainter.text = TextSpan(
        text: note.note,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout(maxWidth: w - 2);
      textPainter.paint(canvas, Offset(x + 3, laneTop + 4));
    }

    final playX = 18 + (playheadBeat - 1) * beatWidth;
    canvas.drawLine(
      Offset(playX, 0),
      Offset(playX, size.height),
      Paint()
        ..color = Colors.redAccent
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter oldDelegate) => true;
}

class _KeyboardStatusCard extends StatelessWidget {
  final bool isRecording;
  final int tempo;
  final double beat;

  const _KeyboardStatusCard({
    required this.isRecording,
    required this.tempo,
    required this.beat,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(
          isRecording
              ? Icons.radio_button_checked
              : Icons.keyboard_alt_outlined,
          color: isRecording ? Colors.red : null,
        ),
        title: const Text('Nhập bằng bàn phím'),
        subtitle: Text(
          'Piano ảo dùng tốt trên điện thoại. Web/desktop: A S D F G H J = C D E F G A B · Space = Play/Pause · BPM $tempo · beat ${beat.toStringAsFixed(2)}',
        ),
      ),
    );
  }
}

class _NotesInspector extends StatelessWidget {
  final List<LessonNote> notes;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onDelete;

  const _NotesInspector({
    required this.notes,
    required this.selectedIndex,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return const Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Chưa có nốt nào. Chạm lên khuông nhạc hoặc dùng piano ảo để nhập nốt.',
          ),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          for (var i = 0; i < notes.length; i++)
            ListTile(
              selected: selectedIndex == i,
              leading: CircleAvatar(child: Text('${i + 1}')),
              title: Text(
                '${notes[i].note} · beat ${notes[i].startBeat.toStringAsFixed(2)}',
              ),
              subtitle: Text(
                'duration ${notes[i].durationBeat.toStringAsFixed(2)} · velocity ${notes[i].velocity}'
                '${notes[i].lyric.isEmpty ? '' : ' · ${notes[i].lyric}'}',
              ),
              onTap: () => onSelect(i),
              trailing: IconButton(
                tooltip: 'Xóa',
                onPressed: () => onDelete(i),
                icon: const Icon(Icons.delete_outline),
              ),
            ),
        ],
      ),
    );
  }
}
