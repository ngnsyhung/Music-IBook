import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart' as mobile_webview;
import 'package:webview_windows/webview_windows.dart' as windows_webview;

/// Hosts OSMD in the platform WebView. The HTML document owns score layout and
/// scrolling, keeping large SVG renders outside Flutter's UI isolate.
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
  windows_webview.WebviewController? _windowsController;
  mobile_webview.WebViewController? _mobileController;
  String? _error;
  bool _documentLoaded = false;
  bool _htmlReady = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(covariant OsmdViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.musicXml != widget.musicXml) _loadMusicXml();
    if (oldWidget.playheadBeat != widget.playheadBeat ||
        oldWidget.maxBeat != widget.maxBeat) {
      _updatePlayhead();
    }
  }

  Future<void> _initialize() async {
    try {
      final html = await rootBundle.loadString('assets/html/osmd_viewer.html');
      if (!kIsWeb && Platform.isWindows) {
        final controller = windows_webview.WebviewController();
        _windowsController = controller;
        controller.webMessage.listen((message) => _handleMessage('$message'));
        await controller.initialize();
        await controller.loadStringContent(html);
      } else if (!kIsWeb) {
        final controller = mobile_webview.WebViewController()
          ..setJavaScriptMode(mobile_webview.JavaScriptMode.unrestricted)
          ..addJavaScriptChannel(
            'FlutterOSMD',
            onMessageReceived: (message) => _handleMessage(message.message),
          );
        _mobileController = controller;
        await controller.loadHtmlString(html);
      }
      if (!mounted) return;
      setState(() => _documentLoaded = true);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  void _handleMessage(String message) {
    if (!mounted) return;
    if (message.startsWith('Error:')) {
      setState(() => _error = message.substring('Error:'.length).trim());
      return;
    }
    if (message == 'Ready') {
      setState(() => _htmlReady = true);
      _loadMusicXml();
      _updatePlayhead();
    }
  }

  void _loadMusicXml() {
    if (!_documentLoaded || !_htmlReady) return;
    final encodedXml = base64Encode(utf8.encode(widget.musicXml));
    final script = 'loadMusicXmlFromBase64(${jsonEncode(encodedXml)});';
    _windowsController?.executeScript(script);
    _mobileController?.runJavaScript(script);
  }

  void _updatePlayhead() {
    if (!_documentLoaded || !_htmlReady) return;
    final script =
        'setPlayheadBeat(${widget.playheadBeat.toStringAsFixed(4)}, ${widget.maxBeat.toStringAsFixed(4)});';
    _windowsController?.executeScript(script);
    _mobileController?.runJavaScript(script);
  }

  @override
  void dispose() {
    _windowsController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _MessagePanel(
        icon: Icons.music_note_outlined,
        text: 'Không thể dựng bản nhạc: $_error',
      );
    }
    if (!_documentLoaded || !_htmlReady) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!kIsWeb && Platform.isWindows && _windowsController != null) {
      return windows_webview.Webview(_windowsController!);
    }
    if (!kIsWeb && _mobileController != null) {
      return mobile_webview.WebViewWidget(controller: _mobileController!);
    }
    return const _MessagePanel(
      icon: Icons.desktop_windows_outlined,
      text: 'Thiết bị này chưa hỗ trợ trình dựng khuông nhạc.',
    );
  }
}

class _MessagePanel extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MessagePanel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32),
          const SizedBox(height: 8),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
