import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../core/api_client.dart';
import '../models/lesson.dart';
import '../models/lesson_note.dart';
import '../services/lesson_service.dart';

class LessonProvider extends ChangeNotifier {
  final _service = LessonService();

  bool loading = false;
  String? error;
  List<MusicLesson> lessons = [];
  MusicLesson? current;

  Future<void> loadLessons() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      lessons = await _service.getAll();
    } catch (e) {
      error = ApiClient.errorMessage(e);
    }
    loading = false;
    notifyListeners();
  }

  Future<MusicLesson?> loadLesson(int id) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      current = await _service.getById(id);
    } catch (e) {
      error = ApiClient.errorMessage(e);
    }
    loading = false;
    notifyListeners();
    return current;
  }

  Future<MusicLesson?> saveLesson(MusicLesson lesson) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      if (lesson.id == null) {
        current = await _service.create(lesson);
      } else {
        current = await _service.update(lesson.id!, lesson);
      }
      return current;
    } catch (e) {
      error = ApiClient.errorMessage(e);
      return null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> addNotesOneByOne(int lessonId, List<LessonNote> notes) async {
    try {
      await _service.addNotesOneByOne(lessonId, notes);
      return true;
    } catch (e) {
      error = ApiClient.errorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadAudio(int lessonId, PlatformFile file) async {
    try {
      await _service.uploadAudio(lessonId, file);
      return true;
    } catch (e) {
      error = ApiClient.errorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> publish(int lessonId) async {
    await _service.publish(lessonId);
    await loadLessons();
  }

  Future<bool> deleteNote(int noteId) async {
    try {
      await _service.deleteNote(noteId);
      return true;
    } catch (e) {
      error = ApiClient.errorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAllNotes(int lessonId) async {
    try {
      await _service.deleteAllNotes(lessonId);
      return true;
    } catch (e) {
      error = ApiClient.errorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteLesson(int lessonId) async {
    try {
      await _service.delete(lessonId);

      lessons.removeWhere((x) => x.id == lessonId);

      notifyListeners();
      return true;
    } catch (e) {
      error = ApiClient.errorMessage(e);
      notifyListeners();
      return false;
    }
  }
}
