import 'package:agrovida_movil/data/actividad_repository.dart';
import 'package:agrovida_movil/models/actividad.dart';
import 'package:agrovida_movil/state/actividad_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('crea, completa y elimina actividades de un terreno', () async {
    final repository = _MemoryActividadRepository();
    final store = ActividadStore(repository, terrenoId: 7);

    await store.cargar();
    await store.crear(
      tipo: 'Inspección',
      descripcion: 'Revisar hojas nuevas.',
      estado: EstadoActividad.pendiente,
      fecha: DateTime(2026, 9, 2),
      evidenciaRuta: '/evidencias/actividad.jpg',
    );
    expect(store.actividades, hasLength(1));
    expect(store.actividades.single.terrenoId, 7);
    expect(store.actividades.single.estado, EstadoActividad.pendiente);

    await store.actualizarEstado(
      store.actividades.single,
      EstadoActividad.realizada,
    );
    expect(store.actividades.single.estado, EstadoActividad.realizada);

    await store.eliminar(store.actividades.single.id!);
    expect(store.actividades, isEmpty);

    store.dispose();
  });
}

class _MemoryActividadRepository implements ActividadRepository {
  final List<Actividad> _items = [];
  int _nextId = 1;

  @override
  Future<void> actualizar(Actividad actividad) async {
    final index = _items.indexWhere((item) => item.id == actividad.id);
    _items[index] = actividad;
  }

  @override
  Future<Actividad> crear(Actividad actividad) async {
    final created = actividad.copyWith(id: _nextId++);
    _items.add(created);
    return created;
  }

  @override
  Future<void> eliminar(int id) async {
    _items.removeWhere((item) => item.id == id);
  }

  @override
  Future<List<Actividad>> obtenerPorTerreno(int terrenoId) async {
    return _items.where((item) => item.terrenoId == terrenoId).toList();
  }
}
