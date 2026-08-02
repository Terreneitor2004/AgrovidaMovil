import 'package:agrovida_movil/data/terreno_repository.dart';
import 'package:agrovida_movil/models/terreno.dart';
import 'package:agrovida_movil/state/terreno_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('crea, actualiza y elimina terrenos', () async {
    final repository = _MemoryTerrenoRepository();
    final store = TerrenoStore(repository);
    final original = Terreno(
      nombre: 'Parcela Norte',
      propietario: 'Andree',
      latitud: 14.6349,
      longitud: -90.5069,
      creadoEn: DateTime(2026, 8, 1),
    );

    await store.cargar();
    await store.crear(original);
    expect(store.terrenos, hasLength(1));
    expect(store.terrenos.single.nombre, 'Parcela Norte');

    final updated = store.terrenos.single.copyWith(nombre: 'Parcela Central');
    await store.actualizar(updated);
    expect(store.terrenos.single.nombre, 'Parcela Central');

    await store.eliminar(store.terrenos.single.id!);
    expect(store.terrenos, isEmpty);

    store.dispose();
  });
}

class _MemoryTerrenoRepository implements TerrenoRepository {
  final List<Terreno> _items = [];
  int _nextId = 1;

  @override
  Future<void> actualizar(Terreno terreno) async {
    final index = _items.indexWhere((item) => item.id == terreno.id);
    _items[index] = terreno;
  }

  @override
  Future<Terreno> crear(Terreno terreno) async {
    final created = terreno.copyWith(id: _nextId++);
    _items.add(created);
    return created;
  }

  @override
  Future<void> eliminar(int id) async {
    _items.removeWhere((item) => item.id == id);
  }

  @override
  Future<List<Terreno>> obtenerTodos() async => List.of(_items);
}
