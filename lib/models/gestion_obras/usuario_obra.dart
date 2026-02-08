//clase para relacion usuario- gestion_obras
import 'package:flutter/material.dart';
class UsuarioObra {
  int idUsuario;
  int idObra;

  UsuarioObra({
    required this.idUsuario,
    required this.idObra,
  });

  factory UsuarioObra.fromMap(Map<String, dynamic> map) {
    return UsuarioObra(
      idUsuario: map['id_usuario'],
      idObra: map['id_obra'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_usuario': idUsuario,
      'id_obra': idObra,
    };
  }
}