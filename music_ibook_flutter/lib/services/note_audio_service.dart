import 'package:audioplayers/audioplayers.dart';

class NoteAudioService {
  static final Map<String, List<AudioPlayer>> _playersPool = {};
  static final Map<String, int> _playerIndex = {};
  static bool _initialized = false;

  // Available audio files (mp3 assets)
  static const _availableNotes = ['C4', 'D4', 'E4', 'F4', 'F#4', 'G4', 'A4', 'B4', 'C5', 'D5', 'E5'];

  static const Map<String, String> noteToFile = {
    'C4': 'C4', 'D4': 'D4', 'E4': 'E4', 'F4': 'F4',
    'F#4': 'Fs4', 'G4': 'G4', 'A4': 'A4', 'B4': 'B4',
    'C5': 'C5', 'D5': 'D5', 'E5': 'E5',
  };

  // Chromatic scale for mapping
  static const _chromaticNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

  /// Maps any note (e.g. B5, F#3, C6) to the nearest available note in C4-E5 range.
  /// Keeps the same pitch class, transposes octave.
  /// Sharps without exact match (G#, A#, D#, C#) map to the nearest available note.
  static String _mapToAvailable(String note) {
    if (_availableNotes.contains(note)) return note;

    // Parse note name + octave (e.g. "A#5" -> name="A#", octave=5)
    final match = RegExp(r'^([A-G]#?)(\d+)$').firstMatch(note);
    if (match == null) return 'C4';
    final name = match.group(1)!;
    final octave = int.parse(match.group(2)!);

    // Try closest octave first (5 for high notes, 4 for low notes)
    if (octave >= 5) {
      final inOct5 = '${name}5';
      if (_availableNotes.contains(inOct5)) return inOct5;
      final inOct4 = '${name}4';
      if (_availableNotes.contains(inOct4)) return inOct4;
    } else {
      final inOct4 = '${name}4';
      if (_availableNotes.contains(inOct4)) return inOct4;
      final inOct5 = '${name}5';
      if (_availableNotes.contains(inOct5)) return inOct5;
    }

    // For notes like G#, A#, D#, C# that have no exact mp3 file,
    // map to the nearest semitone up in octave 4
    final idx = _chromaticNames.indexOf(name);
    if (idx < 0) return 'C4';

    // Map sharp notes to nearest available
    const sharpMapping = {
      'C#': 'D4', 'D#': 'E4', 'G#': 'A4', 'A#': 'B4',
    };
    if (sharpMapping.containsKey(name)) return sharpMapping[name]!;

    return 'C4';
  }

  static void init() {
    if (_initialized) return;
    _initialized = true;

    try {
      AudioPlayer.global.setAudioContext(AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {AVAudioSessionOptions.mixWithOthers},
        ),
      ));
    } catch (_) {}

    for (final note in _availableNotes) {
      final fileName = noteToFile[note] ?? note;
      _playersPool[note] = List.generate(4, (_) {
        final player = AudioPlayer();
        player.setReleaseMode(ReleaseMode.stop);
        player.setSourceAsset('notes/$fileName.mp3');
        return player;
      });
      _playerIndex[note] = 0;
    }
  }

  static Future<void> playNote(String note) async {
    if (!_initialized) init();

    final mappedNote = _mapToAvailable(note);

    final pool = _playersPool[mappedNote];
    if (pool != null && pool.isNotEmpty) {
      final idx = (_playerIndex[mappedNote] ?? 0) % pool.length;
      final player = pool[idx];
      _playerIndex[mappedNote] = idx + 1;

      try {
        if (player.state == PlayerState.playing) {
          await player.stop();
        }
        await player.play(AssetSource('notes/${noteToFile[mappedNote] ?? mappedNote}.mp3'));
      } catch (_) {}
    }
  }

  static void dispose() {
    for (final pool in _playersPool.values) {
      for (final p in pool) {
        p.dispose();
      }
    }
    _playersPool.clear();
    _playerIndex.clear();
    _initialized = false;
  }
}
