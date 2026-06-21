import 'lesson_note.dart';

class MusicLesson {
  int? id;
  int? teacherId;
  String title;
  String composer;
  String clef;
  String keySignature;
  String timeSignature;
  String theoryTitle;
  String theoryContent;
  String practiceGuide;
  String? audioUrl;
  String? audioFileName;
  bool isPublished;
  List<LessonNote> notes;

  MusicLesson({
    this.id,
    this.teacherId,
    required this.title,
    this.composer = '',
    this.clef = 'treble',
    this.keySignature = 'D Major',
    this.timeSignature = '2/4',
    this.theoryTitle = '',
    this.theoryContent = '',
    this.practiceGuide = '',
    this.audioUrl,
    this.audioFileName,
    this.isPublished = false,
    this.notes = const [],
  });

  factory MusicLesson.empty() {
    return MusicLesson(
      title: 'Bài nhạc mới',
      composer: '',
      clef: 'treble',
      keySignature: 'D Major',
      timeSignature: '2/4',
    );
  }

  factory MusicLesson.fromJson(Map<String, dynamic> json) {
    final rawNotes = json['notes'] as List? ?? [];
    return MusicLesson(
      id: json['id'],
      teacherId: json['teacherId'],
      title: json['title'] ?? '',
      composer: json['composer'] ?? '',
      clef: json['clef'] ?? 'treble',
      keySignature: json['keySignature'] ?? 'D Major',
      timeSignature: json['timeSignature'] ?? '2/4',
      theoryTitle: json['theoryTitle'] ?? '',
      theoryContent: json['theoryContent'] ?? '',
      practiceGuide: json['practiceGuide'] ?? '',
      audioUrl: json['audioUrl'],
      audioFileName: json['audioFileName'],
      isPublished: json['isPublished'] ?? false,
      notes: rawNotes.map((e) => LessonNote.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'title': title,
      'composer': composer,
      'clef': clef,
      'keySignature': keySignature,
      'timeSignature': timeSignature,
      'theoryTitle': theoryTitle,
      'theoryContent': theoryContent,
      'practiceGuide': practiceGuide,
    };
  }
}
