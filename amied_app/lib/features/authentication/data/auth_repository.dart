import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseProvider));
});

// Stream que notifica cambios en la sesión de Supabase
final authStateChangesProvider = StreamProvider<User?>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return supabase.auth.onAuthStateChange.map((event) => event.session?.user);
});

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  // Iniciar sesión
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  // Registrar nuevo docente
  Future<void> registerDocente({
    required String email,
    required String password,
    required String nombres,
    required String apellidos,
    required String institucionEducativa,
    required String nivelEducativo,
    required String asignatura,
    required int anosExperiencia,
  }) async {
    // 1. Crear el usuario en Auth
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user != null) {
      // 2. Guardar datos adicionales en la tabla profiles
      // Nota: Si configuraste el Trigger en SQL, la fila ya existe con email. 
      // Hacemos un UPSERT (o UPDATE) para llenar los datos extra.
      await _supabase.from('profiles').upsert({
        'id': user.id,
        'email': email,
        'nombres': nombres,
        'apellidos': apellidos,
        'institucion_educativa': institucionEducativa,
        'nivel_educativo': nivelEducativo,
        'asignatura': asignatura,
        'anos_experiencia': anosExperiencia,
      });
    } else {
      throw Exception('No se pudo crear el usuario');
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
