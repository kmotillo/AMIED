class OpcionRespuesta {
  final String id;
  final String texto;

  OpcionRespuesta({required this.id, required this.texto});

  factory OpcionRespuesta.fromMap(Map<String, dynamic> data) {
    return OpcionRespuesta(
      id: data['id'] ?? '',
      texto: data['texto'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'texto': texto,
    };
  }
}

class CasoSimulado {
  final String id;
  final String idModuloVinculado;
  final String titulo;
  final String situacion;
  final String necesidadEducativa;
  final String nivelDificultad;
  final List<OpcionRespuesta> opciones;
  final String idRespuestaCorrecta;
  final String explicacionPedagogica;

  CasoSimulado({
    required this.id,
    required this.idModuloVinculado,
    required this.titulo,
    required this.situacion,
    required this.necesidadEducativa,
    required this.nivelDificultad,
    required this.opciones,
    required this.idRespuestaCorrecta,
    required this.explicacionPedagogica,
  });

  factory CasoSimulado.fromMap(Map<String, dynamic> data, String documentId) {
    return CasoSimulado(
      id: documentId,
      idModuloVinculado: data['idModuloVinculado'] ?? '',
      titulo: data['titulo'] ?? '',
      situacion: data['situacion'] ?? '',
      necesidadEducativa: data['necesidadEducativa'] ?? '',
      nivelDificultad: data['nivelDificultad'] ?? '',
      opciones: (data['opciones'] as List<dynamic>? ?? [])
          .map((op) => OpcionRespuesta.fromMap(op))
          .toList(),
      idRespuestaCorrecta: data['idRespuestaCorrecta'] ?? '',
      explicacionPedagogica: data['explicacionPedagogica'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idModuloVinculado': idModuloVinculado,
      'titulo': titulo,
      'situacion': situacion,
      'necesidadEducativa': necesidadEducativa,
      'nivelDificultad': nivelDificultad,
      'opciones': opciones.map((op) => op.toMap()).toList(),
      'idRespuestaCorrecta': idRespuestaCorrecta,
      'explicacionPedagogica': explicacionPedagogica,
    };
  }
}
