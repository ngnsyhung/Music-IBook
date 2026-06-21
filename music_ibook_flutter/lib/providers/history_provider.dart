import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../models/practice.dart';
import '../services/history_service.dart';

class HistoryProvider extends ChangeNotifier {
  final _service = HistoryService();

  bool loading = false;
  String? error;
  List<PracticeSession> history = [];

  Future<void> loadHistory() async {
    loading = true;
    notifyListeners();
    try {
      history = await _service.getPracticeHistory();
      error = null;
    } catch (e) {
      error = ApiClient.errorMessage(e);
    }
    loading = false;
    notifyListeners();
  }
}
