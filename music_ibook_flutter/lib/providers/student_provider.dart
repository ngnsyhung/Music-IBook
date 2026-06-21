import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../models/practice.dart';
import '../models/progress.dart';
import '../services/student_service.dart';

class StudentProvider extends ChangeNotifier {
  final _service = StudentService();

  bool loading = false;
  String? error;
  List<StudentProgress> progresses = [];
  List<PracticeSession> history = [];

  Future<void> loadProgress() async {
    loading = true;
    notifyListeners();
    try {
      progresses = await _service.getProgress();
    } catch (e) {
      error = ApiClient.errorMessage(e);
    }
    loading = false;
    notifyListeners();
  }

  Future<void> loadHistory() async {
    loading = true;
    notifyListeners();
    try {
      history = await _service.getPracticeHistory();
    } catch (e) {
      error = ApiClient.errorMessage(e);
    }
    loading = false;
    notifyListeners();
  }

  Future<PracticeSession?> submitPractice(
    int lessonId, 
    List<NoteAttemptRequest> attempts, {
    required bool isExam,
    required int durationSeconds,
  }) async {
    try {
      final result = await _service.submitPractice(
        lessonId: lessonId, 
        attempts: attempts,
        isExam: isExam,
        durationSeconds: durationSeconds,
      );
      history.insert(0, result);
      notifyListeners();
      return result;
    } catch (e) {
      error = ApiClient.errorMessage(e);
      notifyListeners();
      return null;
    }
  }

  Future<void> saveProgress({
    required int lessonId,
    required double lastPositionSecond,
    required int completedNoteCount,
    required int bestScore,
    required bool isCompleted,
  }) async {
    await _service.saveProgress(
      lessonId: lessonId,
      lastPositionSecond: lastPositionSecond,
      completedNoteCount: completedNoteCount,
      bestScore: bestScore,
      isCompleted: isCompleted,
    );
  }
}
