import 'package:agrovida_movil/data/observacion_repository.dart';
import 'package:agrovida_movil/models/observacion.dart';
import 'package:agrovida_movil/state/observacion_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('crea, actualiza y elimina observaciones de un terreno', () async {
    final repository = _MemoryObservacionRepository();
    final store = ObservacionStore(repository, terrenoId: 7);

    await store.cargar();
    await store.crear('Se observó buen crecimiento.');
    expect(store.observaciones, hasLength(1));
    expect(store.observaciones.single.terrenoId, 7);

    final observation = store.observaciones.single;
    await store.actualizar(observation, 'Se observó crecimiento uniforme.');
    expect(
      store.observaciones.single.texto,
      'Se observó crecimiento uniforme.',
    );

    await store.eliminar(store.observaciones.single.id!);
    expect(store.observaciones, isEmpty);

    store.dispose();
  });
}

class _MemoryObservacionRepository implements ObservacionRepository {
  final List<Observacion> _items = [];
  int _nextId = 1;

  @override
  Future<void> actualizar(Observacion observacion) async {
    final index = _items.indexWhere((item) => item.id == observacion.id);
    _items[index] = observacion;
  }

  @override
  Future<Observacion> crear(Observacion observacion) async {
    final created = observacion.copyWith(id: _nextId++);
    _items.add(created);
    return created;
  }

  @override
  Future<void> eliminar(int id) async {
    _items.removeWhere((item) => item.id == id);
  }

  @override
  Future<List<Observacion>> obtenerPorTerreno(int terrenoId) async {
    return _items.where((item) => item.terrenoId == terrenoId).toList();
  }
}
