import 'student_note_attempt.dart';

class NoteAttemptRequest {
  final int lessonNoteId;
  final String playedNote;
  final double playedSecond;

  NoteAttemptRequest({
    required this.lessonNoteId,
    required this.playedNote,
    required this.playedSecond,
  });

  Map<String, dynamic> toJson() => {
    'lessonNoteId': lessonNoteId,
    'playedNote': playedNote,
    'playedAtSecond': playedSecond,
  };
}

class PracticeSession {
  final int id;
  final int lessonId;
  final bool isExam;
  final int score;
  final int correctCount;
  final int wrongCount;
  final double accuracy;
  final int durationSeconds;
  final String? lessonTitle;
  final String? startedAtUtc;
  final List<StudentNoteAttempt> noteAttempts;

  PracticeSession({
    required this.id,
    required this.lessonId,
    required this.isExam,
    required this.score,
    required this.correctCount,
    required this.wrongCount,
    required this.accuracy,
    required this.durationSeconds,
    this.lessonTitle,
    this.startedAtUtc,
    this.noteAttempts = const [],
  });

  factory PracticeSession.fromJson(Map<String, dynamic> json) {
    var list = json['noteAttempts'] as List? ?? [];
    return PracticeSession(
      id: json['id'] ?? 0,
      lessonId: json['lessonId'] ?? 0,
      isExam: json['isExam'] ?? false,
      score: json['score'] ?? 0,
      correctCount: json['correctCount'] ?? 0,
      wrongCount: json['wrongCount'] ?? 0,
      accuracy: (json['accuracy'] ?? 0).toDouble(),
      durationSeconds: json['durationSeconds'] ?? 0,
      lessonTitle: json['lesson']?['title'],
      startedAtUtc: json['startedAtUtc'] ?? json['createdAtUtc'],
      noteAttempts: list.map((e) => StudentNoteAttempt.fromJson(e)).toList(),
    );
  }
}
