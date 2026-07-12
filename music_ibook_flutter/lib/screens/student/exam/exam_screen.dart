import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:go_router/go_router.dart';

import '../../../models/lesson.dart';
import '../../../models/practice.dart';
import '../../../providers/lesson_provider.dart';
import '../../../providers/student_provider.dart';
import '../../../widgets/music_staff.dart';
import '../../../widgets/piano_keyboard.dart';
import '../../../widgets/result_dialog.dart';

class ExamScreen extends StatefulWidget {
  final int lessonId;
  const ExamScreen({super.key, required this.lessonId});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> with TickerProviderStateMixin {
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
  late final AnimationController _timerPulse;
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _feedbackAnim = CurvedAnimation(
      parent: _feedbackController,
      curve: Curves.elasticOut,
    );

    _timerPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));

    Future.microtask(() async {
      final loaded =
          await context.read<LessonProvider>().loadLesson(widget.lessonId);
      if (!mounted) return;
      setState(() => lesson = loaded);
    });
  }

  void startExam() {
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

      _checkMissedNotes();

      if (lesson != null && currentIndex >= lesson!.notes.length) {
        _endExam();
      }
    });
  }

  void _checkMissedNotes() {
    if (lesson == null) return;
    if (currentIndex < lesson!.notes.length) {
      final expected = lesson!.notes[currentIndex];
      if (elapsedSeconds > expected.second + 0.3) {
        wrong++;
        attempts.add(
          NoteAttemptRequest(
            lessonNoteId: expected.id ?? 0,
            playedNote: '',
            playedSecond: elapsedSeconds,
          ),
        );
        currentIndex++;
      }
    }
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

    final timeDiff = (elapsedSeconds - expected.second).abs();
    final correctPitch = expected.note == note;
    final correctTiming = timeDiff <= 0.3;
    final isCorrect = correctPitch && correctTiming;

    setState(() {
      lastWasCorrect = isCorrect;
      if (isCorrect) {
        correct++;
      } else {
        wrong++;
      }
      currentIndex++;
    });

    _feedbackController.forward(from: 0);
  }

  void _endExam() {
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
      isExam: true,
      durationSeconds: durationSeconds,
    );
    if (!mounted || result == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (_) => ResultDialog(
        title: 'Kết quả kiểm tra 📝',
        correctCount: result.correctCount,
        wrongCount: result.wrongCount,
        accuracy: result.accuracy,
        isPractice: false,
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
    _timerPulse.dispose();
    _confettiController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = lesson;
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
                        Color.lerp(const Color(0xFF2a0000), const Color(0xFF1a0020),
                            _bgController.value)!,
                        Color.lerp(const Color(0xFF1a0020), const Color(0xFF0a1a2a),
                            _bgController.value)!,
                        Color.lerp(const Color(0xFF300010), const Color(0xFF200000),
                            _bgController.value)!,
                      ]
                    : [
                        const Color(0xFF2a0a0a),
                        const Color(0xFF1a0010),
                        const Color(0xFF0f0a1e),
                      ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: child,
          );
        },
        child: Stack(
          children: [
            if (!isPlaying) ..._buildDecorativeNotes(),

            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),

                  if (l == null)
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.redAccent),
                      ),
                    )
                  else if (!isPlaying && attempts.isEmpty)
                    Expanded(child: _buildStartScreen(l))
                  else ...[
                    if (isPlaying) _buildExamHUD(isLandscape),

                    Expanded(
                      child: Stack(
                        children: [
                          MusicStaff(lesson: l),
                          // Feedback flash
                          if (lastWasCorrect != null)
                            AnimatedBuilder(
                              animation: _feedbackAnim,
                              builder: (ctx, _) {
                                final alpha = ((1 - _feedbackAnim.value) * 80)
                                    .toInt()
                                    .clamp(0, 255);
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

                    PianoKeyboard(
                      onPressed: press,
                      compact: isLandscape,
                      // No targetNote in exam mode — no hints!
                    ),
                  ],
                ],
              ),
            ),

            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                numberOfParticles: 30,
                colors: const [
                  Colors.orange, Colors.yellow, Colors.red,
                  Colors.pink, Colors.purple, Colors.white,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                color: Colors.white.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
            ),
          ),
          const Spacer(),
          if (!isPlaying)
            Text(
              'Kiểm tra',
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

  Widget _buildExamHUD(bool isLandscape) {
    // Danger mode when more than 60s
    final isDanger = durationSeconds > 60;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDanger
              ? Colors.redAccent.withAlpha(100)
              : Colors.white.withAlpha(25),
          width: isDanger ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _chip('✅ $correct', Colors.green),
              const SizedBox(width: 8),
              _chip('❌ $wrong', Colors.red),
            ],
          ),
          // Timer (pulsing red in danger)
          AnimatedBuilder(
            animation: _timerPulse,
            builder: (ctx, _) {
              final scale = isDanger ? 1.0 + _timerPulse.value * 0.06 : 1.0;
              return Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDanger
                        ? Colors.red.withAlpha(60 + (_timerPulse.value * 40).toInt())
                        : Colors.white.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDanger ? Colors.redAccent : Colors.white30,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: isDanger ? Colors.red : Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${elapsedSeconds.toStringAsFixed(1)}s',
                        style: TextStyle(
                          color: isDanger ? Colors.red.shade300 : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  Widget _buildStartScreen(MusicLesson l) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 420;
        final iconSize = compact ? 72.0 : 120.0;
        final titleFontSize = compact ? 20.0 : 28.0;
        final spacing1 = compact ? 12.0 : 24.0;
        final spacing2 = compact ? 16.0 : 40.0;

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
                        colors: [Colors.red.withAlpha(80), Colors.transparent],
                      ),
                      border: Border.all(color: Colors.red.withAlpha(120), width: 2),
                    ),
                    child: Icon(Icons.assignment,
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
                    '${l.notes.length} nốt nhạc • Không có gợi ý',
                    style: TextStyle(color: Colors.red.withAlpha(180), fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withAlpha(80)),
                    ),
                    child: const Text(
                      '⚠️ Chế độ kiểm tra — phím đàn sẽ không hiển thị gợi ý',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: spacing2),
                  GestureDetector(
                    onTap: startExam,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: compact ? 12 : 18,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red.shade400, Colors.red.shade800],
                        ),
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withAlpha(120),
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
                            'BẮT ĐẦU KIỂM TRA',
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
    final rnd = Random(99);
    final symbols = ['♩', '♪', '♫', '♬', '𝄞'];
    return List.generate(10, (i) {
      return Positioned(
        left: rnd.nextDouble() * 400,
        top: rnd.nextDouble() * 800,
        child: Text(
          symbols[rnd.nextInt(symbols.length)],
          style: TextStyle(
            color: Colors.red.withAlpha(10 + rnd.nextInt(15)),
            fontSize: 24 + rnd.nextInt(40).toDouble(),
          ),
        ),
      );
    });
  }
}
