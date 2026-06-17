import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return ProgressRepository(Supabase.instance.client);
});

final completedLessonsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final repo = ref.watch(progressRepositoryProvider);
  return repo.getCompletedLessons(''); // empty course id, it fetches all
});

class ProgressRepository {
  final SupabaseClient _client;

  ProgressRepository(this._client);

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }
    return user.id;
  }

  // --- MATRÍCULAS (user_progress) ---

  Future<bool> isEnrolled(String courseId) async {
    try {
      final response = await _client
          .from('user_progress')
          .select('id')
          .eq('user_id', _userId)
          .eq('course_id', courseId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> enrollInCourse(String courseId) async {
    await _client.from('user_progress').insert({
      'user_id': _userId,
      'course_id': courseId,
      'enrolled_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<String>> getEnrolledCourses() async {
    try {
      final response = await _client
          .from('user_progress')
          .select('course_id')
          .eq('user_id', _userId);
      return (response as List).map((row) => row['course_id'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> getCompletedCourses() async {
    try {
      final response = await _client
          .from('user_progress')
          .select('course_id')
          .eq('user_id', _userId)
          .not('completed_at', 'is', null);
      return (response as List).map((row) => row['course_id'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> markCourseCompleted(String courseId) async {
    // 1. Marcar en la tabla user_progress
    await _client.from('user_progress').update({
      'completed_at': DateTime.now().toIso8601String(),
    }).eq('user_id', _userId).eq('course_id', courseId);
    
    // 2. Dar una recompensa (ej. 200 XP por curso)
    final xpRes = await _client.from('user_gamification').select('total_xp').eq('user_id', _userId).maybeSingle();
    if (xpRes != null) {
      final currentXp = xpRes['total_xp'] as int? ?? 0;
      await _client.from('user_gamification').update({
        'total_xp': currentXp + 200, // Gran bonus por terminar el curso
      }).eq('user_id', _userId);
    }

    // 3. Crear y asignar la medalla específica del curso
    try {
      final courseRes = await _client.from('courses').select('title').eq('id', courseId).single();
      final courseTitle = courseRes['title'];
      final badgeName = 'Medalla: $courseTitle';

      var badgeRes = await _client.from('badges').select('id').eq('name', badgeName).maybeSingle();
      
      String badgeId;
      if (badgeRes == null) {
        final newBadge = await _client.from('badges').insert({
          'name': badgeName,
          'description': 'Completaste exitosamente el curso: $courseTitle',
          'points_required': 0, // No es por XP, es por completar el curso
        }).select('id').single();
        badgeId = newBadge['id'];
      } else {
        badgeId = badgeRes['id'];
      }

      await _client.from('user_badges').upsert({
        'user_id': _userId,
        'badge_id': badgeId,
      });
    } catch (e) {
      // Ignorar error si falla la asignación de la medalla,
      // para que no rompa el flujo de completación del curso.
    }
  }

  // --- LECCIONES COMPLETADAS (lesson_completion) ---

  Future<List<String>> getCompletedLessons(String courseId) async {
    // Para obtener las lecciones completadas de un curso específico,
    // necesitamos hacer un join con la tabla de lessons y modules, 
    // pero es más fácil simplemente traer las completadas por el usuario.
    // Sin embargo, para no traer toda la base de datos, filtramos usando Supabase.
    
    // Obtenemos todas las completion del usuario para simplificar (o filtramos luego).
    // Idealmente, podríamos obtener los lesson_id directamente:
    final response = await _client
        .from('lesson_completion')
        .select('lesson_id')
        .eq('user_id', _userId);
        
    return (response as List).map((row) => row['lesson_id'] as String).toList();
  }

  Future<bool> isLessonCompleted(String lessonId) async {
    try {
      final response = await _client
          .from('lesson_completion')
          .select('id')
          .eq('user_id', _userId)
          .eq('lesson_id', lessonId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> markLessonCompleted(String lessonId) async {
    // Utilizamos upsert por el UNIQUE(user_id, lesson_id)
    await _client.from('lesson_completion').upsert({
      'user_id': _userId,
      'lesson_id': lessonId,
      'completed_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id, lesson_id');
  }

  // --- EVALUACIONES APROBADAS ---
  Future<Map<String, int>> getPassedModulesWithQuizzes() async {
    final response = await _client
        .from('quiz_attempts')
        .select('score, quizzes!inner(module_id)')
        .eq('user_id', _userId)
        .eq('passed', true);
        
    final Map<String, int> result = {};
    for (var row in response as List) {
      final moduleId = row['quizzes']['module_id'] as String;
      final score = row['score'] as int;
      if (!result.containsKey(moduleId) || score > result[moduleId]!) {
        result[moduleId] = score;
      }
    }
    return result;
  }
}

