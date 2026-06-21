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

  const LessonEditorScreen({
    super.key,
    this.lessonId,
  });

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

  final keySignatures = [
    'C Major',
    'G Major',
    'D Major',
    'A Major',
    'F Major',
  ];

  final timeSignatures = [
    '2/4',
    '3/4',
    '4/4',
  ];

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
        final loaded =
        await context.read<LessonProvider>().loadLesson(widget.lessonId!);

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy nhập lời hát cho nốt')),
      );
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
    final inserted =
    await p.addNotesOneByOne(saved.id!, lesson.notes);

    if (!mounted) return;

    if (!inserted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(p.error ?? 'Lưu note thất bại')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu và đồng bộ toàn bộ nốt nhạc'),
      ),
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã upload nhạc nền: ${file.name}')),
    );
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chưa có nhạc nền')),
    );
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
        actions: [
          IconButton(
            onPressed: saveAll,
            icon: const Icon(Icons.save),
          ),
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: title,
            decoration: const InputDecoration(labelText: 'Tên bài'),
          ),
          TextField(
            controller: composer,
            decoration: const InputDecoration(labelText: 'Tác giả'),
          ),
          DropdownButtonFormField<String>(
            value: lesson.keySignature,
            items: keySignatures.map((e) {
              return DropdownMenuItem(
                value: e,
                child: Text(e),
              );
            }).toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() => lesson.keySignature = v);
            },
            decoration: const InputDecoration(
              labelText: 'Dấu hóa / Giọng',
            ),
          ),
          DropdownButtonFormField<String>(
            value: lesson.timeSignature,
            items: timeSignatures.map((e) {
              return DropdownMenuItem(
                value: e,
                child: Text(e),
              );
            }).toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() => lesson.timeSignature = v);
            },
            decoration: const InputDecoration(
              labelText: 'Số chỉ nhịp',
            ),
          ),
          const SizedBox(height: 16),
          ExpansionTile(
            title: const Text('Lý thuyết'),
            initiallyExpanded: true,
            children: [
              TextField(
                controller: theoryTitle,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề lý thuyết',
                ),
              ),
              TextField(
                controller: theoryContent,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Nội dung lý thuyết',
                ),
              ),
              TextField(
                controller: practiceGuide,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Hướng dẫn luyện tập',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: uploadAudio,
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload nhạc nền'),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF6E6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.brown),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nhạc nền & chọn thời điểm',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
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
          const Divider(height: 32),
          Text(
            'Giây thêm nốt: ${second.toStringAsFixed(1)}s',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          DropdownButtonFormField<String>(
            value: note,
            items: notes.map((e) {
              return DropdownMenuItem(
                value: e,
                child: Text(e),
              );
            }).toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() => note = v);
            },
            decoration: const InputDecoration(labelText: 'Nốt'),
          ),
          DropdownButtonFormField<String>(
            value: duration,
            items: const [
              DropdownMenuItem(
                value: 'eighth',
                child: Text('Nốt móc đơn'),
              ),
              DropdownMenuItem(
                value: 'quarter',
                child: Text('Nốt đen'),
              ),
              DropdownMenuItem(
                value: 'half',
                child: Text('Nốt trắng'),
              ),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => duration = v);
            },
            decoration: const InputDecoration(labelText: 'Trường độ'),
          ),
          TextField(
            controller: chord,
            decoration: const InputDecoration(labelText: 'Hợp âm'),
          ),
          TextField(
            controller: lyric,
            decoration: const InputDecoration(labelText: 'Lời hát'),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: addNote,
            icon: const Icon(Icons.add),
            label: Text(
              'Thêm nốt tại ${second.toStringAsFixed(1)}s',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 360,
            child: MusicStaff(lesson: lesson),
          ),
          const SizedBox(height: 16),
          ...lesson.notes.map(
                (n) => Card(
              child: ListTile(
                title: Text('${n.note} - ${n.lyric}'),
                subtitle: Text(
                  '${n.second.toStringAsFixed(1)}s | ${n.duration} | ${n.chord}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    if (n.id != null) {
                      final ok = await context
                          .read<LessonProvider>()
                          .deleteNote(n.id!);

                      if (!ok) return;
                    }

                    setState(() {
                      lesson.notes.remove(n);
                    });
                  },
                ),
                onTap: () {
                  seekAudio(n.second);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}