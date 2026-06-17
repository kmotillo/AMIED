import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/course_repository.dart';
import '../providers/progress_providers.dart';
import '../../domain/course.dart';

class MyCoursesScreen extends ConsumerWidget {
  const MyCoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsyncValue = ref.watch(publishedCoursesProvider);
    final enrolledCoursesAsyncValue = ref.watch(enrolledCoursesProvider);
    final completedLessonsList = ref.watch(completedLessonsProvider).value ?? [];
    final passedModulesMap = ref.watch(passedModulesWithQuizzesProvider).value ?? {};
    final completedCourses = ref.watch(completedCoursesProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Cursos', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: coursesAsyncValue.when(
        data: (allCourses) {
          return enrolledCoursesAsyncValue.when(
            data: (enrolledCourseIds) {
              final myCourses = allCourses.where((c) => enrolledCourseIds.contains(c.id)).toList();

              if (myCourses.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text(
                        'Aún no te has matriculado en ningún curso.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(publishedCoursesProvider);
                  ref.invalidate(enrolledCoursesProvider);
                  await ref.read(publishedCoursesProvider.future);
                  await ref.read(enrolledCoursesProvider.future);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: myCourses.length,
                  itemBuilder: (context, index) {
                    final course = myCourses[index];
                    final isCourseCompleted = completedCourses.contains(course.id);
                    
                    int totalItems = 0;
                    int completedItems = 0;
                    if (course.modules != null) {
                      for (var module in course.modules!) {
                        totalItems += module.lessons.length;
                        if (module.hasQuiz) totalItems++;
                        
                        for (var lesson in module.lessons) {
                          if (completedLessonsList.contains(lesson.id)) {
                            completedItems++;
                          }
                        }
                        if (module.hasQuiz && passedModulesMap.containsKey(module.id)) {
                          completedItems++;
                        }
                      }
                    }
                    
                    final double progress = totalItems == 0 ? 0 : completedItems / totalItems;

                    return _buildCourseCard(context, course, progress, isCourseCompleted, ref);
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text('Error al cargar cursos: $error', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(publishedCoursesProvider);
                    ref.invalidate(enrolledCoursesProvider);
                  },
                  child: const Text('Reintentar'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course, double progress, bool isCourseCompleted, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          context.push('/courses/${course.id}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              width: 100,
              height: 130,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
              ),
              child: const Center(
                child: Icon(Icons.menu_book, size: 45, color: AppColors.primary),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCourseCompleted
                            ? Colors.green.withValues(alpha: 0.15)
                            : (progress == 1.0 ? Colors.amber.withValues(alpha: 0.3) : AppColors.secondary.withValues(alpha: 0.15)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isCourseCompleted 
                            ? 'Completado' 
                            : (progress == 1.0 ? '¡Listo para Reclamar!' : 'En Progreso'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isCourseCompleted
                              ? Colors.green 
                              : (progress == 1.0 ? Colors.amber.shade900 : AppColors.secondary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      course.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text('${course.estimatedHours ?? 0} horas', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (!isCourseCompleted && progress == 1.0)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            textStyle: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            context.push('/courses/${course.id}');
                          },
                          child: const Text('¡Reclamar Medalla!'),
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.grey[200],
                                color: isCourseCompleted ? Colors.green : AppColors.primary,
                                minHeight: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isCourseCompleted ? Colors.green : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
