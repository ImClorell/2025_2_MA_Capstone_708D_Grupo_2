class Rutina {
  final int id;
  final String usuarioId;
  final String nombre;
  final String? descripcion;
  final String prioridad; // 'baja' | 'media' | 'alta'
  final String estado;    // 'activo' | 'completo' | 'archivado'
  final DateTime? fechaInicio; // date -> manejado como DateTime
  final String? hora;          // text en DB
  final String? frecuencia;
  final String? reglaPersonalizada;
  final DateTime? proximaEjecucionEn;
  final DateTime? ultimaEjecucionEn;
  final DateTime? creadoEn;

  Rutina({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    this.descripcion,
    this.prioridad = 'media',
    this.estado = 'activo',
    this.fechaInicio,
    this.hora,
    this.frecuencia,
    this.reglaPersonalizada,
    this.proximaEjecucionEn,
    this.ultimaEjecucionEn,
    this.creadoEn,
  });

  factory Rutina.fromMap(Map<String, dynamic> m) {
    return Rutina(
      id: m['id'] as int,
      usuarioId: m['usuario_id'] as String,
      nombre: m['nombre'] as String,
      descripcion: m['descripcion'] as String?,
      prioridad: (m['prioridad'] as String?) ?? 'media',
      estado: (m['estado'] as String?) ?? 'activo',
      fechaInicio: m['fecha_inicio'] != null
          ? DateTime.parse(m['fecha_inicio'] as String).toUtc()
          : null,
      hora: m['hora'] as String?,
      frecuencia: m['frecuencia'] as String?,
      reglaPersonalizada: m['regla_personalizada'] as String?,
      proximaEjecucionEn: m['proxima_ejecucion_en'] != null
          ? DateTime.parse(m['proxima_ejecucion_en'] as String).toUtc()
          : null,
      ultimaEjecucionEn: m['ultima_ejecucion_en'] != null
          ? DateTime.parse(m['ultima_ejecucion_en'] as String).toUtc()
          : null,
      creadoEn: m['creado_en'] != null
          ? DateTime.parse(m['creado_en'] as String).toUtc()
          : null,
    );
  }

  Map<String, dynamic> toInsert(String userId) => {
        'usuario_id': userId,
        'nombre': nombre,
        'descripcion': descripcion,
        'prioridad': prioridad,
        'estado': estado,
        'fecha_inicio': fechaInicio?.toIso8601String(),
        'hora': hora,
        'frecuencia': frecuencia,
        'regla_personalizada': reglaPersonalizada,
      };

  Map<String, dynamic> toUpdate() => {
        'nombre': nombre,
        'descripcion': descripcion,
        'prioridad': prioridad,
        'estado': estado,
        'fecha_inicio': fechaInicio?.toIso8601String(),
        'hora': hora,
        'frecuencia': frecuencia,
        'regla_personalizada': reglaPersonalizada,
      };
}
