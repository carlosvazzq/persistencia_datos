import 'package:flutter/material.dart';

import '../data/datasources/tarea_local_dao.dart';
import '../data/models/tarea_model.dart';

class TareasPage extends StatefulWidget {
  const TareasPage({super.key});

  @override
  State<TareasPage> createState() => _TareasPageState();
}

class _TareasPageState extends State<TareasPage> {
  final TareaLocalDao _dao = TareaLocalDao();
  late Future<List<TareaModel>> _tareasFuture;

  @override
  void initState() {
    super.initState();
    _cargarTareas();
  }

  void _cargarTareas() {
    _tareasFuture = _dao.obtenerTareasPendientes();
  }

  Future<void> _actualizarTareas() async {
    setState(_cargarTareas);
    await _tareasFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tareas pendientes')),
      body: FutureBuilder<List<TareaModel>>(
        future: _tareasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'No se pudieron cargar las tareas: ${snapshot.error}',
              ),
            );
          }

          final tareas = snapshot.data ?? const <TareaModel>[];
          if (tareas.isEmpty) {
            return RefreshIndicator(
              onRefresh: _actualizarTareas,
              child: ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text('No hay tareas pendientes')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _actualizarTareas,
            child: ListView.builder(
              itemCount: tareas.length,
              itemBuilder: (context, index) {
                final tarea = tareas[index];
                return ListTile(
                  leading: const Icon(Icons.radio_button_unchecked),
                  title: Text(tarea.titulo),
                  subtitle: Text('ID: ${tarea.id ?? 'sin asignar'}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
