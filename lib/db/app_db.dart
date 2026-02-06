import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  // SINGLETON
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  static Database? _database;

  // TABLAS
  static const String _tablaRoles = '''
  CREATE TABLE roles (
    id_rol INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL UNIQUE,
    descripcion TEXT
  );
  ''';

  static const String _tablaUsuarios = '''
  CREATE TABLE usuarios (
    id_usuario INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL UNIQUE,
    email TEXT NOT NULL UNIQUE,
    nombre_completo TEXT NOT NULL,
    genero TEXT CHECK(genero IN ('M','F','O')),
    fecha_nacimiento INTEGER,
    password_hash TEXT NOT NULL,
    password_salt TEXT NOT NULL,
    fecha_ultimo_cambio_password INTEGER,
    acepta_terminos INTEGER NOT NULL CHECK(acepta_terminos IN (0,1)),
    estado TEXT NOT NULL CHECK(estado IN ('ACTIVO','INACTIVO','BLOQUEADO')) DEFAULT 'ACTIVO',
    fecha_creacion INTEGER NOT NULL,
    id_rol INTEGER NOT NULL,
    FOREIGN KEY (id_rol) REFERENCES roles(id_rol)
  );
  ''';

  static const String _tablaSesiones = '''
  CREATE TABLE sesiones (
    id_sesion INTEGER PRIMARY KEY AUTOINCREMENT,
    id_usuario INTEGER NOT NULL,
    token TEXT NOT NULL UNIQUE,
    fecha_creacion INTEGER NOT NULL,
    fecha_expiracion INTEGER NOT NULL,
    activa INTEGER NOT NULL CHECK(activa IN (0,1)) DEFAULT 1,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
  );
  ''';

  static const String _tablaObras = '''
  CREATE TABLE obras (
    id_obra INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL,
    descripcion TEXT,
    direccion TEXT,
    cliente TEXT,
    fecha_inicio INTEGER,
    fecha_fin INTEGER,
    presupuesto REAL,
    estado TEXT CHECK(estado IN (
      'PLANIFICADA','ACTIVA','SUSPENDIDA','FINALIZADA'
    ))
  );
  ''';

  static const String _tablaUsuarioObra = '''
  CREATE TABLE usuario_obra (
    id_usuario INTEGER NOT NULL,
    id_obra INTEGER NOT NULL,
    PRIMARY KEY (id_usuario, id_obra),
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario),
    FOREIGN KEY (id_obra) REFERENCES obras(id_obra)
  );
  ''';

  // ================= ACTIVIDADES =================
  static const String _tablaActividades = '''
  CREATE TABLE actividades (
    id_actividad INTEGER PRIMARY KEY AUTOINCREMENT,
    id_obra INTEGER NOT NULL,
    nombre TEXT NOT NULL,
    descripcion TEXT,
    estado TEXT DEFAULT 'PENDIENTE',
    FOREIGN KEY (id_obra) REFERENCES obras(id_obra)
  );
  ''';

  // ================= AVANCES =================
  static const String _tablaAvances = '''
  CREATE TABLE avances (
    id_avance INTEGER PRIMARY KEY AUTOINCREMENT,
    id_actividad INTEGER NOT NULL,
    id_usuario INTEGER NOT NULL,
    fecha INTEGER NOT NULL,
    horas_trabajadas REAL,
    descripcion TEXT,
    evidencia_foto TEXT,
    estado TEXT DEFAULT 'REGISTRADO',
    sincronizado INTEGER DEFAULT 0,
    FOREIGN KEY (id_actividad) REFERENCES actividades(id_actividad),
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
  );
  ''';

  static const String _tablaReportesSeguridad = '''
  CREATE TABLE reportes_seguridad (
    id_reporte INTEGER PRIMARY KEY AUTOINCREMENT,
    id_obra INTEGER NOT NULL,
    id_usuario INTEGER NOT NULL,
    tipo TEXT CHECK(tipo IN ('INCIDENTE','CONDICION_INSEGURA')),
    severidad TEXT CHECK(severidad IN ('BAJA','MEDIA','ALTA','CRITICA')),
    descripcion TEXT,
    fecha_evento INTEGER NOT NULL,
    evidencias_foto TEXT,
    estado TEXT DEFAULT 'REPORTADO',
    sincronizado INTEGER DEFAULT 0,
    FOREIGN KEY (id_obra) REFERENCES obras(id_obra),
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
  );
  ''';

  // ================= BASE DE DATOS =================
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'regcons_flutter.db');
    return await openDatabase(
      path,
      version: 1,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(_tablaRoles);
    await db.execute(_tablaUsuarios);
    await db.execute(_tablaSesiones);
    await db.execute(_tablaObras);
    await db.execute(_tablaUsuarioObra);
    await db.execute(_tablaActividades);
    await db.execute(_tablaAvances);
    await db.execute(_tablaReportesSeguridad);

    // Índices
    await db.execute('CREATE INDEX idx_usuarios_rol ON usuarios(id_rol);');
    await db.execute('CREATE INDEX idx_usuarios_username ON usuarios(username);');
    await db.execute('CREATE INDEX idx_usuarios_email ON usuarios(email);');
    await db.execute('CREATE INDEX idx_sesiones_usuario ON sesiones(id_usuario);');
    await db.execute('CREATE INDEX idx_actividades_obra ON actividades(id_obra);');
    await db.execute('CREATE INDEX idx_avances_actividad ON avances(id_actividad);');
    await db.execute('CREATE INDEX idx_avances_usuario ON avances(id_usuario);');
    await db.execute('CREATE INDEX idx_reportes_obra ON reportes_seguridad(id_obra);');

    await _insertarRolesIniciales(db);
    await _insertarUsuarioAdmin(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {}

  // DATOS INICIALES
  Future<void> _insertarRolesIniciales(Database db) async {
    final count = await db.rawQuery('SELECT COUNT(*) FROM roles');
    final rowCount = Sqflite.firstIntValue(count) ?? 0;
    if (rowCount == 0) {
      await db.insert('roles', {'nombre': 'ADMIN', 'descripcion': 'Administrador'});
      await db.insert('roles', {'nombre': 'SUPERVISOR', 'descripcion': 'Supervisor de obra'});
      await db.insert('roles', {'nombre': 'OPERARIO', 'descripcion': 'Operario'});
    }
  }

  Future<void> _insertarUsuarioAdmin(Database db) async {
    final count = await db.rawQuery('SELECT COUNT(*) FROM usuarios WHERE username = ?', ['admin']);
    if ((Sqflite.firstIntValue(count) ?? 0) == 0) {
      final rol = await db.query('roles', where: 'nombre = ?', whereArgs: ['ADMIN']);
      if (rol.isEmpty) return;

      final salt = _generateSalt();
      final hash = _hashPassword('admin123', salt);

      await db.insert('usuarios', {
        'username': 'admin',
        'email': 'admin@regcons.com',
        'nombre_completo': 'Administrador del Sistema',
        'password_hash': hash,
        'password_salt': salt,
        'acepta_terminos': 1,
        'estado': 'ACTIVO',
        'fecha_creacion': DateTime.now().millisecondsSinceEpoch,
        'id_rol': rol.first['id_rol'],
      });
    }
  }

  // SEGURIDAD
  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    return sha256.convert(bytes).toString();
  }
}
