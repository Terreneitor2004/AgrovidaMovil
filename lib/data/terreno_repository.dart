import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/terreno.dart';

abstract interface class TerrenoRepository {
  Future<List<Terreno>> obtenerTodos();

  Future<Terreno> crear(Terreno terreno);

  Future<void> actualizar(Terreno terreno);

  Future<void> eliminar(int id);
}

class SqliteTerrenoRepository implements TerrenoRepository {
  SqliteTerrenoRepository._();

  static final SqliteTerrenoRepository instance = SqliteTerrenoRepository._();

  Database? _database;

  Future<Database> get _db async {
    final existing = _database;
    if (existing != null) return existing;

    final databasePath = join(await getDatabasesPath(), 'agrovida.db');
    final database = await openDatabase(
      databasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE terrenos(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            propietario TEXT NOT NULL,
            latitud REAL NOT NULL,
            longitud REAL NOT NULL,
            creado_en TEXT NOT NULL
          )
        ''');
      },
    );
    _database = database;
    return database;
  }

  @override
  Future<List<Terreno>> obtenerTodos() async {
    final db = await _db;
    final rows = await db.query('terrenos', orderBy: 'creado_en DESC');
    return rows.map(Terreno.fromMap).toList(growable: false);
  }

  @override
  Future<Terreno> crear(Terreno terreno) async {
    final db = await _db;
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

    final db = await _db;
    final values = terreno.toMap()..remove('id');
    await db.update('terrenos', values, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> eliminar(int id) async {
    final db = await _db;
    await db.delete('terrenos', where: 'id = ?', whereArgs: [id]);
  }
}
