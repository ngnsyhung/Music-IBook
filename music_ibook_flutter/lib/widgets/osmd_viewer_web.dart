import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

/// Web implementation: an iframe loads the same OSMD document as the native
/// WebViews. This avoids relying on an unavailable WebView plugin in browsers.
class OsmdViewer extends StatefulWidget {
  final String musicXml;
  final double playheadBeat;
  final double maxBeat;

  const OsmdViewer({
    super.key,
    required this.musicXml,
    this.playheadBeat = 1,
    this.maxBeat = 1,
  });

  @override
  State<OsmdViewer> createState() => _OsmdViewerState();
}

class _OsmdViewerState extends State<OsmdViewer> {
  late final String _viewType;
  late final html.IFrameElement _frame;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _viewType = 'music-ibook-osmd-${identityHashCode(this)}';
    _frame = html.IFrameElement()
      ..src = Uri.base.resolve('assets/assets/html/osmd_viewer.html').toString()
      ..title = 'Bản nhạc'
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.display = 'block';
    _frame.onLoad.listen((_) {
      if (!mounted) return;
      setState(() => _loaded = true);
      _sendScore();
      _sendPlayhead();
    });
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (viewId) => _frame,
    );
  }

  @override
  void didUpdateWidget(covariant OsmdViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_loaded) return;
    if (oldWidget.musicXml != widget.musicXml) _sendScore();
    if (oldWidget.playheadBeat != widget.playheadBeat ||
        oldWidget.maxBeat != widget.maxBeat) {
      _sendPlayhead();
    }
  }

  void _sendScore() => _post({'type': 'score', 'xml': widget.musicXml});

  void _sendPlayhead() => _post({
    'type': 'playhead',
    'beat': widget.playheadBeat,
    'maxBeat': widget.maxBeat,
  });

  void _post(Map<String, Object> message) {
    _frame.contentWindow?.postMessage(jsonEncode(message), '*');
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      HtmlElementView(viewType: _viewType),
      if (!_loaded)
        const ColoredBox(
          color: Color(0xFFFFFAF0),
          child: Center(child: CircularProgressIndicator()),
        ),
    ],
  );
}
