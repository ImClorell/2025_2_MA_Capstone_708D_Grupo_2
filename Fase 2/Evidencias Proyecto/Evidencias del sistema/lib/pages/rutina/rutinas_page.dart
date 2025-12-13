// lib/pages/rutina/rutinas_page.dart
import 'package:flutter/material.dart';

import 'package:agendai/models/rutina.dart';
import 'package:agendai/services/rutinas_service.dart';

import 'detalle_rutina_page.dart';
import 'form_rutina_page.dart';

class RutinasPage extends StatefulWidget {
  const RutinasPage({super.key});

  @override
  State<RutinasPage> createState() => _RutinasPageState();
}

class _RutinasPageState extends State<RutinasPage> {
  final _service = RutinasService();
  late Future<List<Rutina>> _futureRutinas;

  @override
  void initState() {
    super.initState();
    _cargarRutinas();
  }

  void _cargarRutinas() {
    _futureRutinas = _service.listar();
  }

  Future<void> _refrescar() async {
    setState(() {
      _cargarRutinas();
    });
  }

  Future<void> _crearRutina() async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const FormRutinaPage(),
      ),
    );

    if (resultado == true) {
      setState(() {
        _cargarRutinas();
      });
    }
  }

  Future<void> _abrirDetalle(Rutina rutina) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DetalleRutinaPage(rutina: rutina),
      ),
    );

    if (resultado == true) {
      setState(() {
        _cargarRutinas();
      });
    }
  }

  Color _colorPorEstado(String estado) {
    final e = estado.toLowerCase().trim();
    if (e.contains('activa')) {
      return Colors.green;
    } else if (e.contains('complet')) {
      return Colors.blueAccent;
    } else if (e.contains('archiv')) {
      return Colors.grey;
    }
    return Colors.grey;
  }

  String _textoFrecuencia(String? frecuenciaRaw) {
    if (frecuenciaRaw == null || frecuenciaRaw.trim().isEmpty) {
      return 'Sin frecuencia definida';
    }

    final f = frecuenciaRaw.trim().toLowerCase();

    if (f == 'diaria') return 'Diaria';
    if (f == 'semanal') return 'Semanal';
    if (f == 'mensual') return 'Mensual';
    if (f == '3_veces_por_semana' || f == '3 veces por semana') {
      return '3 veces por semana';
    }
    if (f == 'lunes_a_viernes' || f == 'lunes a viernes') {
      return 'Lunes a Viernes';
    }

    // Cualquier otro texto, lo devolvemos tal cual
    return frecuenciaRaw;
  }

  /// Usa fechaInicio + hora (String "HH:mm") como "recordatorio"
  String _textoRecordatorio(Rutina r) {
    if (r.fechaInicio == null || r.hora == null || r.hora!.trim().isEmpty) {
      return 'Sin recordatorio';
    }

    final d = r.fechaInicio!;
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();

    final hora = r.hora!.trim(); // se asume "HH:mm"

    return '$dd/$mm/$yyyy • $hora';
  }

  Widget _tarjetaRutina(
    BuildContext context, {
    required Rutina rutina,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorCard = isDark ? Colors.grey[900]! : Colors.grey[100]!;
    final colorTitulo = isDark ? Colors.white : Colors.black87;
    final colorSub = isDark ? Colors.white70 : Colors.grey[700]!;

    final subtitulo = (rutina.descripcion?.trim().isNotEmpty ?? false)
        ? rutina.descripcion!.trim()
        : 'Sin descripción';

    final freqTexto = _textoFrecuencia(rutina.frecuencia);
    final recTexto = _textoRecordatorio(rutina);
    final estadoColor = _colorPorEstado(rutina.estado);

    return Card(
      color: colorCard,
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Text(
                rutina.nombre,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: colorTitulo,
                ),
              ),
              const SizedBox(height: 4),

              // Descripción
              Text(
                subtitulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: colorSub,
                ),
              ),
              const SizedBox(height: 8),

              // Frecuencia
              Row(
                children: [
                  const Icon(
                    Icons.repeat,
                    size: 18,
                    color: Colors.teal,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Frecuencia: $freqTexto',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorSub,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Recordatorio (fechaInicio + hora)
              Row(
                children: [
                  const Icon(
                    Icons.alarm,
                    size: 18,
                    color: Colors.orangeAccent,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Recordatorio: $recTexto',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorSub,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Estado como chip
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: estadoColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: estadoColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rutina.estado,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: estadoColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rutinas'),
        centerTitle: true,
        backgroundColor: const Color(0xFF8C3C37),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF8C3C37),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva rutina'),
        onPressed: _crearRutina,
      ),
      body: RefreshIndicator(
        onRefresh: _refrescar,
        child: FutureBuilder<List<Rutina>>(
          future: _futureRutinas,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView(
                children: const [
                  SizedBox(
                    height: 250,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ],
              );
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Error al cargar rutinas: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              );
            }

            final rutinas = snapshot.data ?? [];

            if (rutinas.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Center(
                    child: Text(
                      'No hay rutinas registradas.',
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rutinas.length,
              itemBuilder: (context, index) {
                final r = rutinas[index];
                return _tarjetaRutina(
                  context,
                  rutina: r,
                  onTap: () => _abrirDetalle(r),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
