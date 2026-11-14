import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/tarea_model.dart';

const String _urlTareas = 'https://jsonplaceholder.typicode.com/todos';

Future<List<TareaModel>> sincronizarTareasNube(String tokenJwt) async {
  try {
    final response = await http.get(
      Uri.parse(_urlTareas),
      headers: {'Authorization': 'Bearer $tokenJwt'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Error al sincronizar tareas. Código HTTP: ${response.statusCode}',
      );
    }

    final decodedBody = jsonDecode(response.body);
    if (decodedBody is! List) {
      throw const FormatException('La respuesta no contiene una lista.');
    }

    return decodedBody.take(5).map((item) {
      if (item is! Map) {
        throw const FormatException('Una tarea remota no es un objeto válido.');
      }

      return TareaModel.fromMap(Map<String, dynamic>.from(item));
    }).toList();
  } catch (_) {
    rethrow;
  }
}
