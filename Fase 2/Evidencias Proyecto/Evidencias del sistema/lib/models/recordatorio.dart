// lib/models/recordatorio.dart

class Recordatorio {
  final int id;
  final String usuarioId;
  final String tipo;        // personal / nota / rutina
  final String estado;      // activo / pendiente / completado
  final String titulo;
  final String? mensaje;
  final DateTime programadoEn;
  final String tz;
  final int? notaId;
  final int? rutinaId;

  /// Nueva propiedad: prioridad (baja / media / alta)
  final String? prioridad;

  Recordatorio({
    required this.id,
    required this.usuarioId,
    required this.tipo,
    required this.estado,
    required this.titulo,
    this.mensaje,
    required this.programadoEn,
    required this.tz,
    this.notaId,
    this.rutinaId,
    this.prioridad,
  });

  factory Recordatorio.fromMap(Map<String, dynamic> map) {
    return Recordatorio(
      id: map['id'] as int,
      usuarioId: map['usuario_id'] as String,
      tipo: map['tipo'] as String,
      estado: map['estado'] as String,
      titulo: map['titulo'] as String,
      mensaje: map['mensaje'] as String?,
      programadoEn: DateTime.parse(map['programado_en'] as String),
      tz: map['tz'] as String,
      notaId: map['nota_id'] as int?,
      rutinaId: map['rutina_id'] as int?,
      prioridad: map['prioridad'] as String?, // puede venir null
    );
  }

  /// Mapa para INSERT en Supabase
  /// (tu servicio llama: _client.from('recordatorios').insert(recordatorio.toInsert()))
  Map<String, dynamic> toInsert() {
    return {
      'usuario_id': usuarioId,
      'tipo': tipo,
      'estado': estado,
      'titulo': titulo,
      'mensaje': mensaje,
      'programado_en': programadoEn.toUtc().toIso8601String(),
      'tz': tz,
      'nota_id': notaId,
      'rutina_id': rutinaId,
      if (prioridad != null) 'prioridad': prioridad,
    };
  }

  /// Mapa para UPDATE en Supabase
  /// (tu servicio llama: update(recordatorio.toUpdate()).eq('id', id))
  Map<String, dynamic> toUpdate() {
    return {
      'tipo': tipo,
      'estado': estado,
      'titulo': titulo,
      'mensaje': mensaje,
      'programado_en': programadoEn.toUtc().toIso8601String(),
      'tz': tz,
      'nota_id': notaId,
      'rutina_id': rutinaId,
      if (prioridad != null) 'prioridad': prioridad,
      // OJO: aquí NO mandamos usuario_id para no cambiar el dueño
    };
  }
}
