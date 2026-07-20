import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:music_ibook_flutter/models/lesson.dart';
import 'package:music_ibook_flutter/providers/lesson_provider.dart';
import 'package:music_ibook_flutter/services/lesson_service.dart';

import 'lesson_provider_test.mocks.dart';

@GenerateMocks([LessonService])
void main() {
  late MockLessonService mockLessonService;
  late LessonProvider lessonProvider;

  setUp(() {
    mockLessonService = MockLessonService();
    lessonProvider = LessonProvider(service: mockLessonService);
  });

  group('LessonProvider Tests', () {
    test('loadLessons fetches from service and updates state', () async {
      final lessons = [
        MusicLesson(
          id: 1,
          title: 'Test Lesson',
          composer: 'Test Composer',
          clef: 'G',
          keySignature: 'C',
          timeSignature: '4/4',
          tempo: 100,
          teacherId: 1,
          isPublished: true,
          notes: [],
        )
      ];

      when(mockLessonService.getAll()).thenAnswer((_) async => lessons);

      await lessonProvider.loadLessons();

      expect(lessonProvider.lessons.length, 1);
      expect(lessonProvider.lessons.first.title, 'Test Lesson');
      expect(lessonProvider.loading, false);
      expect(lessonProvider.error, null);

      verify(mockLessonService.getAll()).called(1);
    });

    test('loadLessons sets error on failure', () async {
      when(mockLessonService.getAll()).thenThrow(Exception('API Error'));

      await lessonProvider.loadLessons();

      expect(lessonProvider.lessons.isEmpty, true);
      expect(lessonProvider.loading, false);
      expect(lessonProvider.error, isNotNull);
    });
  });
}
