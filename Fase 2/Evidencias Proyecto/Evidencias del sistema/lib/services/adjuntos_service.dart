import '../core/supabase_client.dart';

class AdjuntosService {
  final _sb = Supa.client;

  Future<List<Map<String, dynamic>>> listar(int notaId) async {
    return await _sb
        .from('adjuntos')
        .select('*')
        .eq('nota_id', notaId);
  }

  Future<void> agregar({
    required int notaId,
    required String nombre,
    required String url,
  }) async {
    final uid = _sb.auth.currentUser!.id;

    await _sb.from('adjuntos').insert({
      'usuario_id': uid,
      'nota_id': notaId,
      'nombre': nombre,
      'url': url,
    });
  }

  Future<void> eliminar(int id) async {
    await _sb.from('adjuntos').delete().eq('id', id);
  }
}
