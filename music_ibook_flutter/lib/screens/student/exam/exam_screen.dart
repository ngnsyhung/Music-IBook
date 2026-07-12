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
import '../../../models/note_result_detail.dart';
import '../../../providers/lesson_provider.dart';
import '../../../providers/student_provider.dart';
import '../../../widgets/music_staff.dart';
import '../../../widgets/piano_keyboard.dart';

class ExamScreen extends StatefulWidget {
  final int lessonId;
  const ExamScreen({super.key, required this.lessonId});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> with TickerProviderStateMixin {
  MusicLesson? lesson;

  // ─── Game State ──────────────────────────────────────────────────
  bool isPlaying = false;
  bool isFinished = false;
  bool isCountingDown = false;
  int countdownValue = 0;
  
  int currentIndex = 0;
  int score = 0;
  int correct = 0;
  int wrong = 0;
  double get elapsedSeconds => _elapsedNotifier.value;
  int durationSeconds = 0;
  
  final attempts = <NoteAttemptRequest>[];
  final resultDetails = <NoteResultDetail>[];

  // ─── Timer & Ticker cho 60fps ───────────────────────────────────
  Timer? _countdownTimer;
  Ticker? _ticker;
  final ValueNotifier<double> _elapsedNotifier = ValueNotifier(0.0);

  // ─── Tùy chọn ────────────────────────────────────────────────────
  bool showTimeline = false;

  // ─── Audio Player ─────────────────────────────────────────────────
  final _audioPlayer = AudioPlayer();
  bool _hasAudio = false;

  // ─── Feedback Popup ───────────────────────────────────────────────
  JudgeResult? _lastJudge;
  AnimationController? _feedbackAnim;
  Animation<double>? _feedbackOpacity;

  @override
  void initState() {
    super.initState();

    _feedbackAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _feedbackOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
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
        _startActualExam();
      }
    });
  }

  void _startActualExam() {
    setState(() {
      isPlaying = true;
      isFinished = false;
      _elapsedNotifier.value = -1.5;
      durationSeconds = 0;
      currentIndex = 0;
      score = 0;
      correct = 0;
      wrong = 0;
      attempts.clear();
      resultDetails.clear();
    });

    bool audioStarted = false;

    _ticker = createTicker((elapsed) {
      if (!mounted || !isPlaying) return;
      
      double t = (elapsed.inMicroseconds / 1000000.0) - 1.5;
      _elapsedNotifier.value = t;
      
      if (t < 0) {
        durationSeconds = 0;
      } else {
        durationSeconds = t.floor();
        
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

  // Exam timing window chặt hơn: ±300ms
  void _checkAutoMiss() {
    final l = lesson;
    if (l == null || currentIndex >= l.notes.length) return;
    final expected = l.notes[currentIndex];
    final deadline = expected.second + (kExamTimingWindowMs / 1000.0);
    if (elapsedSeconds > deadline) {
      _recordResult(expected, '', JudgeResult.miss, (elapsedSeconds - expected.second).abs() * 1000);
    }
  }

  void press(String playedNote) {
    if (!isPlaying) return;
    final l = lesson;
    if (l == null || currentIndex >= l.notes.length) return;

    final expected = l.notes[currentIndex];
    final timingErrorMs = (elapsedSeconds - expected.second).abs() * 1000;

    // Exam: chỉ chấp nhận trong ±300ms
    if (timingErrorMs > kExamTimingWindowMs) return;

    final result = judge(
      expectedNote: expected.note,
      playedNote: playedNote,
      expectedSecond: expected.second,
      playedSecond: elapsedSeconds,
      timingWindowMs: kExamTimingWindowMs,
    );

    _recordResult(expected, playedNote, result, timingErrorMs);
  }

  void _recordResult(dynamic expected, String playedNote, JudgeResult result, double timingErrorMs) {
    attempts.add(NoteAttemptRequest(
      lessonNoteId: expected.id ?? 0,
      playedNote: playedNote,
      playedSecond: elapsedSeconds,
      judgeResult: result.label,
      timingErrorMs: timingErrorMs,
    ));

    resultDetails.add(NoteResultDetail(
      noteIndex: currentIndex,
      expectedNote: expected.note,
      playedNote: playedNote.isEmpty ? '-' : playedNote,
      lyric: expected.lyric,
      expectedSecond: expected.second,
      playedSecond: elapsedSeconds,
      timingErrorMs: timingErrorMs,
      judgeResult: result.label,
    ));

    setState(() {
      score = (score + result.score).clamp(0, 99999);
      if (result.isPositive) { correct++; }
      else { wrong++; }
      // Exam: luôn tiến nốt kể cả sai (không cho bấm lại)
      currentIndex++;
    });

    _showFeedback(result);
  }

  void _showFeedback(JudgeResult result) {
    setState(() => _lastJudge = result);
    _feedbackAnim?.reset();
    _feedbackAnim?.forward();
  }

  void _checkFinish() {
    final l = lesson;
    if (l != null && currentIndex >= l.notes.length) {
      _endExam();
    }
  }

  void _endExam() {
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
      isExam: true,
      durationSeconds: durationSeconds,
    );
    if (!mounted || result == null) return;
    _showResultBottomSheet(result);
  }

  void _showResultBottomSheet(dynamic result) {
    final maxScore = (lesson?.notes.length ?? 1) * 10;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => _ResultSheet(
        score: result.score,
        maxScore: maxScore,
        accuracy: result.accuracy,
        correct: correct,
        wrong: wrong,
        durationSeconds: durationSeconds,
        details: resultDetails,
        onClose: () {
          Navigator.pop(context);
          context.pop();
        },
      ),
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
    final isSmallScreen = MediaQuery.of(context).size.height < 500;

    return Scaffold(
      backgroundColor: const Color(0xFF1A0010),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D0015),
        foregroundColor: Colors.white,
        title: Text(l?.title ?? 'Kiểm tra', style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (isPlaying)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '⏱ ${durationSeconds}s',
                  style: const TextStyle(fontSize: 18, color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      body: l == null
          ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
          : Stack(
              children: [
                Column(
                  children: [
                    // ─── Score Bar ─────────────────────────────────
                    Container(
                      color: const Color(0xFF3D0015),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [
                            const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                            const SizedBox(width: 4),
                            Text('$correct', style: const TextStyle(color: Colors.white, fontSize: 18)),
                            const SizedBox(width: 16),
                            const Icon(Icons.cancel, color: Colors.redAccent, size: 20),
                            const SizedBox(width: 4),
                            Text('$wrong', style: const TextStyle(color: Colors.white, fontSize: 18)),
                          ]),
                          Text(
                            '🎯 $score / $maxScore',
                            style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                        ],
                      ),
                    ),

                    // ─── Result Strip (Realtime) ───────────────────
                    if (isPlaying)
                      Container(
                        height: 32,
                        width: double.infinity,
                        color: const Color(0xFF110006),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          itemCount: l.notes.length,
                          itemBuilder: (context, index) {
                            if (index < resultDetails.length) {
                              final res = resultDetails[index].judgeResult;
                              return _buildStripBox(res, _getColorForJudge(res));
                            }
                            // Nốt chưa tới
                            return _buildStripBox('?', Colors.white24);
                          },
                        ),
                      ),

                    // ─── Start / Countdown Screen ───────────────────
                    if (!isPlaying && !isFinished)
                      Expanded(
                        child: Center(
                          child: isCountingDown
                              ? Text(
                                  '$countdownValue',
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: isSmallScreen ? 80 : 120,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : SingleChildScrollView(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                    Icon(Icons.warning_amber_rounded, size: isSmallScreen ? 48 : 60, color: Colors.redAccent),
                                    SizedBox(height: isSmallScreen ? 8 : 16),
                                    Text(l.title, style: TextStyle(color: Colors.white, fontSize: isSmallScreen ? 18 : 22, fontWeight: FontWeight.bold)),
                                    SizedBox(height: isSmallScreen ? 4 : 8),
                                    Text(
                                      'Chế độ kiểm tra:\n• Không có gợi ý màu nốt\n• Cửa sổ thời gian chặt ±300ms\n• Bấm sai tự động chuyển nốt tiếp',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.white54, fontSize: isSmallScreen ? 12 : 14, height: 1.8),
                                    ),
                                    SizedBox(height: isSmallScreen ? 8 : 16),
                                    CheckboxListTile(
                                      value: showTimeline,
                                      onChanged: (val) {
                                        setState(() => showTimeline = val ?? false);
                                      },
                                      title: Text('Hiển thị thanh nhịp độ', style: TextStyle(color: Colors.white70, fontSize: isSmallScreen ? 13 : 15)),
                                      controlAffinity: ListTileControlAffinity.leading,
                                      activeColor: Colors.redAccent,
                                      checkColor: Colors.white,
                                      contentPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 40),
                                      visualDensity: isSmallScreen ? VisualDensity.compact : VisualDensity.standard,
                                    ),
                                    SizedBox(height: isSmallScreen ? 8 : 16),
                                    ElevatedButton.icon(
                                      onPressed: startCountdown,
                                      icon: Icon(Icons.play_circle_fill, size: isSmallScreen ? 24 : 32),
                                      label: Text('BẮT ĐẦU KIỂM TRA', style: TextStyle(fontSize: isSmallScreen ? 15 : 18, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 24 : 40, vertical: isSmallScreen ? 12 : 18),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        ),
                      ),

                    if (isPlaying) ...[
                      Expanded(
                        child: MusicStaff(
                          lesson: l,
                          elapsedNotifier: _elapsedNotifier,
                          showTimeline: showTimeline,
                        ),
                      ),
                    ],
                    
                    // Piano Keyboard luôn hiện để load âm thanh sớm
                    // Không truyền targetNote → không hint màu nốt
                    PianoKeyboard(onPressed: press),
                  ],
                ),

                // ─── Feedback Popup Overlay ─────────────────────────
                if (_lastJudge != null && _feedbackOpacity != null)
                  Positioned(
                    top: 100,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _feedbackOpacity!,
                        builder: (_, child) => Opacity(
                          opacity: _feedbackOpacity!.value,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                              decoration: BoxDecoration(
                                color: Color(_lastJudge!.colorValue).withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _lastJudge!.label,
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _lastJudge!.score >= 0 ? '+${_lastJudge!.score}' : '${_lastJudge!.score}',
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
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

  Widget _buildStripBox(String label, Color color) {
    return Container(
      width: 20,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          label.substring(0, 1), // Chỉ lấy chữ cái đầu P/G/L/W/M
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Color _getColorForJudge(String label) {
    switch (label) {
      case 'PERFECT': return Colors.cyanAccent;
      case 'GOOD': return Colors.greenAccent;
      case 'LATE': return Colors.amber;
      case 'WRONG': return Colors.redAccent;
      case 'MISS': return Colors.grey;
      default: return Colors.white;
    }
  }
}

// ─── Result Bottom Sheet ──────────────────────────────────────────

class _ResultSheet extends StatelessWidget {
  final int score;
  final int maxScore;
  final double accuracy;
  final int correct;
  final int wrong;
  final int durationSeconds;
  final List<NoteResultDetail> details;
  final VoidCallback onClose;

  const _ResultSheet({
    required this.score,
    required this.maxScore,
    required this.accuracy,
    required this.correct,
    required this.wrong,
    required this.durationSeconds,
    required this.details,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    String grade;
    Color gradeColor;
    if (score >= maxScore * 0.9) { grade = 'Xuất sắc'; gradeColor = Colors.amber; }
    else if (score >= maxScore * 0.7) { grade = 'Tốt'; gradeColor = Colors.greenAccent; }
    else if (score >= maxScore * 0.5) { grade = 'Khá'; gradeColor = Colors.blueAccent; }
    else { grade = 'Cần luyện thêm'; gradeColor = Colors.redAccent; }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Báo Cáo Kiểm Tra', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
            
            const TabBar(
              indicatorColor: Colors.redAccent,
              labelColor: Colors.redAccent,
              unselectedLabelColor: Colors.white54,
              tabs: [
                Tab(text: 'Tổng Quan', icon: Icon(Icons.pie_chart)),
                Tab(text: 'Chi Tiết Lỗi', icon: Icon(Icons.list_alt)),
              ],
            ),

            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Tổng quan
                  _buildOverview(grade, gradeColor),
                  
                  // Tab 2: Chi tiết nốt
                  _buildDetailsList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview(String grade, Color gradeColor) {
    int p = 0, g = 0, l = 0, w = 0, m = 0;
    for (final d in details) {
      if (d.judgeResult == 'PERFECT') { p++; }
      else if (d.judgeResult == 'GOOD') { g++; }
      else if (d.judgeResult == 'LATE') { l++; }
      else if (d.judgeResult == 'WRONG') { w++; }
      else if (d.judgeResult == 'MISS') { m++; }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(grade, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: gradeColor)),
          const SizedBox(height: 8),
          Text('$score / $maxScore', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
          const Text('Điểm', style: TextStyle(color: Colors.white54, fontSize: 16)),
          
          const SizedBox(height: 32),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStat('Độ chính xác', '${accuracy.toStringAsFixed(1)}%', Colors.cyanAccent),
              _buildStat('Thời gian', '${durationSeconds}s', Colors.white),
              _buildStat('Đúng/Sai', '$correct / $wrong', Colors.amber),
            ],
          ),

          const SizedBox(height: 32),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          const Text('Thống kê phản xạ', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          _buildBarRow('PERFECT', p, Colors.cyanAccent),
          _buildBarRow('GOOD', g, Colors.greenAccent),
          _buildBarRow('LATE', l, Colors.amber),
          _buildBarRow('WRONG', w, Colors.redAccent),
          _buildBarRow('MISS', m, Colors.grey),
          
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onClose,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: const EdgeInsets.all(16)),
              child: const Text('Hoàn thành', style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget _buildBarRow(String label, int count, Color color) {
    final maxCount = details.isEmpty ? 1 : details.length;
    final pct = count / maxCount;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(width: 30, child: Text('$count', style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  Widget _buildDetailsList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: details.length,
      separatorBuilder: (context, i) => const Divider(color: Colors.white10),
      itemBuilder: (context, index) {
        final d = details[index];
        Color c;
        if (d.judgeResult == 'PERFECT') { c = Colors.cyanAccent; }
        else if (d.judgeResult == 'GOOD') { c = Colors.greenAccent; }
        else if (d.judgeResult == 'LATE') { c = Colors.amber; }
        else if (d.judgeResult == 'WRONG') { c = Colors.redAccent; }
        else { c = Colors.grey; }

        final errText = d.judgeResult == 'MISS' 
            ? 'Bỏ qua nốt' 
            : '${d.timingErrorMs.toStringAsFixed(0)}ms';

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: c.withValues(alpha: 0.2),
            child: Text('${index + 1}', style: TextStyle(color: c)),
          ),
          title: Row(
            children: [
              Text('Nốt chuẩn: ', style: const TextStyle(color: Colors.white54, fontSize: 13)),
              Text('${d.expectedNote} ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              if (d.playedNote != '-') ...[
                const Icon(Icons.arrow_forward, color: Colors.white54, size: 14),
                Text(' Bấm: ', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                Text(d.playedNote, style: TextStyle(color: d.expectedNote == d.playedNote ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold)),
              ]
            ],
          ),
          subtitle: Text('Độ trễ: $errText', style: const TextStyle(color: Colors.white54)),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: c.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
            child: Text(d.judgeResult, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        );
      },
    );
  }
}
