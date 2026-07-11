import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/api_client.dart';
import '../core/api_config.dart';
import '../core/token_storage.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final _service = AuthService();
  final _storage = TokenStorage();

  bool loading = false;
  String? error;
  String? token;
  String? role;
  String? fullName;

  bool get isLoggedIn => token != null && token!.isNotEmpty;

  Future<void> loadUser() async {
    token = await _storage.token;
    role = await _storage.role;
    fullName = await _storage.fullName;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final res = await _service.login(email, password);
      token = res.accessToken;
      role = res.role;
      fullName = res.fullName;
      await _storage.saveAuth(token: token!, role: role!, fullName: fullName!);
      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = ApiClient.errorMessage(e);
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(
    String fullName,
    String email,
    String password,
    String role,
  ) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final res = await _service.register(
        fullName: fullName,
        email: email,
        password: password,
        role: role,
      );
      token = res.accessToken;
      this.role = res.role;
      this.fullName = res.fullName;
      await _storage.saveAuth(
        token: token!,
        role: this.role!,
        fullName: this.fullName!,
      );
      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = ApiClient.errorMessage(e);
      loading = false;
      notifyListeners();
      return false;
    }
  }

  static bool _googleSignInInitialized = false;

  Future<bool> googleLogin(String role) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final googleSignIn = GoogleSignIn.instance;
      if (!_googleSignInInitialized) {
        await googleSignIn.initialize(
          serverClientId: ApiConfig.googleServerClientId,
        );
        _googleSignInInitialized = true;
      }

      final googleUser = await googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) throw Exception('Không thể lấy Google ID Token');

      final res = await _service.googleLogin(idToken, role: role);
      token = res.accessToken;
      this.role = res.role;
      fullName = res.fullName;
      await _storage.saveAuth(
        token: token!,
        role: this.role!,
        fullName: fullName!,
      );

      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = ApiClient.errorMessage(e);
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile(String newFullName, String? newPassword) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final res = await _service.updateProfile(newFullName, newPassword);
      token = res.accessToken;
      role = res.role;
      fullName = res.fullName;
      await _storage.saveAuth(token: token!, role: role!, fullName: fullName!);

      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = ApiClient.errorMessage(e);
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.clear();
    token = null;
    role = null;
    fullName = null;
    try {
      if (_googleSignInInitialized) {
        await GoogleSignIn.instance.signOut();
      }
    } catch (_) {}
    notifyListeners();
  }
}
