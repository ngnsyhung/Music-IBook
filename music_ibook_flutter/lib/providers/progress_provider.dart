import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../services/progress_service.dart';
import '../services/teacher_service.dart';

class ProgressProvider extends ChangeNotifier {
  final _service = ProgressService();

  bool loading = false;
  String? error;
  List<StudentProgressOverview> studentsProgress = [];
  StudentDetailProgress? currentStudentDetail;

  Future<void> loadStudentsProgress() async {
    loading = true;
    notifyListeners();
    try {
      studentsProgress = await _service.getStudentsProgress();
      error = null;
    } catch (e) {
      error = ApiClient.errorMessage(e);
    }
    loading = false;
    notifyListeners();
  }

  Future<void> loadStudentDetail(int studentId) async {
    loading = true;
    currentStudentDetail = null;
    notifyListeners();
    try {
      currentStudentDetail = await _service.getStudentProgressDetail(studentId);
      error = null;
    } catch (e) {
      error = ApiClient.errorMessage(e);
    }
    loading = false;
    notifyListeners();
  }
}
