import 'module.dart';

class Course {
  final String id;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final int? estimatedHours;
  final bool isPublished;
  final List<CourseModule>? modules;

  Course({
    required this.id,
    required this.title,
    this.description,
    this.thumbnailUrl,
    this.estimatedHours,
    required this.isPublished,
    this.modules,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    List<CourseModule>? modulesList;
    if (json['modules'] != null) {
      modulesList = (json['modules'] as List)
          .map((m) => CourseModule.fromJson(m))
          .toList()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    }

    return Course(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      estimatedHours: json['estimated_hours'] as int?,
      isPublished: json['is_published'] as bool? ?? false,
      modules: modulesList,
    );
  }
}
