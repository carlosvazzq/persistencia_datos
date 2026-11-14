import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persistencia_datos/data/datasources/tarea_local_dao.dart';
import 'package:persistencia_datos/data/models/tarea_model.dart';
import 'package:persistencia_datos/presentation/tareas_page.dart';

void main() {
  testWidgets('muestra la pantalla y permite añadir una tarea', (tester) async {
    final dataSource = _FakeTareaDataSource();

    await tester.pumpWidget(
      MaterialApp(home: TareasPage(dataSource: dataSource)),
    );
    await tester.pumpAndSettle();

    expect(find.text('No hay tareas'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Comprar pan');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Comprar pan'), findsOneWidget);
    expect(dataSource.tareas.single.titulo, 'Comprar pan');
  });

  testWidgets('permite completar, editar y eliminar una tarea', (tester) async {
    final dataSource = _FakeTareaDataSource(
      tareas: [
        const TareaModel(id: 1, titulo: 'Tarea original', completada: false),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: TareasPage(dataSource: dataSource)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(dataSource.tareas.single.completada, isTrue);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Tarea editada');
    await tester.tap(find.text('Actualizar'));
    await tester.pumpAndSettle();
    expect(find.text('Tarea editada'), findsOneWidget);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar').last);
    await tester.pumpAndSettle();

    expect(find.text('No hay tareas'), findsOneWidget);
    expect(dataSource.tareas, isEmpty);
  });
}

class _FakeTareaDataSource implements TareaLocalDataSource {
  _FakeTareaDataSource({List<TareaModel>? tareas})
    : tareas = List<TareaModel>.from(tareas ?? const []);

  final List<TareaModel> tareas;
  int _nextId = 1;

  @override
  Future<int> insertarTarea(TareaModel tarea) async {
    final id = tarea.id ?? _nextId++;
    tareas.add(
      TareaModel(id: id, titulo: tarea.titulo, completada: tarea.completada),
    );
    return id;
  }

  @override
  Future<void> insertarTareas(List<TareaModel> nuevasTareas) async {
    for (final tarea in nuevasTareas) {
      await insertarTarea(tarea);
    }
  }

  @override
  Future<List<TareaModel>> obtenerTareas() async {
    return List<TareaModel>.from(tareas.reversed);
  }

  @override
  Future<List<TareaModel>> obtenerTareasPendientes() async {
    return tareas.where((tarea) => !tarea.completada).toList();
  }

  @override
  Future<int> actualizarTarea(TareaModel tarea) async {
    final index = tareas.indexWhere((item) => item.id == tarea.id);
    if (index == -1) return 0;
    tareas[index] = tarea;
    return 1;
  }

  @override
  Future<int> eliminarTarea(int id) async {
    final count = tareas.where((tarea) => tarea.id == id).length;
    tareas.removeWhere((tarea) => tarea.id == id);
    return count;
  }
}
