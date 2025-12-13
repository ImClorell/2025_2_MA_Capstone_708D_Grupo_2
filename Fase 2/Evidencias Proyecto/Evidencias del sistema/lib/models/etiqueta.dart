import 'package:flutter/material.dart';

class Etiqueta {
  final int id;
  final String nombre;
  final Color color;

  Etiqueta({
    required this.id,
    required this.nombre,
    required this.color,
  });

  factory Etiqueta.fromMap(Map<String, dynamic> map) {
    return Etiqueta(
      id: map['id'] as int,
      nombre: map['nombre'] as String,
      color: Color(map['color'] as int),
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'nombre': nombre,
      // value está deprecado, usamos toARGB32()
      'color': color.toARGB32(),
    };
  }
}
