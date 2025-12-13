// lib/pages/recordatorio/recordatorios_page.dart
import 'package:flutter/material.dart';
import 'package:agendai/models/recordatorio.dart';
import 'package:agendai/services/recordatorios_service.dart';

import 'detalle_recordatorio_page.dart';
import 'form_recordatorio_page.dart';

class RecordatoriosPage extends StatefulWidget {
  const RecordatoriosPage({super.key});

  @override
  State<RecordatoriosPage> createState() => _RecordatoriosPageState();
}

class _RecordatoriosPageState extends State<RecordatoriosPage> {
  final _service = RecordatoriosService();
  late Future<List<Recordatorio>> _futureRecordatorios;

  @override
  void initState() {
    super.initState();
    _futureRecordatorios = _cargarRecordatorios();
  }

  Future<List<Recordatorio>> _cargarRecordatorios() async {
    // Usa el listar() que agregamos en el servicio
    return _service.listar();
  }

  Future<void> _refrescar() async {
    setState(() {
      _futureRecordatorios = _cargarRecordatorios();
    });
  }

  Future<void> _crearRecordatorio() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FormRecordatorioPage(),
      ),
    );

    if (result == true) {
      await _refrescar();
    }
  }

  Future<void> _abrirDetalle(Recordatorio recordatorio) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetalleRecordatorioPage(recordatorio: recordatorio),
      ),
    );

    if (result == true) {
      await _refrescar();
    }
  }

  Color _colorPorPrioridad(String? prioridad) {
    switch ((prioridad ?? 'media').toLowerCase()) {
      case 'alta':
        return Colors.redAccent;
      case 'baja':
        return Colors.green;
      case 'media':
      default:
        return Colors.orangeAccent;
    }
  }

  Color _colorPorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'completado':
        return Colors.blueAccent;
      case 'pendiente':
        return Colors.orange;
      case 'activo':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorFondoCard = isDark ? Colors.grey[900]! : Colors.grey[100]!;
    final colorTitulo = isDark ? Colors.white : Colors.black;
    final colorSubtitulo = isDark ? Colors.white70 : Colors.grey[800];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recordatorios'),
        centerTitle: true,
        backgroundColor: const Color(0xFF8C3C37),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF8C3C37),
        foregroundColor: Colors.white,
        onPressed: _crearRecordatorio,
        label: const Text('Nuevo Recordatorio'),
        icon: const Icon(Icons.add_alert),
      ),
      body: RefreshIndicator(
        onRefresh: _refrescar,
        child: FutureBuilder<List<Recordatorio>>(
          future: _futureRecordatorios, // <- nombre correcto
          builder: (context, snapshot) {
            // Cargando
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  Center(child: CircularProgressIndicator()),
                ],
              );
            }

            // Error
            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 40),
                  const Center(
                    child: Text(
                      'Error al cargar los recordatorios.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }

            final recordatorios = snapshot.data ?? [];

            // Lista vacía
            if (recordatorios.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  Center(
                    child: Text(
                      'No hay recordatorios próximos',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              );
            }

            // Lista con datos
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: recordatorios.length,
              itemBuilder: (context, index) {
                final recordatorio = recordatorios[index];

                // Derivamos fecha y hora desde programadoEn
                final dt = recordatorio.programadoEn.toLocal();
                final fecha = "${dt.day}/${dt.month}/${dt.year}";
                final hora = TimeOfDay.fromDateTime(dt).format(context);

                final descripcion = recordatorio.mensaje ?? '';

                return Card(
                  color: colorFondoCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: const Icon(
                      Icons.alarm,
                      color: Colors.orangeAccent,
                      size: 28,
                    ),
                    title: Text(
                      recordatorio.titulo,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorTitulo,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "$fecha • $hora",
                                style: TextStyle(color: colorSubtitulo),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          if (descripcion.isNotEmpty)
                            Text(
                              descripcion,
                              style: TextStyle(color: colorSubtitulo),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.flag,
                                color:
                                    _colorPorPrioridad(recordatorio.prioridad),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Prioridad: ${recordatorio.prioridad ?? 'media'}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.circle,
                                color: _colorPorEstado(recordatorio.estado),
                                size: 10,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                recordatorio.estado,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    isThreeLine: true,
                    onTap: () => _abrirDetalle(recordatorio),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
