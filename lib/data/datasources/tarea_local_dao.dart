import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/tarea_model.dart';

abstract interface class TareaLocalDataSource {
  Future<int> insertarTarea(TareaModel tarea);

  Future<void> insertarTareas(List<TareaModel> tareas);

  Future<List<TareaModel>> obtenerTareas();

  Future<List<TareaModel>> obtenerTareasPendientes();

  Future<int> actualizarTarea(TareaModel tarea);

  Future<int> eliminarTarea(int id);
}

class TareaLocalDao implements TareaLocalDataSource {
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

  @override
  Future<int> insertarTarea(TareaModel tarea) async {
    final database = await _database;

    return database.insert(
      _nombreTabla,
      tarea.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
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

  @override
  Future<List<TareaModel>> obtenerTareas() async {
    final database = await _database;
    final rows = await database.query(
      _nombreTabla,
      columns: const ['id', 'titulo', 'completada'],
      orderBy: 'id DESC',
    );

    return rows.map(TareaModel.fromMap).toList();
  }

  @override
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

  @override
  Future<int> actualizarTarea(TareaModel tarea) async {
    final id = tarea.id;
    if (id == null) {
      throw ArgumentError('No se puede actualizar una tarea sin id.');
    }

    final database = await _database;
    return database.update(
      _nombreTabla,
      tarea.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<int> eliminarTarea(int id) async {
    final database = await _database;
    return database.delete(_nombreTabla, where: 'id = ?', whereArgs: [id]);
  }
}
