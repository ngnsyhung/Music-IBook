import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_config.dart';
import '../../models/lesson.dart';
import '../../models/lesson_note.dart';
import '../../providers/lesson_provider.dart';
import '../../widgets/music_staff.dart';

class LessonEditorScreen extends StatefulWidget {
  final int? lessonId;

  const LessonEditorScreen({super.key, this.lessonId});

  @override
  State<LessonEditorScreen> createState() => _LessonEditorScreenState();
}

class _LessonEditorScreenState extends State<LessonEditorScreen> {
  MusicLesson lesson = MusicLesson.empty();

  final title = TextEditingController();
  final composer = TextEditingController();
  final theoryTitle = TextEditingController();
  final theoryContent = TextEditingController();
  final practiceGuide = TextEditingController();
  final lyric = TextEditingController();
  final chord = TextEditingController();

  final audioPlayer = AudioPlayer();

  Duration audioDuration = Duration.zero;
  Duration audioPosition = Duration.zero;

  bool isPlaying = false;

  PlatformFile? selectedAudioFile;

  String note = 'C4';
  String duration = 'eighth';
  double second = 0;

  final notes = [
    'C4',
    'D4',
    'E4',
    'F4',
    'F#4',
    'G4',
    'A4',
    'B4',
    'C5',
    'D5',
    'E5',
  ];

  final keySignatures = ['C Major', 'G Major', 'D Major', 'A Major', 'F Major'];

  final timeSignatures = ['2/4', '3/4', '4/4'];

  @override
  void initState() {
    super.initState();

    audioPlayer.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => audioDuration = d);
    });

    audioPlayer.onPositionChanged.listen((p) {
      if (!mounted) return;
      setState(() {
        audioPosition = p;
        second = p.inMilliseconds / 1000;
      });
    });

    audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        isPlaying = false;
        audioPosition = Duration.zero;
        second = 0;
      });
    });

    if (widget.lessonId != null) {
      Future.microtask(() async {
        final loaded = await context.read<LessonProvider>().loadLesson(
          widget.lessonId!,
        );

        if (loaded != null) {
          setLesson(loaded);
          await prepareRemoteAudio(loaded);
        }
      });
    } else {
      setLesson(lesson);
    }
  }

  Future<void> prepareRemoteAudio(MusicLesson loaded) async {
    if (loaded.audioUrl == null || loaded.audioUrl!.isEmpty) return;

    final url = '${ApiConfig.baseUrl}${loaded.audioUrl}';

    try {
      await audioPlayer.setSource(UrlSource(url));
    } catch (_) {}
  }

  void setLesson(MusicLesson l) {
    setState(() {
      lesson = l;

      title.text = l.title;
      composer.text = l.composer;
      theoryTitle.text = l.theoryTitle;
      theoryContent.text = l.theoryContent;
      practiceGuide.text = l.practiceGuide;
    });
  }

  void syncLesson() {
    lesson.title = title.text.trim();
    lesson.composer = composer.text.trim();
    lesson.theoryTitle = theoryTitle.text.trim();
    lesson.theoryContent = theoryContent.text.trim();
    lesson.practiceGuide = practiceGuide.text.trim();
  }

  void addNote() {
    if (lyric.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Hãy nhập lời hát cho nốt')));
      return;
    }

    setState(() {
      lesson.notes = [
        ...lesson.notes,
        LessonNote(
          second: second,
          note: note,
          duration: duration,
          lyric: lyric.text.trim(),
          chord: chord.text.trim(),
        ),
      ]..sort((a, b) => a.second.compareTo(b.second));

      lyric.clear();
      chord.clear();
    });
  }

  Future<void> saveAll() async {
    syncLesson();

    final p = context.read<LessonProvider>();

    final saved = await p.saveLesson(lesson);
    if (saved == null) return;

    lesson.id = saved.id;

    // XÓA TOÀN BỘ NOTE CŨ
    final deleted = await p.deleteAllNotes(saved.id!);

    if (!deleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(p.error ?? 'Không thể xoá note cũ')),
      );
      return;
    }

    // INSERT LẠI TOÀN BỘ NOTE
    final inserted = await p.addNotesOneByOne(saved.id!, lesson.notes);

    if (!mounted) return;

    if (!inserted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(p.error ?? 'Lưu note thất bại')));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu và đồng bộ toàn bộ nốt nhạc')),
    );
  }

  Future<void> uploadAudio() async {
    if (lesson.id == null) {
      await saveAll();
    }

    if (lesson.id == null) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      withData: true,
    );

    if (result == null) return;

    final file = result.files.single;

    if (file.bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không đọc được file nhạc trên Web')),
      );
      return;
    }

    selectedAudioFile = file;

    final ok = await context.read<LessonProvider>().uploadAudio(
      lesson.id!,
      file,
    );

    if (!ok) return;

    await audioPlayer.stop();
    await audioPlayer.setSource(BytesSource(file.bytes!));

    setState(() {
      isPlaying = false;
      audioPosition = Duration.zero;
      second = 0;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Đã upload nhạc nền: ${file.name}')));
  }

  Future<void> playPauseAudio() async {
    if (isPlaying) {
      await audioPlayer.pause();
      setState(() => isPlaying = false);
      return;
    }

    if (selectedAudioFile?.bytes != null) {
      await audioPlayer.play(BytesSource(selectedAudioFile!.bytes!));
      setState(() => isPlaying = true);
      return;
    }

    if (lesson.audioUrl != null && lesson.audioUrl!.isNotEmpty) {
      final url = '${ApiConfig.baseUrl}${lesson.audioUrl}';
      await audioPlayer.play(UrlSource(url));
      setState(() => isPlaying = true);
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Chưa có nhạc nền')));
  }

  Future<void> seekAudio(double value) async {
    final target = Duration(milliseconds: (value * 1000).toInt());

    await audioPlayer.seek(target);

    setState(() {
      audioPosition = target;
      second = value;
    });
  }

  String formatTime(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final ms = d.inMilliseconds.remainder(1000) ~/ 100;

    return '$m:$s.$ms';
  }

  @override
  void dispose() {
    audioPlayer.dispose();

    title.dispose();
    composer.dispose();
    theoryTitle.dispose();
    theoryContent.dispose();
    practiceGuide.dispose();
    lyric.dispose();
    chord.dispose();

    super.dispose();
  }

  Widget _buildCard(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LessonProvider>();
    final totalSeconds = audioDuration.inMilliseconds == 0
        ? 1.0
        : audioDuration.inMilliseconds / 1000;
    final currentAudioSecond = audioPosition.inMilliseconds / 1000;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Soạn bài học'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(onPressed: saveAll, icon: const Icon(Icons.save)),
          IconButton(
            onPressed: () async {
              await saveAll();
              if (lesson.id == null) return;
              await provider.publish(lesson.id!);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã lưu nốt và xuất bản bài học')),
              );
            },
            icon: const Icon(Icons.publish),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Watermark
          Positioned(
            top: 100,
            right: -100,
            child: Icon(
              Icons.edit_document,
              size: 300,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.05),
            ),
          ),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildCard('Thông tin chung', [
                TextField(
                  controller: title,
                  decoration: InputDecoration(
                    labelText: 'Tên bài',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: composer,
                  decoration: InputDecoration(
                    labelText: 'Tác giả',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: lesson.keySignature,
                        items: keySignatures
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null)
                            setState(() => lesson.keySignature = v);
                        },
                        decoration: InputDecoration(
                          labelText: 'Dấu hóa',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: lesson.timeSignature,
                        items: timeSignatures
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null)
                            setState(() => lesson.timeSignature = v);
                        },
                        decoration: InputDecoration(
                          labelText: 'Số chỉ nhịp',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ]),

              _buildCard('Lý thuyết', [
                TextField(
                  controller: theoryTitle,
                  decoration: InputDecoration(
                    labelText: 'Tiêu đề lý thuyết',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: theoryContent,
                  minLines: 3,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: 'Nội dung',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: practiceGuide,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Hướng dẫn luyện tập',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ]),

              _buildCard('Nhạc nền & Biên tập Nốt', [
                ElevatedButton.icon(
                  onPressed: uploadAudio,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload nhạc nền'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (selectedAudioFile != null)
                        Text(
                          'File đang chọn: ${selectedAudioFile!.name}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      Row(
                        children: [
                          IconButton.filled(
                            onPressed: playPauseAudio,
                            icon: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(formatTime(audioPosition)),
                          const Spacer(),
                          Text(formatTime(audioDuration)),
                        ],
                      ),
                      Slider(
                        value: currentAudioSecond.clamp(0, totalSeconds),
                        min: 0,
                        max: totalSeconds,
                        onChanged: seekAudio,
                      ),
                      Text(
                        'Giây đang chọn: ${second.toStringAsFixed(1)}s',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: note,
                        items: notes
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => note = v);
                        },
                        decoration: InputDecoration(
                          labelText: 'Nốt',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: duration,
                        items: const [
                          DropdownMenuItem(value: 'eighth', child: Text('Đơn')),
                          DropdownMenuItem(
                            value: 'quarter',
                            child: Text('Đen'),
                          ),
                          DropdownMenuItem(value: 'half', child: Text('Trắng')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => duration = v);
                        },
                        decoration: InputDecoration(
                          labelText: 'Trường độ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: chord,
                        decoration: InputDecoration(
                          labelText: 'Hợp âm',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: lyric,
                        decoration: InputDecoration(
                          labelText: 'Lời hát',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: addNote,
                    icon: const Icon(Icons.add),
                    label: Text('Thêm nốt tại ${second.toStringAsFixed(1)}s'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ]),

              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bản nhạc',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(height: 360, child: MusicStaff(lesson: lesson)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              ...lesson.notes.map(
                (n) => Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    title: Text(
                      '${n.note} - ${n.lyric}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${n.second.toStringAsFixed(1)}s | ${n.duration} | ${n.chord}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () async {
                        if (n.id != null) {
                          final ok = await context
                              .read<LessonProvider>()
                              .deleteNote(n.id!);
                          if (!ok) return;
                        }
                        setState(() => lesson.notes.remove(n));
                      },
                    ),
                    onTap: () => seekAudio(n.second),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
