import '../models/observacion.dart';
import 'agrovida_database.dart';

abstract interface class ObservacionRepository {
  Future<List<Observacion>> obtenerPorTerreno(int terrenoId);

  Future<Observacion> crear(Observacion observacion);

  Future<void> actualizar(Observacion observacion);

  Future<void> eliminar(int id);
}

class SqliteObservacionRepository implements ObservacionRepository {
  SqliteObservacionRepository._();

  static final SqliteObservacionRepository instance =
      SqliteObservacionRepository._();

  @override
  Future<List<Observacion>> obtenerPorTerreno(int terrenoId) async {
    final db = await AgrovidaDatabase.instance.database;
    final rows = await db.query(
      'observaciones',
      where: 'terreno_id = ?',
      whereArgs: [terrenoId],
      orderBy: 'creado_en DESC',
    );
    return rows.map(Observacion.fromMap).toList(growable: false);
  }

  @override
  Future<Observacion> crear(Observacion observacion) async {
    final db = await AgrovidaDatabase.instance.database;
    final values = observacion.toMap()..remove('id');
    final id = await db.insert('observaciones', values);
    return observacion.copyWith(id: id);
  }

  @override
  Future<void> actualizar(Observacion observacion) async {
    final id = observacion.id;
    if (id == null) {
      throw ArgumentError('La observación debe tener un identificador.');
    }

    final db = await AgrovidaDatabase.instance.database;
    final values = observacion.toMap()..remove('id');
    await db.update('observaciones', values, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> eliminar(int id) async {
    final db = await AgrovidaDatabase.instance.database;
    await db.delete('observaciones', where: 'id = ?', whereArgs: [id]);
  }
}
