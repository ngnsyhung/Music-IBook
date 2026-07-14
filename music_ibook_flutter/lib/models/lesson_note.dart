class LessonNote {
  int? id;
  int? lessonId;
  double second;
  double startBeat;
  double durationBeat;
  int velocity;
  String note;
  String duration;
  String lyric;
  String chord;

  LessonNote({
    this.id,
    this.lessonId,
    required this.second,
    double? startBeat,
    double? durationBeat,
    this.velocity = 90,
    required this.note,
    required this.duration,
    required this.lyric,
    this.chord = '',
  }) : startBeat = startBeat ?? second,
       durationBeat = durationBeat ?? _durationToBeat(duration);

  factory LessonNote.fromJson(Map<String, dynamic> json) {
    final duration = json['duration'] ?? '';
    final second = (json['second'] ?? 0).toDouble();
    return LessonNote(
      id: json['id'],
      lessonId: json['lessonId'],
      second: second,
      startBeat: (json['startBeat'] ?? json['beat'] ?? second).toDouble(),
      durationBeat: (json['durationBeat'] ?? _durationToBeat(duration))
          .toDouble(),
      velocity: json['velocity'] ?? 90,
      note: json['note'] ?? '',
      duration: duration,
      lyric: json['lyric'] ?? '',
      chord: json['chord'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'second': second,
      'startBeat': startBeat,
      'durationBeat': durationBeat,
      'velocity': velocity,
      'note': note,
      'duration': duration,
      'lyric': lyric,
      'chord': chord,
    };
  }

  LessonNote copyWith({
    int? id,
    int? lessonId,
    double? second,
    double? startBeat,
    double? durationBeat,
    int? velocity,
    String? note,
    String? duration,
    String? lyric,
    String? chord,
  }) {
    return LessonNote(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      second: second ?? this.second,
      startBeat: startBeat ?? this.startBeat,
      durationBeat: durationBeat ?? this.durationBeat,
      velocity: velocity ?? this.velocity,
      note: note ?? this.note,
      duration: duration ?? this.duration,
      lyric: lyric ?? this.lyric,
      chord: chord ?? this.chord,
    );
  }

  static double _durationToBeat(String duration) {
    switch (duration) {
      case 'whole':
        return 4;
      case 'dotted_half':
        return 3;
      case 'half':
        return 2;
      case 'dotted_quarter':
        return 1.5;
      case 'quarter':
        return 1;
      case 'dotted_eighth':
        return 0.75;
      case 'eighth':
        return 0.5;
      case 'dotted_sixteenth':
        return 0.375;
      case 'sixteenth':
        return 0.25;
      case 'thirty_second':
        return 0.125;
      case 'sixty_fourth':
        return 0.0625;
      default:
        return 1;
    }
  }
}
