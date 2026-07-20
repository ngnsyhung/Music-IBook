import '../core/api_client.dart';
import '../utils/vietnam_time.dart';

class TeacherDashboardData {
  final int totalLessons;
  final int totalStudents;
  final int totalPracticeSessions;
  final int totalExamSessions;
  final double averageSystemScore;

  TeacherDashboardData({
    required this.totalLessons,
    required this.totalStudents,
    required this.totalPracticeSessions,
    required this.totalExamSessions,
    required this.averageSystemScore,
  });

  factory TeacherDashboardData.fromJson(Map<String, dynamic> json) {
    return TeacherDashboardData(
      totalLessons: json['totalLessons'] ?? 0,
      totalStudents: json['totalStudents'] ?? 0,
      totalPracticeSessions: json['totalPracticeSessions'] ?? 0,
      totalExamSessions: json['totalExamSessions'] ?? 0,
      averageSystemScore: (json['averageSystemScore'] ?? 0).toDouble(),
    );
  }
}

class StudentProgressOverview {
  final int studentId;
  final String studentName;
  final String email;
  final int lessonCount;
  final int examCount;
  final double averageScore;
  final DateTime? lastActivityAt;

  StudentProgressOverview({
    required this.studentId,
    required this.studentName,
    required this.email,
    required this.lessonCount,
    required this.examCount,
    required this.averageScore,
    this.lastActivityAt,
  });

  factory StudentProgressOverview.fromJson(Map<String, dynamic> json) {
    return StudentProgressOverview(
      studentId: json['studentId'] ?? 0,
      studentName: json['studentName'] ?? '',
      email: json['email'] ?? '',
      lessonCount: json['lessonCount'] ?? 0,
      examCount: json['examCount'] ?? 0,
      averageScore: (json['averageScore'] ?? 0).toDouble(),
      lastActivityAt: VietnamTime.parseUtc(json['lastActivityAt']),
    );
  }
}

class LessonProgressDetail {
  final int lessonId;
  final String lessonName;
  final DateTime? lastPracticeAt;
  final DateTime? lastExamAt;
  final int highestScore;
  final double averageScore;
  final double accuracy;

  LessonProgressDetail({
    required this.lessonId,
    required this.lessonName,
    this.lastPracticeAt,
    this.lastExamAt,
    required this.highestScore,
    required this.averageScore,
    required this.accuracy,
  });

  factory LessonProgressDetail.fromJson(Map<String, dynamic> json) {
    return LessonProgressDetail(
      lessonId: json['lessonId'] ?? 0,
      lessonName: json['lessonName'] ?? '',
      lastPracticeAt: VietnamTime.parseUtc(json['lastPracticeAt']),
      lastExamAt: VietnamTime.parseUtc(json['lastExamAt']),
      highestScore: json['highestScore'] ?? 0,
      averageScore: (json['averageScore'] ?? 0).toDouble(),
      accuracy: (json['accuracy'] ?? 0).toDouble(),
    );
  }
}

class StudentDetailProgress {
  final int studentId;
  final String studentName;
  final List<LessonProgressDetail> lessons;

  StudentDetailProgress({
    required this.studentId,
    required this.studentName,
    required this.lessons,
  });

  factory StudentDetailProgress.fromJson(Map<String, dynamic> json) {
    var list = json['lessons'] as List? ?? [];
    return StudentDetailProgress(
      studentId: json['studentId'] ?? 0,
      studentName: json['studentName'] ?? '',
      lessons: list.map((e) => LessonProgressDetail.fromJson(e)).toList(),
    );
  }
}

class PracticeSessionTrend {
  final int sessionId;
  final bool isExam;
  final int score;
  final double accuracy;
  final int correctCount;
  final int wrongCount;
  final DateTime startedAt;

  PracticeSessionTrend({
    required this.sessionId,
    required this.isExam,
    required this.score,
    required this.accuracy,
    required this.correctCount,
    required this.wrongCount,
    required this.startedAt,
  });

  factory PracticeSessionTrend.fromJson(Map<String, dynamic> json) =>
      PracticeSessionTrend(
        sessionId: json['sessionId'] ?? 0,
        isExam: json['isExam'] ?? false,
        score: json['score'] ?? 0,
        accuracy: (json['accuracy'] ?? 0).toDouble(),
        correctCount: json['correctCount'] ?? 0,
        wrongCount: json['wrongCount'] ?? 0,
        startedAt:
            VietnamTime.parseUtc(json['startedAtUtc']) ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}

class NoteErrorSummary {
  final String note;
  final int errorCount;
  final int wrongPitchCount;
  final int timingErrorCount;

  NoteErrorSummary({
    required this.note,
    required this.errorCount,
    required this.wrongPitchCount,
    required this.timingErrorCount,
  });

  factory NoteErrorSummary.fromJson(Map<String, dynamic> json) =>
      NoteErrorSummary(
        note: json['note'] ?? '',
        errorCount: json['errorCount'] ?? 0,
        wrongPitchCount: json['wrongPitchCount'] ?? 0,
        timingErrorCount: json['timingErrorCount'] ?? 0,
      );
}

class StudentAssignment {
  final int id;
  final int? lessonSectionId;
  final int? lessonExerciseId;
  final String? sectionTitle;
  final String? exerciseTitle;
  final String message;
  final DateTime? dueAt;
  final DateTime createdAt;
  final bool isCompleted;

  StudentAssignment({
    required this.id,
    this.lessonSectionId,
    this.lessonExerciseId,
    this.sectionTitle,
    this.exerciseTitle,
    required this.message,
    this.dueAt,
    required this.createdAt,
    required this.isCompleted,
  });

  factory StudentAssignment.fromJson(Map<String, dynamic> json) =>
      StudentAssignment(
        id: json['id'] ?? 0,
        lessonSectionId: json['lessonSectionId'],
        lessonExerciseId: json['lessonExerciseId'],
        sectionTitle: json['sectionTitle'],
        exerciseTitle: json['exerciseTitle'],
        message: json['message'] ?? '',
        dueAt: VietnamTime.parseUtc(json['dueAtUtc']),
        createdAt:
            VietnamTime.parseUtc(json['createdAtUtc']) ??
            DateTime.fromMillisecondsSinceEpoch(0),
        isCompleted: json['isCompleted'] ?? false,
      );
}

class LessonAnalytics {
  final List<PracticeSessionTrend> sessions;
  final List<NoteErrorSummary> errorNotes;
  final List<StudentAssignment> assignments;

  LessonAnalytics({
    required this.sessions,
    required this.errorNotes,
    required this.assignments,
  });

  factory LessonAnalytics.fromJson(Map<String, dynamic> json) =>
      LessonAnalytics(
        sessions: (json['sessions'] as List? ?? [])
            .map((item) => PracticeSessionTrend.fromJson(item))
            .toList(),
        errorNotes: (json['errorNotes'] as List? ?? [])
            .map((item) => NoteErrorSummary.fromJson(item))
            .toList(),
        assignments: (json['assignments'] as List? ?? [])
            .map((item) => StudentAssignment.fromJson(item))
            .toList(),
      );
}

class TeacherService {
  final _dio = ApiClient.instance.dio;

  Future<TeacherDashboardData> getDashboard() async {
    final res = await _dio.get('/api/teacher/dashboard');
    return TeacherDashboardData.fromJson(res.data);
  }

  Future<List<StudentProgressOverview>> getStudentsProgress() async {
    final res = await _dio.get('/api/teacher/students-progress');
    final list = res.data as List;
    return list.map((e) => StudentProgressOverview.fromJson(e)).toList();
  }

  Future<StudentDetailProgress> getStudentProgressDetail(int studentId) async {
    final res = await _dio.get('/api/teacher/students/$studentId/progress');
    return StudentDetailProgress.fromJson(res.data);
  }

  Future<LessonAnalytics> getLessonAnalytics(
    int studentId,
    int lessonId,
  ) async {
    final res = await _dio.get(
      '/api/teacher/students/$studentId/lessons/$lessonId/analytics',
    );
    return LessonAnalytics.fromJson(res.data);
  }

  Future<void> createAssignment({
    required int studentId,
    required int lessonId,
    int? lessonSectionId,
    int? lessonExerciseId,
    required String message,
    DateTime? dueAt,
  }) async {
    await _dio.post(
      '/api/teacher/assignments',
      data: {
        'studentId': studentId,
        'lessonId': lessonId,
        'lessonSectionId': lessonSectionId,
        'lessonExerciseId': lessonExerciseId,
        'message': message,
        'dueAtUtc': dueAt?.toUtc().toIso8601String(),
      },
    );
  }
}
