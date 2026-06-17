import 'dart:convert';

class Lesson {
  final String id;
  final String moduleId;
  final String title;
  final String? contentMarkdown;
  final String? videoUrl;
  final int orderIndex;

  Lesson({
    required this.id,
    required this.moduleId,
    required this.title,
    this.contentMarkdown,
    this.videoUrl,
    required this.orderIndex,
  });

  List<String> get videoUrlsList {
    if (videoUrl == null || videoUrl!.trim().isEmpty) return [];
    
    final trimmed = videoUrl!.trim();
    if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is List) {
          return List<String>.from(decoded.map((e) => e.toString()));
        }
      } catch (_) {
        // Fallback if parsing fails
      }
    }
    
    // Single URL fallback
    return [trimmed];
  }

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as String,
      moduleId: json['module_id'] as String,
      title: json['title'] as String,
      contentMarkdown: json['content_markdown'] as String?,
      videoUrl: json['video_url'] as String?,
      orderIndex: json['order_index'] as int,
    );
  }
}
