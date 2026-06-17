import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../authentication/data/auth_repository.dart';
import '../domain/caso_simulado.dart';
import '../domain/respuesta_docente.dart';

final simulatorRepositoryProvider = Provider<SimulatorRepository>((ref) {
  return SimulatorRepository(ref.watch(supabaseProvider));
});

class SimulatorRepository {
  final SupabaseClient _supabase;

  SimulatorRepository(this._supabase);

  // Obtener casos simulados vinculados a un módulo
  Future<List<CasoSimulado>> getCasosPorModulo(String idModulo) async {
    final response = await _supabase
        .from('casos_simulados')
        .select()
        .eq('id_modulo_vinculado', idModulo);
    
    return (response as List).map((data) {
      // Adaptar mapa de DB (snake_case) al modelo
      return CasoSimulado.fromMap({
        'idModuloVinculado': data['id_modulo_vinculado'],
        'titulo': data['titulo'],
        'situacion': data['situacion'],
        'necesidadEducativa': data['necesidad_educativa'],
        'nivelDificultad': data['nivel_dificultad'],
        'opciones': data['opciones'], // Supabase JSONB viene como List de Maps
        'idRespuestaCorrecta': data['id_respuesta_correcta'],
        'explicacionPedagogica': data['explicacion_pedagogica'],
      }, data['id']);
    }).toList();
  }

  // Guardar respuesta del docente
  Future<void> guardarRespuesta(RespuestaDocente respuesta) async {
    await _supabase.from('respuestas_docente').insert({
      'id_docente': respuesta.idDocente,
      'id_caso': respuesta.idCaso,
      'id_opcion_seleccionada': respuesta.idOpcionSeleccionada,
      'es_correcta': respuesta.esCorrecta,
      'puntaje': respuesta.puntaje,
      'fecha': respuesta.fecha.toIso8601String(),
    });
  }
}
