import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_router.dart';
import 'core/error_handler.dart';
import 'providers/auth_provider.dart';
import 'providers/lesson_provider.dart';
import 'providers/student_provider.dart';
import 'providers/history_provider.dart';
import 'providers/progress_provider.dart';
import 'core/theme.dart';

void main() {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      GlobalErrorHandler.init();
      runApp(const MusicIBookApp());
    },
    (error, stack) {
      // Unhandled async errors outside Flutter framework
      debugPrint('Uncaught error in runZonedGuarded: $error');
    },
  );
}

class MusicIBookApp extends StatelessWidget {
  const MusicIBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..loadUser()),
        ChangeNotifierProvider(create: (_) => LessonProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final router = buildRouter(auth);
          return MaterialApp.router(
            scaffoldMessengerKey: globalMessengerKey,
            title: 'Music IBook',
            debugShowCheckedModeBanner: false,
            theme: MusicAppTheme.lightTheme,
            darkTheme: MusicAppTheme.darkTheme,
            themeMode: ThemeMode.system,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
