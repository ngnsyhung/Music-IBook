import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Web Client ID (client_type: 3) từ google-services.json — dùng làm serverClientId
  // để Google SDK sinh ra idToken cho backend verify
  static const String googleWebClientId = '638962679580-5i797i08ere2hper6rtaooma332vfm4e.apps.googleusercontent.com';

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
