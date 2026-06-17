import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../authentication/data/auth_repository.dart';
import '../domain/modulo.dart';
import '../domain/progreso_docente.dart';

final learningRepositoryProvider = Provider<LearningRepository>((ref) {
  return LearningRepository(ref.watch(supabaseProvider));
});

class LearningRepository {
  final SupabaseClient _supabase;

  LearningRepository(this._supabase);

  // Obtener todos los módulos disponibles
  Future<List<Modulo>> getModulos() async {
    final response = await _supabase.from('modulos').select();
    return (response as List).map((data) => Modulo.fromMap(data, data['id'])).toList();
  }

  // Obtener el progreso de un docente específico
  Future<List<ProgresoDocente>> getProgreso(String idDocente) async {
    final response = await _supabase
        .from('progreso_docente')
        .select()
        .eq('id_docente', idDocente);
    
    return (response as List).map((data) {
      // Adaptar mapa de snake_case (DB) a camelCase (Modelo)
      return ProgresoDocente.fromMap({
        'idDocente': data['id_docente'],
        'idModulo': data['id_modulo'],
        'porcentajeAvance': data['porcentaje_avance'],
        'fechaInicio': data['fecha_inicio'],
        'fechaFinalizacion': data['fecha_finalizacion'],
        'estado': data['estado'],
      });
    }).toList();
  }

  // Actualizar o crear el progreso de un módulo
  Future<void> updateProgreso(ProgresoDocente progreso) async {
    await _supabase.from('progreso_docente').upsert({
      'id_docente': progreso.idDocente,
      'id_modulo': progreso.idModulo,
      'porcentaje_avance': progreso.porcentajeAvance,
      'fecha_inicio': progreso.fechaInicio.toIso8601String(),
      'fecha_finalizacion': progreso.fechaFinalizacion?.toIso8601String(),
      'estado': progreso.estado.name,
    });
  }
}
