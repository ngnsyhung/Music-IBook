import 'dart:math';

import 'package:flutter/material.dart';

import '../models/lesson_authoring.dart';

/// Teacher-only authoring controls for the information a MIDI file cannot carry.
class TeacherAuthoringTools extends StatelessWidget {
  final List<LessonSection> sections;
  final List<LessonAnnotation> annotations;
  final List<LessonExercise> exercises;
  final int defaultTempo;
  final String defaultDifficulty;
  final String defaultHand;
  final double maxBeat;
  final ValueChanged<List<LessonSection>> onSectionsChanged;
  final ValueChanged<List<LessonAnnotation>> onAnnotationsChanged;
  final ValueChanged<List<LessonExercise>> onExercisesChanged;

  const TeacherAuthoringTools({
    super.key,
    required this.sections,
    required this.annotations,
    required this.exercises,
    required this.defaultTempo,
    required this.defaultDifficulty,
    required this.defaultHand,
    required this.maxBeat,
    required this.onSectionsChanged,
    required this.onAnnotationsChanged,
    required this.onExercisesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AuthoringCard(
          icon: Icons.call_split_rounded,
          title: 'Đoạn luyện tập',
          subtitle: 'Chia bài thành phần mở đầu, điệp khúc hoặc toàn bộ bài.',
          addLabel: 'Thêm đoạn',
          onAdd: () async {
            final nextOrder = sections.isEmpty
                ? 0
                : sections.map((item) => item.sortOrder).reduce(max) + 1;
            final section = await _editSection(
              context,
              initial: LessonSection(
                title: 'Bài ${sections.length + 1}',
                startBeat: 1,
                endBeat: maxBeat,
                defaultTempo: defaultTempo,
                difficulty: defaultDifficulty,
                hand: defaultHand,
                sortOrder: nextOrder,
              ),
              maxBeat: maxBeat,
            );
            if (section != null) onSectionsChanged([...sections, section]);
          },
          child: sections.isEmpty
              ? const _EmptyHint('Chưa chia đoạn. Có thể tạo “8 ô nhịp đầu”, “điệp khúc”…')
              : Column(
                  children: [
                    for (final section in [...sections]
                      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)))
                      ListTile(
                        dense: true,
                        leading: CircleAvatar(child: Text('${section.sortOrder + 1}')),
                        title: Text(section.title),
                        subtitle: Text(
                          'Beat ${_beat(section.startBeat)}–${_beat(section.endBeat)} · '
                          '${section.handLabel} · ${section.defaultTempo} BPM · ${section.difficultyLabel}',
                        ),
                        trailing: _EditDeleteButtons(
                          onEdit: () async {
                            final edited = await _editSection(
                              context,
                              initial: section,
                              maxBeat: maxBeat,
                            );
                            if (edited == null) return;
                            onSectionsChanged([
                              for (final item in sections)
                                if (identical(item, section)) edited else item,
                            ]);
                          },
                          onDelete: () => onSectionsChanged(
                            sections.where((item) => !identical(item, section)).toList(),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        _AuthoringCard(
          icon: Icons.edit_note_rounded,
          title: 'Ghi chú sư phạm & ký hiệu',
          subtitle: 'Ngón đàn, pedal, forte/piano, legato, nhấn nhịp và tempo.',
          addLabel: 'Thêm ghi chú',
          onAdd: () async {
            final annotation = await _editAnnotation(
              context,
              initial: LessonAnnotation(
                startBeat: 1,
                kind: 'TeacherNote',
                text: '',
              ),
              maxBeat: maxBeat,
            );
            if (annotation != null) {
              onAnnotationsChanged([...annotations, annotation]);
            }
          },
          child: annotations.isEmpty
              ? const _EmptyHint('Ví dụ: “Đoạn này chú ý ngón số 3” hoặc “Giữ pedal ở đây”.')
              : Column(
                  children: [
                    for (final annotation in [...annotations]
                      ..sort((a, b) => a.startBeat.compareTo(b.startBeat)))
                      ListTile(
                        dense: true,
                        leading: Icon(_annotationIcon(annotation.kind)),
                        title: Text(annotation.text),
                        subtitle: Text(
                          '${annotationLabel(annotation.kind)} · beat ${_beat(annotation.startBeat)}'
                          '${annotation.endBeat == null ? '' : '–${_beat(annotation.endBeat!)}'}',
                        ),
                        trailing: _EditDeleteButtons(
                          onEdit: () async {
                            final edited = await _editAnnotation(
                              context,
                              initial: annotation,
                              maxBeat: maxBeat,
                            );
                            if (edited == null) return;
                            onAnnotationsChanged([
                              for (final item in annotations)
                                if (identical(item, annotation)) edited else item,
                            ]);
                          },
                          onDelete: () => onAnnotationsChanged(
                            annotations
                                .where((item) => !identical(item, annotation))
                                .toList(),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        _AuthoringCard(
          icon: Icons.assignment_rounded,
          title: 'Thiết kế bài tập',
          subtitle: 'Tạo hoạt động đọc nốt, tiết tấu, hợp âm, nghe chép hoặc metronome.',
          addLabel: 'Thêm bài tập',
          onAdd: () async {
            final exercise = await _editExercise(
              context,
              initial: LessonExercise(
                title: '',
                type: 'Metronome',
                sortOrder: exercises.isEmpty
                    ? 0
                    : exercises.map((item) => item.sortOrder).reduce(max) + 1,
              ),
              sections: sections,
            );
            if (exercise != null) onExercisesChanged([...exercises, exercise]);
          },
          child: exercises.isEmpty
              ? const _EmptyHint('Bài tập sẽ được lưu kèm bài học để giao bổ sung cho học sinh.')
              : Column(
                  children: [
                    for (final exercise in [...exercises]
                      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)))
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.quiz_outlined),
                        title: Text(exercise.title),
                        subtitle: Text(
                          '${exerciseTypeLabel(exercise.type)}'
                          '${exercise.sectionSortOrder == null ? '' : ' · ${_sectionTitle(sections, exercise.sectionSortOrder!)}'}'
                          '${exercise.instruction.isEmpty ? '' : '\n${exercise.instruction}'}',
                        ),
                        isThreeLine: exercise.instruction.isNotEmpty,
                        trailing: _EditDeleteButtons(
                          onEdit: () async {
                            final edited = await _editExercise(
                              context,
                              initial: exercise,
                              sections: sections,
                            );
                            if (edited == null) return;
                            onExercisesChanged([
                              for (final item in exercises)
                                if (identical(item, exercise)) edited else item,
                            ]);
                          },
                          onDelete: () => onExercisesChanged(
                            exercises.where((item) => !identical(item, exercise)).toList(),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  static Future<LessonSection?> _editSection(
    BuildContext context, {
    required LessonSection initial,
    required double maxBeat,
  }) async {
    final title = TextEditingController(text: initial.title);
    final start = TextEditingController(text: _beat(initial.startBeat));
    final end = TextEditingController(text: _beat(initial.endBeat));
    final tempo = TextEditingController(text: initial.defaultTempo.toString());
    var difficulty = initial.difficulty;
    var hand = initial.hand;
    return showDialog<LessonSection>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Đoạn luyện tập'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: title, decoration: const InputDecoration(labelText: 'Tên đoạn')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: start, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Beat bắt đầu'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: end, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Beat kết thúc (≤ ${_beat(maxBeat)})'))),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(controller: tempo, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tốc độ mặc định (BPM)')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: difficulty,
                  decoration: const InputDecoration(labelText: 'Mức độ khó'),
                  items: difficultyOptions.map((value) => DropdownMenuItem(value: value, child: Text(difficultyLabel(value)))).toList(),
                  onChanged: (value) => setDialogState(() => difficulty = value!),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: hand,
                  decoration: const InputDecoration(labelText: 'Tay luyện tập'),
                  items: handOptions.map((value) => DropdownMenuItem(value: value, child: Text(handLabel(value)))).toList(),
                  onChanged: (value) => setDialogState(() => hand = value!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
            FilledButton(
              onPressed: () {
                final startBeat = double.tryParse(start.text.replaceAll(',', '.'));
                final endBeat = double.tryParse(end.text.replaceAll(',', '.'));
                final defaultTempo = int.tryParse(tempo.text);
                if (title.text.trim().isEmpty || startBeat == null || endBeat == null || defaultTempo == null || startBeat < 1 || endBeat < startBeat || endBeat > maxBeat || defaultTempo < 30 || defaultTempo > 300) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kiểm tra tên đoạn, phạm vi beat và BPM (30–300).')));
                  return;
                }
                Navigator.pop(dialogContext, LessonSection(
                  id: initial.id,
                  lessonId: initial.lessonId,
                  title: title.text.trim(),
                  startBeat: startBeat,
                  endBeat: endBeat,
                  defaultTempo: defaultTempo,
                  difficulty: difficulty,
                  hand: hand,
                  sortOrder: initial.sortOrder,
                ));
              },
              child: const Text('Lưu đoạn'),
            ),
          ],
        ),
      ),
    );
  }

  static Future<LessonAnnotation?> _editAnnotation(
    BuildContext context, {
    required LessonAnnotation initial,
    required double maxBeat,
  }) async {
    final text = TextEditingController(text: initial.text);
    final start = TextEditingController(text: _beat(initial.startBeat));
    final end = TextEditingController(text: initial.endBeat == null ? '' : _beat(initial.endBeat!));
    var kind = initial.kind;
    return showDialog<LessonAnnotation>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ghi chú sư phạm'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: kind,
                  decoration: const InputDecoration(labelText: 'Loại ký hiệu'),
                  items: annotationKinds.map((value) => DropdownMenuItem(value: value, child: Text(annotationLabel(value)))).toList(),
                  onChanged: (value) => setDialogState(() => kind = value!),
                ),
                const SizedBox(height: 8),
                TextField(controller: text, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Nội dung')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: start, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Beat bắt đầu'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: end, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Beat kết thúc (tùy chọn)'))),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
            FilledButton(
              onPressed: () {
                final startBeat = double.tryParse(start.text.replaceAll(',', '.'));
                final endBeat = end.text.trim().isEmpty ? null : double.tryParse(end.text.replaceAll(',', '.'));
                if (text.text.trim().isEmpty || startBeat == null || startBeat < 1 || startBeat > maxBeat || (endBeat != null && (endBeat < startBeat || endBeat > maxBeat))) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kiểm tra nội dung và phạm vi beat.')));
                  return;
                }
                Navigator.pop(dialogContext, LessonAnnotation(
                  id: initial.id,
                  lessonId: initial.lessonId,
                  startBeat: startBeat,
                  endBeat: endBeat,
                  kind: kind,
                  text: text.text.trim(),
                ));
              },
              child: const Text('Lưu ghi chú'),
            ),
          ],
        ),
      ),
    );
  }

  static Future<LessonExercise?> _editExercise(
    BuildContext context, {
    required LessonExercise initial,
    required List<LessonSection> sections,
  }) async {
    final title = TextEditingController(text: initial.title);
    final instruction = TextEditingController(text: initial.instruction);
    var type = initial.type;
    var sectionOrder = initial.sectionSortOrder;
    final sectionValues = <int?>[null, ...sections.map((item) => item.sortOrder)];
    if (!sectionValues.contains(sectionOrder)) sectionOrder = null;
    return showDialog<LessonExercise>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Thiết kế bài tập'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: title, decoration: const InputDecoration(labelText: 'Tên bài tập')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Dạng bài'),
                  items: exerciseTypes.map((value) => DropdownMenuItem(value: value, child: Text(exerciseTypeLabel(value)))).toList(),
                  onChanged: (value) => setDialogState(() => type = value!),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int?>(
                  value: sectionOrder,
                  decoration: const InputDecoration(labelText: 'Áp dụng cho đoạn'),
                  items: sectionValues.map((value) => DropdownMenuItem<int?>(value: value, child: Text(value == null ? 'Toàn bộ tác phẩm' : _sectionTitle(sections, value)))).toList(),
                  onChanged: (value) => setDialogState(() => sectionOrder = value),
                ),
                const SizedBox(height: 8),
                TextField(controller: instruction, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Yêu cầu / hướng dẫn')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
            FilledButton(
              onPressed: () {
                if (title.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nhập tên bài tập.')));
                  return;
                }
                Navigator.pop(dialogContext, LessonExercise(
                  id: initial.id,
                  lessonId: initial.lessonId,
                  lessonSectionId: initial.lessonSectionId,
                  sectionSortOrder: sectionOrder,
                  title: title.text.trim(),
                  type: type,
                  instruction: instruction.text.trim(),
                  configJson: initial.configJson,
                  sortOrder: initial.sortOrder,
                ));
              },
              child: const Text('Lưu bài tập'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthoringCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String addLabel;
  final VoidCallback onAdd;
  final Widget child;

  const _AuthoringCard({required this.icon, required this.title, required this.subtitle, required this.addLabel, required this.onAdd, required this.child});

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: ExpansionTile(
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: Text(addLabel)),
        ),
        child,
      ],
    ),
  );
}

class _EditDeleteButtons extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _EditDeleteButtons({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(tooltip: 'Sửa', onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
      IconButton(tooltip: 'Xóa', onPressed: onDelete, icon: const Icon(Icons.delete_outline)),
    ],
  );
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 8),
    child: Text(text, style: Theme.of(context).textTheme.bodySmall),
  );
}

const difficultyOptions = ['Beginner', 'Intermediate', 'Advanced'];
const handOptions = ['Both', 'Right', 'Left'];
const annotationKinds = ['Finger', 'Dynamic', 'Articulation', 'Pedal', 'Tempo', 'TeacherNote'];
const exerciseTypes = ['NoteReading', 'Rhythm', 'MissingNote', 'ChordRecognition', 'Dictation', 'Metronome'];

String difficultyLabel(String value) => switch (value) {
  'Intermediate' => 'Trung bình',
  'Advanced' => 'Nâng cao',
  _ => 'Cơ bản',
};

String handLabel(String value) => switch (value) {
  'Right' => 'Tay phải',
  'Left' => 'Tay trái',
  _ => 'Hai tay',
};

String annotationLabel(String value) => switch (value) {
  'Finger' => 'Ngón đàn',
  'Dynamic' => 'Cường độ (p/f)',
  'Articulation' => 'Liền tiếng / legato',
  'Pedal' => 'Pedal',
  'Tempo' => 'Tốc độ',
  _ => 'Ghi chú giáo viên',
};

IconData _annotationIcon(String value) => switch (value) {
  'Finger' => Icons.back_hand_outlined,
  'Dynamic' => Icons.volume_up_outlined,
  'Articulation' => Icons.gesture_outlined,
  'Pedal' => Icons.pedal_bike_outlined,
  'Tempo' => Icons.speed_outlined,
  _ => Icons.sticky_note_2_outlined,
};

String exerciseTypeLabel(String value) => switch (value) {
  'NoteReading' => 'Luyện đọc nốt',
  'Rhythm' => 'Luyện tiết tấu',
  'MissingNote' => 'Điền nốt còn thiếu',
  'ChordRecognition' => 'Nhận diện hợp âm',
  'Dictation' => 'Nghe rồi chép nhạc',
  _ => 'Chơi cùng metronome',
};

String _sectionTitle(List<LessonSection> sections, int order) => sections
    .where((item) => item.sortOrder == order)
    .map((item) => item.title)
    .firstOrNull ?? 'Đoạn đã xóa';

String _beat(double value) => value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);

extension on Iterable<String> {
  String? get firstOrNull => isEmpty ? null : first;
}

extension on LessonSection {
  String get difficultyLabel => difficultyLabelForValue(difficulty);
  String get handLabel => handLabelForValue(hand);
}

String difficultyLabelForValue(String value) => difficultyLabel(value);
String handLabelForValue(String value) => handLabel(value);
