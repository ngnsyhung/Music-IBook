import '../core/api_client.dart';
import '../models/practice.dart';

class HistoryService {
  final _dio = ApiClient.instance.dio;

  Future<List<PracticeSession>> getPracticeHistory() async {
    final res = await _dio.get('/api/student/practice-history');
    final list = res.data as List;
    return list.map((e) => PracticeSession.fromJson(e)).toList();
  }
}
