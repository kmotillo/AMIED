import 'lesson.dart';

class CourseModule {
  final String id;
  final String courseId;
  final String title;
  final String? description;
  final int orderIndex;
  final List<Lesson> lessons;

  final bool hasQuiz;

  CourseModule({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    required this.orderIndex,
    this.lessons = const [],
    this.hasQuiz = false,
  });

  factory CourseModule.fromJson(Map<String, dynamic> json) {
    var lessonsList = <Lesson>[];
    if (json['lessons'] != null) {
      lessonsList = (json['lessons'] as List)
          .map((l) => Lesson.fromJson(l))
          .toList()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    }
    
    bool hasQuizValue = false;
    if (json['quizzes'] != null && (json['quizzes'] as List).isNotEmpty) {
      hasQuizValue = true;
    }

    return CourseModule(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      orderIndex: json['order_index'] as int,
      lessons: lessonsList,
      hasQuiz: hasQuizValue,
    );
  }
}
