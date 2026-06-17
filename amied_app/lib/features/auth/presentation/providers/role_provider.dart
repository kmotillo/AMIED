import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/auth_repository.dart';

final userRoleProvider = FutureProvider.autoDispose<String>((ref) async {
  final authState = ref.watch(authStateChangesProvider).value;
  final session = authState?.session;
  if (session == null) return 'student'; // Default role

  try {
    final client = Supabase.instance.client;
    final response = await client
        .from('user_roles')
        .select('role')
        .eq('user_id', session.user.id)
        .maybeSingle();

    if (response != null && response['role'] != null) {
      return response['role'] as String;
    }
  } catch (e) {
    // Si la tabla no existe o hay un error, asumimos rol básico
    debugPrint('Error fetching role: $e');
  }
  
  return 'student'; // Rol por defecto
});
