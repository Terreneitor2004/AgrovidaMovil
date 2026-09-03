import '../models/actividad.dart';
import 'agrovida_database.dart';

abstract interface class ActividadRepository {
  Future<List<Actividad>> obtenerPorTerreno(int terrenoId);

  Future<Actividad> crear(Actividad actividad);

  Future<void> actualizar(Actividad actividad);

  Future<void> eliminar(int id);
}

class SqliteActividadRepository implements ActividadRepository {
  SqliteActividadRepository._();

  static final SqliteActividadRepository instance =
      SqliteActividadRepository._();

  @override
  Future<List<Actividad>> obtenerPorTerreno(int terrenoId) async {
    final db = await AgrovidaDatabase.instance.database;
    final rows = await db.query(
      'actividades',
      where: 'terreno_id = ?',
      whereArgs: [terrenoId],
      orderBy: 'fecha DESC, creado_en DESC',
    );
    return rows.map(Actividad.fromMap).toList(growable: false);
  }

  @override
  Future<Actividad> crear(Actividad actividad) async {
    final db = await AgrovidaDatabase.instance.database;
    final values = actividad.toMap()..remove('id');
    final id = await db.insert('actividades', values);
    return actividad.copyWith(id: id);
  }

  @override
  Future<void> actualizar(Actividad actividad) async {
    final id = actividad.id;
    if (id == null) {
      throw ArgumentError('La actividad debe tener un identificador.');
    }

    final db = await AgrovidaDatabase.instance.database;
    final values = actividad.toMap()..remove('id');
    await db.update('actividades', values, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> eliminar(int id) async {
    final db = await AgrovidaDatabase.instance.database;
    await db.delete('actividades', where: 'id = ?', whereArgs: [id]);
  }
}
