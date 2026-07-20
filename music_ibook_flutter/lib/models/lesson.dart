import 'lesson_note.dart';
import 'lesson_authoring.dart';

class MusicLesson {
  int? id;
  int? teacherId;
  String title;
  String composer;
  String clef;
  String keySignature;
  String timeSignature;
  String timeSignatureMap;
  String tempoMap;
  int tempo;
  String? audioUrl;
  String? audioFileName;
  bool isPublished;
  List<LessonNote> notes;
  List<LessonSection> sections;
  List<LessonAnnotation> annotations;
  List<LessonExercise> exercises;

  MusicLesson({
    this.id,
    this.teacherId,
    required this.title,
    this.composer = '',
    this.clef = 'treble',
    this.keySignature = 'D Major',
    this.timeSignature = '2/4',
    this.timeSignatureMap = '',
    this.tempoMap = '',
    this.tempo = 80,
    this.audioUrl,
    this.audioFileName,
    this.isPublished = false,
    this.notes = const [],
    this.sections = const [],
    this.annotations = const [],
    this.exercises = const [],
  });

  factory MusicLesson.empty() {
    return MusicLesson(
      title: 'Bài nhạc mới',
      composer: '',
      clef: 'treble',
      keySignature: 'D Major',
      timeSignature: '2/4',
      timeSignatureMap: '',
      tempoMap: '',
      tempo: 80,
    );
  }

  factory MusicLesson.fromJson(Map<String, dynamic> json) {
    final rawNotes = json['notes'] as List? ?? [];
    final sections = (json['sections'] as List? ?? [])
        .map((e) => LessonSection.fromJson(e))
        .toList();
    final exercises = (json['exercises'] as List? ?? [])
        .map((e) => LessonExercise.fromJson(e))
        .toList();
    final sectionOrdersById = {
      for (final section in sections)
        if (section.id != null) section.id!: section.sortOrder,
    };
    for (final exercise in exercises) {
      exercise.sectionSortOrder = sectionOrdersById[exercise.lessonSectionId];
    }
    return MusicLesson(
      id: json['id'],
      teacherId: json['teacherId'],
      title: json['title'] ?? '',
      composer: json['composer'] ?? '',
      clef: json['clef'] ?? 'treble',
      keySignature: json['keySignature'] ?? 'D Major',
      timeSignature: json['timeSignature'] ?? '2/4',
      timeSignatureMap: json['timeSignatureMap'] ?? '',
      tempoMap: json['tempoMap'] ?? '',
      tempo: json['tempo'] ?? 80,
      audioUrl: json['audioUrl'],
      audioFileName: json['audioFileName'],
      isPublished: json['isPublished'] ?? false,
      notes: rawNotes.map((e) => LessonNote.fromJson(e)).toList(),
      sections: sections,
      annotations: (json['annotations'] as List? ?? [])
          .map((e) => LessonAnnotation.fromJson(e))
          .toList(),
      exercises: exercises,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'title': title,
      'composer': composer,
      'clef': clef,
      'keySignature': keySignature,
      'timeSignature': timeSignature,
      'timeSignatureMap': timeSignatureMap,
      'tempoMap': tempoMap,
      'tempo': tempo,
    };
  }

  Map<String, dynamic> toContentJson() => {
    'notes': notes.map((note) => note.toJson()).toList(),
    'sections': sections.map((section) => section.toJson()).toList(),
    'annotations': annotations
        .map((annotation) => annotation.toJson())
        .toList(),
    'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
  };
}
