class Terreno {
  const Terreno({
    this.id,
    required this.nombre,
    required this.propietario,
    required this.latitud,
    required this.longitud,
    required this.creadoEn,
  });

  final int? id;
  final String nombre;
  final String propietario;
  final double latitud;
  final double longitud;
  final DateTime creadoEn;

  Terreno copyWith({
    int? id,
    String? nombre,
    String? propietario,
    double? latitud,
    double? longitud,
    DateTime? creadoEn,
  }) {
    return Terreno(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      propietario: propietario ?? this.propietario,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      creadoEn: creadoEn ?? this.creadoEn,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'propietario': propietario,
      'latitud': latitud,
      'longitud': longitud,
      'creado_en': creadoEn.toIso8601String(),
    };
  }

  factory Terreno.fromMap(Map<String, Object?> map) {
    return Terreno(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      propietario: map['propietario'] as String,
      latitud: (map['latitud'] as num).toDouble(),
      longitud: (map['longitud'] as num).toDouble(),
      creadoEn: DateTime.parse(map['creado_en'] as String),
    );
  }
}
