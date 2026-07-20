import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/token_storage.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service;
  final TokenStorage _storage;

  AuthProvider({AuthService? service, TokenStorage? storage})
      : _service = service ?? AuthService(),
        _storage = storage ?? TokenStorage();

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

  Future<bool> updateProfile(String fullName, String? newPassword) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final res = await _service.updateProfile(fullName, newPassword);
      token = res.accessToken;
      role = res.role;
      this.fullName = res.fullName;
      await _storage.saveAuth(
        token: token!,
        role: role!,
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

  Future<void> logout() async {
    await _storage.clear();
    token = null;
    role = null;
    fullName = null;
    notifyListeners();
  }
}
