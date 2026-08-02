import 'package:flutter/foundation.dart';

import '../data/observacion_repository.dart';
import '../models/observacion.dart';

class ObservacionStore extends ChangeNotifier {
  ObservacionStore(this._repository, {required this.terrenoId});

  final int terrenoId;
  final ObservacionRepository _repository;

  List<Observacion> _observaciones = const [];
  bool _cargando = false;
  String? _error;

  List<Observacion> get observaciones => List.unmodifiable(_observaciones);
  bool get cargando => _cargando;
  String? get error => _error;

  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _observaciones = await _repository.obtenerPorTerreno(terrenoId);
    } catch (_) {
      _error = 'No se pudieron cargar las observaciones.';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> crear(String texto) async {
    await _repository.crear(
      Observacion(
        terrenoId: terrenoId,
        texto: texto.trim(),
        creadoEn: DateTime.now(),
      ),
    );
    await cargar();
  }

  Future<void> actualizar(Observacion observacion, String texto) async {
    await _repository.actualizar(observacion.copyWith(texto: texto.trim()));
    await cargar();
  }

  Future<void> eliminar(int id) async {
    await _repository.eliminar(id);
    await cargar();
  }
}
