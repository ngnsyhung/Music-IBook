import 'package:music_ibook_flutter/models/lesson_note.dart';

class StudentNoteAttempt {
  final int id;
  final int practiceSessionId;
  final int lessonNoteId;
  final String expectedNote;
  final String playedNote;
  final double expectedAtSecond;
  final double playedAtSecond;
  final double timingErrorMs;
  final bool isCorrectPitch;
  final bool isCorrectTiming;
  final bool isCorrect;
  final String createdAtUtc;
  final LessonNote? lessonNote;

  StudentNoteAttempt({
    required this.id,
    required this.practiceSessionId,
    required this.lessonNoteId,
    required this.expectedNote,
    required this.playedNote,
    required this.expectedAtSecond,
    required this.playedAtSecond,
    required this.timingErrorMs,
    required this.isCorrectPitch,
    required this.isCorrectTiming,
    required this.isCorrect,
    required this.createdAtUtc,
    this.lessonNote,
  });

  factory StudentNoteAttempt.fromJson(Map<String, dynamic> json) {
    return StudentNoteAttempt(
      id: json['id'] ?? 0,
      practiceSessionId: json['practiceSessionId'] ?? 0,
      lessonNoteId: json['lessonNoteId'] ?? 0,
      expectedNote: json['expectedNote'] ?? '',
      playedNote: json['playedNote'] ?? '',
      expectedAtSecond: (json['expectedAtSecond'] ?? 0).toDouble(),
      playedAtSecond: (json['playedAtSecond'] ?? 0).toDouble(),
      timingErrorMs: (json['timingErrorMs'] ?? 0).toDouble(),
      isCorrectPitch: json['isCorrectPitch'] ?? false,
      isCorrectTiming: json['isCorrectTiming'] ?? false,
      isCorrect: json['isCorrect'] ?? false,
      createdAtUtc: json['createdAtUtc'] ?? '',
      lessonNote: json['lessonNote'] != null
          ? LessonNote.fromJson(json['lessonNote'])
          : null,
    );
  }
}
