import '../core/supabase_client.dart';

class TareasService {
  final _sb = Supa.client;

  Future<List<Map<String, dynamic>>> listar(int notaId) async {
    return await _sb
        .from('tareas_nota')
        .select('*')
        .eq('nota_id', notaId)
        .order('posicion');
  }

  Future<void> crear({
    required int notaId,
    required String titulo,
  }) async {
    await _sb.from('tareas_nota').insert({
      'nota_id': notaId,
      'titulo': titulo,
    });
  }

  Future<void> actualizar(int id, bool completada) async {
    await _sb.from('tareas_nota').update({
      'completada': completada,
    }).eq('id', id);
  }

  Future<void> eliminar(int id) async {
    await _sb.from('tareas_nota').delete().eq('id', id);
  }
}
