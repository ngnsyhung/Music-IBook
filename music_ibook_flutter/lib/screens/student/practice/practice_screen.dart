import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_config.dart';
import '../../../core/game_judge.dart';
import '../../../models/lesson.dart';
import '../../../models/practice.dart';
import '../../../providers/lesson_provider.dart';
import '../../../providers/student_provider.dart';
import '../../../widgets/piano_keyboard.dart';
import '../../../widgets/rhythm_timeline.dart';

class PracticeScreen extends StatefulWidget {
  final int lessonId;
  const PracticeScreen({super.key, required this.lessonId});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen>
    with TickerProviderStateMixin {
  MusicLesson? lesson;

  // ─── Game State ──────────────────────────────────────────────────
  bool isPlaying = false;
  bool isFinished = false;
  int currentNoteIndex = 0;
  int score = 0;
  int correct = 0;
  int wrong = 0;
  int durationSeconds = 0;
  final attempts = <NoteAttemptRequest>[];

  /// Lưu lịch sử kết quả theo index nốt để vẽ màu trên RhythmTimeline
  final judgeHistory = <int, String>{};

  // ─── Ticker & Notifier cho Animation 60fps ────────────────────────
  Timer? _countdownTimer;
  bool isCountingDown = false;
  int countdownValue = 0;
  Ticker? _ticker;
  final ValueNotifier<double> _elapsedNotifier = ValueNotifier<double>(0.0);

  // ─── Audio Player ─────────────────────────────────────────────────
  final _audioPlayer = AudioPlayer();
  bool _hasAudio = false;

  // ─── Feedback Popup ───────────────────────────────────────────────
  JudgeResult? _lastJudge;
  AnimationController? _feedbackAnim;
  Animation<double>? _feedbackOpacity;
  Animation<double>? _feedbackSlide;

  @override
  void initState() {
    super.initState();

    _feedbackAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _feedbackOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _feedbackAnim!, curve: Curves.easeOut),
    );
    _feedbackSlide = Tween<double>(begin: 0.0, end: -30.0).animate(
      CurvedAnimation(parent: _feedbackAnim!, curve: Curves.easeOut),
    );

    Future.microtask(() async {
      if (!mounted) return;
      lesson = await context.read<LessonProvider>().loadLesson(widget.lessonId);
      if (!mounted) return;
      setState(() {});

      if (lesson?.audioUrl != null && lesson!.audioUrl!.isNotEmpty) {
        final url = '${ApiConfig.baseUrl}${lesson!.audioUrl}';
        try {
          await _audioPlayer.setSource(UrlSource(url));
          _hasAudio = true;
        } catch (_) {
          _hasAudio = false;
        }
      }
    });
  }

  void startCountdown() {
    setState(() {
      isCountingDown = true;
      countdownValue = 3;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (countdownValue > 1) {
        setState(() => countdownValue--);
      } else {
        timer.cancel();
        setState(() => isCountingDown = false);
        startPractice();
      }
    });
  }

  // ─── Bắt đầu luyện tập ───────────────────────────────────────────
  void startPractice() {
    setState(() {
      isPlaying = true;
      isFinished = false;
      _elapsedNotifier.value = -1.5; // Offset để nốt đầu tiên chạy xa hơn
      durationSeconds = 0;
      currentNoteIndex = 0;
      score = 0;
      correct = 0;
      wrong = 0;
      attempts.clear();
      judgeHistory.clear();
    });

    bool audioStarted = false;

    // Dùng chung Ticker 60fps cho cả chế độ có Audio và không có Audio để Timeline mượt tuyệt đối
    _ticker = createTicker((elapsed) {
      if (!mounted || !isPlaying) return;
      
      // Kéo timeline lùi về -1.5s
      double t = (elapsed.inMicroseconds / 1000000.0) - 1.5;
      _elapsedNotifier.value = t;
      
      if (t < 0) {
        durationSeconds = 0;
      } else {
        durationSeconds = t.floor();
        
        // Bắt đầu nhạc khi thời gian đạt mốc 0.0
        if (_hasAudio && !audioStarted) {
          _audioPlayer.resume();
          audioStarted = true;
        }

        _checkAutoMiss();
        _checkFinish();
      }
    });
    _ticker?.start();
  }

  // ─── Auto-MISS khi quá cửa sổ ±500ms ─────────────────────────────
  void _checkAutoMiss() {
    final l = lesson;
    if (l == null || currentNoteIndex >= l.notes.length) return;

    final expected = l.notes[currentNoteIndex];
    final deadline = expected.second + (kPracticeTimingWindowMs / 1000.0);
    final elapsed = _elapsedNotifier.value;

    if (elapsed > deadline) {
      _recordResult(
        noteIndex: currentNoteIndex,
        expected: expected,
        playedNote: '',
        result: JudgeResult.miss,
        timingErrorMs: (elapsed - expected.second) * 1000,
        advance: true,
      );
    }
  }

  void _checkFinish() {
    final l = lesson;
    if (l != null && currentNoteIndex >= l.notes.length) {
      _endPractice();
    }
  }

  // ─── Học sinh bấm phím đàn ────────────────────────────────────────
  void press(String playedNote) {
    if (!isPlaying) return;
    final l = lesson;
    if (l == null || currentNoteIndex >= l.notes.length) return;

    final expected = l.notes[currentNoteIndex];
    final elapsed = _elapsedNotifier.value;
    final timingErrorMs = (elapsed - expected.second).abs() * 1000;

    // Chỉ chấp nhận khi đang trong cửa sổ thời gian
    if (timingErrorMs > kPracticeTimingWindowMs) return;

    final result = judge(
      expectedNote: expected.note,
      playedNote: playedNote,
      expectedSecond: expected.second,
      playedSecond: elapsed,
      timingWindowMs: kPracticeTimingWindowMs,
    );

    final shouldAdvance = result.isPositive; // Chỉ tiến nốt khi đúng
    _recordResult(
      noteIndex: currentNoteIndex,
      expected: expected,
      playedNote: playedNote,
      result: result,
      timingErrorMs: timingErrorMs,
      advance: shouldAdvance,
    );
  }

  void _recordResult({
    required int noteIndex,
    required dynamic expected,
    required String playedNote,
    required JudgeResult result,
    required double timingErrorMs,
    required bool advance,
  }) {
    attempts.add(NoteAttemptRequest(
      lessonNoteId: expected.id ?? 0,
      playedNote: playedNote,
      playedSecond: _elapsedNotifier.value,
      judgeResult: result.label,
      timingErrorMs: timingErrorMs,
    ));

    setState(() {
      judgeHistory[noteIndex] = result.label;
      score = (score + result.score).clamp(0, 99999);
      if (result.isPositive) {
        correct++;
      } else {
        wrong++;
      }
      if (advance) currentNoteIndex++;
    });

    _showFeedback(result);
  }

  void _showFeedback(JudgeResult result) {
    setState(() => _lastJudge = result);
    _feedbackAnim?.reset();
    _feedbackAnim?.forward();
  }

  // ─── Kết thúc ────────────────────────────────────────────────────
  void _endPractice() {
    _ticker?.stop();
    _countdownTimer?.cancel();
    _audioPlayer.stop();
    setState(() {
      isPlaying = false;
      isFinished = true;
    });
    _submitResult();
  }

  Future<void> _submitResult() async {
    final result = await context.read<StudentProvider>().submitPractice(
      widget.lessonId,
      attempts,
      isExam: false,
      durationSeconds: durationSeconds,
    );
    if (!mounted || result == null) return;
    _showResultDialog(result);
  }

  void _showResultDialog(dynamic result) {
    final maxScore = (lesson?.notes.length ?? 1) * 10;
    final pct = maxScore == 0 ? 0 : (score / maxScore * 100).round();

    String grade;
    Color gradeColor;
    if (pct >= 90) { grade = '⭐ Xuất sắc!'; gradeColor = Colors.amber; }
    else if (pct >= 70) { grade = '👍 Tốt!'; gradeColor = Colors.greenAccent; }
    else if (pct >= 50) { grade = '📖 Khá'; gradeColor = Colors.blueAccent; }
    else { grade = '💪 Cần luyện thêm'; gradeColor = Colors.orange; }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A2433),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(grade, style: TextStyle(color: gradeColor, fontWeight: FontWeight.bold, fontSize: 22)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$score / $maxScore điểm',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statChip('✅ Đúng', correct.toString(), Colors.greenAccent),
                _statChip('❌ Sai', wrong.toString(), Colors.redAccent),
                _statChip('⏱ Thời gian', '${durationSeconds}s', Colors.blueAccent),
              ],
            ),
            const SizedBox(height: 8),
            Text('Độ chính xác: ${result.accuracy.toStringAsFixed(1)}%',
                style: const TextStyle(color: Colors.white54, fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); startPractice(); },
            child: const Text('Thử lại', style: TextStyle(color: Colors.blueAccent)),
          ),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); context.pop(); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text('Hoàn thành'),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _countdownTimer?.cancel();
    _audioPlayer.dispose();
    _feedbackAnim?.dispose();
    _elapsedNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = lesson;
    final maxScore = (l?.notes.length ?? 1) * 10;
    final currentNote = (l == null || currentNoteIndex >= l.notes.length)
        ? null
        : l.notes[currentNoteIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        foregroundColor: Colors.white,
        title: Text(l?.title ?? 'Luyện tập',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: isPlaying && l != null
              ? LinearProgressIndicator(
                  value: l.notes.isEmpty ? 0 : currentNoteIndex / l.notes.length,
                  backgroundColor: const Color(0xFF30363D),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00BCD4)),
                  minHeight: 4,
                )
              : const SizedBox(height: 4),
        ),
      ),
      body: l == null
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4)))
          : Stack(
              children: [
                Column(
                  children: [
                    // ─── Score + Timer Bar ───────────────────────────
                    _buildScoreBar(maxScore),

                    // ─── Nốt cần bấm (chỉ hiện khi đang chơi) ───────────────────
                    if (isPlaying) _buildCurrentNoteHint(currentNote),

                    // ─── RhythmTimeline & Overlays ───────────────────
                    Expanded(
                      child: Stack(
                        children: [
                          // Luôn hiện RhythmTimeline để xem trước bản nhạc
                          RhythmTimeline(
                            notes: l.notes,
                            elapsedNotifier: _elapsedNotifier,
                            currentNoteIndex: currentNoteIndex,
                            judgeHistory: judgeHistory,
                          ),

                          // Overlay Start / Countdown
                          if (!isPlaying && !isFinished)
                            _buildStartOverlay(l, maxScore),
                        ],
                      ),
                    ),

                    // Piano Keyboard luôn hiện để load âm thanh sớm
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: PianoKeyboard(
                          onPressed: press,
                          targetNote: isPlaying ? currentNote?.note : null,
                        ),
                      ),
                    ),
                  ],
                ),

                // ─── Feedback Popup Overlay ──────────────────────────
                if (_lastJudge != null &&
                    _feedbackOpacity != null &&
                    _feedbackSlide != null)
                  Positioned(
                    top: 80,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _feedbackAnim!,
                        builder: (_, child) => Opacity(
                          opacity: _feedbackOpacity!.value,
                          child: Transform.translate(
                            offset: Offset(0, _feedbackSlide!.value),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 28, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Color(_lastJudge!.colorValue)
                                      .withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(_lastJudge!.colorValue)
                                          .withValues(alpha: 0.4),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    )
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _lastJudge!.label,
                                      style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      _lastJudge!.score >= 0
                                          ? '+${_lastJudge!.score}'
                                          : '${_lastJudge!.score}',
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildScoreBar(int maxScore) {
    return Container(
      color: const Color(0xFF161B22),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Đồng hồ thời gian (Chỉ build lại text này khi thời gian đổi, ko build cả thanh)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF30363D)),
            ),
            child: Row(children: [
              const Icon(Icons.timer, color: Color(0xFF00BCD4), size: 16),
              const SizedBox(width: 4),
              ValueListenableBuilder<double>(
                valueListenable: _elapsedNotifier,
                builder: (context, elapsed, _) {
                  return Text(
                    _formatTime(elapsed),
                    style: const TextStyle(
                      color: Color(0xFF80DEEA),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'monospace',
                    ),
                  );
                },
              ),
            ]),
          ),
          const SizedBox(width: 12),

          // Đúng/Sai
          Row(children: [
            const Icon(Icons.check_circle, color: Colors.greenAccent, size: 18),
            const SizedBox(width: 3),
            Text('$correct',
                style: const TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(width: 10),
            const Icon(Icons.cancel, color: Colors.redAccent, size: 18),
            const SizedBox(width: 3),
            Text('$wrong',
                style: const TextStyle(color: Colors.white, fontSize: 16)),
          ]),

          const Spacer(),

          // Điểm số
          Text(
            '🎵 $score',
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentNoteHint(dynamic currentNote) {
    return Container(
      color: const Color(0xFF0F2232),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.music_note, color: Color(0xFF00BCD4), size: 18),
          const SizedBox(width: 8),
          if (currentNote != null) ...[
            const Text(
              'Bấm nốt: ',
              style: TextStyle(color: Colors.white54, fontSize: 15),
            ),
            Text(
              '${currentNote.note} (${currentNote.lyric})',
              style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
          ] else
            const Text('Hoàn thành!',
                style: TextStyle(color: Colors.greenAccent, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildStartOverlay(MusicLesson l, int maxScore) {
    final isSmallScreen = MediaQuery.of(context).size.height < 500;
    return Container(
      color: Colors.black.withOpacity(0.65), // Mờ đi để thấy bản nhạc
      alignment: Alignment.center,
      child: isCountingDown
          ? Text(
              '$countdownValue',
              style: TextStyle(
                color: const Color(0xFF00BCD4),
                fontSize: isSmallScreen ? 80 : 120,
                fontWeight: FontWeight.bold,
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Luôn hiện Title
                    Text(l.title,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 20 : 22,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(
                      '${l.notes.length} nốt nhạc  ·  Điểm tối đa: $maxScore',
                      style: TextStyle(color: Colors.white54, fontSize: isSmallScreen ? 13 : 14),
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    
                    if (!isSmallScreen) ...[
                      // Hướng dẫn hiển thị trực tiếp trên màn hình lớn
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B22),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF30363D)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Cách chơi:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            const _HintRow(icon: '━━', color: Color(0xFF00E5FF), text: 'Vạch xanh = vị trí cần bấm'),
                            const _HintRow(icon: '⬛', color: Color(0xFF2979FF), text: 'Ô màu xanh = nốt sắp tới'),
                            const _HintRow(icon: '🟠', color: Colors.orange, text: 'Ô cam = bấm ngay bây giờ!'),
                            const _HintRow(icon: '✅', color: Colors.greenAccent, text: 'PERFECT < 100ms · GOOD < 200ms'),
                            const _HintRow(icon: '⚠', color: Colors.amber, text: 'LATE < 500ms · WRONG = sai nốt'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: l.notes.isEmpty ? null : startCountdown,
                          icon: Icon(Icons.play_circle_fill, size: isSmallScreen ? 24 : 28),
                          label: Text('BẮT ĐẦU LUYỆN TẬP',
                              style: TextStyle(fontSize: isSmallScreen ? 15 : 17, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0288D1),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 24 : 40, vertical: isSmallScreen ? 12 : 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                        ),
                        if (isSmallScreen) ...[
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: () => _showRulesDialog(context),
                            icon: const Icon(Icons.help_outline, color: Colors.white70, size: 28),
                            tooltip: 'Hướng dẫn cách chơi',
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFF161B22),
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (!_hasAudio)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                            '⚠ Chưa có nhạc nền, sẽ chạy theo timer tự động.',
                            style: TextStyle(color: Colors.orange, fontSize: 13),
                            textAlign: TextAlign.center),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  void _showRulesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('Cách chơi', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _HintRow(icon: '━━', color: Color(0xFF00E5FF), text: 'Vạch xanh = vị trí cần bấm'),
            _HintRow(icon: '⬛', color: Color(0xFF2979FF), text: 'Ô màu xanh = nốt sắp tới'),
            _HintRow(icon: '🟠', color: Colors.orange, text: 'Ô cam = bấm ngay bây giờ!'),
            _HintRow(icon: '✅', color: Colors.greenAccent, text: 'PERFECT < 100ms · GOOD < 200ms'),
            _HintRow(icon: '⚠', color: Colors.amber, text: 'LATE < 500ms · WRONG = sai nốt'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng', style: TextStyle(color: Color(0xFF00BCD4))),
          ),
        ],
      ),
    );
  }

  String _formatTime(double seconds) {
    if (seconds < 0) return '00:00.0';
    final mm = (seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toStringAsFixed(1).padLeft(4, '0');
    return '$mm:$ss';
  }
}

class _HintRow extends StatelessWidget {
  final String icon;
  final Color color;
  final String text;

  const _HintRow({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(icon, style: TextStyle(color: color, fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style:
                    const TextStyle(color: Colors.white54, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
