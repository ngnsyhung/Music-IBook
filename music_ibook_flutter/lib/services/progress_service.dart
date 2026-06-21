import '../core/api_client.dart';
import 'teacher_service.dart';

class ProgressService {
  final _dio = ApiClient.instance.dio;

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
