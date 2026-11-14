import 'package:flutter/material.dart';

import '../data/datasources/tarea_local_dao.dart';
import '../data/models/tarea_model.dart';

class TareasPage extends StatefulWidget {
  const TareasPage({super.key, this.dataSource});

  final TareaLocalDataSource? dataSource;

  @override
  State<TareasPage> createState() => _TareasPageState();
}

class _TareasPageState extends State<TareasPage> {
  late final TareaLocalDataSource _dao;
  late Future<List<TareaModel>> _tareasFuture;

  @override
  void initState() {
    super.initState();
    _dao = widget.dataSource ?? TareaLocalDao();
    _cargarTareas();
  }

  void _cargarTareas() {
    _tareasFuture = _dao.obtenerTareas();
  }

  Future<void> _actualizarTareas() async {
    setState(_cargarTareas);
    try {
      await _tareasFuture;
    } on Exception catch (error, stackTrace) {
      debugPrint('Error al actualizar tareas: $error\n$stackTrace');
      if (mounted) _mostrarError();
    }
  }

  Future<String?> _pedirTitulo({String? tituloInicial}) async {
    var titulo = tituloInicial ?? '';

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(tituloInicial == null ? 'Nueva tarea' : 'Editar tarea'),
          content: TextFormField(
            autofocus: true,
            initialValue: tituloInicial,
            onChanged: (value) => titulo = value,
            onFieldSubmitted: (_) {
              final tituloNormalizado = titulo.trim();
              if (tituloNormalizado.isNotEmpty) {
                Navigator.of(context).pop(tituloNormalizado);
              }
            },
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Título',
              hintText: 'Escribe el título de la tarea',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final tituloNormalizado = titulo.trim();
                if (tituloNormalizado.isNotEmpty) {
                  Navigator.of(context).pop(tituloNormalizado);
                }
              },
              child: Text(tituloInicial == null ? 'Guardar' : 'Actualizar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _agregarTarea() async {
    try {
      final titulo = await _pedirTitulo();
      if (!mounted || titulo == null) return;

      await _dao.insertarTarea(TareaModel(titulo: titulo, completada: false));
      if (!mounted) return;
      setState(_cargarTareas);
      _mostrarMensaje('Tarea guardada correctamente');
    } on Exception catch (error, stackTrace) {
      debugPrint('Error al guardar tarea: $error\n$stackTrace');
      if (mounted) _mostrarError('No se pudo guardar la tarea.');
    }
  }

  Future<void> _cambiarCompletada(TareaModel tarea, bool completada) async {
    try {
      await _dao.actualizarTarea(
        TareaModel(id: tarea.id, titulo: tarea.titulo, completada: completada),
      );
      if (!mounted) return;
      setState(_cargarTareas);
    } on Exception catch (error, stackTrace) {
      debugPrint('Error al cambiar estado de tarea: $error\n$stackTrace');
      if (mounted) _mostrarError('No se pudo actualizar la tarea.');
    }
  }

  Future<void> _editarTarea(TareaModel tarea) async {
    try {
      final titulo = await _pedirTitulo(tituloInicial: tarea.titulo);
      if (!mounted || titulo == null || tarea.id == null) return;

      await _dao.actualizarTarea(
        TareaModel(id: tarea.id, titulo: titulo, completada: tarea.completada),
      );
      if (!mounted) return;
      setState(_cargarTareas);
      _mostrarMensaje('Tarea actualizada correctamente');
    } on Exception catch (error, stackTrace) {
      debugPrint('Error al editar tarea: $error\n$stackTrace');
      if (mounted) _mostrarError('No se pudo actualizar la tarea.');
    }
  }

  Future<void> _eliminarTarea(TareaModel tarea) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar tarea'),
          content: const Text('¿Quieres eliminar esta tarea?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmar != true || tarea.id == null) return;

    try {
      await _dao.eliminarTarea(tarea.id!);
      if (!mounted) return;
      setState(_cargarTareas);
      _mostrarMensaje('Tarea eliminada correctamente');
    } on Exception catch (error, stackTrace) {
      debugPrint('Error al eliminar tarea: $error\n$stackTrace');
      if (mounted) _mostrarError('No se pudo eliminar la tarea.');
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  void _mostrarError([String mensaje = 'No se pudieron cargar las tareas.']) {
    _mostrarMensaje('$mensaje Intenta de nuevo.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tareas')),
      body: FutureBuilder<List<TareaModel>>(
        future: _tareasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('No se pudieron cargar las tareas.'),
            );
          }

          final tareas = snapshot.data ?? const <TareaModel>[];
          if (tareas.isEmpty) {
            return RefreshIndicator(
              onRefresh: _actualizarTareas,
              child: ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text('No hay tareas')),
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
                  leading: Checkbox(
                    value: tarea.completada,
                    onChanged: (value) {
                      if (value != null) {
                        _cambiarCompletada(tarea, value);
                      }
                    },
                  ),
                  title: Text(
                    tarea.titulo,
                    style: TextStyle(
                      decoration: tarea.completada
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  subtitle: Text('ID: ${tarea.id ?? 'sin asignar'}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) {
                      if (action == 'editar') {
                        _editarTarea(tarea);
                      } else if (action == 'eliminar') {
                        _eliminarTarea(tarea);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'editar', child: Text('Editar')),
                      PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregarTarea,
        icon: const Icon(Icons.add),
        label: const Text('Añadir tarea'),
      ),
    );
  }
}
