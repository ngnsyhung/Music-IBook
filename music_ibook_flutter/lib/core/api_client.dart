import 'package:dio/dio.dart';

import 'api_config.dart';
import 'token_storage.dart';

class ApiClient {
  static final ApiClient instance = ApiClient._();
  late final Dio dio;

  ApiClient._() {
    dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await TokenStorage().token;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  static String errorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) return data['message'].toString();
      if (data is String && data.isNotEmpty) return data;
      return e.message ?? 'Lỗi kết nối API';
    }
    return e.toString();
  }
}
