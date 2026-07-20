import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:music_ibook_flutter/providers/auth_provider.dart';
import 'package:music_ibook_flutter/screens/auth/login_screen.dart';

import 'login_screen_test.mocks.dart';

@GenerateMocks([AuthProvider])
void main() {
  late MockAuthProvider mockAuthProvider;

  setUp(() {
    mockAuthProvider = MockAuthProvider();
  });

  Widget createLoginScreen() {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: mockAuthProvider,
      child: const MaterialApp(
        home: LoginScreen(),
      ),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('renders login screen elements', (WidgetTester tester) async {
      when(mockAuthProvider.error).thenReturn(null);
      when(mockAuthProvider.loading).thenReturn(false);

      await tester.pumpWidget(createLoginScreen());

      expect(find.text('MUSIC IBOOK'), findsOneWidget);
      expect(find.text('01 / USER IDENTIFICATION'), findsOneWidget);
      expect(find.text('02 / SECURITY KEY'), findsOneWidget);
      expect(find.text('LOGIN TO ARCHIVE'), findsOneWidget);
      expect(find.text('CREATE NEW ACCOUNT'), findsOneWidget);
    });

    testWidgets('shows error message if auth_provider has error', (WidgetTester tester) async {
      when(mockAuthProvider.error).thenReturn('Invalid credentials');
      when(mockAuthProvider.loading).thenReturn(false);

      await tester.pumpWidget(createLoginScreen());

      expect(find.text('Invalid credentials'), findsOneWidget);
    });

    testWidgets('shows loading state when loading', (WidgetTester tester) async {
      when(mockAuthProvider.error).thenReturn(null);
      when(mockAuthProvider.loading).thenReturn(true);

      await tester.pumpWidget(createLoginScreen());

      expect(find.text('PROCESSING...'), findsOneWidget);
    });

    testWidgets('calls login when sign in button pressed', (WidgetTester tester) async {
      when(mockAuthProvider.error).thenReturn(null);
      when(mockAuthProvider.loading).thenReturn(false);
      when(mockAuthProvider.login(any, any)).thenAnswer((_) async => true);

      await tester.pumpWidget(createLoginScreen());

      // Enter email
      final emailField = find.byType(TextField).at(0);
      await tester.enterText(emailField, 'test@email.com');

      // Enter password
      final passwordField = find.byType(TextField).at(1);
      await tester.enterText(passwordField, 'password123');

      // Tap Sign in (BrutalistButton actually detects taps, we tap the text inside it)
      final signInBtn = find.text('LOGIN TO ARCHIVE');
      await tester.tap(signInBtn);
      await tester.pump();

      verify(mockAuthProvider.login('test@email.com', 'password123')).called(1);
    });
  });
}
