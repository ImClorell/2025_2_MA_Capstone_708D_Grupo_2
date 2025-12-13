import 'package:flutter/material.dart';
import 'package:agendai/core/supabase_client.dart';
import 'package:agendai/models/etiqueta.dart';

class EtiquetasService {
  final _client = Supa.client;

  // Etiquetas por defecto que queremos que existan
  static final List<Map<String, dynamic>> _defaultEtiquetas = [
    {
      'nombre': 'Salud',
      'color': const Color(0xFF26A69A), // verde agua
    },
    {
      'nombre': 'Trabajo',
      'color': const Color(0xFF42A5F5), // azul
    },
    {
      'nombre': 'Estudio',
      'color': const Color(0xFF5C6BC0), // morado azulado
    },
    {
      'nombre': 'Personal',
      'color': const Color(0xFFAB47BC), // morado
    },
  ];

  Future<List<Etiqueta>> listar() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('No hay usuario autenticado');
    }

    // 1) Leer etiquetas SOLO del usuario actual
    final data = await _client
        .from('etiquetas')
        .select()
        .eq('usuario_id', user.id)
        .order('nombre', ascending: true);

    List<dynamic> lista = data;

    // Si ya tiene etiquetas, las devolvemos
    if (lista.isNotEmpty) {
      return lista
          .map((e) => Etiqueta.fromMap(e as Map<String, dynamic>))
          .toList();
    }

    // 2) Si no tiene ninguna, insertamos las 4 por defecto en la BD
    final rowsToInsert = _defaultEtiquetas
        .map((e) => {
              'usuario_id': user.id,
              'nombre': e['nombre'] as String,
              'color': (e['color'] as Color).toARGB32(), // se guarda como int
            })
        .toList();

    final inserted = await _client
        .from('etiquetas')
        .insert(rowsToInsert)
        .select()
        .order('nombre', ascending: true);

    lista = inserted;

    return lista
        .map((e) => Etiqueta.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<Etiqueta> crear({
    required String nombre,
    required Color color,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('No hay usuario autenticado');
    }

    final Map<String, dynamic> data = await _client
        .from('etiquetas')
        .insert({
          'usuario_id': user.id,
          'nombre': nombre.trim(),
          'color': color.toARGB32(),
        })
        .select()
        .single();

    return Etiqueta.fromMap(data);
  }
}
