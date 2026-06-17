import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(() {
  return AuthController();
});

class AuthController extends AsyncNotifier<void> {
  late AuthRepository _authRepository;

  @override
  Future<void> build() async {
    _authRepository = ref.watch(authRepositoryProvider);
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _authRepository.signInWithEmailAndPassword(email, password));
  }

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
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _authRepository.registerDocente(
      email: email,
      password: password,
      nombres: nombres,
      apellidos: apellidos,
      institucionEducativa: institucionEducativa,
      nivelEducativo: nivelEducativo,
      asignatura: asignatura,
      anosExperiencia: anosExperiencia,
    ));
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _authRepository.signOut());
  }
}
