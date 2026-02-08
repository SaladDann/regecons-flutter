import '../../db/app_db.dart';
import '../../db/daos/auth/usuario_dao.dart';
import '../../db/daos/auth/sesion_dao.dart';
import '../../models/auth/sesion.dart';
import '../../utils/password_hasher.dart';
import '../../models/auth/usuario.dart';

class AuthService {
  late UsuarioDao _usuarioDao;
  late SesionDao _sesionDao;
  bool _inicializado = false;

  Future<void> _initialize() async {
    if (!_inicializado) {
      final db = await AppDatabase().database;
      _usuarioDao = UsuarioDao(db);
      _sesionDao = SesionDao(db);
      _inicializado = true;
    }
  }

  Future<Usuario?> login(String username, String password) async {
    await _initialize();

    final usuario = await _usuarioDao.getByUsername(username);

    if (usuario == null || usuario.estado != 'ACTIVO') {
      return null;
    }

    final isValid = PasswordHasher.verifyPassword(
      password,
      usuario.passwordHash,
      usuario.passwordSalt,
    );

    if (!isValid) {
      return null;
    }

    await _sesionDao.invalidateAllUserSessions(usuario.idUsuario!);

    final token = PasswordHasher.generateSessionToken();
    final now = DateTime.now();
    final expiracion = now.add(const Duration(days: 7));

    final nuevaSesion = Sesion(
      idUsuario: usuario.idUsuario!,
      token: token,
      fechaCreacion: now,
      fechaExpiracion: expiracion,
      activa: true,
    );

    await _sesionDao.insert(nuevaSesion);

    return usuario;
  }

  Future<bool> verificarSesionActiva() async {
    await _initialize();
    await _sesionDao.cleanExpiredSessions();

    final db = await AppDatabase().database;
    final sesionesActivas = await db.query(
      'sesiones',
      where: 'activa = 1',
      limit: 1,
    );

    return sesionesActivas.isNotEmpty;
  }

  Future<void> logout(int userId) async {
    await _initialize();
    await _sesionDao.invalidateAllUserSessions(userId);
  }

  Future<Usuario?> registrarUsuario({
    required String username,
    required String email,
    required String nombreCompleto,
    required String password,
    required bool aceptaTerminos,
    required String genero,
    DateTime? fechaNacimiento,
    required String rol,
  }) async {
    await _initialize();

    if (await _usuarioDao.exists(username)) {
      throw Exception('El usuario ya existe');
    }

    if (await _usuarioDao.getByEmail(email) != null) {
      throw Exception('El email ya está registrado');
    }

    final db = await AppDatabase().database;

    // rol
    final roles = await db.query(
      'roles',
      where: 'nombre = ?',
      whereArgs: [rol.toUpperCase()],
    );

    if (roles.isEmpty) {
      throw Exception('No se encontró el rol $rol');
    }

    final idRolEncontrado = roles.first['id_rol'] as int;
    final salt = PasswordHasher.generateSalt();
    final hash = PasswordHasher.hashPassword(password, salt);

    // Creacion de usuario
    final nuevoUsuario = Usuario(
      username: username,
      email: email,
      nombreCompleto: nombreCompleto,
      genero: genero,
      fechaNacimiento: fechaNacimiento,
      passwordHash: hash,
      passwordSalt: salt,
      aceptaTerminos: aceptaTerminos,
      estado: 'ACTIVO',
      fechaCreacion: DateTime.now(),
      idRol: idRolEncontrado,
    );

    final id = await _usuarioDao.insert(nuevoUsuario);
    nuevoUsuario.idUsuario = id;

    return nuevoUsuario;
  }

  Future<Usuario?> getUsuarioActual() async {
    await _initialize();

    final db = await AppDatabase().database;
    final sesiones = await db.query(
      'sesiones',
      where: 'activa = 1',
      orderBy: 'fecha_creacion DESC',
      limit: 1,
    );

    if (sesiones.isEmpty) {
      return null;
    }

    final idUsuario = sesiones.first['id_usuario'] as int;
    final usuarios = await db.query(
      'usuarios',
      where: 'id_usuario = ?',
      whereArgs: [idUsuario],
    );

    if (usuarios.isEmpty) {
      return null;
    }

    return Usuario.fromMap(usuarios.first);
  }
}
