import 'package:flutter/material.dart';

class Avance {
  int? idAvance;
  int idObra;
  int idActividad;
  DateTime fecha;
  double? horasTrabajadas;
  String? descripcion;
  String? evidenciaFoto;
  String estado;
  int sincronizado;

  // Solo para UI (no persistente)
  double porcentajeEjecutado;

  Avance({
    this.idAvance,
    required this.idObra,
    required this.idActividad,
    required this.fecha,
    this.horasTrabajadas = 0,
    this.descripcion,
    this.evidenciaFoto,
    this.estado = 'REGISTRADO',
    this.sincronizado = 0,
    this.porcentajeEjecutado = 0,
  });

  // ======================
  // MAP <-> MODELO
  // ======================

  factory Avance.fromMap(Map<String, dynamic> map) {
    return Avance(
      idAvance: map['id_avance'],
      idObra: map['id_obra'],
      idActividad: map['id_actividad'],
      fecha: DateTime.fromMillisecondsSinceEpoch(map['fecha']),
      horasTrabajadas: (map['horas_trabajadas'] as num?)?.toDouble() ?? 0,
      descripcion: map['descripcion'],
      evidenciaFoto: map['evidencia_foto'],
      estado: map['estado'] ?? 'REGISTRADO',
      sincronizado: map['sincronizado'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_avance': idAvance,
      'id_obra': idObra,
      'id_actividad': idActividad,
      'fecha': fecha.millisecondsSinceEpoch,
      'horas_trabajadas': horasTrabajadas,
      'descripcion': descripcion,
      'evidencia_foto': evidenciaFoto,
      'estado': estado,
      'sincronizado': sincronizado,
    };
  }

  // ======================
  // UI / HELPERS
  // ======================

  String get fechaFormateada =>
      '${fecha.day}/${fecha.month}/${fecha.year}';

  String get horaFormateada =>
      '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';

  String get fechaHoraCompleta => '$fechaFormateada $horaFormateada';

  Color get estadoColor {
    switch (estado) {
      case 'FINALIZADO':
        return Colors.green;
      case 'EN_PROCESO':
        return Colors.orange;
      case 'PENDIENTE':
        return Colors.yellow;
      case 'CANCELADO':
        return Colors.red;
      default:
        return Colors.blue; // REGISTRADO
    }
  }

  IconData get estadoIcon {
    switch (estado) {
      case 'FINALIZADO':
        return Icons.check_circle;
      case 'EN_PROCESO':
        return Icons.play_circle_fill;
      case 'PENDIENTE':
        return Icons.schedule;
      case 'CANCELADO':
        return Icons.cancel;
      default:
        return Icons.assignment;
    }
  }

  String get estadoTexto {
    switch (estado) {
      case 'FINALIZADO':
        return 'Finalizado';
      case 'EN_PROCESO':
        return 'En proceso';
      case 'PENDIENTE':
        return 'Pendiente';
      case 'CANCELADO':
        return 'Cancelado';
      default:
        return 'Registrado';
    }
  }

  // ======================
  // VALIDACIONES
  // ======================

  bool get tieneEvidencia =>
      evidenciaFoto != null && evidenciaFoto!.isNotEmpty;

  bool get tieneDescripcion =>
      descripcion != null && descripcion!.isNotEmpty;

  bool get tieneHorasTrabajadas => horasTrabajadas! > 0;

  String get porcentajeTexto =>
      '${porcentajeEjecutado.toStringAsFixed(1)}%';

  String? get horasTexto =>
      horasTrabajadas! > 0
          ? '${horasTrabajadas?.toStringAsFixed(1)} horas'
          : null;

  // ======================
  // COPY
  // ======================

  Avance copyWith({
    int? idAvance,
    int? idObra,
    int? idActividad,
    DateTime? fecha,
    double? horasTrabajadas,
    String? descripcion,
    String? evidenciaFoto,
    String? estado,
    int? sincronizado,
    double? porcentajeEjecutado,
  }) {
    return Avance(
      idAvance: idAvance ?? this.idAvance,
      idObra: idObra ?? this.idObra,
      idActividad: idActividad ?? this.idActividad,
      fecha: fecha ?? this.fecha,
      horasTrabajadas: horasTrabajadas ?? this.horasTrabajadas,
      descripcion: descripcion ?? this.descripcion,
      evidenciaFoto: evidenciaFoto ?? this.evidenciaFoto,
      estado: estado ?? this.estado,
      sincronizado: sincronizado ?? this.sincronizado,
      porcentajeEjecutado:
      porcentajeEjecutado ?? this.porcentajeEjecutado,
    );
  }
}
