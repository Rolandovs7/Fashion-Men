import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('menstyle_offline.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE productos (
        id INTEGER PRIMARY KEY,
        nombre TEXT,
        precio REAL,
        imagen_url TEXT,
        stock INTEGER,
        empresa_id INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE operaciones_pendientes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT UNIQUE,
        tipo TEXT,
        datos_json TEXT,
        estado TEXT,
        fecha TEXT
      )
    ''');
  }

  Future<int> insertProducto(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('productos', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertProductos(List<Map<String, dynamic>> rows) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var row in rows) {
      batch.insert('productos', row, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getProductos() async {
    final db = await instance.database;
    return await db.query('productos');
  }

  Future<int> insertOperacionPendiente(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('operaciones_pendientes', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getOperacionesPendientes() async {
    final db = await instance.database;
    return await db.query('operaciones_pendientes');
  }

  Future<int> updateOperacionPendiente(String uuid, String estado) async {
    final db = await instance.database;
    return await db.update(
      'operaciones_pendientes',
      {'estado': estado},
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
  }

  Future<int> deleteOperacionPendiente(String uuid) async {
    final db = await instance.database;
    return await db.delete(
      'operaciones_pendientes',
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
  }
}
