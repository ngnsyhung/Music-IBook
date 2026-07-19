import 'dart:math';

import 'package:flutter/material.dart';

import '../models/lesson.dart';
import '../services/score_engraving_service.dart';
import 'engraved_score.dart';

/// Read-only score used by lesson, exam and practice screens.
///
/// The same engraving model is also used by the teacher editor, so an imported
/// MIDI keeps identical measure breaks, spacing, staves and accidentals after it
/// is saved and opened by a student.
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

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(covariant MusicStaff oldWidget) {
    super.didUpdateWidget(oldWidget);
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
