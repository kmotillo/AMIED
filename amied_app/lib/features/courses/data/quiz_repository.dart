import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/quiz.dart';

import '../../gamification/data/gamification_repository.dart';

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  final gamificationRepo = ref.watch(gamificationRepositoryProvider);
  return QuizRepository(Supabase.instance.client, gamificationRepo);
});

final moduleQuizProvider = FutureProvider.family<Quiz?, String>((ref, moduleId) async {
  final repository = ref.watch(quizRepositoryProvider);
  return repository.getQuizForModule(moduleId);
});

class QuizRepository {
  final SupabaseClient _client;
  final GamificationRepository _gamificationRepository;

  QuizRepository(this._client, this._gamificationRepository);

  Future<Quiz?> getQuizForModule(String moduleId) async {
    try {
      final response = await _client
          .from('quizzes')
          .select('*, questions(*, answers(*))')
          .eq('module_id', moduleId)
          .maybeSingle();
      
      if (response == null) return null;
      return Quiz.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener la evaluación: $e');
    }
  }

  Future<void> saveQuizAttempt({
    required String quizId,
    required int score,
    required bool passed,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      bool alreadyPassed = false;
      if (passed) {
        final prevAttempts = await _client
            .from('quiz_attempts')
            .select('id')
            .eq('user_id', user.id)
            .eq('quiz_id', quizId)
            .eq('passed', true)
            .limit(1);
        alreadyPassed = prevAttempts.isNotEmpty;
      }

      await _client.from('quiz_attempts').insert({
        'user_id': user.id,
        'quiz_id': quizId,
        'score': score,
        'passed': passed,
      });

      if (passed && !alreadyPassed) {
        // Otorgar 50 XP solo si es la primera vez que aprueba
        await _gamificationRepository.awardXP(50);
      }
    } catch (e) {
      throw Exception('Error al guardar el intento: $e');
    }
  }
}
