class Modulo {
  final String id;
  final String titulo;
  final String descripcion;
  final String contenido;
  final String categoria;
  final String dificultad;
  final List<String> recursos;

  Modulo({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.contenido,
    required this.categoria,
    required this.dificultad,
    this.recursos = const [],
  });

  factory Modulo.fromMap(Map<String, dynamic> data, String documentId) {
    return Modulo(
      id: documentId,
      titulo: data['titulo'] ?? '',
      descripcion: data['descripcion'] ?? '',
      contenido: data['contenido'] ?? '',
      categoria: data['categoria'] ?? '',
      dificultad: data['dificultad'] ?? '',
      recursos: List<String>.from(data['recursos'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'contenido': contenido,
      'categoria': categoria,
      'dificultad': dificultad,
      'recursos': recursos,
    };
  }
}
