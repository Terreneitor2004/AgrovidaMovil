import 'package:flutter/foundation.dart';

import '../data/actividad_repository.dart';
import '../models/actividad.dart';

class ActividadStore extends ChangeNotifier {
  ActividadStore(this._repository, {required this.terrenoId});

  final int terrenoId;
  final ActividadRepository _repository;

  List<Actividad> _actividades = const [];
  bool _cargando = false;
  String? _error;

  List<Actividad> get actividades => List.unmodifiable(_actividades);
  bool get cargando => _cargando;
  String? get error => _error;

  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _actividades = await _repository.obtenerPorTerreno(terrenoId);
    } catch (_) {
      _error = 'No se pudieron cargar las actividades.';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> crear({
    required String tipo,
    required String descripcion,
    required EstadoActividad estado,
    required DateTime fecha,
    String? evidenciaRuta,
  }) async {
    await _repository.crear(
      Actividad(
        terrenoId: terrenoId,
        tipo: tipo,
        descripcion: descripcion.trim(),
        estado: estado,
        fecha: fecha,
        evidenciaRuta: evidenciaRuta,
        creadoEn: DateTime.now(),
      ),
    );
    await cargar();
  }

  Future<void> actualizarEstado(
    Actividad actividad,
    EstadoActividad estado,
  ) async {
    await _repository.actualizar(actividad.copyWith(estado: estado));
    await cargar();
  }

  Future<void> eliminar(int id) async {
    await _repository.eliminar(id);
    await cargar();
  }
}
