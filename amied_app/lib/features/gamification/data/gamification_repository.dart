import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/gamification_models.dart';

final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  return GamificationRepository(Supabase.instance.client);
});

final userGamificationProvider = FutureProvider.autoDispose<UserGamification?>((ref) async {
  final repository = ref.watch(gamificationRepositoryProvider);
  return repository.getUserGamification();
});

final userBadgesProvider = FutureProvider.autoDispose<List<Badge>>((ref) async {
  final repository = ref.watch(gamificationRepositoryProvider);
  return repository.getUserBadges();
});

final allBadgesProvider = FutureProvider.autoDispose<List<Badge>>((ref) async {
  final repository = ref.watch(gamificationRepositoryProvider);
  return repository.getAllBadges();
});

class GamificationRepository {
  final SupabaseClient _client;

  GamificationRepository(this._client);

  Future<UserGamification?> getUserGamification() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _client
          .from('user_gamification')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) {
        // Inicializar si no existe
        final newRecord = await _client.from('user_gamification').insert({
          'user_id': user.id,
          'total_xp': 0,
          'current_level': 1
        }).select().single();
        return UserGamification.fromJson(newRecord);
      }

      return UserGamification.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener perfil de gamificación: $e');
    }
  }

  Future<List<Badge>> getAllBadges() async {
    final response = await _client.from('badges').select().order('points_required');
    return (response as List).map((json) => Badge.fromJson(json)).toList();
  }

  Future<List<Badge>> getUserBadges() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('user_badges')
        .select('badges(*)')
        .eq('user_id', user.id);

    return (response as List).map((json) => Badge.fromJson(json['badges'])).toList();
  }

  Future<void> awardXP(int xpEarned) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final profile = await getUserGamification();
    if (profile == null) return;

    final newTotalXp = profile.totalXp + xpEarned;
    // Lógica simple de niveles: 1 nivel por cada 100 XP
    final newLevel = (newTotalXp ~/ 100) + 1;

    await _client.from('user_gamification').update({
      'total_xp': newTotalXp,
      'current_level': newLevel,
    }).eq('user_id', user.id);

    // Verificar si ganó nuevas medallas
    final allBadges = await getAllBadges();
    final earnedBadgesIds = (await getUserBadges()).map((b) => b.id).toList();

    for (var badge in allBadges) {
      if (newTotalXp >= badge.pointsRequired && !earnedBadgesIds.contains(badge.id)) {
        await _client.from('user_badges').insert({
          'user_id': user.id,
          'badge_id': badge.id,
        });
      }
    }
  }
}
