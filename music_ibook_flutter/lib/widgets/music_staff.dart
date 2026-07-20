import 'dart:math';

import 'package:flutter/material.dart';

import '../models/lesson.dart';
import '../services/score_engraving_service.dart';
import '../utils/music_xml_generator.dart';
import 'engraved_score.dart';
import 'osmd_viewer.dart';

/// Read-only score used by lesson, exam and practice screens.
///
/// Read-only lesson pages use the exact same MusicXML + OSMD pipeline as the
/// teacher editor. Interactive exam overlays keep the canvas renderer because
/// they need per-note hit geometry and 60 fps feedback.
class MusicStaff extends StatefulWidget {
  final MusicLesson lesson;
  final int? highlightIndex;
  final double? countdownSeconds;
  final bool wasCorrect;
  final ValueNotifier<double>? elapsedNotifier;
  final bool showTimeline;

  const MusicStaff({
    super.key,
    required this.lesson,
    this.highlightIndex,
    this.countdownSeconds,
    this.wasCorrect = false,
    this.elapsedNotifier,
    this.showTimeline = false,
  });

  @override
  State<MusicStaff> createState() => _MusicStaffState();
}

class _MusicStaffState extends State<MusicStaff> with TickerProviderStateMixin {
  final ScrollController _verticalController = ScrollController();
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;
  EngravedScoreLayout? _lastLayout;
  String? _cachedMusicXml;
  int? _cachedMusicXmlHash;

  bool get _needsInteractiveOverlay =>
      widget.highlightIndex != null ||
      widget.countdownSeconds != null ||
      widget.elapsedNotifier != null ||
      widget.showTimeline;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (_needsInteractiveOverlay) {
      _glowController.repeat(reverse: true);
    }
    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(covariant MusicStaff oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldNeedsInteractiveOverlay =
        oldWidget.highlightIndex != null ||
        oldWidget.countdownSeconds != null ||
        oldWidget.elapsedNotifier != null ||
        oldWidget.showTimeline;
    if (_needsInteractiveOverlay != oldNeedsInteractiveOverlay) {
      if (_needsInteractiveOverlay) {
        _glowController.repeat(reverse: true);
      } else {
        _glowController.stop();
      }
    }
    if (widget.highlightIndex != oldWidget.highlightIndex &&
        widget.highlightIndex != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToHighlight();
      });
    }
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _scrollToHighlight() {
    final index = widget.highlightIndex;
    final layout = _lastLayout;
    if (index == null ||
        layout == null ||
        index >= widget.lesson.notes.length) {
      return;
    }
    final systemIndex = layout.systemForBeat(
      widget.lesson.notes[index].startBeat,
    );
    final systemTop = layout.systems[systemIndex].top;
    final screenHeight = MediaQuery.sizeOf(context).height;
    var target = max(0.0, systemTop - screenHeight / 3);
    if (!_verticalController.hasClients) return;
    target = min(target, _verticalController.position.maxScrollExtent);
    _verticalController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_needsInteractiveOverlay) {
      final lesson = widget.lesson;
      final xmlHash = Object.hashAll([
        lesson.title,
        lesson.composer,
        lesson.keySignature,
        lesson.timeSignature,
        lesson.timeSignatureMap,
        lesson.tempo,
        lesson.tempoMap,
        ...lesson.notes.map(
          (note) => Object.hash(
            note.note,
            note.startBeat,
            note.durationBeat,
            note.track,
            note.trackName,
            note.staff,
            note.voice,
            note.lyric,
            note.chord,
            note.fingering,
          ),
        ),
        ...lesson.annotations.map(
          (annotation) => Object.hash(
            annotation.startBeat,
            annotation.endBeat,
            annotation.kind,
            annotation.text,
          ),
        ),
      ]);
      if (_cachedMusicXmlHash != xmlHash) {
        _cachedMusicXmlHash = xmlHash;
        _cachedMusicXml = MusicXmlGenerator.generate(
          lesson.notes,
          title: lesson.title,
          composer: lesson.composer,
          timeSignature: lesson.timeSignature,
          timeSignatureMap: lesson.timeSignatureMap,
          keySignature: lesson.keySignature,
          tempo: lesson.tempo,
          tempoMap: lesson.tempoMap,
          annotations: lesson.annotations,
        );
      }
      final maxBeat = lesson.notes.isEmpty
          ? 1.0
          : lesson.notes
                .map((note) => note.startBeat + note.durationBeat)
                .reduce(max);
      return OsmdViewer(musicXml: _cachedMusicXml!, maxBeat: maxBeat);
    }

    return ColoredBox(
      color: const Color(0xFFFFF6E6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final canvasWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          final layout = ScoreEngravingService.layout(
            notes: widget.lesson.notes,
            width: canvasWidth,
            timeSignature: widget.lesson.timeSignature,
            timeSignatureMap: widget.lesson.timeSignatureMap,
            keySignature: widget.lesson.keySignature,
            style: const EngravingStyle(
              pageTop: 150,
              pageLeft: 40,
              pageRight: 32,
              systemHeaderWidth: 142,
              systemHeight: 270,
              staffSpace: 11,
              grandStaffDistance: 104,
              minimumMeasureWidth: 108,
              minimumSliceWidth: 21,
            ),
          );
          _lastLayout = layout;
          final contentHeight = max(
            constraints.maxHeight.isFinite ? constraints.maxHeight : 500.0,
            max(500.0, layout.height),
          );

          return SingleChildScrollView(
            controller: _verticalController,
            child: SizedBox(
              width: canvasWidth,
              height: contentHeight,
              child: Stack(
                children: [
                  RepaintBoundary(
                    child: CustomPaint(
                      size: Size(canvasWidth, contentHeight),
                      painter: EngravedScorePainter(
                        layout: layout,
                        tempo: widget.lesson.tempo,
                        title: widget.lesson.title,
                        composer: widget.lesson.composer,
                        backgroundColor: const Color(0xFFFFF6E6),
                        scrollController: _verticalController,
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) => CustomPaint(
                      size: Size(canvasWidth, contentHeight),
                      painter: EngravedScoreOverlayPainter(
                        layout: layout,
                        notes: widget.lesson.notes,
                        highlightIndex: widget.highlightIndex,
                        countdownSeconds: widget.countdownSeconds,
                        glowProgress: _glowAnimation.value,
                        elapsedNotifier: widget.elapsedNotifier,
                        showTimeline: widget.showTimeline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
