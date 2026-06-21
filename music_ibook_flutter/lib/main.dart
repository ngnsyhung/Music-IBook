import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/lesson_provider.dart';
import 'providers/student_provider.dart';
import 'providers/history_provider.dart';
import 'providers/progress_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MusicIBookApp());
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
            title: 'Music IBook',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.orange),
            routerConfig: router,
          );
        },
      ),
    );
  }
}
