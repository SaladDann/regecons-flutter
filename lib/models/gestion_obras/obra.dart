import 'package:flutter/material.dart';

class Obra {
  int? idObra;
  String nombre;
  String? descripcion;
  String? direccion;
  String? cliente;
  DateTime? fechaInicio;
  DateTime? fechaFin;
  double? presupuesto;
  String estado; // 'PLANIFICADA','ACTIVA','SUSPENDIDA','FINALIZADA'
  double? porcentajeAvance;

  Obra({
    this.idObra,
    required this.nombre,
    this.descripcion,
    this.direccion,
    this.cliente,
    this.fechaInicio,
    this.fechaFin,
    this.presupuesto,
    required this.estado,
    this.porcentajeAvance = 0.0,
  });

  factory Obra.fromMap(Map<String, dynamic> map) {
    return Obra(
      idObra: map['id_obra'],
      nombre: map['nombre'],
      descripcion: map['descripcion'],
      direccion: map['direccion'],
      cliente: map['cliente'],
      fechaInicio: map['fecha_inicio'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['fecha_inicio'])
          : null,
      fechaFin: map['fecha_fin'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['fecha_fin'])
          : null,
      presupuesto: (map['presupuesto'] as num?)?.toDouble(),
      estado: map['estado'] ?? 'PLANIFICADA',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_obra': idObra,
      'nombre': nombre,
      'descripcion': descripcion,
      'direccion': direccion,
      'cliente': cliente,
      'fecha_inicio': fechaInicio?.millisecondsSinceEpoch,
      'fecha_fin': fechaFin?.millisecondsSinceEpoch,
      'presupuesto': presupuesto,
      'estado': estado,
    };
  }

  String get fechaInicioFormatted {
    if (fechaInicio == null) return 'No definida';
    return '${fechaInicio!.day}/${fechaInicio!.month}/${fechaInicio!.year}';
  }

  String get fechaFinFormatted {
    if (fechaFin == null) return 'No definida';
    return '${fechaFin!.day}/${fechaFin!.month}/${fechaFin!.year}';
  }

  Color get estadoColor {
    switch (estado) {
      case 'ACTIVA':
        return Colors.green;
      case 'PLANIFICADA':
        return Colors.yellow;
      case 'SUSPENDIDA':
        return Colors.orange;
      case 'FINALIZADA':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData get estadoIcon {
    switch (estado) {
      case 'ACTIVA':
        return Icons.play_circle_fill;
      case 'PLANIFICADA':
        return Icons.schedule;
      case 'SUSPENDIDA':
        return Icons.pause_circle_filled;
      case 'FINALIZADA':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }
}
