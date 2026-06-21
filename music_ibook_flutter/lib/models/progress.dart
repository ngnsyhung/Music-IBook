class StudentProgress {
  final int id;
  final int lessonId;
  final double lastPositionSecond;
  final int completedNoteCount;
  final int bestScore;
  final int totalAttempts;
  final bool isCompleted;
  final String? lessonTitle;

  StudentProgress({
    required this.id,
    required this.lessonId,
    required this.lastPositionSecond,
    required this.completedNoteCount,
    required this.bestScore,
    required this.totalAttempts,
    required this.isCompleted,
    this.lessonTitle,
  });

  factory StudentProgress.fromJson(Map<String, dynamic> json) {
    return StudentProgress(
      id: json['id'] ?? 0,
      lessonId: json['lessonId'] ?? 0,
      lastPositionSecond: (json['lastPositionSecond'] ?? 0).toDouble(),
      completedNoteCount: json['completedNoteCount'] ?? 0,
      bestScore: json['bestScore'] ?? 0,
      totalAttempts: json['totalAttempts'] ?? 0,
      isCompleted: json['isCompleted'] ?? false,
      lessonTitle: json['lesson']?['title'],
    );
  }
}
