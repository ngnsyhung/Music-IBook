import '../core/api_client.dart';

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
  final String? lastActivityAt;

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
      lastActivityAt: json['lastActivityAt'],
    );
  }
}

class LessonProgressDetail {
  final int lessonId;
  final String lessonName;
  final String? lastPracticeAt;
  final String? lastExamAt;
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
      lastPracticeAt: json['lastPracticeAt'],
      lastExamAt: json['lastExamAt'],
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
}
