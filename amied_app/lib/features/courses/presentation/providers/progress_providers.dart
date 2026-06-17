import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/progress_repository.dart';

// Estado de inscripción de un curso específico
final isEnrolledProvider = FutureProvider.autoDispose.family<bool, String>((ref, courseId) async {
  final repository = ref.watch(progressRepositoryProvider);
  return repository.isEnrolled(courseId);
});

// Lista de IDs de cursos matriculados por el usuario
final enrolledCoursesProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final repository = ref.watch(progressRepositoryProvider);
  return repository.getEnrolledCourses();
});

// Lista de IDs de cursos completados por el usuario
final completedCoursesProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final repository = ref.watch(progressRepositoryProvider);
  return repository.getCompletedCourses();
});

// Lista de IDs de lecciones completadas por el usuario
final completedLessonsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final repository = ref.watch(progressRepositoryProvider);
  // Aquí podríamos pasar el courseId si lo requerimos, pero el repositorio actual
  // trae todas las lecciones del usuario para simplificar.
  return repository.getCompletedLessons('');
});

// Lista de IDs de módulos donde el usuario ya aprobó la evaluación, junto con su puntaje
final passedModulesWithQuizzesProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final repository = ref.watch(progressRepositoryProvider);
  return repository.getPassedModulesWithQuizzes();
});

// Notifier para manejar acciones de progreso sin UI blocking
final progressControllerProvider = NotifierProvider<ProgressController, AsyncValue<void>>(() {
  return ProgressController();
});

class ProgressController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<bool> enrollCourse(String courseId) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(progressRepositoryProvider);
      await repository.enrollInCourse(courseId);
      state = const AsyncValue.data(null);
      
      // Invalida para que la UI se actualice
      ref.invalidate(isEnrolledProvider(courseId));
      ref.invalidate(enrolledCoursesProvider);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> claimCourseMedal(String courseId) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(progressRepositoryProvider);
      await repository.markCourseCompleted(courseId);
      state = const AsyncValue.data(null);
      
      // Invalida para que la UI se actualice
      ref.invalidate(completedCoursesProvider);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> markLessonCompleted(String lessonId) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(progressRepositoryProvider);
      await repository.markLessonCompleted(lessonId);
      state = const AsyncValue.data(null);
      
      // Invalida para que la UI se actualice
      ref.invalidate(completedLessonsProvider);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}
