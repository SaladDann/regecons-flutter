import '../../db/app_db.dart';
import '../../db/daos/gestion_obras/usuario_obra_dao.dart';
import '../../models/gestion_obras/usuario_obra.dart';

class UsuarioObraService {
  late UsuarioObraDao _usuarioObraDao;
  bool _inicializado = false;

  Future<void> _initialize() async {
    if (!_inicializado) {
      final db = await AppDatabase().database;
      _usuarioObraDao = UsuarioObraDao(db);
      _inicializado = true;
    }
  }

  // ASIGNAR usuario a obra
  Future<void> asignarUsuarioAObra(int idUsuario, int idObra) async {
    await _initialize();
    await _usuarioObraDao.insert(UsuarioObra(
      idUsuario: idUsuario,
      idObra: idObra,
    ));
  }

  // ELIMINAR asignación de usuario a obra
  Future<void> eliminarAsignacionUsuarioObra(int idUsuario, int idObra) async {
    await _initialize();
    await _usuarioObraDao.delete(idUsuario, idObra);
  }

  // OBTENER gestion_obras de un usuario
  Future<List<int>> obtenerObrasDeUsuario(int idUsuario) async {
    await _initialize();
    return await _usuarioObraDao.getObrasByUsuario(idUsuario);
  }

  // OBTENER usuarios de una obra
  Future<List<int>> obtenerUsuariosDeObra(int idObra) async {
    await _initialize();
    return await _usuarioObraDao.getUsuariosByObra(idObra);
  }

  // VERIFICAR acceso de usuario a obra
  Future<bool> tieneAccesoAObra(int idUsuario, int idObra) async {
    await _initialize();
    return await _usuarioObraDao.tieneAcceso(idUsuario, idObra);
  }

  // ASIGNAR múltiples usuarios a una obra
  Future<void> asignarUsuariosAObra(List<int> idsUsuarios, int idObra) async {
    await _initialize();

    for (var idUsuario in idsUsuarios) {
      await _usuarioObraDao.insert(UsuarioObra(
        idUsuario: idUsuario,
        idObra: idObra,
      ));
    }
  }

  // ELIMINAR todos los usuarios de una obra
  Future<void> eliminarTodosUsuariosDeObra(int idObra) async {
    await _initialize();
    await _usuarioObraDao.deleteByObra(idObra);
  }

  // ELIMINAR todas las gestion_obras de un usuario
  Future<void> eliminarTodasObrasDeUsuario(int idUsuario) async {
    await _initialize();
    await _usuarioObraDao.deleteByUsuario(idUsuario);
  }

  // OBTENER gestion_obras accesibles con filtro
  Future<List<int>> obtenerObrasAccesibles(
      int idUsuario, {
        List<int>? excludeObras,
      }) async {
    await _initialize();

    final todasObras = await _usuarioObraDao.getObrasByUsuario(idUsuario);

    if (excludeObras != null) {
      return todasObras.where((obra) => !excludeObras.contains(obra)).toList();
    }

    return todasObras;
  }
}