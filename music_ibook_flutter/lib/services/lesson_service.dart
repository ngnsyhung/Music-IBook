import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../core/api_client.dart';
import '../models/lesson.dart';
import '../models/lesson_note.dart';

class LessonService {
  final _dio = ApiClient.instance.dio;

  Future<List<MusicLesson>> getAll() async {
    final res = await _dio.get('/api/lessons');
    final list = res.data as List;
    return list.map((e) => MusicLesson.fromJson(e)).toList();
  }

  Future<MusicLesson> getById(int id) async {
    final res = await _dio.get('/api/lessons/$id');
    return MusicLesson.fromJson(res.data);
  }

  Future<MusicLesson> create(MusicLesson lesson) async {
    final res = await _dio.post('/api/lessons', data: lesson.toCreateJson());
    return MusicLesson.fromJson(res.data);
  }

  Future<MusicLesson> update(int id, MusicLesson lesson) async {
    final res = await _dio.put('/api/lessons/$id', data: lesson.toCreateJson());
    return MusicLesson.fromJson(res.data);
  }

  Future<void> addNote(int lessonId, LessonNote note) async {
    await _dio.post('/api/lessons/$lessonId/notes', data: note.toJson());
  }

  Future<void> addNotesOneByOne(int lessonId, List<LessonNote> notes) async {
    for (final note in notes) {
      await addNote(lessonId, note);
    }
  }

  Future<void> uploadAudio(int lessonId, PlatformFile file) async {
    MultipartFile multipart;

    if (file.bytes != null) {
      multipart = MultipartFile.fromBytes(file.bytes!, filename: file.name);
    } else if (file.path != null) {
      multipart = await MultipartFile.fromFile(file.path!, filename: file.name);
    } else {
      throw Exception('Không đọc được file nhạc');
    }

    final form = FormData.fromMap({'file': multipart});
    await _dio.post('/api/lessons/$lessonId/audio', data: form);
  }

  Future<void> publish(int lessonId) async {
    await _dio.put('/api/lessons/$lessonId/publish');
  }

  Future<void> delete(int lessonId) async {
    await _dio.delete('/api/lessons/$lessonId');
  }

  Future<void> deleteNote(int noteId) async {
    await _dio.delete('/api/lessons/notes/$noteId');
  }

  Future<void> deleteAllNotes(int lessonId) async {
    await _dio.delete('/api/lessons/$lessonId/notes');
  }
}
