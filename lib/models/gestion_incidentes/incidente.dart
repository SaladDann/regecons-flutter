import 'dart:convert';

class Incidente {
  int? idReporte;
  int idObra;
  int idUsuario;

  /// INCIDENTE | CONDICION_INSEGURA
  String tipo;

  /// BAJA | MEDIA | ALTA | CRITICA
  String severidad;

  String descripcion;
  DateTime fechaEvento;

  /// Lista de paths locales serializados en JSON
  List<String> evidenciasFoto;

  /// REPORTADO | EN_ANALISIS | RESUELTO | CERRADO
  String estado;

  /// 0 = no sincronizado, 1 = sincronizado
  int sincronizado;

  Incidente({
    this.idReporte,
    required this.idObra,
    required this.idUsuario,
    required this.tipo,
    required this.severidad,
    required this.descripcion,
    required this.fechaEvento,
    this.evidenciasFoto = const [],
    this.estado = 'REPORTADO',
    this.sincronizado = 0,
  });

  // =========================
  // SERIALIZACIÓN BD
  // =========================

  Map<String, dynamic> toMap() {
    return {
      'id_reporte': idReporte,
      'id_obra': idObra,
      'id_usuario': idUsuario,
      'tipo': tipo,
      'severidad': severidad,
      'descripcion': descripcion,
      'fecha_evento': fechaEvento.millisecondsSinceEpoch,
      'evidencias_foto': evidenciasFoto.isNotEmpty
          ? jsonEncode(evidenciasFoto)
          : null,
      'estado': estado,
      'sincronizado': sincronizado,
    };
  }

  factory Incidente.fromMap(Map<String, dynamic> map) {
    return Incidente(
      idReporte: map['id_reporte'],
      idObra: map['id_obra'],
      idUsuario: map['id_usuario'],
      tipo: map['tipo'],
      severidad: map['severidad'],
      descripcion: map['descripcion'] ?? '',
      fechaEvento:
      DateTime.fromMillisecondsSinceEpoch(map['fecha_evento']),
      evidenciasFoto: map['evidencias_foto'] != null
          ? List<String>.from(jsonDecode(map['evidencias_foto']))
          : [],
      estado: map['estado'] ?? 'REPORTADO',
      sincronizado: map['sincronizado'] ?? 0,
    );
  }

  // =========================
  // HELPERS DE UI
  // =========================

  bool get esCritico => severidad == 'CRITICA';

  bool get tieneEvidencias => evidenciasFoto.isNotEmpty;
  String get fechaEventoFormatted {
    return '${fechaEvento.day.toString().padLeft(2, '0')}/'
        '${fechaEvento.month.toString().padLeft(2, '0')}/'
        '${fechaEvento.year}';
  }
}
