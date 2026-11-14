class TareaModel {
  const TareaModel({
    this.id,
    required this.titulo,
    required this.completada,
  });

  final int? id;
  final String titulo;
  final bool completada;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'completada': completada ? 1 : 0,
    };
  }

  factory TareaModel.fromMap(Map<String, dynamic> map) {
    final Object? rawId = map['id'];
    final Object? rawTitulo = map['titulo'] ?? map['title'];
    final Object? rawCompletada = map['completada'] ?? map['completed'];

    return TareaModel(
      id: rawId == null
          ? null
          : rawId is int
              ? rawId
              : rawId is num
                  ? rawId.toInt()
                  : throw FormatException('El id debe ser un número entero.'),
      titulo: rawTitulo is String
          ? rawTitulo
          : throw FormatException('El título debe ser una cadena de texto.'),
      completada: _parseCompletada(rawCompletada),
    );
  }

  static bool _parseCompletada(Object? value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      if (value == 1) return true;
      if (value == 0) return false;
    }

    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }

    throw FormatException(
      'El campo completada/completed debe ser booleano o 0/1.',
    );
  }
}
