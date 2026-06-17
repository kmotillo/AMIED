enum EstadoProgreso { noIniciado, enProgreso, completado }

class ProgresoDocente {
  final String idDocente;
  final String idModulo;
  final double porcentajeAvance;
  final DateTime fechaInicio;
  final DateTime? fechaFinalizacion;
  final EstadoProgreso estado;

  ProgresoDocente({
    required this.idDocente,
    required this.idModulo,
    required this.porcentajeAvance,
    required this.fechaInicio,
    this.fechaFinalizacion,
    required this.estado,
  });

  factory ProgresoDocente.fromMap(Map<String, dynamic> data) {
    return ProgresoDocente(
      idDocente: data['idDocente'] ?? '',
      idModulo: data['idModulo'] ?? '',
      porcentajeAvance: (data['porcentajeAvance'] ?? 0.0).toDouble(),
      fechaInicio: data['fechaInicio'] != null
          ? DateTime.parse(data['fechaInicio'])
          : DateTime.now(),
      fechaFinalizacion: data['fechaFinalizacion'] != null
          ? DateTime.parse(data['fechaFinalizacion'])
          : null,
      estado: _parseEstado(data['estado']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idDocente': idDocente,
      'idModulo': idModulo,
      'porcentajeAvance': porcentajeAvance,
      'fechaInicio': fechaInicio.toIso8601String(),
      'fechaFinalizacion': fechaFinalizacion?.toIso8601String(),
      'estado': estado.name,
    };
  }

  static EstadoProgreso _parseEstado(String? estadoStr) {
    switch (estadoStr) {
      case 'enProgreso':
        return EstadoProgreso.enProgreso;
      case 'completado':
        return EstadoProgreso.completado;
      default:
        return EstadoProgreso.noIniciado;
    }
  }
}
