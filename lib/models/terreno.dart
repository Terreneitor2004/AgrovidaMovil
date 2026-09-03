import 'dart:convert';

class PuntoBorde {
  const PuntoBorde({required this.latitud, required this.longitud});

  final double latitud;
  final double longitud;

  Map<String, double> toMap() => {'latitud': latitud, 'longitud': longitud};

  factory PuntoBorde.fromMap(Map<String, Object?> map) {
    return PuntoBorde(
      latitud: (map['latitud'] as num).toDouble(),
      longitud: (map['longitud'] as num).toDouble(),
    );
  }
}

class Terreno {
  const Terreno({
    this.id,
    required this.nombre,
    required this.propietario,
    required this.latitud,
    required this.longitud,
    required this.creadoEn,
    this.limite = const [],
  });

  final int? id;
  final String nombre;
  final String propietario;
  final double latitud;
  final double longitud;
  final DateTime creadoEn;
  final List<PuntoBorde> limite;

  bool get tieneLimite => limite.length >= 3;

  Terreno copyWith({
    int? id,
    String? nombre,
    String? propietario,
    double? latitud,
    double? longitud,
    DateTime? creadoEn,
    List<PuntoBorde>? limite,
  }) {
    return Terreno(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      propietario: propietario ?? this.propietario,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      creadoEn: creadoEn ?? this.creadoEn,
      limite: limite ?? this.limite,
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
      'limite_json': jsonEncode(limite.map((punto) => punto.toMap()).toList()),
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
      limite: _limiteDesdeJson(map['limite_json']),
    );
  }

  static List<PuntoBorde> _limiteDesdeJson(Object? rawJson) {
    if (rawJson is! String || rawJson.trim().isEmpty) return const [];

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! List) return const [];

      return decoded
          .whereType<Map>()
          .map((punto) => PuntoBorde.fromMap(Map<String, Object?>.from(punto)))
          .toList(growable: false);
    } on FormatException {
      return const [];
    } on TypeError {
      return const [];
    }
  }
}
