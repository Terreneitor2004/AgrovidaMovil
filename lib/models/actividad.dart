enum EstadoActividad { pendiente, realizada }

extension EstadoActividadLabel on EstadoActividad {
  String get value => switch (this) {
    EstadoActividad.pendiente => 'pendiente',
    EstadoActividad.realizada => 'realizada',
  };

  String get label => switch (this) {
    EstadoActividad.pendiente => 'Pendiente',
    EstadoActividad.realizada => 'Realizada',
  };
}

class Actividad {
  const Actividad({
    this.id,
    required this.terrenoId,
    required this.tipo,
    required this.descripcion,
    required this.estado,
    required this.fecha,
    this.evidenciaRuta,
    required this.creadoEn,
  });

  final int? id;
  final int terrenoId;
  final String tipo;
  final String descripcion;
  final EstadoActividad estado;
  final DateTime fecha;
  final String? evidenciaRuta;
  final DateTime creadoEn;

  Actividad copyWith({
    int? id,
    int? terrenoId,
    String? tipo,
    String? descripcion,
    EstadoActividad? estado,
    DateTime? fecha,
    String? evidenciaRuta,
    DateTime? creadoEn,
  }) {
    return Actividad(
      id: id ?? this.id,
      terrenoId: terrenoId ?? this.terrenoId,
      tipo: tipo ?? this.tipo,
      descripcion: descripcion ?? this.descripcion,
      estado: estado ?? this.estado,
      fecha: fecha ?? this.fecha,
      evidenciaRuta: evidenciaRuta ?? this.evidenciaRuta,
      creadoEn: creadoEn ?? this.creadoEn,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'terreno_id': terrenoId,
      'tipo': tipo,
      'descripcion': descripcion,
      'estado': estado.value,
      'fecha': fecha.toIso8601String(),
      'evidencia_ruta': evidenciaRuta,
      'creado_en': creadoEn.toIso8601String(),
    };
  }

  factory Actividad.fromMap(Map<String, Object?> map) {
    return Actividad(
      id: map['id'] as int?,
      terrenoId: map['terreno_id'] as int,
      tipo: map['tipo'] as String,
      descripcion: map['descripcion'] as String,
      estado: (map['estado'] as String) == EstadoActividad.realizada.value
          ? EstadoActividad.realizada
          : EstadoActividad.pendiente,
      fecha: DateTime.parse(map['fecha'] as String),
      evidenciaRuta: map['evidencia_ruta'] as String?,
      creadoEn: DateTime.parse(map['creado_en'] as String),
    );
  }
}
