import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/lesson.dart';
import '../providers/progress_providers.dart';
import 'package:audioplayers/audioplayers.dart';

class LessonScreen extends ConsumerWidget {
  final String courseId;
  final Lesson lesson;

  const LessonScreen({super.key, required this.courseId, required this.lesson});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEnrolledAsync = ref.watch(isEnrolledProvider(courseId));
    final isEnrolled = isEnrolledAsync.value ?? false;

    final completedLessonsAsync = ref.watch(completedLessonsProvider);
    final isCompleted = completedLessonsAsync.maybeWhen(
      data: (completed) => completed.contains(lesson.id),
      orElse: () => false,
    );
    final progressState = ref.watch(progressControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lesson.videoUrlsList.isNotEmpty)
              ...lesson.videoUrlsList.map((url) => _VideoLinkCard(url: url)),
            if (lesson.contentMarkdown == null || lesson.contentMarkdown!.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('Esta lección no tiene contenido escrito.', style: TextStyle(color: Colors.grey)),
              ))
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: MarkdownBody(
                  data: lesson.contentMarkdown!,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(fontSize: 16, height: 1.6),
                    h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                    h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.secondary),
                    listBullet: const TextStyle(fontSize: 16, height: 1.6),
                    code: TextStyle(
                      backgroundColor: Colors.grey[200],
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/ai-tutor'),
        backgroundColor: AppColors.primary,
        tooltip: 'Tutor Virtual',
        child: const Icon(Icons.psychology, color: Colors.white),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: !isEnrolled 
                  ? Colors.grey 
                  : (isCompleted ? Colors.green : AppColors.secondary),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: progressState.isLoading
                ? null
                : () async {
                    if (!isEnrolled) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Debes inscribirte en el curso primero para guardar tu progreso.')),
                      );
                      return;
                    }

                    if (!isCompleted) {
                      try {
                        final player = AudioPlayer();
                        await player.play(AssetSource('sounds/success.ogg'));
                      } catch (e) {
                        // Ignore audio errors (e.g., if asset is not loaded yet)
                      }
                      
                      final success = await ref.read(progressControllerProvider.notifier).markLessonCompleted(lesson.id);
                      
                      if (context.mounted) {
                        if (success) {
                          Navigator.of(context).pop();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Error al completar la lección')),
                          );
                        }
                      }
                    } else {
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    }
                  },
            child: progressState.isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    !isEnrolled 
                        ? 'Inscríbete para marcar como completada'
                        : (isCompleted ? 'Lección Completada (Volver)' : 'Marcar como Completada y Volver'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }
}

class _VideoLinkCard extends StatelessWidget {
  final String url;
  
  const _VideoLinkCard({required this.url});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.secondary.withValues(alpha: 0.1),
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ListTile(
        leading: const Icon(Icons.video_library, color: AppColors.secondary, size: 36),
        title: const Text('Material en Video', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Haz clic aquí para abrir el video en YouTube o en tu navegador'),
        trailing: const Icon(Icons.open_in_new),
        onTap: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No se pudo abrir el enlace.')),
              );
            }
          }
        },
      ),
    );
  }
}
