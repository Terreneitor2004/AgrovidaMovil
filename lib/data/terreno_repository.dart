import '../models/terreno.dart';
import 'agrovida_database.dart';

abstract interface class TerrenoRepository {
  Future<List<Terreno>> obtenerTodos();

  Future<Terreno> crear(Terreno terreno);

  Future<void> actualizar(Terreno terreno);

  Future<void> eliminar(int id);
}

class SqliteTerrenoRepository implements TerrenoRepository {
  SqliteTerrenoRepository._();

  static final SqliteTerrenoRepository instance = SqliteTerrenoRepository._();

  @override
  Future<List<Terreno>> obtenerTodos() async {
    final db = await AgrovidaDatabase.instance.database;
    final rows = await db.query('terrenos', orderBy: 'creado_en DESC');
    return rows.map(Terreno.fromMap).toList(growable: false);
  }

  @override
  Future<Terreno> crear(Terreno terreno) async {
    final db = await AgrovidaDatabase.instance.database;
    final values = terreno.toMap()..remove('id');
    final id = await db.insert('terrenos', values);
    return terreno.copyWith(id: id);
  }

  @override
  Future<void> actualizar(Terreno terreno) async {
    final id = terreno.id;
    if (id == null) {
      throw ArgumentError('El terreno debe tener un identificador.');
    }

    final db = await AgrovidaDatabase.instance.database;
    final values = terreno.toMap()..remove('id');
    await db.update('terrenos', values, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> eliminar(int id) async {
    final db = await AgrovidaDatabase.instance.database;
    await db.delete('terrenos', where: 'id = ?', whereArgs: [id]);
  }
}
