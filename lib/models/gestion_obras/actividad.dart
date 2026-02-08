import 'package:flutter/material.dart';

class Actividad {
  int? idActividad;
  int idObra;
  String nombre;
  String? descripcion;
  String estado;

  // Solo calculado temporalmente para UI, no persistente
  double porcentajeCompletado = 0;

  Actividad({
    this.idActividad,
    required this.idObra,
    required this.nombre,
    this.descripcion,
    this.estado = 'PENDIENTE',
    this.porcentajeCompletado = 0,
  });

  // Convertir de Map a Actividad (solo columnas reales de BD)
  factory Actividad.fromMap(Map<String, dynamic> map) {
    return Actividad(
      idActividad: map['id_actividad'],
      idObra: map['id_obra'],
      nombre: map['nombre'],
      descripcion: map['descripcion'],
      estado: map['estado'] ?? 'PENDIENTE',
    );
  }

  // Convertir de Actividad a Map (solo columnas reales de BD)
  Map<String, dynamic> toMap() {
    return {
      'id_actividad': idActividad,
      'id_obra': idObra,
      'nombre': nombre,
      'descripcion': descripcion,
      'estado': estado,
    };
  }

  // Métodos de utilidad para UI
  Color get estadoColor {
    switch (estado) {
      case 'COMPLETADA':
        return Colors.green;
      case 'EN_PROGRESO':
        return Colors.orange;
      case 'PENDIENTE':
        return Colors.yellow;
      case 'ATRASADA':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData get estadoIcon {
    switch (estado) {
      case 'COMPLETADA':
        return Icons.check_circle;
      case 'EN_PROGRESO':
        return Icons.play_circle_fill;
      case 'PENDIENTE':
        return Icons.schedule;
      case 'ATRASADA':
        return Icons.warning;
      default:
        return Icons.help;
    }
  }

  String get estadoTexto {
    switch (estado) {
      case 'COMPLETADA':
        return 'Completada';
      case 'EN_PROGRESO':
        return 'En Progreso';
      case 'PENDIENTE':
        return 'Pendiente';
      case 'ATRASADA':
        return 'Atrasada';
      default:
        return estado;
    }
  }

  // Validaciones
  bool get esCompletada => estado == 'COMPLETADA';
  bool get tieneDescripcion => descripcion != null && descripcion!.isNotEmpty;

  String? get porcentajeCompletadoTexto {
    return '${porcentajeCompletado.toStringAsFixed(1)}% completado';
  }

  // Copiar con nuevos valores
  Actividad copyWith({
    int? idActividad,
    int? idObra,
    String? nombre,
    String? descripcion,
    String? estado,
    double? porcentajeCompletado,
  }) {
    return Actividad(
      idActividad: idActividad ?? this.idActividad,
      idObra: idObra ?? this.idObra,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      estado: estado ?? this.estado,
      porcentajeCompletado: porcentajeCompletado ?? this.porcentajeCompletado,
    );
  }

  // Validar antes de guardar
  List<String> validar() {
    final errores = <String>[];

    if (nombre.isEmpty) {
      errores.add('El nombre de la actividad es requerido');
    }

    if (idObra <= 0) {
      errores.add('Debe seleccionar una obra válida');
    }

    return errores;
  }
}
