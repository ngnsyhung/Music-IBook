class LessonSection {
  int? id;
  int? lessonId;
  String title;
  double startBeat;
  double endBeat;
  int defaultTempo;
  String difficulty;
  String hand;
  int sortOrder;

  LessonSection({
    this.id,
    this.lessonId,
    required this.title,
    required this.startBeat,
    required this.endBeat,
    required this.defaultTempo,
    this.difficulty = 'Beginner',
    this.hand = 'Both',
    required this.sortOrder,
  });

  factory LessonSection.fromJson(Map<String, dynamic> json) => LessonSection(
    id: json['id'],
    lessonId: json['lessonId'],
    title: json['title'] ?? '',
    startBeat: (json['startBeat'] ?? 1).toDouble(),
    endBeat: (json['endBeat'] ?? 1).toDouble(),
    defaultTempo: json['defaultTempo'] ?? 80,
    difficulty: json['difficulty'] ?? 'Beginner',
    hand: json['hand'] ?? 'Both',
    sortOrder: json['sortOrder'] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'startBeat': startBeat,
    'endBeat': endBeat,
    'defaultTempo': defaultTempo,
    'difficulty': difficulty,
    'hand': hand,
    'sortOrder': sortOrder,
  };
}

class LessonAnnotation {
  int? id;
  int? lessonId;
  double startBeat;
  double? endBeat;
  String kind;
  String text;

  LessonAnnotation({
    this.id,
    this.lessonId,
    required this.startBeat,
    this.endBeat,
    this.kind = 'TeacherNote',
    required this.text,
  });

  factory LessonAnnotation.fromJson(Map<String, dynamic> json) =>
      LessonAnnotation(
        id: json['id'],
        lessonId: json['lessonId'],
        startBeat: (json['startBeat'] ?? 1).toDouble(),
        endBeat: json['endBeat'] == null
            ? null
            : (json['endBeat'] as num).toDouble(),
        kind: json['kind'] ?? 'TeacherNote',
        text: json['text'] ?? '',
      );

  Map<String, dynamic> toJson() => {
    'startBeat': startBeat,
    'endBeat': endBeat,
    'kind': kind,
    'text': text,
  };
}

class LessonExercise {
  int? id;
  int? lessonId;
  int? lessonSectionId;
  // Kept locally so an exercise can refer to a brand-new section before IDs exist.
  int? sectionSortOrder;
  String title;
  String type;
  String instruction;
  String configJson;
  int sortOrder;

  LessonExercise({
    this.id,
    this.lessonId,
    this.lessonSectionId,
    this.sectionSortOrder,
    required this.title,
    required this.type,
    this.instruction = '',
    this.configJson = '{}',
    required this.sortOrder,
  });

  factory LessonExercise.fromJson(Map<String, dynamic> json) => LessonExercise(
    id: json['id'],
    lessonId: json['lessonId'],
    lessonSectionId: json['lessonSectionId'],
    title: json['title'] ?? '',
    type: json['type'] ?? 'Metronome',
    instruction: json['instruction'] ?? '',
    configJson: json['configJson'] ?? '{}',
    sortOrder: json['sortOrder'] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'type': type,
    'instruction': instruction,
    'configJson': configJson,
    'sectionSortOrder': sectionSortOrder,
    'sortOrder': sortOrder,
  };
}

class StudentAssignmentItem {
  final int id;
  final int lessonId;
  final int? lessonSectionId;
  final int? lessonExerciseId;
  final String? sectionTitle;
  final String? exerciseTitle;
  final String message;
  final DateTime? dueAtUtc;
  final DateTime createdAtUtc;
  bool isCompleted;

  StudentAssignmentItem({
    required this.id,
    required this.lessonId,
    this.lessonSectionId,
    this.lessonExerciseId,
    this.sectionTitle,
    this.exerciseTitle,
    required this.message,
    this.dueAtUtc,
    required this.createdAtUtc,
    required this.isCompleted,
  });

  factory StudentAssignmentItem.fromJson(Map<String, dynamic> json) =>
      StudentAssignmentItem(
        id: json['id'] ?? 0,
        lessonId: json['lessonId'] ?? 0,
        lessonSectionId: json['lessonSectionId'],
        lessonExerciseId: json['lessonExerciseId'],
        sectionTitle: json['sectionTitle'],
        exerciseTitle: json['exerciseTitle'],
        message: json['message'] ?? '',
        dueAtUtc: _parseUtc(json['dueAtUtc']),
        createdAtUtc:
            _parseUtc(json['createdAtUtc']) ??
            DateTime.fromMillisecondsSinceEpoch(0),
        isCompleted: json['isCompleted'] ?? false,
      );

  static DateTime? _parseUtc(Object? raw) {
    if (raw == null) return null;
    final value = raw.toString();
    final hasZone =
        value.endsWith('Z') || RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(value);
    return DateTime.tryParse(hasZone ? value : '${value}Z')?.toUtc();
  }
}
