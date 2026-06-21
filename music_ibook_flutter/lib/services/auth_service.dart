import '../core/api_client.dart';
import '../models/auth_models.dart';

class AuthService {
  final _dio = ApiClient.instance.dio;

  Future<AuthResponse> login(String email, String password) async {
    final res = await _dio.post('/api/auth/login', data: {
      'email': email,
      'password': password,
    });
    return AuthResponse.fromJson(res.data);
  }

  Future<AuthResponse> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    final res = await _dio.post('/api/auth/register', data: {
      'fullName': fullName,
      'email': email,
      'password': password,
      'role': role,
    });
    return AuthResponse.fromJson(res.data);
  }

  Future<String> forgotPassword(String email) async {
    final res = await _dio.post('/api/auth/forgot-password', data: {'email': email});
    return res.data['resetToken']?.toString() ?? res.data['message']?.toString() ?? '';
  }

  Future<void> resetPassword(String token, String newPassword) async {
    await _dio.post('/api/auth/reset-password', data: {
      'token': token,
      'newPassword': newPassword,
    });
  }
}
