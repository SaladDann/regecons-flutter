class Usuario {
  int? idUsuario;
  String username;
  String email;
  String nombreCompleto;
  String? genero;
  DateTime? fechaNacimiento;
  String passwordHash;
  String passwordSalt;
  DateTime? fechaUltimoCambioPassword;
  bool aceptaTerminos;
  String estado;
  DateTime fechaCreacion;
  int idRol;

  Usuario({
    this.idUsuario,
    required this.username,
    required this.email,
    required this.nombreCompleto,
    this.genero,
    this.fechaNacimiento,
    required this.passwordHash,
    required this.passwordSalt,
    this.fechaUltimoCambioPassword,
    required this.aceptaTerminos,
    required this.estado,
    required this.fechaCreacion,
    required this.idRol,
  });

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      idUsuario: map['id_usuario'],
      username: map['username'],
      email: map['email'],
      nombreCompleto: map['nombre_completo'],
      genero: map['genero'],
      fechaNacimiento: map['fecha_nacimiento'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['fecha_nacimiento'])
          : null,
      passwordHash: map['password_hash'],
      passwordSalt: map['password_salt'],
      fechaUltimoCambioPassword: map['fecha_ultimo_cambio_password'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
          map['fecha_ultimo_cambio_password'])
          : null,
      aceptaTerminos: map['acepta_terminos'] == 1,
      estado: map['estado'],
      fechaCreacion:
      DateTime.fromMillisecondsSinceEpoch(map['fecha_creacion']),
      idRol: map['id_rol'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_usuario': idUsuario,
      'username': username,
      'email': email,
      'nombre_completo': nombreCompleto,
      'genero': genero,
      'fecha_nacimiento': fechaNacimiento?.millisecondsSinceEpoch,
      'password_hash': passwordHash,
      'password_salt': passwordSalt,
      'fecha_ultimo_cambio_password':
      fechaUltimoCambioPassword?.millisecondsSinceEpoch,
      'acepta_terminos': aceptaTerminos ? 1 : 0,
      'estado': estado,
      'fecha_creacion': fechaCreacion.millisecondsSinceEpoch,
      'id_rol': idRol,
    };
  }
}