import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/tarea_model.dart';

class TareaLocalDao {
  TareaLocalDao() : _database = _inicializarBaseDeDatos();

  static const String _nombreBaseDeDatos = 'tareas_offline.db';
  static const String _nombreTabla = 'tareas';

  final Future<Database> _database;

  static Future<Database> _inicializarBaseDeDatos() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _nombreBaseDeDatos);

    return openDatabase(
      path,
      version: 1,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE $_nombreTabla (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            titulo TEXT NOT NULL,
            completada INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertarTarea(TareaModel tarea) async {
    final database = await _database;

    return database.insert(
      _nombreTabla,
      tarea.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertarTareas(List<TareaModel> tareas) async {
    final database = await _database;
    final batch = database.batch();

    for (final tarea in tareas) {
      batch.insert(
        _nombreTabla,
        tarea.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<TareaModel>> obtenerTareasPendientes() async {
    final database = await _database;
    final rows = await database.query(
      _nombreTabla,
      columns: const ['id', 'titulo', 'completada'],
      where: 'completada = ?',
      whereArgs: [0],
    );

    return rows.map(TareaModel.fromMap).toList();
  }
}
