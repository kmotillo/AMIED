import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../courses/data/course_repository.dart';
import '../../../courses/domain/course.dart';
import '../../data/admin_repository.dart';
import 'dart:convert';
import '../../../courses/domain/lesson.dart';

class CourseEditorScreen extends ConsumerStatefulWidget {
  final String? courseId; // null = Nuevo Curso

  const CourseEditorScreen({super.key, this.courseId});

  @override
  ConsumerState<CourseEditorScreen> createState() => _CourseEditorScreenState();
}

class _CourseEditorScreenState extends ConsumerState<CourseEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (widget.courseId != null) {
      final courseAsync = ref.watch(courseDetailsProvider(widget.courseId!));

      return courseAsync.when(
        data: (course) {
          
          return _buildEditor(course: course);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      );
    } else {
      return _buildEditor();
    }
  }

  Widget _buildEditor({Course? course}) {
    final courseTitle = course?.title;
    final courseDesc = course?.description;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go('/admin/courses'),
                ),
                Text(
                  widget.courseId == null
                      ? 'Crear Nuevo Curso'
                      : 'Editar Curso',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              initialValue: courseTitle,
              decoration: const InputDecoration(
                labelText: 'Título del Curso',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
              onSaved: (v) => _title = v!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: courseDesc,
              decoration: const InputDecoration(
                labelText: 'Descripción Corta',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
              onSaved: (v) => _description = v!,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isLoading ? null : _saveCourse,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Guardar Curso'),
              ),
            ),
            const SizedBox(height: 48),
            if (course != null) ...[
              const Divider(height: 48),
              _buildModulesList(course),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModulesList(Course course) {
    if (course.modules == null || course.modules!.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aún no hay módulos.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Añadir Primer Módulo'),
            onPressed: () => _showAddModuleDialog(course.id),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Módulos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Añadir Módulo'),
              onPressed: () => _showAddModuleDialog(course.id),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: course.modules!.length,
          itemBuilder: (context, index) {
            final module = course.modules![index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                title: Text(
                  module.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                children: [
                  if (module.lessons.isNotEmpty)
                    ...module.lessons.map(
                      (lesson) => ListTile(
                        leading: const Icon(Icons.play_circle_outline),
                        title: Text(lesson.title),
                        subtitle: lesson.videoUrlsList.isNotEmpty
                            ? Text(
                                'Videos: ${lesson.videoUrlsList.length}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : const Text('Sin video'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showEditLessonDialog(lesson),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteLesson(lesson.id),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ListTile(
                    leading: const Icon(Icons.add, color: AppColors.primary),
                    title: const Text(
                      'Añadir Lección',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () => _showAddLessonDialog(
                      module.id,
                      (module.lessons.length) + 1,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.quiz, color: Colors.orange),
                    title: const Text(
                      'Gestionar Evaluación (Quiz)',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () => context.push('/admin/quiz/${module.id}'),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  void _showAddModuleDialog(String courseId) {
    String title = '';
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Añadir Módulo'),
          content: TextField(
            decoration: const InputDecoration(labelText: 'Título del módulo'),
            onChanged: (v) => title = v,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (title.trim().isEmpty) return;
                Navigator.of(dialogContext).pop();
                try {
                  final repo = ref.read(adminRepositoryProvider);
                  // Usamos un orden temporal basado en la hora para simplicidad
                  await repo.createModule(
                    courseId,
                    title.trim(),
                    DateTime.now().millisecondsSinceEpoch ~/ 1000,
                  );
                  ref.invalidate(courseDetailsProvider(courseId));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Módulo creado')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _showAddLessonDialog(String moduleId, int orderIndex) {
    String title = '';
    String content = '';
    List<TextEditingController> videoControllers = [TextEditingController()];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Añadir Lección'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Título de la lección',
                        ),
                        onChanged: (v) => title = v,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Contenido (Markdown)',
                        ),
                        maxLines: 3,
                        onChanged: (v) => content = v,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Enlaces a videos (Opcional)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...videoControllers.asMap().entries.map((entry) {
                        int idx = entry.key;
                        var controller = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: controller,
                                  decoration: InputDecoration(
                                    labelText: 'URL del Video ${idx + 1}',
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              if (videoControllers.length > 1)
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    setStateDialog(() {
                                      videoControllers.removeAt(idx);
                                    });
                                  },
                                ),
                            ],
                          ),
                        );
                      }),
                      TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar otro video'),
                        onPressed: () {
                          setStateDialog(() {
                            videoControllers.add(TextEditingController());
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (title.trim().isEmpty) return;

                    // Procesar videos
                    List<String> validUrls = videoControllers
                        .map((c) => c.text.trim())
                        .where((t) => t.isNotEmpty)
                        .toList();

                    String? finalVideoUrl;
                    if (validUrls.isNotEmpty) {
                      if (validUrls.length == 1) {
                        finalVideoUrl = validUrls.first;
                      } else {
                        finalVideoUrl = jsonEncode(validUrls);
                      }
                    }

                    Navigator.of(dialogContext).pop();
                    try {
                      final repo = ref.read(adminRepositoryProvider);
                      await repo.createLesson(
                        moduleId,
                        title.trim(),
                        content.trim(),
                        orderIndex,
                        videoUrl: finalVideoUrl,
                      );
                      ref.invalidate(courseDetailsProvider(widget.courseId!));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Lección creada')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      // Clean up controllers
      for (var c in videoControllers) {
        c.dispose();
      }
    });
  }

  void _showEditLessonDialog(Lesson lesson) {
    String title = lesson.title;
    String content = lesson.contentMarkdown ?? '';

    // Convert current videoUrlsList to controllers
    List<TextEditingController> videoControllers = [];
    if (lesson.videoUrlsList.isNotEmpty) {
      for (var url in lesson.videoUrlsList) {
        videoControllers.add(TextEditingController(text: url));
      }
    } else {
      videoControllers.add(TextEditingController());
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Editar Lección'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        initialValue: title,
                        decoration: const InputDecoration(
                          labelText: 'Título de la lección',
                        ),
                        onChanged: (v) => title = v,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: content,
                        decoration: const InputDecoration(
                          labelText: 'Contenido (Markdown)',
                        ),
                        maxLines: 3,
                        onChanged: (v) => content = v,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Enlaces a videos (Opcional)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...videoControllers.asMap().entries.map((entry) {
                        int idx = entry.key;
                        var controller = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: controller,
                                  decoration: InputDecoration(
                                    labelText: 'URL del Video ${idx + 1}',
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              if (videoControllers.length > 1)
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    setStateDialog(() {
                                      videoControllers.removeAt(idx);
                                    });
                                  },
                                ),
                            ],
                          ),
                        );
                      }),
                      TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar otro video'),
                        onPressed: () {
                          setStateDialog(() {
                            videoControllers.add(TextEditingController());
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (title.trim().isEmpty) return;

                    List<String> validUrls = videoControllers
                        .map((c) => c.text.trim())
                        .where((t) => t.isNotEmpty)
                        .toList();

                    String? finalVideoUrl;
                    if (validUrls.isNotEmpty) {
                      if (validUrls.length == 1) {
                        finalVideoUrl = validUrls.first;
                      } else {
                        finalVideoUrl = jsonEncode(validUrls);
                      }
                    }

                    Navigator.of(dialogContext).pop();
                    try {
                      final repo = ref.read(adminRepositoryProvider);
                      await repo.updateLesson(
                        lesson.id,
                        title.trim(),
                        content.trim(),
                        videoUrl: finalVideoUrl,
                      );
                      ref.invalidate(courseDetailsProvider(widget.courseId!));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Lección actualizada')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      for (var c in videoControllers) {
        c.dispose();
      }
    });
  }

  void _deleteLesson(String lessonId) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar Lección'),
          content: const Text(
            '¿Estás seguro de que deseas eliminar esta lección? Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  final repo = ref.read(adminRepositoryProvider);
                  await repo.deleteLesson(lessonId);
                  ref.invalidate(courseDetailsProvider(widget.courseId!));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lección eliminada')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(adminRepositoryProvider);

      if (widget.courseId == null) {
        // Crear
        await repo.createCourse(_title, _description);
      } else {
        // Actualizar
        await repo.updateCourse(widget.courseId!, _title, _description);
      }

      // Refrescar el provider de cursos
      ref.invalidate(adminAllCoursesProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Guardado exitosamente')));
        context.go('/admin/courses');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
