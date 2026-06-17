import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(Supabase.instance.client);
});

final adminAllCoursesProvider = FutureProvider<List<dynamic>>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  return repository.getAllCourses();
});

class AdminRepository {
  final SupabaseClient _client;

  AdminRepository(this._client);

  // ---------- Cursos ----------

  Future<List<dynamic>> getAllCourses() async {
    final response = await _client.from('courses').select().order('created_at');
    return response as List<dynamic>;
  }

  Future<void> createCourse(String title, String description) async {
    await _client.from('courses').insert({
      'title': title,
      'description': description,
    });
  }

  Future<void> updateCourse(String courseId, String title, String description) async {
    await _client.from('courses').update({
      'title': title,
      'description': description,
    }).eq('id', courseId);
  }

  Future<List<dynamic>> getAllUsersProgress() async {
    final response = await _client.rpc('get_all_users_progress');
    return response as List<dynamic>;
  }

  Future<Map<String, dynamic>> getUserDetailedProgress(String userId, {String? courseId}) async {
    var enrolledQuery = _client
        .from('user_progress')
        .select('enrolled_at, completed_at, courses(title)')
        .eq('user_id', userId);

    if (courseId != null) {
      enrolledQuery = enrolledQuery.eq('course_id', courseId);
    }
    final enrolledRes = await enrolledQuery;

    final quizzesRes = await _client
        .from('quiz_attempts')
        .select('score, passed, attempt_date, quizzes!inner(title, module_id, modules!inner(course_id))')
        .eq('user_id', userId)
        .order('attempt_date', ascending: false);

    List<dynamic> finalQuizzes = quizzesRes;
    if (courseId != null) {
      finalQuizzes = (quizzesRes as List).where((q) {
        try {
          return q['quizzes']['modules']['course_id'] == courseId;
        } catch (e) {
          return false;
        }
      }).toList();
    }

    final badgesRes = await _client
        .from('user_badges')
        .select('awarded_at, badges(name, description)')
        .eq('user_id', userId);

    return {
      'courses': enrolledRes,
      'quizzes': finalQuizzes,
      'badges': badgesRes,
    };
  }

  Future<List<Map<String, dynamic>>> getUsersReportData() async {
    final usersRes = await _client.rpc('get_all_users_progress') as List<dynamic>;
    final coursesRes = await _client.from('courses').select('id, title, modules(id, lessons(id), quizzes(id))') as List<dynamic>;
    final progressRes = await _client.from('user_progress').select('user_id, course_id, enrolled_at') as List<dynamic>;
    final lessonsRes = await _client.from('lesson_completion').select('user_id, lesson_id') as List<dynamic>;
    final quizzesRes = await _client.from('quiz_attempts').select('user_id, quizzes!inner(module_id)').eq('passed', true) as List<dynamic>;

    final courseItemsCount = <String, int>{};
    final courseLessonsMap = <String, Set<String>>{};
    final courseQuizzesMap = <String, Set<String>>{};

    for (var c in coursesRes) {
      final cId = c['id'] as String;
      int total = 0;
      final lessonSet = <String>{};
      final quizSet = <String>{};

      final modules = c['modules'] as List<dynamic>? ?? [];
      for (var m in modules) {
        final mId = m['id'] as String;
        final lessons = m['lessons'] as List<dynamic>? ?? [];
        total += lessons.length;
        for (var l in lessons) {
          lessonSet.add(l['id'] as String);
        }

        final quizzes = m['quizzes'] as List<dynamic>? ?? [];
        if (quizzes.isNotEmpty) {
          total += 1;
          quizSet.add(mId);
        }
      }
      courseItemsCount[cId] = total;
      courseLessonsMap[cId] = lessonSet;
      courseQuizzesMap[cId] = quizSet;
    }

    final userCompletions = <String, Set<String>>{};
    for (var l in lessonsRes) {
      final uId = l['user_id'] as String;
      userCompletions.putIfAbsent(uId, () => {}).add(l['lesson_id'] as String);
    }

    final userQuizCompletions = <String, Set<String>>{};
    for (var q in quizzesRes) {
      final uId = q['user_id'] as String;
      final moduleInfo = q['quizzes'] as Map<String, dynamic>?;
      if (moduleInfo != null && moduleInfo['module_id'] != null) {
        userQuizCompletions.putIfAbsent(uId, () => {}).add(moduleInfo['module_id'] as String);
      }
    }

    final usersMap = <String, dynamic>{};
    for (var u in usersRes) {
      usersMap[u['user_id'] as String] = u;
    }

    final List<Map<String, dynamic>> reportData = [];

    for (var prog in progressRes) {
      final uId = prog['user_id'] as String;
      final cId = prog['course_id'] as String;
      final user = usersMap[uId];
      if (user == null) continue;

      final courseTitle = coursesRes.firstWhere((c) => c['id'] == cId, orElse: () => {'title': 'Curso Desconocido'})['title'] as String;
      final totalItems = courseItemsCount[cId] ?? 0;

      int completedItems = 0;
      final userLessonSet = userCompletions[uId] ?? {};
      final courseLessonSet = courseLessonsMap[cId] ?? {};

      for (var lId in courseLessonSet) {
        if (userLessonSet.contains(lId)) completedItems++;
      }

      final userQuizSet = userQuizCompletions[uId] ?? {};
      final courseQuizSet = courseQuizzesMap[cId] ?? {};

      for (var mId in courseQuizSet) {
        if (userQuizSet.contains(mId)) completedItems++;
      }

      int progressPercentage = 0;
      if (totalItems > 0) {
        progressPercentage = ((completedItems / totalItems) * 100).floor();
      }

      final status = progressPercentage >= 100 ? 'completed' : 'in_progress';

      reportData.add({
        'user_id': uId,
        'full_name': user['full_name'] ?? 'Usuario',
        'email': user['email'] ?? '',
        'institution': user['institution'] ?? 'N/A',
        'course_id': cId,
        'course_title': courseTitle,
        'progress_percentage': progressPercentage,
        'status': status,
        'role': user['role'],
        'total_xp': user['total_xp'],
        'current_level': user['current_level'],
      });
    }

    return reportData;
  }

  Future<void> deleteCourse(String courseId) async {
    await _client.from('courses').delete().eq('id', courseId);
  }

  // ---------- Módulos ----------

  Future<void> createModule(String courseId, String title, int orderIndex) async {
    await _client.from('modules').insert({
      'course_id': courseId,
      'title': title,
      'order_index': orderIndex,
    });
  }

  // ---------- Lecciones ----------

  Future<void> createLesson(String moduleId, String title, String markdown, int orderIndex, {String? videoUrl}) async {
    final Map<String, dynamic> data = {
      'module_id': moduleId,
      'title': title,
      'content_markdown': markdown,
      'order_index': orderIndex,
    };
    if (videoUrl != null && videoUrl.trim().isNotEmpty) {
      data['video_url'] = videoUrl.trim();
    }
    await _client.from('lessons').insert(data);
  }

  Future<void> updateLesson(String lessonId, String title, String markdown, {String? videoUrl}) async {
    final Map<String, dynamic> data = {
      'title': title,
      'content_markdown': markdown,
    };
    if (videoUrl != null && videoUrl.trim().isNotEmpty) {
      data['video_url'] = videoUrl.trim();
    }
    await _client.from('lessons').update(data).eq('id', lessonId);
  }

  Future<void> deleteLesson(String lessonId) async {
    // Primero, eliminar las referencias en lesson_completion para evitar errores de llave foránea
    await _client.from('lesson_completion').delete().eq('lesson_id', lessonId);
    
    // Ahora sí, eliminar la lección
    await _client.from('lessons').delete().eq('id', lessonId);
  }

  // ---------- Quizzes (Evaluaciones) ----------

  Future<Map<String, dynamic>?> getQuizForModule(String moduleId) async {
    try {
      final response = await _client
          .from('quizzes')
          .select('*, questions(*, answers(*))')
          .eq('module_id', moduleId)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<void> saveQuizForModule({
    required String moduleId,
    String? existingQuizId,
    required String title,
    required int passingScore,
    required int maxAttempts,
    required List<Map<String, dynamic>> questions,
  }) async {
    String quizId;

    if (existingQuizId != null) {
      // Actualizar quiz existente
      await _client.from('quizzes').update({
        'title': title,
        'passing_score': passingScore,
        'max_attempts': maxAttempts,
      }).eq('id', existingQuizId);
      quizId = existingQuizId;

      // Borramos las preguntas antiguas (esto borrará las respuestas en cascada si está configurado,
      // pero por si acaso borramos explícitamente las respuestas primero si podemos, 
      // o confiamos en el CASCADE de Supabase).
      // Para mayor seguridad, primero obtenemos los IDs de las preguntas:
      final oldQuestions = await _client.from('questions').select('id').eq('quiz_id', quizId);
      for (var oq in oldQuestions) {
        await _client.from('answers').delete().eq('question_id', oq['id']);
      }
      await _client.from('questions').delete().eq('quiz_id', quizId);

    } else {
      // Crear nuevo quiz
      final res = await _client.from('quizzes').insert({
        'module_id': moduleId,
        'title': title,
        'passing_score': passingScore,
        'max_attempts': maxAttempts,
      }).select().single();
      quizId = res['id'];
    }

    // Insertar nuevas preguntas y respuestas
    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final qRes = await _client.from('questions').insert({
        'quiz_id': quizId,
        'question_text': q['question_text'],
        'question_type': q['question_type'],
        'order_index': i,
      }).select().single();

      final questionId = qRes['id'];
      final answers = q['answers'] as List<dynamic>;

      for (var a in answers) {
        await _client.from('answers').insert({
          'question_id': questionId,
          'answer_text': a['answer_text'],
          'is_correct': a['is_correct'],
          'feedback_text': a['feedback_text'],
        });
      }
    }
  }
}

