// lib/models/nota.dart
class Nota {
  final int? id;
  final String? usuarioId;
  final String titulo;
  final String? descripcion;
  final String? detalle;
  final String? etiqueta;
  final String prioridad; // 'baja' | 'media' | 'alta'
  final String estado;    // 'activo' | 'completada' | 'archivada'
  final DateTime? venceEn;
  final bool fijada;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  Nota({
    this.id,
    this.usuarioId, // ahora ES OPCIONAL
    required this.titulo,
    this.descripcion,
    this.detalle,
    this.etiqueta,
    this.prioridad = 'media',
    this.estado = 'activo',
    this.venceEn,
    this.fijada = false,
    this.creadoEn,
    this.actualizadoEn,
  });

  factory Nota.fromMap(Map<String, dynamic> map) {
    return Nota(
      id: map['id'] as int?,
      usuarioId: map['usuario_id'] as String?,
      titulo: (map['titulo'] as String?) ?? '',
      descripcion: map['descripcion'] as String?,
      detalle: map['detalle'] as String?,
      etiqueta: map['etiqueta'] as String?,
      prioridad: (map['prioridad'] as String?) ?? 'media',
      estado: (map['estado'] as String?) ?? 'activo',
      venceEn: map['vence_en'] != null
          ? DateTime.parse(map['vence_en'].toString())
          : null,
      fijada: map['fijada'] as bool? ?? false,
      creadoEn: map['creado_en'] != null
          ? DateTime.parse(map['creado_en'].toString())
          : null,
      actualizadoEn: map['actualizado_en'] != null
          ? DateTime.parse(map['actualizado_en'].toString())
          : null,
    );
  }

  /// Mapa para insertar en Supabase
  Map<String, dynamic> toInsertMap() {
    return {
      'usuario_id': usuarioId,
      'titulo': titulo,
      'descripcion': descripcion,
      'detalle': detalle,
      'etiqueta': etiqueta,
      'prioridad': prioridad,
      'estado': estado,
      'vence_en': venceEn?.toIso8601String(),
      'fijada': fijada,
    };
  }

  /// Mapa para actualizar en Supabase
  Map<String, dynamic> toUpdateMap() {
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'detalle': detalle,
      'etiqueta': etiqueta,
      'prioridad': prioridad,
      'estado': estado,
      'vence_en': venceEn?.toIso8601String(),
      'fijada': fijada,
      'actualizado_en': DateTime.now().toIso8601String(),
    };
  }

  Nota copyWith({
    int? id,
    String? usuarioId,
    String? titulo,
    String? descripcion,
    String? detalle,
    String? etiqueta,
    String? prioridad,
    String? estado,
    DateTime? venceEn,
    bool? fijada,
    DateTime? creadoEn,
    DateTime? actualizadoEn,
  }) {
    return Nota(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      detalle: detalle ?? this.detalle,
      etiqueta: etiqueta ?? this.etiqueta,
      prioridad: prioridad ?? this.prioridad,
      estado: estado ?? this.estado,
      venceEn: venceEn ?? this.venceEn,
      fijada: fijada ?? this.fijada,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
    );
  }
}
