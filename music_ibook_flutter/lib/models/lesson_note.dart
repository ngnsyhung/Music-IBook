class LessonNote {
  int? id;
  int? lessonId;
  double second;
  String note;
  String duration;
  String lyric;
  String chord;

  LessonNote({
    this.id,
    this.lessonId,
    required this.second,
    required this.note,
    required this.duration,
    required this.lyric,
    this.chord = '',
  });

  factory LessonNote.fromJson(Map<String, dynamic> json) {
    return LessonNote(
      id: json['id'],
      lessonId: json['lessonId'],
      second: (json['second'] ?? 0).toDouble(),
      note: json['note'] ?? '',
      duration: json['duration'] ?? '',
      lyric: json['lyric'] ?? '',
      chord: json['chord'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'second': second,
      'note': note,
      'duration': duration,
      'lyric': lyric,
      'chord': chord,
    };
  }
}
