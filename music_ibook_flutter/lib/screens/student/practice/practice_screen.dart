import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';

import '../../../models/lesson.dart';
import '../../../models/practice.dart';
import '../../../providers/lesson_provider.dart';
import '../../../providers/student_provider.dart';
import '../../../widgets/music_staff.dart';
import '../../../widgets/piano_keyboard.dart';
import '../../../widgets/result_dialog.dart';

class PracticeScreen extends StatefulWidget {
  final int lessonId;
  const PracticeScreen({super.key, required this.lessonId});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen>
    with TickerProviderStateMixin {
  MusicLesson? lesson;
  int currentIndex = 0;
  int correct = 0;
  int wrong = 0;
  final attempts = <NoteAttemptRequest>[];

  bool isPlaying = false;
  double elapsedSeconds = 0;
  Timer? timer;
  int durationSeconds = 0;

  bool? lastWasCorrect;
  late final AnimationController _bgController;
  late final AnimationController _feedbackController;
  late final Animation<double> _feedbackAnim;
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _feedbackAnim = CurvedAnimation(
      parent: _feedbackController,
      curve: Curves.elasticOut,
    );

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));

    Future.microtask(() async {
      final loaded =
          await context.read<LessonProvider>().loadLesson(widget.lessonId);
      if (!mounted) return;
      setState(() => lesson = loaded);
    });
  }

  void startPractice() {
    setState(() {
      isPlaying = true;
      elapsedSeconds = 0;
      currentIndex = 0;
      correct = 0;
      wrong = 0;
      lastWasCorrect = null;
      attempts.clear();
      durationSeconds = 0;
    });

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted) return;
      setState(() {
        elapsedSeconds += 0.1;
        durationSeconds = elapsedSeconds.floor();
      });

      if (lesson != null && currentIndex >= lesson!.notes.length) {
        _endPractice();
      }
    });
  }

  void press(String note) {
    if (!isPlaying) return;
    final l = lesson;
    if (l == null || currentIndex >= l.notes.length) return;

    final expected = l.notes[currentIndex];

    attempts.add(
      NoteAttemptRequest(
        lessonNoteId: expected.id ?? 0,
        playedNote: note,
        playedSecond: elapsedSeconds,
      ),
    );

    final isCorrect = expected.note == note;

    setState(() {
      lastWasCorrect = isCorrect;
      if (isCorrect) {
        correct++;
        currentIndex++;
      } else {
        wrong++;
      }
    });

    _feedbackController.forward(from: 0);
  }

  void _endPractice() {
    timer?.cancel();
    setState(() {
      isPlaying = false;
    });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _confettiController.play();
    submit();
  }

  Future<void> submit() async {
    final studentProvider = context.read<StudentProvider>();
    final result = await studentProvider.submitPractice(
      widget.lessonId,
      attempts,
      isExam: false,
      durationSeconds: durationSeconds,
    );

    if (!mounted || result == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (_) => ResultDialog(
        title: 'Luyện tập hoàn thành! 🎉',
        correctCount: result.correctCount,
        wrongCount: result.wrongCount,
        accuracy: result.accuracy,
        isPractice: true,
        onClose: () {
          Navigator.pop(context);
          context.pop();
        },
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    _bgController.dispose();
    _feedbackController.dispose();
    _confettiController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = lesson;
    final current = l == null || currentIndex >= l.notes.length
        ? null
        : l.notes[currentIndex];

    double? countdown;
    if (isPlaying && current != null) {
      countdown = current.second - elapsedSeconds;
      if (countdown < 0) countdown = 0;
    }

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isPlaying
                    ? [
                        Color.lerp(const Color(0xFF0d1b2a), const Color(0xFF1a0a3b),
                            _bgController.value)!,
                        Color.lerp(const Color(0xFF1a0a3b), const Color(0xFF0a2a1a),
                            _bgController.value)!,
                        Color.lerp(const Color(0xFF0a2a1a), const Color(0xFF2a0a1a),
                            _bgController.value)!,
                      ]
                    : [
                        const Color(0xFF1a1a2e),
                        const Color(0xFF16213e),
                        const Color(0xFF0f3460),
                      ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: child,
          );
        },
        child: Stack(
          children: [
            // Decorative music notes background
            if (!isPlaying)
              ..._buildDecorativeNotes(),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  // AppBar area
                  _buildHeader(isLandscape),

                  if (l == null)
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    )
                  else if (!isPlaying && attempts.isEmpty)
                    Expanded(child: _buildStartScreen(l))
                  else ...[
                    // Floating score HUD
                    if (isPlaying) _buildHUD(current, isLandscape),

                    // Music staff
                    Expanded(
                      child: Stack(
                        children: [
                          MusicStaff(
                            lesson: l,
                            highlightIndex:
                                isPlaying && currentIndex < l.notes.length
                                    ? currentIndex
                                    : null,
                            countdownSeconds: countdown,
                          ),
                          // Feedback flash overlay
                          if (lastWasCorrect != null)
                            AnimatedBuilder(
                              animation: _feedbackAnim,
                              builder: (ctx, _) {
                                final alpha =
                                    ((1 - _feedbackAnim.value) * 80).toInt().clamp(0, 255);
                                return Positioned.fill(
                                  child: IgnorePointer(
                                    child: Container(
                                      color: lastWasCorrect!
                                          ? Colors.green.withAlpha(alpha)
                                          : Colors.red.withAlpha(alpha),
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),

                    // Piano
                    PianoKeyboard(
                      onPressed: press,
                      targetNote: isPlaying ? current?.note : null,
                      compact: isLandscape,
                    ),
                  ],
                ],
              ),
            ),

            // Confetti
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                numberOfParticles: 30,
                colors: const [
                  Colors.orange, Colors.yellow, Colors.green,
                  Colors.blue, Colors.pink, Colors.purple,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isLandscape) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
              context.pop();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
            ),
          ),
          const Spacer(),
          if (!isPlaying)
            Text(
              'Luyện tập',
              style: TextStyle(
                color: Colors.white.withAlpha(220),
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildHUD(dynamic current, bool isLandscape) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Score
          Row(
            children: [
              _scoreChip('✅ $correct', Colors.green),
              const SizedBox(width: 8),
              _scoreChip('❌ $wrong', Colors.red),
            ],
          ),
          // Note to press
          if (current != null)
            AnimatedBuilder(
              animation: _feedbackAnim,
              builder: (ctx, _) => Transform.scale(
                scale: 1 + _feedbackAnim.value * 0.1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.shade400,
                        Colors.orange.shade700,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withAlpha(100),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Text(
                    '♪ ${current.note}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
          // Timer
          Text(
            '${durationSeconds}s',
            style: TextStyle(
              color: Colors.white.withAlpha(180),
              fontSize: 14,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildStartScreen(MusicLesson l) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 400;
        final iconSize = compact ? 72.0 : 120.0;
        final titleFontSize = compact ? 20.0 : 28.0;
        final spacing1 = compact ? 12.0 : 24.0;
        final spacing2 = compact ? 20.0 : 40.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Colors.blue.withAlpha(80), Colors.transparent],
                      ),
                      border: Border.all(color: Colors.blue.withAlpha(100), width: 2),
                    ),
                    child: Icon(Icons.music_note,
                        size: iconSize * 0.5, color: Colors.white),
                  ),
                  SizedBox(height: spacing1),
                  Text(
                    l.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  if (l.composer.isNotEmpty)
                    Text(
                      '— ${l.composer}',
                      style: TextStyle(
                          color: Colors.white.withAlpha(160), fontSize: 14),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '${l.notes.length} nốt nhạc',
                    style:
                        TextStyle(color: Colors.white.withAlpha(120), fontSize: 13),
                  ),
                  SizedBox(height: spacing2),
                  GestureDetector(
                    onTap: startPractice,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: compact ? 12 : 18,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade700],
                        ),
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withAlpha(120),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow_rounded,
                              color: Colors.white, size: 26),
                          SizedBox(width: 8),
                          Text(
                            'BẮT ĐẦU LUYỆN TẬP',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildDecorativeNotes() {
    final rnd = Random(42);
    final symbols = ['♩', '♪', '♫', '♬', '𝄞', '𝄢'];
    return List.generate(12, (i) {
      return Positioned(
        left: rnd.nextDouble() * 400,
        top: rnd.nextDouble() * 800,
        child: Text(
          symbols[rnd.nextInt(symbols.length)],
          style: TextStyle(
            color: Colors.white.withAlpha(10 + rnd.nextInt(15)),
            fontSize: 24 + rnd.nextInt(40).toDouble(),
          ),
        ),
      );
    });
  }
}


