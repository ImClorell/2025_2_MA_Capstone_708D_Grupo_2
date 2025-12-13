import 'package:agendai/core/supabase_client.dart';
import 'package:agendai/models/nota.dart';

class NotasService {
  final _client = Supa.client;

  Future<List<Nota>> listar() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return [];
    }

    final response = await _client
        .from('notas')
        .select()
        .eq('usuario_id', user.id)
        .order('creado_en', ascending: false);

    final data = response as List<dynamic>;
    return data
        .map((row) => Nota.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> crear(Nota nota) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }

    final notaConUsuario = nota.copyWith(usuarioId: user.id);
    final insertData = notaConUsuario.toInsertMap();

    await _client.from('notas').insert(insertData);
  }

  Future<void> actualizar(Nota nota) async {
    final id = nota.id;
    if (id == null) {
      throw Exception('La nota no tiene id para actualizar');
    }

    final updateData = nota.toUpdateMap();

    await _client.from('notas').update(updateData).eq('id', id);
  }

  Future<void> eliminar(int id) async {
    await _client.from('notas').delete().eq('id', id);
  }
}
