import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/teacher/teacher_dashboard.dart';
import '../screens/teacher/lesson_editor_screen.dart';
import '../screens/teacher/progress/student_detail_screen.dart';
import '../screens/student/student_home.dart';
import '../screens/student/lesson_detail_screen.dart';
import '../screens/student/practice/practice_screen.dart';
import '../screens/student/exam/exam_screen.dart';
import '../screens/student/history/history_screen.dart';

GoRouter buildRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: auth,
    redirect: (context, state) {
      final loggedIn = auth.isLoggedIn;
      final path = state.uri.path;
      final isAuthPage = path == '/login' ||
          path == '/register' ||
          path == '/forgot-password' ||
          path == '/reset-password';

      if (!loggedIn && !isAuthPage) return '/login';
      if (loggedIn && isAuthPage) {
        return auth.role == 'Teacher' ? '/teacher' : '/student';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: '/reset-password', builder: (_, state) {
        final token = state.uri.queryParameters['token'] ?? '';
        return ResetPasswordScreen(token: token);
      }),
      GoRoute(path: '/teacher', builder: (_, __) => const TeacherDashboard()),
      GoRoute(path: '/teacher/lesson/new', builder: (_, __) => const LessonEditorScreen()),
      GoRoute(path: '/teacher/lesson/:id', builder: (_, state) {
        final id = int.parse(state.pathParameters['id']!);
        return LessonEditorScreen(lessonId: id);
      }),
      GoRoute(path: '/teacher/student/:id', builder: (_, state) {
        final id = int.parse(state.pathParameters['id']!);
        return StudentDetailScreen(studentId: id);
      }),
      GoRoute(path: '/student', builder: (_, __) => const StudentHome()),
      GoRoute(path: '/student/lesson/:id', builder: (_, state) {
        final id = int.parse(state.pathParameters['id']!);
        return LessonDetailScreen(lessonId: id);
      }),
      GoRoute(path: '/student/practice/:id', builder: (_, state) {
        final id = int.parse(state.pathParameters['id']!);
        return PracticeScreen(lessonId: id);
      }),
      GoRoute(path: '/student/exam/:id', builder: (_, state) {
        final id = int.parse(state.pathParameters['id']!);
        return ExamScreen(lessonId: id);
      }),
      GoRoute(path: '/student/history', builder: (_, __) => const HistoryScreen()),
    ],
  );
}
