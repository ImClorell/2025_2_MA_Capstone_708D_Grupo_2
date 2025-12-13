import '../core/supabase_client.dart';
import '../models/rutina.dart';

class RutinasService {
  final _sb = Supa.client;

  /// Lista rutinas
  Future<List<Rutina>> listar() async {
    final uid = _sb.auth.currentUser!.id;

    final data = await _sb
        .from('rutinas')
        .select('*')
        .eq('usuario_id', uid)
        .order('creado_en', ascending: false);

    return (data as List).map((m) => Rutina.fromMap(m)).toList();
  }

  /// Crear rutina
  Future<Rutina> crear(Rutina r) async {
    final uid = _sb.auth.currentUser!.id;

    final inserted = await _sb
        .from('rutinas')
        .insert(r.toInsert(uid))
        .select()
        .single();

    return Rutina.fromMap(inserted);
  }

  /// Actualizar rutina
  Future<void> actualizar(int id, Rutina r) async {
    await _sb.from('rutinas').update(r.toUpdate()).eq('id', id);
  }

  /// Eliminar rutina
  Future<void> eliminar(int id) async {
    await _sb.from('rutinas').delete().eq('id', id);
  }
}
