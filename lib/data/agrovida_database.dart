import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AgrovidaDatabase {
  AgrovidaDatabase._();

  static final AgrovidaDatabase instance = AgrovidaDatabase._();

  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) return existing;

    final databasePath = join(await getDatabasesPath(), 'agrovida.db');
    final database = await openDatabase(
      databasePath,
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createTerrenosTable(db);
        await _createObservacionesTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createObservacionesTable(db);
        }
      },
    );
    _database = database;
    return database;
  }

  Future<void> _createTerrenosTable(Database db) async {
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
  }

  Future<void> _createObservacionesTable(Database db) async {
    await db.execute('''
      CREATE TABLE observaciones(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        terreno_id INTEGER NOT NULL,
        texto TEXT NOT NULL,
        creado_en TEXT NOT NULL,
        FOREIGN KEY (terreno_id) REFERENCES terrenos(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_observaciones_terreno
      ON observaciones(terreno_id)
    ''');
  }
}
