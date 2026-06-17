import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/course_repository.dart';
import '../providers/progress_providers.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'course_completed_screen.dart';

class CourseDetailScreen extends ConsumerWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseAsyncValue = ref.watch(courseDetailsProvider(courseId));
    final isEnrolledAsync = ref.watch(isEnrolledProvider(courseId));
    final completedCoursesAsync = ref.watch(completedCoursesProvider);
    final completedLessonsAsync = ref.watch(completedLessonsProvider);
    final passedModulesAsync = ref.watch(passedModulesWithQuizzesProvider);
    final progressState = ref.watch(progressControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detalles del Curso',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: courseAsyncValue.when(
        data: (course) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(courseDetailsProvider(courseId));
              await ref.read(courseDetailsProvider(courseId).future);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cabecera del curso
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.school, size: 70, color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        course.title,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      MarkdownBody(
                        data: course.description ?? 'Sin descripción',
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(fontSize: 16, color: Colors.white70),
                          h1: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                          h2: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                          h3: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                          listBullet: const TextStyle(color: Colors.white70),
                          strong: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          em: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              '${course.estimatedHours ?? 0} horas estimadas',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Módulos
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Temario del Curso',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (course.modules == null || course.modules!.isEmpty)
                        const Text(
                          'Este curso aún no tiene módulos publicados.',
                        )
                      else
                        ExpansionPanelList.radio(
                          elevation: 1,
                          children: course.modules!.map((module) {
                            return ExpansionPanelRadio(
                              value: module.id,
                              canTapOnHeader: true,
                              headerBuilder: (context, isExpanded) {
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.secondary
                                        .withValues(alpha: 0.2),
                                    child: const Icon(
                                      Icons.menu_book,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                  title: Text(
                                    module.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                              body: Column(
                                children: [
                                  ...module.lessons.map((lesson) {
                                    return ListTile(
                                      leading: const Icon(
                                        Icons.play_circle_outline,
                                        color: AppColors.primary,
                                      ),
                                      title: Text(lesson.title),
                                      trailing: completedLessonsAsync.maybeWhen(
                                        data: (completed) =>
                                            completed.contains(lesson.id)
                                                ? const Icon(
                                                    Icons.check_circle,
                                                    color: Colors.green,
                                                  )
                                                : null,
                                        orElse: () => null,
                                      ),
                                      onTap: () {
                                        context.push(
                                          '/lesson/${course.id}',
                                          extra: lesson,
                                        );
                                      },
                                    );
                                  }),
                                  if (module.hasQuiz)
                                    ListTile(
                                      leading: const Icon(
                                        Icons.assignment,
                                        color: AppColors.secondary,
                                      ),
                                      title: const Text(
                                        'Tomar Evaluación',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.secondary,
                                        ),
                                      ),
                                      trailing: passedModulesAsync.maybeWhen(
                                        data: (passedModulesMap) {
                                          if (passedModulesMap.containsKey(
                                            module.id,
                                          )) {
                                            return Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  '${passedModulesMap[module.id]}%',
                                                  style: const TextStyle(
                                                    color: Colors.green,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                const Icon(
                                                  Icons.check_circle,
                                                  color: Colors.green,
                                                ),
                                              ],
                                            );
                                          }
                                          return null;
                                        },
                                        orElse: () => null,
                                      ),
                                      onTap: () {
                                        context.push('/quiz/${course.id}/${module.id}');
                                      },
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar curso: $error',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/ai-tutor'),
        backgroundColor: AppColors.primary,
        tooltip: 'Tutor Virtual',
        child: const Icon(Icons.psychology, color: Colors.white),
      ),
      bottomNavigationBar: isEnrolledAsync.when(
        data: (isEnrolled) {
          if (!isEnrolled) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: progressState.isLoading
                      ? null
                      : () async {
                          final success = await ref
                              .read(progressControllerProvider.notifier)
                              .enrollCourse(courseId);
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('¡Te has inscrito correctamente!'),
                              ),
                            );
                          }
                        },
                  child: progressState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Inscribirme y Empezar'),
                ),
              ),
            );
          }

          // Si está matriculado, verificar si el curso ya fue completado
          final completedCourses = completedCoursesAsync.value ?? [];
          final isCourseCompleted = completedCourses.contains(courseId);

          if (isCourseCompleted) {
            return SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                color: Colors.green.withValues(alpha: 0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                    SizedBox(width: 8),
                    Text(
                      '¡Curso Completado!',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Verificar si todas las lecciones están leídas y si todos los quizzes están aprobados
          bool allLessonsCompleted = true;
          bool allQuizzesPassed = true;

          final completedLessonsList = completedLessonsAsync.value ?? [];
          final passedModulesMap = passedModulesAsync.value ?? {};

          courseAsyncValue.whenData((course) {
            for (var module in course.modules ?? []) {
              // 1. Validar Lecciones
              for (var lesson in module.lessons) {
                if (!completedLessonsList.contains(lesson.id)) {
                  allLessonsCompleted = false;
                  break;
                }
              }
              // 2. Validar Quizzes si el módulo tiene uno
              if (module.hasQuiz) {
                if (!passedModulesMap.containsKey(module.id)) {
                  allQuizzesPassed = false;
                }
              }
            }
          });

          final canClaimMedal = allLessonsCompleted && allQuizzesPassed;

          if (canClaimMedal) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.stars),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 4,
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: progressState.isLoading
                      ? null
                      : () async {
                          final success = await ref
                              .read(progressControllerProvider.notifier)
                              .claimCourseMedal(courseId);

                          if (success && context.mounted) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const CourseCompletedScreen(),
                                fullscreenDialog: true,
                              ),
                            );
                          }
                        },
                  label: progressState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.black87,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('¡Reclamar Medalla!'),
                ),
              ),
            );
          }

          // Si está inscrito pero no ha terminado todo
          return const SizedBox.shrink();
        },
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
      ),
    );
  }
}
