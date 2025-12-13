import '../core/supabase_client.dart';

class AjustesService {
  final _sb = Supa.client;

  /// Obtiene ajustes del usuario actual
  Future<Map<String, dynamic>?> obtener() async {
    final uid = _sb.auth.currentUser!.id;

    final res = await _sb
        .from('ajustes_usuario')
        .select('*')
        .eq('usuario_id', uid)
        .maybeSingle();

    return res;
  }

  /// Upsert de ajustes
  Future<void> upsert({
    required String zonaHoraria,
    String? idioma,
    bool? notificaciones,
    String? posponerPor,
    int? horasLaborales,
  }) async {
    final uid = _sb.auth.currentUser!.id;

    await _sb.from('ajustes_usuario').upsert({
      'usuario_id': uid,
      'zona_horaria': zonaHoraria,
      if (idioma != null) 'idioma': idioma,
      if (notificaciones != null) 'notificaciones': notificaciones,
      if (posponerPor != null) 'posponer_por': posponerPor,
      if (horasLaborales != null) 'horas_laborales': horasLaborales,
    });
  }
}
