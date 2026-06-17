class RespuestaDocente {
  final String id;
  final String idDocente;
  final String idCaso;
  final String idOpcionSeleccionada;
  final bool esCorrecta;
  final int puntaje;
  final DateTime fecha;

  RespuestaDocente({
    this.id = '',
    required this.idDocente,
    required this.idCaso,
    required this.idOpcionSeleccionada,
    required this.esCorrecta,
    required this.puntaje,
    required this.fecha,
  });

  factory RespuestaDocente.fromMap(Map<String, dynamic> data, String documentId) {
    return RespuestaDocente(
      id: documentId,
      idDocente: data['idDocente'] ?? '',
      idCaso: data['idCaso'] ?? '',
      idOpcionSeleccionada: data['idOpcionSeleccionada'] ?? '',
      esCorrecta: data['esCorrecta'] ?? false,
      puntaje: data['puntaje']?.toInt() ?? 0,
      fecha: data['fecha'] != null ? DateTime.parse(data['fecha']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idDocente': idDocente,
      'idCaso': idCaso,
      'idOpcionSeleccionada': idOpcionSeleccionada,
      'esCorrecta': esCorrecta,
      'puntaje': puntaje,
      'fecha': fecha.toIso8601String(),
    };
  }
}
