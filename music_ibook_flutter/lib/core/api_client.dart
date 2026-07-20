import 'package:dio/dio.dart';

import 'api_config.dart';
import 'token_storage.dart';

class ApiClient {
  static final ApiClient instance = ApiClient._();
  late final Dio dio;

  ApiClient._() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        // On Flutter Web, the browser adapter can count the wait for the
        // first response bytes as connection time. Lesson-list responses can
        // legitimately take longer because they contain score data.
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 120),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage().token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  static String errorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      if (data is String && data.trim().isNotEmpty) {
        final message = data.trim();
        final looksLikeServerTrace =
            message.length > 500 ||
            message.contains('System.') ||
            message.contains('Microsoft.') ||
            message.contains(' at ');
        if (!looksLikeServerTrace) return message;
        return 'Máy chủ gặp lỗi khi xử lý yêu cầu. Vui lòng thử lại.';
      }
      if (e.type == DioExceptionType.connectionTimeout) {
        return 'Máy chủ phản hồi quá chậm. Vui lòng kiểm tra máy chủ và thử lại.';
      }
      if (e.type == DioExceptionType.sendTimeout) {
        return 'Gửi dữ liệu quá thời gian cho phép. Vui lòng thử lại.';
      }
      if (e.type == DioExceptionType.receiveTimeout) {
        return 'Máy chủ mất quá nhiều thời gian để trả dữ liệu. Vui lòng thử lại.';
      }
      if (e.type == DioExceptionType.transformTimeout) {
        return 'Dữ liệu bản nhạc quá lớn nên không thể xử lý kịp thời. Vui lòng thử lại.';
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'Không thể kết nối máy chủ. Hãy kiểm tra API đang chạy và thử lại.';
      }
      if (e.type == DioExceptionType.badResponse) {
        final status = e.response?.statusCode;
        return status == null
            ? 'Máy chủ trả về phản hồi không hợp lệ.'
            : 'Máy chủ trả về lỗi $status.';
      }
      if (e.type == DioExceptionType.cancel) {
        return 'Yêu cầu đã bị hủy.';
      }
      if (e.type == DioExceptionType.badCertificate) {
        return 'Chứng chỉ bảo mật của máy chủ không hợp lệ.';
      }
      return e.message ?? 'Lỗi kết nối API';
    }
    return e.toString();
  }
}
