import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soundpool/soundpool.dart';

class PianoKeyboard extends StatefulWidget {
  final void Function(String note) onPressed;
  final String? targetNote;
  final bool compact;

  const PianoKeyboard({
    super.key,
    required this.onPressed,
    this.targetNote,
    this.compact = false,
  });

  @override
  State<PianoKeyboard> createState() => _PianoKeyboardState();
}

class _PianoKeyboardState extends State<PianoKeyboard>
    with TickerProviderStateMixin {
  late final Soundpool _soundpool;
  final Map<String, int> _soundIds = {};
  final Map<String, AnimationController> _pressControllers = {};
  final Map<String, AnimationController> _glowControllers = {};
  final Set<String> _pressedKeys = {};

  // White keys in order
  static const List<String> whiteNotes = [
    'C4', 'D4', 'E4', 'F4', 'G4', 'A4', 'B4', 'C5', 'D5', 'E5'
  ];

  // Black key positions: note -> index between white keys (null = no black key after that white)
  static const Map<String, String?> blackAfterWhite = {
    'C4': 'C#4',
    'D4': 'D#4',
    'E4': null,
    'F4': 'F#4',
    'G4': 'G#4',
    'A4': 'A#4',
    'B4': null,
    'C5': 'C#5',
    'D5': 'D#5',
    'E5': null,
  };

  // Asset file name mapping
  static const Map<String, String> noteToFile = {
    'C4': 'C4', 'D4': 'D4', 'E4': 'E4', 'F4': 'F4',
    'F#4': 'Fs4', 'G4': 'G4', 'A4': 'A4', 'B4': 'B4',
    'C5': 'C5', 'D5': 'D5', 'E5': 'E5',
    // Black keys fallback to nearest
    'C#4': 'D4', 'D#4': 'E4', 'G#4': 'A4', 'A#4': 'B4',
    'C#5': 'D5', 'D#5': 'E5',
  };

  @override
  void initState() {
    super.initState();

    // Initialize Soundpool
    _soundpool = Soundpool.fromOptions(options: const SoundpoolOptions(
      streamType: StreamType.music,
      maxStreams: 8,
    ));

    // Load audio for playable notes
    _initSounds();

    // Create press animation controllers for all keys
    for (final note in whiteNotes) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 80),
        reverseDuration: const Duration(milliseconds: 200),
      );
      _pressControllers[note] = ctrl;
    }
    for (final entry in blackAfterWhite.entries) {
      final black = entry.value;
      if (black != null) {
        final ctrl = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 80),
          reverseDuration: const Duration(milliseconds: 200),
        );
        _pressControllers[black] = ctrl;
      }
    }

    // Glow animation for target note (pulsing)
    for (final note in whiteNotes) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 700),
      )..repeat(reverse: true);
      _glowControllers[note] = ctrl;
    }
  }

  Future<void> _initSounds() async {
    for (final note in ['C4','D4','E4','F4','F#4','G4','A4','B4','C5','D5','E5']) {
      final fileName = noteToFile[note] ?? note;
      try {
        final assetData = await rootBundle.load('assets/notes/$fileName.mp3');
        final soundId = await _soundpool.load(assetData);
        _soundIds[note] = soundId;
      } catch (e) {
        debugPrint('Lỗi load âm thanh $note: $e');
      }
    }
  }

  @override
  void dispose() {
    _soundpool.dispose();
    for (final c in _pressControllers.values) {
      c.dispose();
    }
    for (final c in _glowControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _handlePress(String note) async {
    widget.onPressed(note);

    // Lấy note gốc thực sự sẽ phát (để hỗ trợ phím đen fallback sang phím trắng nếu thiếu file)
    // Các phím đen nếu thiếu file thì fallback sang phím kế tiếp theo noteToFile
    final mappedNote = ['C4','D4','E4','F4','F#4','G4','A4','B4','C5','D5','E5'].contains(note)
        ? note
        : (noteToFile[note] ?? note);

    final soundId = _soundIds[mappedNote];
    if (soundId != null) {
      await _soundpool.play(soundId);
    }

    // Press animation
    final ctrl = _pressControllers[note];
    if (ctrl != null) {
      ctrl.forward().then((_) => ctrl.reverse());
    }
    setState(() => _pressedKeys.add(note));
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _pressedKeys.remove(note));
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isSmall = MediaQuery.of(context).size.height < 500;
    final keyHeight = widget.compact || (isLandscape && isSmall) ? 75.0 : 110.0;
    final fontSize = widget.compact || (isLandscape && isSmall) ? 7.0 : 9.0;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth - 12;
          final whiteKeyWidth = totalWidth / whiteNotes.length;
          final blackKeyWidth = whiteKeyWidth * 0.6;
          final blackKeyHeight = keyHeight * 0.62;

          return SizedBox(
            height: keyHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // White keys
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: whiteNotes.map((note) {
                    final isTarget = note == widget.targetNote;
                    final isPressed = _pressedKeys.contains(note);
                    final glowCtrl = _glowControllers[note];
                    final pressCtrl = _pressControllers[note];

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.5),
                        child: RepaintBoundary(
                          child: AnimatedBuilder(
                            animation: Listenable.merge([
                              if (pressCtrl != null) pressCtrl,
                              if (isTarget && glowCtrl != null) glowCtrl,
                            ]),
                            builder: (context, _) {
                              final pressVal = pressCtrl?.value ?? 0.0;
                              final glowVal = isTarget ? (glowCtrl?.value ?? 0.0) : 0.0;
  
                              return Transform.translate(
                                offset: Offset(0, pressVal * 4),
                                child: GestureDetector(
                                  onTapDown: (_) => _handlePress(note),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: isTarget
                                          ? LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Color.lerp(Colors.white, const Color(0xFFFFD700), 0.3 + glowVal * 0.4)!,
                                                Color.lerp(const Color(0xFFFFF0CC), const Color(0xFFFF9800), 0.3 + glowVal * 0.3)!,
                                              ],
                                            )
                                          : isPressed
                                              ? const LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [Color(0xFF90CAF9), Color(0xFF42A5F5)],
                                                )
                                              : const LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [Color(0xFFFFFFF0), Color(0xFFEEEEEE)],
                                                ),
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(5),
                                        bottomRight: Radius.circular(5),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isTarget
                                              ? Color.lerp(Colors.orange.withAlpha(120), Colors.orange.withAlpha(200), glowVal)!
                                              : Colors.black.withAlpha(isPressed ? 20 : 60),
                                          blurRadius: isTarget ? 12 + glowVal * 8 : 3,
                                          spreadRadius: isTarget ? glowVal * 3 : 0,
                                          offset: Offset(0, isPressed ? 1 : 3),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: isTarget
                                            ? Colors.orange.withAlpha(180)
                                            : Colors.black38,
                                        width: isTarget ? 1.5 : 0.8,
                                      ),
                                    ),
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Padding(
                                        padding: const EdgeInsets.only(bottom: 6),
                                        child: Text(
                                          _shortNote(note),
                                          style: TextStyle(
                                            fontSize: fontSize,
                                            fontWeight: FontWeight.bold,
                                            color: isTarget
                                                ? Colors.orange.shade800
                                                : Colors.black54,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                // Black keys overlay
                ...List.generate(whiteNotes.length, (i) {
                  final whiteNote = whiteNotes[i];
                  final blackNote = blackAfterWhite[whiteNote];
                  if (blackNote == null) return const SizedBox.shrink();

                  final leftPos = (i + 1) * whiteKeyWidth - blackKeyWidth / 2 + 3;
                  final isPressed = _pressedKeys.contains(blackNote);
                  final pressCtrl = _pressControllers[blackNote];

                  return Positioned(
                    left: leftPos,
                    top: 0,
                    width: blackKeyWidth,
                    height: blackKeyHeight,
                    child: RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: pressCtrl ?? const AlwaysStoppedAnimation(0),
                        builder: (context, _) {
                          final pressVal = pressCtrl?.value ?? 0.0;
                          return Transform.translate(
                            offset: Offset(0, pressVal * 3),
                            child: GestureDetector(
                              onTapDown: (_) => _handlePress(blackNote),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: isPressed
                                      ? const LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [Color(0xFF444466), Color(0xFF222244)],
                                        )
                                      : const LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [Color(0xFF2c2c3e), Color(0xFF1a1a2a)],
                                        ),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(4),
                                    bottomRight: Radius.circular(4),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(isPressed ? 100 : 180),
                                      blurRadius: isPressed ? 2 : 5,
                                      offset: Offset(0, isPressed ? 1 : 4),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  String _shortNote(String note) {
    // Return something like "C4", "D4" etc.
    return note.replaceAll('#', '♯');
  }
}
