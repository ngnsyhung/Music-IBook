import '../core/api_client.dart';
import '../models/practice.dart';
import '../models/progress.dart';
import '../models/lesson_authoring.dart';

class StudentService {
  final _dio = ApiClient.instance.dio;

  Future<List<StudentProgress>> getProgress() async {
    final res = await _dio.get('/api/student/progress');
    final list = res.data as List;
    return list.map((e) => StudentProgress.fromJson(e)).toList();
  }

  Future<void> saveProgress({
    required int lessonId,
    required double lastPositionSecond,
    required int completedNoteCount,
    required int bestScore,
    required bool isCompleted,
  }) async {
    await _dio.put(
      '/api/student/progress/$lessonId',
      data: {
        'lastPositionSecond': lastPositionSecond,
        'completedNoteCount': completedNoteCount,
        'bestScore': bestScore,
        'isCompleted': isCompleted,
      },
    );
  }

  Future<PracticeSession> submitPractice({
    required int lessonId,
    required bool isExam,
    required int durationSeconds,
    required List<NoteAttemptRequest> attempts,
    int? studentAssignmentId,
  }) async {
    final res = await _dio.post(
      '/api/student/practice',
      data: {
        'lessonId': lessonId,
        'studentAssignmentId': studentAssignmentId,
        'isExam': isExam,
        'durationSeconds': durationSeconds,
        'attempts': attempts.map((e) => e.toJson()).toList(),
      },
    );
    return PracticeSession.fromJson(res.data);
  }

  Future<List<StudentAssignmentItem>> getAssignments({int? lessonId}) async {
    final queryParameters = <String, dynamic>{};
    if (lessonId != null) queryParameters['lessonId'] = lessonId;
    final res = await _dio.get(
      '/api/student/assignments',
      queryParameters: queryParameters,
    );
    final list = res.data as List;
    return list.map((item) => StudentAssignmentItem.fromJson(item)).toList();
  }

  Future<List<PracticeSession>> getPracticeHistory() async {
    final res = await _dio.get('/api/student/practice-history');
    final list = res.data as List;
    return list.map((e) => PracticeSession.fromJson(e)).toList();
  }
}
