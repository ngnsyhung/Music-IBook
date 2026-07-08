import 'package:google_sign_in/google_sign_in.dart';
import '../core/api_client.dart';
import '../core/api_config.dart';
import '../models/auth_models.dart';

class AuthService {
  final _dio = ApiClient.instance.dio;
  final GoogleSignIn _googleSignIn;

  AuthService({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ?? GoogleSignIn(
          // serverClientId bắt buộc trên Android để nhận được idToken
          // Dùng Web Client ID (client_type: 3) từ google-services.json
          serverClientId: ApiConfig.googleWebClientId,
          scopes: ['email', 'profile', 'openid'],
        );

  Future<AuthResponse> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception("Đăng nhập bằng Google bị hủy");
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception("Không lấy được Google ID Token");
      }

      final res = await _dio.post('/api/auth/google-login', data: {
        'idToken': idToken,
      });
      return AuthResponse.fromJson(res.data);
    } catch (e) {
      rethrow;
    }
  }

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
