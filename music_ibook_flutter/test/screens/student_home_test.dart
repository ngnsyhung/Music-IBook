import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:music_ibook_flutter/models/lesson.dart';
import 'package:music_ibook_flutter/providers/auth_provider.dart';
import 'package:music_ibook_flutter/providers/lesson_provider.dart';
import 'package:music_ibook_flutter/screens/student/student_home.dart';
import 'package:music_ibook_flutter/widgets/lesson_card.dart';

import 'student_home_test.mocks.dart';

@GenerateMocks([LessonProvider, AuthProvider])
void main() {
  late MockLessonProvider mockLessonProvider;
  late MockAuthProvider mockAuthProvider;

  setUp(() {
    mockLessonProvider = MockLessonProvider();
    mockAuthProvider = MockAuthProvider();
  });

  Widget createStudentHomeScreen() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LessonProvider>.value(value: mockLessonProvider),
        ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
      ],
      child: const MaterialApp(
        home: StudentHome(),
      ),
    );
  }

  group('StudentHome Widget Tests', () {
    testWidgets('shows loading state when loading', (WidgetTester tester) async {
      when(mockLessonProvider.loading).thenReturn(true);
      when(mockLessonProvider.error).thenReturn(null);
      when(mockLessonProvider.lessons).thenReturn([]);
      when(mockAuthProvider.fullName).thenReturn('Test Student');

      await tester.pumpWidget(createStudentHomeScreen());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error state when error occurs', (WidgetTester tester) async {
      when(mockLessonProvider.loading).thenReturn(false);
      when(mockLessonProvider.error).thenReturn('Network Error');
      when(mockLessonProvider.lessons).thenReturn([]);
      when(mockAuthProvider.fullName).thenReturn('Test Student');

      await tester.pumpWidget(createStudentHomeScreen());

      expect(find.text('Network Error'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    });

    testWidgets('shows list of lessons when loaded successfully', (WidgetTester tester) async {
      final lessons = [
        MusicLesson(
          id: 1,
          title: 'Lesson 1',
          composer: 'Composer 1',
          clef: 'G',
          keySignature: 'C',
          timeSignature: '4/4',
          tempo: 100,
          teacherId: 1,
          isPublished: true,
          notes: [],
        ),
        MusicLesson(
          id: 2,
          title: 'Lesson 2',
          composer: 'Composer 2',
          clef: 'F',
          keySignature: 'G',
          timeSignature: '3/4',
          tempo: 80,
          teacherId: 1,
          isPublished: true,
          notes: [],
        )
      ];

      when(mockLessonProvider.loading).thenReturn(false);
      when(mockLessonProvider.error).thenReturn(null);
      when(mockLessonProvider.lessons).thenReturn(lessons);
      when(mockAuthProvider.fullName).thenReturn('Test Student');

      await tester.pumpWidget(createStudentHomeScreen());
      await tester.pumpAndSettle();

      expect(find.byType(LessonCard), findsNWidgets(2));
      expect(find.text('Lesson 1'), findsOneWidget);
      expect(find.text('Lesson 2'), findsOneWidget);
    });
  });
}
