import '../models/tarea_model.dart';
import 'tarea_local_dao.dart';
import 'tarea_remota_datasource.dart';

class TareaSyncDataSource {
  TareaSyncDataSource({TareaLocalDao? localDao})
    : _localDao = localDao ?? TareaLocalDao();

  final TareaLocalDao _localDao;

  Future<List<TareaModel>> sincronizarYGuardarTareas(String tokenJwt) async {
    final tareasRemotas = await sincronizarTareasNube(tokenJwt);
    await _localDao.insertarTareas(tareasRemotas);
    return _localDao.obtenerTareasPendientes();
  }
}
