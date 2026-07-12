/// Judge Engine - Hệ thống chấm điểm cho Practice và Exam Mode
/// Dùng chung cho cả [PracticeScreen] và [ExamScreen]

// ─── Timing Windows ───────────────────────────────────────────────
const double kPracticeTimingWindowMs = 500.0; // ±500ms cho Practice
const double kExamTimingWindowMs = 300.0;      // ±300ms cho Exam

// Ngưỡng phán xét (tính từ 0ms)
const double kPerfectMs = 100.0;
const double kGoodMs = 200.0;
// LATE nằm trong [kGoodMs, timingWindow]

// ─── Điểm số ──────────────────────────────────────────────────────
const int kScorePerfect = 10;
const int kScoreGood = 8;
const int kScoreLate = 5;
const int kScoreWrong = -5;
const int kScoreMiss = -10;

// ─── Judge Result enum ─────────────────────────────────────────────
enum JudgeResult { perfect, good, late, wrong, miss }

extension JudgeResultX on JudgeResult {
  String get label {
    switch (this) {
      case JudgeResult.perfect: return 'PERFECT';
      case JudgeResult.good:    return 'GOOD';
      case JudgeResult.late:    return 'LATE';
      case JudgeResult.wrong:   return 'WRONG';
      case JudgeResult.miss:    return 'MISS';
    }
  }

  int get score {
    switch (this) {
      case JudgeResult.perfect: return kScorePerfect;
      case JudgeResult.good:    return kScoreGood;
      case JudgeResult.late:    return kScoreLate;
      case JudgeResult.wrong:   return kScoreWrong;
      case JudgeResult.miss:    return kScoreMiss;
    }
  }

  bool get isPositive => this == JudgeResult.perfect || this == JudgeResult.good || this == JudgeResult.late;

  /// Màu hiển thị popup feedback
  int get colorValue {
    switch (this) {
      case JudgeResult.perfect: return 0xFF00E5FF; // Cyan
      case JudgeResult.good:    return 0xFF76FF03; // Green
      case JudgeResult.late:    return 0xFFFFD600; // Yellow
      case JudgeResult.wrong:   return 0xFFFF1744; // Red
      case JudgeResult.miss:    return 0xFF9E9E9E; // Grey
    }
  }
}

// ─── Hàm phán xét chính ───────────────────────────────────────────

/// Phán xét kết quả bấm phím.
/// [expectedNote]   : Nốt nhạc đúng cần bấm (vd: "C4")
/// [playedNote]     : Nốt nhạc học sinh đã bấm
/// [expectedSecond] : Thời điểm cần bấm (giây trên timeline)
/// [playedSecond]   : Thời điểm học sinh thực sự bấm
/// [timingWindowMs] : Cửa sổ chấp nhận (ms), mặc định 500ms
JudgeResult judge({
  required String expectedNote,
  required String playedNote,
  required double expectedSecond,
  required double playedSecond,
  double timingWindowMs = kPracticeTimingWindowMs,
}) {
  final timingErrorMs = (playedSecond - expectedSecond).abs() * 1000;

  if (playedNote != expectedNote) return JudgeResult.wrong;
  if (timingErrorMs < kPerfectMs) return JudgeResult.perfect;
  if (timingErrorMs < kGoodMs) return JudgeResult.good;
  if (timingErrorMs < timingWindowMs) return JudgeResult.late;
  return JudgeResult.wrong; // Bấm đúng nốt nhưng quá chậm → cũng tính wrong
}
