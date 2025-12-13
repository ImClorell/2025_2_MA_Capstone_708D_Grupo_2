// lib/services/recordatorios_service.dart
import 'package:agendai/core/supabase_client.dart';
import 'package:agendai/models/recordatorio.dart';

class RecordatoriosService {
  final _client = Supa.client;

  /// Lista TODOS los recordatorios del usuario actual,
  /// ordenados por fecha de programación ascendente.
  /// (Método genérico que usa listarDelUsuario internamente)
  Future<List<Recordatorio>> listar() {
    return listarDelUsuario();
  }

  /// Lista solo los recordatorios con estado 'pendiente' del usuario actual,
  /// ordenados por fecha de programación ascendente.
  Future<List<Recordatorio>> listarPendientes() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('No hay usuario autenticado');
    }

    final data = await _client
        .from('recordatorios')
        .select()
        .eq('usuario_id', user.id)
        .eq('estado', 'pendiente')
        .order('programado_en', ascending: true);

    final List<dynamic> lista = data;

    return lista
        .map((e) => Recordatorio.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Lista todos los recordatorios del usuario actual,
  /// ordenados por fecha de programación ascendente.
  Future<List<Recordatorio>> listarDelUsuario() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('No hay usuario autenticado');
    }

    final data = await _client
        .from('recordatorios')
        .select()
        .eq('usuario_id', user.id)
        .order('programado_en', ascending: true);

    final List<dynamic> lista = data;

    return lista
        .map((e) => Recordatorio.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Obtiene un recordatorio por ID (si pertenece al usuario actual).
  Future<Recordatorio?> obtenerPorId(int id) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('No hay usuario autenticado');
    }

    final data = await _client
        .from('recordatorios')
        .select()
        .eq('usuario_id', user.id)
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;

    final row = Map<String, dynamic>.from(data as Map);
    return Recordatorio.fromMap(row);
  }

  /// Crea un nuevo recordatorio en Supabase.
  Future<void> crear(Recordatorio recordatorio) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('No hay usuario autenticado');
    }

    // Tomamos el mapa base del modelo y forzamos usuario_id correcto
    final values = recordatorio.toInsert()
      ..['usuario_id'] = user.id;

    await _client.from('recordatorios').insert(values);
  }

  /// Actualiza un recordatorio existente (por ID).
  Future<void> actualizar(int id, Recordatorio recordatorio) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('No hay usuario autenticado');
    }

    final values = recordatorio.toUpdate();

    await _client
        .from('recordatorios') // corregido: antes decía 'recorditorios'
        .update(values)
        .eq('id', id)
        .eq('usuario_id', user.id);
  }

  /// Elimina un recordatorio por ID.
  Future<void> eliminar(int id) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('No hay usuario autenticado');
    }

    await _client
        .from('recordatorios')
        .delete()
        .eq('id', id)
        .eq('usuario_id', user.id);
  }
}
