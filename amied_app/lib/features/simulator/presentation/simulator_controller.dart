import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/data/auth_repository.dart';
import '../data/simulator_repository.dart';
import '../domain/caso_simulado.dart';
import '../domain/respuesta_docente.dart';

// Proveedor para obtener el caso simulado dado un ID de módulo
// Nota: en una app real podría haber varios, por ahora traeremos el primero que exista para ese módulo.
final casoPorModuloProvider = FutureProvider.family<CasoSimulado?, String>((ref, idModulo) async {
  final repo = ref.watch(simulatorRepositoryProvider);
  final casos = await repo.getCasosPorModulo(idModulo);
  if (casos.isNotEmpty) {
    return casos.first;
  }
  return null;
});

final simulatorControllerProvider = Provider<SimulatorController>((ref) {
  return SimulatorController(ref);
});

class SimulatorController {
  final Ref ref;

  SimulatorController(this.ref);

  Future<bool> evaluarRespuesta({
    required CasoSimulado caso,
    required OpcionRespuesta opcionSeleccionada,
  }) async {
    final user = ref.read(authStateChangesProvider).value;
    if (user == null) return false;

    final esCorrecta = caso.idRespuestaCorrecta == opcionSeleccionada.id;
    final puntaje = esCorrecta ? 10 : 0; // Simple lógica de puntaje por defecto

    final respuesta = RespuestaDocente(
      idDocente: user.id,
      idCaso: caso.id,
      idOpcionSeleccionada: opcionSeleccionada.id,
      esCorrecta: esCorrecta,
      puntaje: puntaje,
      fecha: DateTime.now(),
    );

    await ref.read(simulatorRepositoryProvider).guardarRespuesta(respuesta);
    
    return esCorrecta;
  }
}
