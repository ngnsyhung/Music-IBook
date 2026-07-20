import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Android emulator: http://10.0.2.2:5238
  // Edge/Web local: http://localhost:5238
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5238';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:5238';
      }
    } catch (_) {
      // Safety fallback if Platform check throws
    }
    return 'http://localhost:5238';
  }
}
