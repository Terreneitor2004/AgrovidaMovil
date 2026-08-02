import 'package:flutter/foundation.dart';

import '../data/terreno_repository.dart';
import '../models/terreno.dart';

class TerrenoStore extends ChangeNotifier {
  TerrenoStore(this._repository);

  final TerrenoRepository _repository;

  List<Terreno> _terrenos = const [];
  bool _cargando = false;
  String? _error;

  List<Terreno> get terrenos => List.unmodifiable(_terrenos);
  bool get cargando => _cargando;
  String? get error => _error;

  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _terrenos = await _repository.obtenerTodos();
    } catch (_) {
      _error = 'No se pudieron cargar los terrenos guardados.';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> crear(Terreno terreno) async {
    await _repository.crear(terreno);
    await cargar();
  }

  Future<void> actualizar(Terreno terreno) async {
    await _repository.actualizar(terreno);
    await cargar();
  }

  Future<void> eliminar(int id) async {
    await _repository.eliminar(id);
    await cargar();
  }
}
