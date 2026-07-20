import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:music_ibook_flutter/core/token_storage.dart';
import 'package:music_ibook_flutter/models/auth_models.dart';
import 'package:music_ibook_flutter/providers/auth_provider.dart';
import 'package:music_ibook_flutter/services/auth_service.dart';

import 'auth_provider_test.mocks.dart';

@GenerateMocks([AuthService, TokenStorage])
void main() {
  late MockAuthService mockAuthService;
  late MockTokenStorage mockTokenStorage;
  late AuthProvider authProvider;

  setUp(() {
    mockAuthService = MockAuthService();
    mockTokenStorage = MockTokenStorage();
    authProvider = AuthProvider(
      service: mockAuthService,
      storage: mockTokenStorage,
    );
  });

  group('AuthProvider Tests', () {
    test('loadUser fetches from storage', () async {
      when(mockTokenStorage.token).thenAnswer((_) async => 'fake_token');
      when(mockTokenStorage.role).thenAnswer((_) async => 'Student');
      when(mockTokenStorage.fullName).thenAnswer((_) async => 'Test User');

      await authProvider.loadUser();

      expect(authProvider.token, 'fake_token');
      expect(authProvider.role, 'Student');
      expect(authProvider.fullName, 'Test User');
      expect(authProvider.isLoggedIn, true);
    });

    test('login success sets token and saves to storage', () async {
      final authResponse = AuthResponse(
        accessToken: 'new_fake_token',
        fullName: 'Test User',
        role: 'Student',
      );

      when(mockAuthService.login('test@email.com', 'password123'))
          .thenAnswer((_) async => authResponse);
      when(mockTokenStorage.saveAuth(
        token: 'new_fake_token',
        role: 'Student',
        fullName: 'Test User',
      )).thenAnswer((_) async => {});

      final success = await authProvider.login('test@email.com', 'password123');

      expect(success, true);
      expect(authProvider.token, 'new_fake_token');
      expect(authProvider.role, 'Student');
      expect(authProvider.fullName, 'Test User');
      expect(authProvider.isLoggedIn, true);
      expect(authProvider.error, null);
      
      verify(mockTokenStorage.saveAuth(
        token: 'new_fake_token',
        role: 'Student',
        fullName: 'Test User',
      )).called(1);
    });

    test('login failure sets error', () async {
      when(mockAuthService.login('test@email.com', 'wrong_pass'))
          .thenThrow(Exception('Unauthorized'));

      final success = await authProvider.login('test@email.com', 'wrong_pass');

      expect(success, false);
      expect(authProvider.isLoggedIn, false);
      expect(authProvider.error, isNotNull);
    });
  });
}
