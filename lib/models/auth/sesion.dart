class Sesion {
  int? idSesion;
  int idUsuario;
  String token;
  DateTime fechaCreacion;
  DateTime fechaExpiracion;
  bool activa;

  Sesion({
    this.idSesion,
    required this.idUsuario,
    required this.token,
    required this.fechaCreacion,
    required this.fechaExpiracion,
    required this.activa,
  });

  factory Sesion.fromMap(Map<String, dynamic> map) {
    return Sesion(
      idSesion: map['id_sesion'],
      idUsuario: map['id_usuario'],
      token: map['token'],
      fechaCreacion:
      DateTime.fromMillisecondsSinceEpoch(map['fecha_creacion']),
      fechaExpiracion:
      DateTime.fromMillisecondsSinceEpoch(map['fecha_expiracion']),
      activa: map['activa'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_sesion': idSesion,
      'id_usuario': idUsuario,
      'token': token,
      'fecha_creacion': fechaCreacion.millisecondsSinceEpoch,
      'fecha_expiracion': fechaExpiracion.millisecondsSinceEpoch,
      'activa': activa ? 1 : 0,
    };
  }
}