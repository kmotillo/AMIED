import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/data/auth_repository.dart';
import '../data/learning_repository.dart';
import '../domain/modulo.dart';
import '../domain/progreso_docente.dart';

// Proveedor para obtener la lista de módulos
final modulosProvider = FutureProvider<List<Modulo>>((ref) async {
  final repo = ref.watch(learningRepositoryProvider);
  return await repo.getModulos();
});

// Proveedor para obtener el progreso del docente actual
final progresoProvider = FutureProvider<List<ProgresoDocente>>((ref) async {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return [];

  final repo = ref.watch(learningRepositoryProvider);
  return await repo.getProgreso(user.id);
});

// Controlador para acciones de aprendizaje (ej. marcar como completado)
final learningControllerProvider = Provider<LearningController>((ref) {
  return LearningController(ref);
});

class LearningController {
  final Ref ref;

  LearningController(this.ref);

  Future<void> marcarModuloCompletado(String idModulo) async {
    final user = ref.read(authStateChangesProvider).value;
    if (user == null) return;

    final repo = ref.read(learningRepositoryProvider);

    final progreso = ProgresoDocente(
      idDocente: user.id,
      idModulo: idModulo,
      porcentajeAvance: 100.0,
      fechaInicio:
          DateTime.now(), // Simplificado: Idealmente buscar la original
      fechaFinalizacion: DateTime.now(),
      estado: EstadoProgreso.completado,
    );

    await repo.updateProgreso(progreso);
    // Refrescar el estado en la UI
    ref.invalidate(progresoProvider);
  }
}
