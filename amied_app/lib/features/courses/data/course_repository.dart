import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/course.dart';

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return CourseRepository(Supabase.instance.client);
});

final publishedCoursesProvider = FutureProvider.autoDispose<List<Course>>((ref) async {
  final repository = ref.watch(courseRepositoryProvider);
  return repository.getPublishedCourses();
});

final unpublishedCoursesProvider = FutureProvider.autoDispose<List<Course>>((ref) async {
  final repository = ref.watch(courseRepositoryProvider);
  return repository.getUnpublishedCourses();
});

final courseDetailsProvider = FutureProvider.autoDispose.family<Course, String>((ref, courseId) async {
  final repository = ref.watch(courseRepositoryProvider);
  return repository.getCourseDetails(courseId);
});

class CourseRepository {
  final SupabaseClient _client;

  CourseRepository(this._client);

  Future<List<Course>> getPublishedCourses() async {
    final response = await _client
        .from('courses')
        .select('*, modules(*, lessons(*), quizzes(id))')
        .eq('is_published', true)
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => Course.fromJson(json)).toList();
  }

  Future<List<Course>> getUnpublishedCourses() async {
    final response = await _client
        .from('courses')
        .select('*, modules(*, lessons(*), quizzes(id))')
        .eq('is_published', false)
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => Course.fromJson(json)).toList();
  }

  Future<Course> getCourseDetails(String courseId) async {
    final response = await _client
        .from('courses')
        .select('*, modules(*, lessons(*), quizzes(id))')
        .eq('id', courseId)
        .single();
    
    return Course.fromJson(response);
  }
}
