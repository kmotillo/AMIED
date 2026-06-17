import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/onboarding/presentation/welcome_screen.dart';
import '../../main.dart';

import '../../features/admin/presentation/screens/admin_layout_screen.dart';
import '../../features/admin/presentation/screens/admin_courses_screen.dart';
import '../../features/admin/presentation/screens/course_editor_screen.dart';
import '../../features/admin/presentation/screens/lesson_editor_screen.dart';
import '../../features/admin/presentation/screens/admin_users_screen.dart';
import '../../features/admin/presentation/screens/quiz_editor_screen.dart';
import '../../features/gamification/presentation/screens/main_layout_screen.dart';
import '../../features/courses/presentation/screens/courses_catalog_screen.dart';
import '../../features/courses/presentation/screens/course_detail_screen.dart';
import '../../features/courses/presentation/screens/lesson_screen.dart';
import '../../features/courses/presentation/screens/quiz_screen.dart';
import '../../features/courses/domain/lesson.dart';
import '../../features/ai_tutor/presentation/ai_tutor_screen.dart';
final appRouterProvider = Provider<GoRouter>((ref) {
  // authState se puede usar para recargar el router si cambia, pero aquí usamos currentSession
  ref.watch(authStateChangesProvider);
  final prefs = ref.watch(sharedPreferencesProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final hasSeenWelcome = prefs.getBool('has_seen_welcome') ?? false;
      // Usar Supabase currentSession para verificación síncrona
      final session = Supabase.instance.client.auth.currentSession;
      final isAuth = session != null;
      final isLoggingIn = state.matchedLocation == '/login';
      final isWelcome = state.matchedLocation == '/welcome';

      if (!hasSeenWelcome && !isWelcome) {
        return '/welcome';
      }
      
      if (hasSeenWelcome && isWelcome) {
        return isAuth ? '/' : '/login';
      }

      if (!isAuth && !isLoggingIn && hasSeenWelcome) {
        return '/login';
      }
      if (isAuth && isLoggingIn) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const MainLayoutScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/courses',
        builder: (context, state) => const CoursesCatalogScreen(),
      ),
      GoRoute(
        path: '/dev-courses',
        builder: (context, state) => const CoursesCatalogScreen(showUnpublished: true),
      ),
      GoRoute(
        path: '/courses/:id',
        builder: (context, state) {
          final courseId = state.pathParameters['id']!;
          return CourseDetailScreen(courseId: courseId);
        },
      ),
      GoRoute(
        path: '/lesson/:courseId',
        builder: (context, state) {
          final lesson = state.extra as Lesson;
          return LessonScreen(
            courseId: state.pathParameters['courseId']!,
            lesson: lesson,
          );
        },
      ),
      GoRoute(
        path: '/quiz/:courseId/:moduleId',
        builder: (context, state) => QuizScreen(
          courseId: state.pathParameters['courseId']!,
          moduleId: state.pathParameters['moduleId']!,
        ),
      ),
      // --- ADMINISTRACIÓN ---
      ShellRoute(
        builder: (context, state, child) {
          return AdminLayoutScreen(child: child);
        },
        routes: [
          GoRoute(
            path: '/admin/courses',
            builder: (context, state) => const AdminCoursesScreen(),
          ),
          GoRoute(
            path: '/admin/courses/new',
            builder: (context, state) => const CourseEditorScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (context, state) => const AdminUsersScreen(),
          ),
          GoRoute(
            path: '/admin/courses/:id',
            builder: (context, state) => CourseEditorScreen(courseId: state.pathParameters['id']),
          ),
          GoRoute(
            path: '/admin/lesson-editor',
            builder: (context, state) => const LessonEditorScreen(), // Ruta para pruebas del editor markdown
          ),
          GoRoute(
            path: '/admin/quiz/:moduleId',
            builder: (context, state) => QuizEditorScreen(moduleId: state.pathParameters['moduleId']!),
          ),
        ],
      ),
      GoRoute(
        path: '/ai-tutor',
        builder: (context, state) => const AiTutorScreen(),
      ),
    ],
  );
});
