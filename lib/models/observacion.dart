class Observacion {
  const Observacion({
    this.id,
    required this.terrenoId,
    required this.texto,
    required this.creadoEn,
  });

  final int? id;
  final int terrenoId;
  final String texto;
  final DateTime creadoEn;

  Observacion copyWith({
    int? id,
    int? terrenoId,
    String? texto,
    DateTime? creadoEn,
  }) {
    return Observacion(
      id: id ?? this.id,
      terrenoId: terrenoId ?? this.terrenoId,
      texto: texto ?? this.texto,
      creadoEn: creadoEn ?? this.creadoEn,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'terreno_id': terrenoId,
      'texto': texto,
      'creado_en': creadoEn.toIso8601String(),
    };
  }

  factory Observacion.fromMap(Map<String, Object?> map) {
    return Observacion(
      id: map['id'] as int?,
      terrenoId: map['terreno_id'] as int,
      texto: map['texto'] as String,
      creadoEn: DateTime.parse(map['creado_en'] as String),
    );
  }
}
