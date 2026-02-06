import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Avance {
  int? idAvance;
  int idActividad;
  int idUsuario;
  DateTime fecha;
  double horasTrabajadas;
  String? descripcion;
  String? evidenciaFoto;
  String estado;

  // Solo para UI, no persistente
  double porcentajeEjecutado = 0;

  Avance({
    this.idAvance,
    required this.idActividad,
    required this.idUsuario,
    required this.fecha,
    this.porcentajeEjecutado = 0,
    this.horasTrabajadas = 0,
    this.descripcion,
    this.evidenciaFoto,
    this.estado = 'REGISTRADO',
  });

  // Convertir de Map a Avance (solo columnas reales de BD)
  factory Avance.fromMap(Map<String, dynamic> map) {
    return Avance(
      idAvance: map['id_avance'],
      idActividad: map['id_actividad'],
      idUsuario: map['id_usuario'],
      fecha: DateTime.fromMillisecondsSinceEpoch(map['fecha']),
      horasTrabajadas: map['horas_trabajadas'] != null
          ? (map['horas_trabajadas'] as num).toDouble()
          : 0,
      descripcion: map['descripcion'],
      evidenciaFoto: map['evidencia_foto'],
      estado: map['estado'] ?? 'REGISTRADO',
    );
  }

  // Convertir de Avance a Map (solo columnas reales de BD)
  Map<String, dynamic> toMap() {
    return {
      'id_avance': idAvance,
      'id_actividad': idActividad,
      'id_usuario': idUsuario,
      'fecha': fecha.millisecondsSinceEpoch,
      'horas_trabajadas': horasTrabajadas,
      'descripcion': descripcion,
      'evidencia_foto': evidenciaFoto,
      'estado': estado,
    };
  }

  // Métodos de utilidad
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
      default: // REGISTRADO
        return Colors.blue;
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
        return 'En Proceso';
      case 'PENDIENTE':
        return 'Pendiente';
      case 'CANCELADO':
        return 'Cancelado';
      default:
        return 'Registrado';
    }
  }

  // Validaciones
  bool get tieneEvidencia =>
      evidenciaFoto != null && evidenciaFoto!.isNotEmpty;
  bool get tieneDescripcion =>
      descripcion != null && descripcion!.isNotEmpty;
  bool get tieneHorasTrabajadas => horasTrabajadas > 0;

  String get porcentajeTexto =>
      '${porcentajeEjecutado.toStringAsFixed(1)}%';

  String? get horasTexto =>
      horasTrabajadas > 0 ? '${horasTrabajadas.toStringAsFixed(1)} horas' : null;

  // Copiar con nuevos valores
  Avance copyWith({
    int? idAvance,
    int? idActividad,
    int? idUsuario,
    DateTime? fecha,
    double? porcentajeEjecutado,
    double? horasTrabajadas,
    String? descripcion,
    String? evidenciaFoto,
    String? estado,
  }) {
    return Avance(
      idAvance: idAvance ?? this.idAvance,
      idActividad: idActividad ?? this.idActividad,
      idUsuario: idUsuario ?? this.idUsuario,
      fecha: fecha ?? this.fecha,
      porcentajeEjecutado: porcentajeEjecutado ?? this.porcentajeEjecutado,
      horasTrabajadas: horasTrabajadas ?? this.horasTrabajadas,
      descripcion: descripcion ?? this.descripcion,
      evidenciaFoto: evidenciaFoto ?? this.evidenciaFoto,
      estado: estado ?? this.estado,
    );
  }
}
