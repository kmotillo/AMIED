import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/course_repository.dart';
import '../providers/progress_providers.dart';
import '../../domain/course.dart';

class CoursesCatalogScreen extends ConsumerWidget {
  final bool showUnpublished;
  
  const CoursesCatalogScreen({
    super.key, 
    this.showUnpublished = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = showUnpublished ? unpublishedCoursesProvider : publishedCoursesProvider;
    final coursesAsyncValue = ref.watch(provider);
    final completedLessonsList = ref.watch(completedLessonsProvider).value ?? [];
    final passedModulesMap = ref.watch(passedModulesWithQuizzesProvider).value ?? {};

    return Scaffold(

      appBar: AppBar(
        title: Text(showUnpublished ? 'Cursos en Desarrollo' : 'Catálogo de Cursos', style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: coursesAsyncValue.when(
        data: (courses) {
          if (courses.isEmpty) {
            return const Center(
              child: Text(
                'Aún no hay cursos publicados.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(provider);
              await ref.read(provider.future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                
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

                return _buildCourseCard(context, course, progress);
              },
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
                const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text('Error al cargar cursos: $error', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(provider),
                  child: const Text('Reintentar'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course, double progress) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.push('/courses/${course.id}');
          },
          borderRadius: BorderRadius.circular(24),
          child: Row(
            children: [
              Container(
                width: 110,
                height: 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary.withValues(alpha: 0.8), AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), bottomLeft: Radius.circular(24)),
                ),
                child: const Center(
                  child: Icon(Icons.school, size: 48, color: Colors.white),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          showUnpublished ? 'Prueba' : 'Disponible',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: showUnpublished ? Colors.orange : AppColors.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        course.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.text),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.timer, size: 16, color: AppColors.textLight),
                          const SizedBox(width: 6),
                          Text('${course.estimatedHours ?? 0} horas', style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: const Color(0xFFE2E8F0),
                                color: progress == 1.0 ? const Color(0xFF10B981) : AppColors.secondary,
                                minHeight: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: progress == 1.0 ? const Color(0xFF10B981) : AppColors.secondary,
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
      ),
    );
  }
}
